import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:fieldpulse/app/router/go_router_refresh_stream.dart';
import 'package:fieldpulse/app/router/routes.dart';
import 'package:fieldpulse/features/auth/presentation/auth_cubit.dart';
import 'package:fieldpulse/features/auth/presentation/pages/login_page.dart';
import 'package:fieldpulse/features/orders/presentation/pages/order_details_page.dart';
import 'package:fieldpulse/features/orders/presentation/pages/orders_page.dart';

GoRouter buildRouter({required AuthCubit authCubit}) {
  return GoRouter(
    initialLocation: AppRoute.orders,
    refreshListenable: GoRouterRefreshStream(authCubit.stream),
    redirect: (context, state) {
      final status = authCubit.state.status;
      final onLogin = state.matchedLocation == AppRoute.login;

      if (status == AuthStatus.unknown) {
        return null;
      }
      if (status == AuthStatus.unauthenticated) {
        return onLogin ? null : AppRoute.login;
      }
      if (onLogin) {
        return AppRoute.orders;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoute.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoute.orders,
        builder: (context, state) => const OrdersPage(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) =>
                OrderDetailsPage(orderId: state.pathParameters['id'] ?? ''),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Directionality(
      textDirection: TextDirection.ltr,
      child: Text(state.error?.toString() ?? 'Ошибка маршрута'),
    ),
  );
}
