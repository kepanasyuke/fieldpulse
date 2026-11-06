import 'package:hive/hive.dart';

abstract final class HiveBoxes {
  static const String orders = 'orders_cache_v1';
  static const String outbox = 'outbox_v1';

  static Future<void> openAll() async {
    if (!Hive.isBoxOpen(orders)) {
      await Hive.openBox<dynamic>(orders);
    }
    if (!Hive.isBoxOpen(outbox)) {
      await Hive.openBox<dynamic>(outbox);
    }
  }

  static Box<dynamic> get ordersBox => Hive.box<dynamic>(orders);

  static Box<dynamic> get outboxBox => Hive.box<dynamic>(outbox);
}
