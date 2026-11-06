# Архитектура FieldPulse

## Монорепо

Репозиторий — [pub workspace](https://dart.dev/tools/pub/workspaces) на Dart 3.13: один
`flutter pub get` из корня резолвит приложение, пакеты и лаборатории, версии зависимостей
согласуются автоматически, `pubspec.lock` один на всё.

| Пакет | Роль | Зависимости |
|---|---|---|
| `packages/core_network` | `Result`, `Failure`, `ApiClient`, маппинг ошибок Dio, `retry` | `dio` |
| `packages/core_storage` | `SecureTokenStore` (токены), `SettingsStore` (настройки) | `flutter_secure_storage`, `shared_preferences` |
| `packages/core_ui` | `AppTheme` (Material 3), адаптивные хелперы iOS/Android | `flutter` |
| корень (`fieldpulse`) | приложение: фичи, домен, DI, роутер, Firebase | пакеты выше |
| `labs/*` | маленькие приложения-лаборатории на тех же пакетах | пакеты выше |

Правила, которые держат границы:

1. `domain` не зависит ни от Flutter, ни от пакетов — только Dart.
2. Зависимость идёт в одну сторону: `app`/`labs` → `packages`. Обратной связи нет.
3. Пакет выносится по правилу двух потребителей: сначала код живёт в приложении,
   при появлении второго использования переезжает в `packages/`.
4. Лаборатории — не демо ради демо: каждая проверяет, что пакет реально
   переиспользуется в другом приложении, и гоняется в CI наравне с основным приложением.

## Слои

```
┌──────────────────────────────────────────────────────────────┐
│ presentation — MVI: Event → Bloc → State → Widget            │
│   orders/presentation/bloc, auth/presentation                │
├──────────────────────────────────────────────────────────────┤
│ domain — модели, контракты, use cases (без Flutter)          │
│   orders/domain (entities, repositories, usecases)           │
├──────────────────────────────────────────────────────────────┤
│ data — DTO, REST/WS/Firestore источники, Hive, репозиторий   │
│   orders/data (datasources, mappers, outbox, repositories)   │
├──────────────────────────────────────────────────────────────┤
│ core — сеть, realtime, хранилища, нативные сервисы, isolates │
└──────────────────────────────────────────────────────────────┘
```

Зависимости направлены только вниз. `domain` не знает про Dio, Hive и Firebase:
репозиторий возвращает доменные `Order`/`OrderEvent`, а не DTO. Это позволяет
тестировать блоки без сети и подменять источники данных в DI.

## Поток данных (offline-first)

```
        ┌─────────── push (FCM) ───────────┐
        │                                  │
REST ──► OrderListRemoteSource ──┐          │
        (Dio + isolate-парсинг)  │          │
                                 ├─► OrdersRepositoryImpl ──► Hive (кэш + outbox)
WS ────► OrderRealtimeSource ────┘            │                        │
        (кады → OrderEvent)                   │                        ▼
                                              └──────────────► watchCachedOrders()
                                                                       │
                                                              OrdersBloc (MVI)
                                                                       │
                                                                   Widgets
```

Ключевое решение: **единственный источник правды для UI — Hive**. Любой ответ сети или
WebSocket сначала пишется в кэш, а UI реактивно перестраивается из `watchCachedOrders()`.
Поэтому интерфейс одинаково работает с живыми данными и в самолётном режиме, а гонки между
REST-ответом и WS-событием не приводят к «миганию» списка.

## MVI в фиче orders

- `OrdersEvent` — намерения пользователя и внешние сигналы (`OrdersStarted`,
  `OrdersSearchChanged`, `OrdersRefreshed`, `OrdersSyncRequested`, `OrdersRemoteEventReceived`).
- `OrdersState` — одно неизменяемое состояние: список, фильтр, поиск, счётчик очереди, баннер.
- `OrdersBloc` — чистая функция `(state, event) → новый state`; сайд-эффекты только через репозиторий.

Поиск выполняется в `SearchOrders`: до 120 нарядов фильтрация идёт на главном изоляте,
выше — через `Isolate.run`, чтобы не ронять кадры на больших выгрузках. Гонки поиска
защищены монотонным токеном (`_searchToken`): ответ устаревшего запроса отбрасывается.

## Обработка мутаций и офлайн-очередь

`changeStatus` / `attachPhoto`:

1. если сети нет — мутация сразу идёт в `outbox` (`PendingAction`) и оптимистично применяется к кэшу;
2. если сеть есть, но ответ — сетевой сбой или 5xx — действие тоже уходит в очередь;
3. 4xx (кроме 401) не ретраится: это ошибка данных, она возвращается в UI.

У каждой мутации есть `Idempotency-Key` (`newRequestId()`), заголовок уходит и в REST, и в
повторе — сервер может безопасно отбросить дубликат после обрыва связи на этапе ответа.

`SyncCoordinator` слушает `connectivity_plus`, при восстановлении связи прогоняет очередь
(`flushPendingUpdates`) и делает `fetchOrders(forceRefresh: true)`; дополнительно есть
страховочный таймер раз в 2 минуты.

## Realtime

`RealtimeClient` (`lib/core/realtime/realtime_client.dart`) держит одно WebSocket-соединение:

- токен передаётся в query-параметре (заголовки для WS в мобильных клиентах недоступны);
- heartbeat раз в 25 секунд, ответы `pong` не попадают в бизнес-поток;
- реконнект с экспоненциальной задержкой 1→2→4→8→16→30 c и джиттером до 400 мс;
- статусы (`connecting/connected/reconnecting/disconnected`) отдаются отдельным стримом.

Форматы кадров (`OrderRealtimeSource`):

```json
{"type": "orders.snapshot", "payload": [{...}]}
{"type": "order.upserted", "reason": "dispatch", "payload": {...}}
{"type": "order.removed", "payload": {"id": "o-42"}}
{"type": "order.comment", "payload": {"order_id": "o-42", "author": "Диспетчер", "text": "..."}}
{"type": "connection", "payload": {"online": true}}
```

## REST

`OrdersApi` (Retrofit) — типизированные операции: карточка наряда, смена статуса, загрузка фото
(multipart), комментарии. Список нарядов сознательно идёт не через Retrofit: тело читается
как строка и парсится в изоляте (`OrderListRemoteSource` + `PayloadDecoder`) — это самая
тяжёлая операция в приложении, и её парсинг не должен конкурировать с рендером.

Интерсепторы Dio:

| Интерсептор | Задача |
|---|---|
| `AuthInterceptor` | Bearer-токен из `SecureStorage`, при 401 — очистка токенов и выход |
| `RetryInterceptor` | 3 попытки на сетевые ошибки и 5xx, экспоненциальный backoff + jitter |
| `PrettyDioLogger` | логи только в debug-сборке (`NETWORK_LOGS`) |

Ошибки приводятся к доменным `Failure` через `DioFailureMapper`, поэтому UI не зависит от Dio.

## Хранилища

| Хранилище | Что лежит | Почему |
|---|---|---|
| Hive `orders_cache_v1` | JSON-снимки нарядов | быстрый офлайн-старт, реактивные `watch()` |
| Hive `outbox_v1` | `PendingAction` | переживает перезапуск и убийство процесса |
| `flutter_secure_storage` | access/refresh токен, флаг биометрии | Keystore/Keychain, `encryptedSharedPreferences` |
| `shared_preferences` | тема, push-настройки, время последней синхронизации | простые скалярные настройки |

Hive-адаптеры не используются намеренно: в боксах лежат JSON-совместимые `Map`, что исключает
проблемы миграции схемы и позволяет переиспользовать один формат для сети и кэша (см. ADR-2).

## Firebase

- **Auth** — вход по почте/паролю, `authStateChanges()` → `AuthCubit` → редирект `go_router`.
- **Firestore** — лента комментариев диспетчера по наряду (`FirestoreCommentsSource`).
- **FCM** — фоновый обработчик `firebaseBackgroundHandler`, deep link по `data.order_id`
  открывает карточку наряда; топики `engineer_<uid>` и `dispatchers`.
- **Cloud Functions** (`functions/src/index.ts`) — `updateOrderStatus` (транзакция + проверка
  допустимых переходов + push), `registerDeviceToken`, `notifyAssignee` (триггер на изменение
  статуса), `archiveClosedOrders` (cron, ежедневно 03:00 МСК).
- **Crashlytics** — `CrashReporter` оборачивает фатальные (`FlutterError.onError`,
  `PlatformDispatcher.onError`, `runZonedGuarded`) и обработанные ошибки (например, битый
  realtime-кадр), проставляет `user_id`.

Если Firebase не сконфигурирован (нет `google-services.json` / `GoogleService-Info.plist`),
`bootstrap` не падает: поднимается `DemoAuthRepository`, push отключается, заказы читаются из
Hive. Это позволяет открыть проект на чистой машине и посмотреть UI.

## Навигация

`go_router` с единственным источником правды о сессии — `AuthCubit`:
`refreshListenable: GoRouterRefreshStream(authCubit.stream)`, redirect на `/login` для
неавторизованных и обратно на `/orders` после входа. Deep link из push:
`/orders/:id`.

## DI

`get_it` (`lib/app/di/injector.dart`). Всё, что имеет состояние, — ленивые синглтоны
(репозиторий, realtime, монитор сети); блоки экранов — фабрики, чтобы состояние не утекало
между переходами. Тяжёлые зависимости (Hive, SharedPreferences) инициализируются в `bootstrap`
до первого `runApp`.
