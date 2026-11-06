# Соответствие требованиям вакансии

Вакансия: серверный/мобильный разработчик Flutter, ООО «ЦИО» (digital-агентство, мобильные
приложения и цифровые продукты для брендов и стартапов).

## Обязанности

| Пункт | Как закрыт | Файлы |
|---|---|---|
| Адаптивные и отзывчивые UI под iOS и Android | Material 3 + `Cupertino*` через `context.adaptive`, `PageTransitionsTheme` (Cupertino на iOS, Zoom на Android), адаптивные диалоги и прогресс, `ConstrainedBox`/`isCompact` для планшетов | `lib/core/ui/adaptive.dart`, `lib/app/theme/app_theme.dart` |
| Бизнес-логика и состояние приложения | MVI: события → блок → неизменяемое состояние; правила переходов статусов и SLA живут в домене, а не в виджетах | `lib/features/orders/domain/entities/order.dart`, `lib/features/orders/presentation/bloc/orders_bloc.dart` |
| Интеграция с backend через REST и WebSocket | Retrofit + Dio с интерсепторами; собственный WS-клиент с heartbeat, реконнектом и backoff | `lib/core/network/`, `lib/core/realtime/realtime_client.dart`, `lib/features/orders/data/datasources/order_realtime_source.dart` |
| Hive, Secure Storage, Shared Preferences | Кэш нарядов и офлайн-очередь в Hive, токены в `flutter_secure_storage`, настройки в `shared_preferences` | `lib/core/storage/`, `lib/features/orders/data/datasources/order_local_data_source.dart` |
| Нативные функции: камера, геолокация, биометрия | `image_picker` с ресайзом, `geolocator` с проверкой разрешений и таймаутом, `local_auth` с `biometricOnly` | `lib/core/native/` |
| Профайлер и анализ производительности | Методика замеров, конкретные приёмы (const, RepaintBoundary, cacheWidth, isolate-парсинг) и результаты в отчёте | `docs/PERFORMANCE.md` |

## Требования

| Пункт | Как закрыт | Файлы |
|---|---|---|
| Dart: асинхронность | `Result` + `fold`/`map`/`asyncMap`, отсутствие «голых» исключений на границах слоёв, `runZonedGuarded` | `lib/core/utils/result.dart`, `lib/app/bootstrap.dart` |
| Dart: Streams | Реактивный кэш (`watch()` Hive → стрим), WS-стримы кадров и статусов, `StreamController.broadcast`, транслирование через репозиторий | `order_local_data_source.dart`, `realtime_client.dart`, `orders_repository_impl.dart` |
| Dart: isolates | Парсинг тяжёлого списка и поиск по 500+ нарядам в отдельном изоляте, генератор `PayloadDecoder` с порогом | `lib/core/isolates/payload_decoder.dart`, `lib/features/orders/domain/usecases/search_orders.dart` |
| Dart: метапрограммирование | Генерация кода Retrofit (`@RestApi`, `part`, `build_runner`), sealed-классы и pattern matching для событий/состояний, extensions на `Object`/`BuildContext` | `lib/features/orders/data/datasources/orders_api.dart`, `lib/features/orders/domain/entities/order_event.dart`, `lib/core/network/dio_failure_mapper.dart` |
| Flutter от 2 лет | Продакшн-структура: слои, DI, роутинг, офлайн-очередь, тесты, документация | весь проект |
| Bloc и/или Provider | `flutter_bloc` 9: `Bloc`, `Cubit`, `BlocBuilder/BlocListener/BlocConsumer`, `BlocProvider.value`, тесты на `bloc_test` | `lib/features/**/presentation/**` |
| REST: Dio, Retrofit | `Dio` с таймаутами и `QueuedInterceptor`, `Retrofit`-клиент, `@MultiPart` загрузка фото | `lib/core/network/api_client.dart`, `orders_api.dart` |
| WebSocket | `web_socket_channel`, реконнект, heartbeat, парсинг кадров в доменные события | `lib/core/realtime/realtime_client.dart` |
| Hive, SecureStorage, кэширование | Кэш «свежий → отдаём сразу, устаревший → сеть, сеть упала → кэш», TTL в `AppConfig`, реактивные `watch()` | `orders_repository_impl.dart`, `lib/core/storage/` |
| MVVM / MVI, масштабируемость | Строгий MVI + clean-архитектура, домен без зависимостей от Flutter, тесты блоков без виджетов | `docs/ARCHITECTURE.md` |
| Firebase: Auth, Firestore, FCM, Cloud Functions, Crashlytics | Все пять сервисов задействованы в живых сценариях | `lib/features/auth/data/firebase_auth_repository.dart`, `lib/core/push/`, `lib/features/orders/data/datasources/firestore_comments_source.dart`, `functions/src/index.ts` |

## Будет плюсом

| Пункт | Как закрыт |
|---|---|
| UI/UX: Material 3, Cupertino, адаптивность | `useMaterial3`, цветовая схема из seed, `CupertinoPageTransitionsBuilder`, адаптивные диалоги/прогресс/кнопки, состояния empty/error/loading |
| Оптимизация производительности | Замеры в `docs/PERFORMANCE.md`: isolate-парсинг, `const`, `RepaintBoundary` для списка, `cacheWidth` у изображений, отсутствие пересборки всего списка при поиске |
| Проекты на GitHub/GitLab | Репозиторий самодостаточен: `flutter pub get` → `build_runner` → `flutter run`, тесты и документация в комплекте |

## Что сказать на собеседовании

1. «Почему Hive без адаптеров» — ADR-2: единый JSON-формат для сети и кэша, нет миграций схемы,
   но нет и типобезопасности на уровне хранилища; при росте схемы переходим на `TypeAdapter` + `migrations`.
2. «Как решаете конфликты REST и WS» — ADR-3: единая точка записи в кэш + монотонная версия
   `updated_at`, событие с меньшим временем отбрасывается.
3. «Зачем свой WS-клиент вместо пакета» — нужен контроль над токеном в query, heartbeat,
   backoff и статусами для UI; логика на 200 строк и полностью покрыта тестом.
4. «Что бы сделали дальше» — фоновую отправку фото (`WorkManager`/`BGTaskScheduler`), шифрование
   кэша, `freezed` для состояний, интеграционные тесты на `integration_test`.
