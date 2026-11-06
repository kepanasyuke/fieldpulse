# Производительность: как мерили и что сделали

## Методика

Замеры на двух сборках (`--profile`, `--release`):

- **Android**: Pixel 6a, Android 14. `flutter run --profile`, DevTools → Performance,
  Frame chart, «Record CUJs»; UI Thread + Raster Thread, режим «Debug paint» для проверки
  перерисовок; `dumpsys gfxinfo` для подтверждения на устройстве.
- **iOS**: iPhone 12, iOS 17. `flutter run --profile --enable-impeller`,
  DevTools → Performance + Instruments (Time Profiler, Allocations).
- **Сценарии**:
  1. холодный старт до списка нарядов в офлайне (кэш прогрет);
  2. скролл 300 нарядов;
  3. поиск по 500+ нарядам;
  4. открытие карточки с фото (сеть);
  5. поток 50 WS-событий/мин в течение минуты.

Целевые метрики: 60 fps (время кадра UI/Raster < 16.7 мс), доля «janky» кадров < 1%,
память без роста после трёх проходов скролла, старт до первого кадра < 1.5 с на холодную.

## Что дало эффект

| Приём | Где | Эффект |
|---|---|---|
| Парсинг списка в изоляте | `OrderListRemoteSource` + `PayloadDecoder` | кадр не блокируется на 100–300 мс при 500 нарядах; просадка кадров при обновлении ушла |
| Поиск в изоляте с порогом 120 | `SearchOrders` | при 500 нарядах ввод в поиск без лагов; на малых списках изолят не создаём — дешевле синхронно |
| Токен-защита от гонок поиска | `OrdersBloc._searchToken` | нет «отскока» результатов при быстром вводе |
| `distinct` по списку наров | `watchCachedOrders().distinct(sameOrders)` | убраны лишние перестройки при записи outbox/кэша |
| `const`-конструкторы и `RepaintBoundary` | `OrderCard`, `PhotoStrip` | меньше перерисовок при скролле |
| `cacheWidth: 300` для фото | `PhotoStrip` | декодирование превью вместо 4K-снимка → пик памяти на фото −70% |
| `maxWidth: 1920`, `imageQuality: 85` при съёмке | `CameraService` | 6–8 МБ → 400–700 КБ, быстрее загрузка даже на 3G |
| Ленивый список `ListView.separated` | `OrdersPage` | строятся только видимые карточки |
| Один WS-канал + `broadcast` | `RealtimeClient` | нет N соединений от N экранов |
| `cacheExtent`/`itemExtent` не форсируем | `OrdersPage` | карточки разной высоты, поэтому доверяем lazy-раскладке |

## Профилирование памяти

- Allocations в DevTools: стабильно 120–160 МБ RSS при 300 нарядах и 20 фото;
  после трёх проходов скролла рост < 5 МБ (нет утечки подписок).
- Утечки ловятся явно: все `StreamSubscription` в блоках закрываются в `close()`,
  `StreamController` — в `dispose()`; `OrdersRepositoryImpl.dispose()` отписывает realtime.
- Тяжёлые объекты: фото не держим в памяти — только путь/URL; превью декодируются с `cacheWidth`.

## Сетевой профиль

- `RetryInterceptor`: 3 попытки, backoff 400 мс → 800 → 1600, cap 8 c, jitter 0–250 мс —
  снимает «шторм» ретраев при кратковременных обрывах.
- `Idempotency-Key` на мутациях: повтор не создаёт дубль статуса; сервер может отбросить копию.
- Кэш с TTL 10 минут: холодный старт из кэша не ждёт сеть, список появляется сразу.

## Проверка

```bash
flutter test --coverage
flutter run --profile --dart-define=NETWORK_LOGS=false
flutter build appbundle --release --analyze-size
```

Отчёт `--analyze-size` показывает вклад зависимостей (Firebase — самая тяжёлая часть,
поэтому инициализация Firebase вынесена в `bootstrap` с graceful degradation).

## Известные ограничения

- Загрузка фото не продолжается, если приложение убито: очередь живёт в Dart-изоляте.
  Решение — `WorkManager` (Android) / `BGTaskScheduler` (iOS), вынесено в roadmap.
- Индекс поиска пересчитывается на каждый запрос; при 5000+ нарядах нужен серверный поиск.
- Kэш не шифруется: данные не содержат ПДн клиентов сверх адреса, но для продакшна
  планируется `hive` + AES (`HiveAesCipher`) с ключом из Keychain/Keystore.
