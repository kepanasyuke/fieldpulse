# FieldPulse

Realtime-приложение для выездных инженеров и курьеров сервисной компании: заказы приходят по WebSocket,
работают офлайн, наряд закрывается с камерой, геолокацией и биометрией.

Проект собран как портфолио под вакансию **серверного (мобильного) разработчика Flutter в ООО «ЦИО»**
и закрывает каждый пункт требований — см. [docs/VACANCY_MAPPING.md](docs/VACANCY_MAPPING.md).

## Что показывает проект

| Требование вакансии | Где смотреть |
|---|---|
| Dart: async, Streams, isolates, метапрограммирование | `lib/core/isolates/`, `lib/core/realtime/`, `lib/core/utils/result.dart` |
| Flutter, адаптивный UI под iOS/Android | `lib/app/theme/`, `lib/core/ui/`, `lib/features/orders/presentation/widgets/` |
| Bloc / Provider, state-менеджмент | `lib/features/orders/presentation/bloc/`, `lib/features/auth/presentation/` |
| REST (Dio, Retrofit), WebSocket | `lib/core/network/`, `lib/features/orders/data/datasources/` |
| Hive, SecureStorage, кэширование | `lib/core/storage/`, `lib/features/orders/data/datasources/order_local_data_source.dart` |
| MVVM/MVI, масштабируемая архитектура | `lib/features/orders/presentation/bloc/orders_bloc.dart`, [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) |
| Firebase: Auth, Firestore, FCM, Functions, Crashlytics | `lib/features/auth/data/`, `lib/core/push/`, `functions/src/index.ts` |
| Камера, геолокация, биометрия | `lib/core/native/` |
| Профайлер и производительность | [docs/PERFORMANCE.md](docs/PERFORMANCE.md), `lib/features/orders/domain/usecases/search_orders.dart` |

## Запуск

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # Retrofit codegen (orders_api.g.dart)
flutter run --dart-define=API_BASE_URL=https://api.fieldpulse.dev/v1 \
            --dart-define=WS_URL=wss://api.fieldpulse.dev/realtime
```

Firebase-конфиг добавляется штатно: `android/app/google-services.json` и `ios/Runner/GoogleService-Info.plist`
(либо `flutterfire configure`). Без них приложение поднимается в offline-режиме: Auth и Push отключаются,
заказы читаются из Hive-кэша, экраны остаются работоспособными.

## Тесты

```bash
flutter test
flutter test --coverage
```

Покрыто: MVI-блок заказов (включая офлайн-ветку и outbox), маппинг DTO, isolate-поиск, realtime-клиент
с реконнектом, виджет-тест карточки заказа.

## Структура

```
lib/
  app/            # bootstrap, DI, роутер, тема
  core/           # сеть, realtime, хранилища, isolates, нативные сервисы, push
  features/
    auth/         # Firebase Auth + биометрический замок
    orders/       # домен / данные / MVI-презентация
    sync/         # очередь офлайн-мутаций, наблюдатель связности
functions/        # Cloud Functions (TypeScript)
docs/             # архитектура, ADR, производительность, соответствие вакансии
test/             # unit + widget тесты
```
