import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:fieldpulse/app/di/injector.dart';
import 'package:fieldpulse/app/router/app_router.dart';
import 'package:fieldpulse/app/router/routes.dart';
import 'package:core_ui/core_ui.dart';
import 'package:fieldpulse/core/platform/lifecycle_observer.dart';
import 'package:fieldpulse/core/push/push_service.dart';
import 'package:fieldpulse/features/auth/presentation/auth_cubit.dart';
import 'package:fieldpulse/features/auth/presentation/bloc/app_lock_bloc.dart';
import 'package:fieldpulse/features/auth/presentation/pages/app_lock_screen.dart';

class FieldPulseApp extends StatefulWidget {
  const FieldPulseApp({super.key});

  @override
  State<FieldPulseApp> createState() => _FieldPulseAppState();
}

class _FieldPulseAppState extends State<FieldPulseApp> {
  late final AuthCubit _authCubit = getIt<AuthCubit>();
  late final AppLockBloc _appLockBloc = getIt<AppLockBloc>();
  late final GoRouter _router = buildRouter(authCubit: _authCubit);
  late final LifecycleObserver _lifecycle = LifecycleObserver(
    onBackground: () => _appLockBloc.add(const AppLockRequested()),
  );
  StreamSubscription<String>? _pushSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(_lifecycle);
    _authCubit.start();
    _appLockBloc.add(const AppLockStarted());

    if (getIt.isRegistered<PushService>()) {
      _pushSubscription = getIt<PushService>().orderDeepLinks.listen((orderId) {
        if (orderId.isNotEmpty) {
          _router.push(AppRoute.orderDetailsPath(orderId));
        }
      });
    }
  }

  @override
  void dispose() {
    unawaited(_pushSubscription?.cancel());
    WidgetsBinding.instance.removeObserver(_lifecycle);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: _authCubit),
        BlocProvider<AppLockBloc>.value(value: _appLockBloc),
      ],
      child: BlocBuilder<AppLockBloc, AppLockState>(
        builder: (context, lockState) {
          return MaterialApp.router(
            title: 'FieldPulse',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            routerConfig: _router,
            builder: (context, child) => AppLockScreen(
              locked: lockState.isLocked,
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
      ),
    );
  }
}
