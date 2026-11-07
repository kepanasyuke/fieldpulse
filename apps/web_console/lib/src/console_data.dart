class ConsoleOrder {
  const ConsoleOrder({
    required this.number,
    required this.client,
    required this.status,
    required this.slaMinutes,
  });

  final String number;
  final String client;
  final String status;
  final int slaMinutes;

  bool get isOverdue => slaMinutes < 0;

  bool get isClosed => status == 'закрыт' || status == 'отменён';

  String get slaLabel {
    if (isClosed) {
      return '—';
    }

    return isOverdue ? 'просрочен на ${-slaMinutes} мин' : '$slaMinutes мин';
  }
}

class ConsoleMetrics {
  const ConsoleMetrics({
    required this.total,
    required this.inProgress,
    required this.overdue,
  });

  final int total;
  final int inProgress;
  final int overdue;

  factory ConsoleMetrics.of(List<ConsoleOrder> orders) {
    return ConsoleMetrics(
      total: orders.length,
      inProgress: orders.where((order) => order.status == 'в работе').length,
      overdue: orders
          .where((order) => order.isOverdue && !order.isClosed)
          .length,
    );
  }
}

List<ConsoleOrder> demoOrders() {
  return const [
    ConsoleOrder(
      number: 'FP-1042',
      client: 'ООО «Ромашка»',
      status: 'в работе',
      slaMinutes: 45,
    ),
    ConsoleOrder(
      number: 'FP-1043',
      client: 'ИП Петров',
      status: 'назначен',
      slaMinutes: -20,
    ),
    ConsoleOrder(
      number: 'FP-1044',
      client: 'Кофейня «Пар»',
      status: 'новый',
      slaMinutes: 120,
    ),
    ConsoleOrder(
      number: 'FP-1045',
      client: 'ООО «Вектор»',
      status: 'закрыт',
      slaMinutes: 0,
    ),
    ConsoleOrder(
      number: 'FP-1046',
      client: 'ТЦ «Север»',
      status: 'в работе',
      slaMinutes: -75,
    ),
  ];
}

List<ConsoleOrder> sortBySla(List<ConsoleOrder> orders) {
  final sorted = [...orders];
  sorted.sort((first, second) => first.slaMinutes.compareTo(second.slaMinutes));

  return sorted;
}

List<ConsoleOrder> filterByStatus(List<ConsoleOrder> orders, String? status) {
  if (status == null) {
    return orders;
  }

  return orders
      .where((order) => order.status == status)
      .toList(growable: false);
}

List<String> statusOptions(List<ConsoleOrder> orders) {
  final unique = <String>{for (final order in orders) order.status};
  final options = unique.toList()..sort();

  return ['Все', ...options];
}
