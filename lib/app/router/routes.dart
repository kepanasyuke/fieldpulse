abstract final class AppRoute {
  static const login = '/login';
  static const orders = '/orders';
  static const orderDetails = '/orders/:id';

  static String orderDetailsPath(String orderId) => '/orders/$orderId';
}
