import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fieldpulse/core/config/app_config.dart';
import 'package:fieldpulse/core/isolates/payload_decoder.dart';
import 'package:fieldpulse/core/native/biometric_service.dart';
import 'package:fieldpulse/core/native/camera_service.dart';
import 'package:fieldpulse/core/native/location_service.dart';
import 'package:fieldpulse/core/network/api_client.dart';
import 'package:fieldpulse/core/network/network_monitor.dart';
import 'package:fieldpulse/core/platform/crash_reporter.dart';
import 'package:fieldpulse/core/push/device_token_registrar.dart';
import 'package:fieldpulse/core/push/push_service.dart';
import 'package:fieldpulse/core/realtime/realtime_client.dart';
import 'package:fieldpulse/core/storage/hive_boxes.dart';
import 'package:fieldpulse/core/storage/secure_token_store.dart';
import 'package:fieldpulse/core/storage/settings_store.dart';
import 'package:fieldpulse/features/auth/data/demo_auth_repository.dart';
import 'package:fieldpulse/features/auth/data/firebase_auth_repository.dart';
import 'package:fieldpulse/features/auth/domain/auth_repository.dart';
import 'package:fieldpulse/features/auth/presentation/auth_cubit.dart';
import 'package:fieldpulse/features/auth/presentation/bloc/app_lock_bloc.dart';
import 'package:fieldpulse/features/orders/data/datasources/firestore_comments_source.dart';
import 'package:fieldpulse/features/orders/data/datasources/order_list_remote_source.dart';
import 'package:fieldpulse/features/orders/data/datasources/order_local_data_source.dart';
import 'package:fieldpulse/features/orders/data/datasources/order_realtime_source.dart';
import 'package:fieldpulse/features/orders/data/datasources/orders_api.dart';
import 'package:fieldpulse/features/orders/data/mappers/order_mapper.dart';
import 'package:fieldpulse/features/orders/data/repositories/orders_repository_impl.dart';
import 'package:fieldpulse/features/orders/domain/repositories/order_repository.dart';
import 'package:fieldpulse/features/orders/domain/usecases/attach_photo.dart';
import 'package:fieldpulse/features/orders/domain/usecases/search_orders.dart';
import 'package:fieldpulse/features/orders/presentation/bloc/order_details_bloc.dart';
import 'package:fieldpulse/features/orders/presentation/bloc/orders_bloc.dart';
import 'package:fieldpulse/features/sync/sync_coordinator.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies({
  required AppConfig config,
  required bool firebaseReady,
}) async {
  await HiveBoxes.openAll();
  final preferences = await SharedPreferences.getInstance();

  getIt
    ..registerSingleton<AppConfig>(config)
    ..registerSingleton<SettingsStore>(SettingsStore(preferences))
    ..registerSingleton<CrashReporter>(
      CrashReporter(
        crashlytics: firebaseReady ? FirebaseCrashlytics.instance : null,
      ),
    )
    ..registerLazySingleton<SecureTokenStore>(
      () => SecureTokenStore(
        const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        ),
      ),
    );

  _registerPlatformServices();
  _registerNetwork(config, firebaseReady);
  _registerOrders();
  _registerPresentation(firebaseReady);
}

void _registerPlatformServices() {
  getIt
    ..registerLazySingleton<NetworkMonitor>(
      () => NetworkMonitor(Connectivity()),
    )
    ..registerLazySingleton<PayloadDecoder>(PayloadDecoder.new)
    ..registerLazySingleton<BiometricService>(
      () => BiometricService(LocalAuthentication()),
    )
    ..registerLazySingleton<CameraService>(() => CameraService(ImagePicker()))
    ..registerLazySingleton<LocationService>(
      () => LocationService(GeolocatorPlatform.instance),
    )
    ..registerLazySingleton<SearchOrders>(() => const SearchOrders())
    ..registerLazySingleton<OrderMapper>(OrderMapper.new);
}

void _registerNetwork(AppConfig config, bool firebaseReady) {
  getIt
    ..registerLazySingleton<AuthRepository>(() {
      final tokenStore = getIt<SecureTokenStore>();
      if (!firebaseReady) {
        return DemoAuthRepository(tokenStore);
      }
      return FirebaseAuthRepository(
        auth: FirebaseAuth.instance,
        tokenStore: tokenStore,
      );
    })
    ..registerLazySingleton<ApiClient>(
      () => ApiClient(
        config: config,
        tokenStore: getIt<SecureTokenStore>(),
        onUnauthorized: () async => getIt<AuthRepository>().signOut(),
      ),
    )
    ..registerLazySingleton<RealtimeClient>(
      () => RealtimeClient(
        url: config.realtimeUrl,
        tokenProvider: () => getIt<AuthRepository>().idToken(),
      ),
    );

  if (firebaseReady) {
    getIt
      ..registerLazySingleton<FirestoreCommentsSource>(
        () => FirestoreCommentsSource(FirebaseFirestore.instance),
      )
      ..registerLazySingleton<PushService>(
        () => PushService(
          messaging: FirebaseMessaging.instance,
          crashReporter: getIt<CrashReporter>(),
        ),
      )
      ..registerLazySingleton<DeviceTokenRegistrar>(
        () => DeviceTokenRegistrar(
          pushService: getIt<PushService>(),
          auth: getIt<AuthRepository>(),
          crashReporter: getIt<CrashReporter>(),
          functions: FirebaseFunctions.instance,
        ),
      );
  }
}

void _registerOrders() {
  getIt
    ..registerLazySingleton<OrdersApi>(() => OrdersApi(getIt<ApiClient>().dio))
    ..registerLazySingleton<OrderListRemoteSource>(
      () => OrderListRemoteSource(
        apiClient: getIt<ApiClient>(),
        decoder: getIt<PayloadDecoder>(),
      ),
    )
    ..registerLazySingleton<OrderLocalDataSource>(
      () => OrderLocalDataSource(
        ordersBox: HiveBoxes.ordersBox,
        outboxBox: HiveBoxes.outboxBox,
        mapper: getIt<OrderMapper>(),
      ),
    )
    ..registerLazySingleton<OrderRealtimeSource>(
      () => OrderRealtimeSource(
        client: getIt<RealtimeClient>(),
        mapper: getIt<OrderMapper>(),
        crashReporter: getIt<CrashReporter>(),
      ),
    )
    ..registerLazySingleton<OrderRepository>(
      () => OrdersRepositoryImpl(
        api: getIt<OrdersApi>(),
        listRemote: getIt<OrderListRemoteSource>(),
        local: getIt<OrderLocalDataSource>(),
        realtime: getIt<OrderRealtimeSource>(),
        mapper: getIt<OrderMapper>(),
        networkMonitor: getIt<NetworkMonitor>(),
        settings: getIt<SettingsStore>(),
        crashReporter: getIt<CrashReporter>(),
        config: getIt<AppConfig>(),
      ),
    )
    ..registerLazySingleton<AttachPhoto>(
      () => AttachPhoto(
        repository: getIt<OrderRepository>(),
        camera: getIt<CameraService>(),
      ),
    )
    ..registerLazySingleton<SyncCoordinator>(
      () => SyncCoordinator(
        networkMonitor: getIt<NetworkMonitor>(),
        repository: getIt<OrderRepository>(),
        crashReporter: getIt<CrashReporter>(),
      ),
    );
}

void _registerPresentation(bool firebaseReady) {
  getIt
    ..registerLazySingleton<AuthCubit>(
      () => AuthCubit(repository: getIt<AuthRepository>()),
    )
    ..registerLazySingleton<AppLockBloc>(
      () => AppLockBloc(
        biometrics: getIt<BiometricService>(),
        settings: getIt<SettingsStore>(),
        auth: getIt<AuthRepository>(),
      ),
    )
    ..registerFactory<OrdersBloc>(
      () => OrdersBloc(
        repository: getIt<OrderRepository>(),
        searchOrders: getIt<SearchOrders>(),
      ),
    )
    ..registerFactory<OrderDetailsBloc>(
      () => OrderDetailsBloc(
        repository: getIt<OrderRepository>(),
        attachPhoto: getIt<AttachPhoto>(),
        locationService: getIt<LocationService>(),
      ),
    );
}

Future<void> resetDependencies() async {
  await getIt.reset();
}
