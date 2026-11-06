import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:fieldpulse/app/di/injector.dart';
import 'package:fieldpulse/app/router/routes.dart';
import 'package:core_ui/core_ui.dart';
import 'package:fieldpulse/features/auth/presentation/auth_cubit.dart';
import 'package:fieldpulse/features/orders/domain/entities/order.dart';
import 'package:fieldpulse/features/orders/presentation/bloc/orders_bloc.dart';
import 'package:fieldpulse/features/orders/presentation/widgets/order_card.dart';
import 'package:fieldpulse/features/orders/presentation/widgets/sync_banner.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrdersBloc>(
      create: (_) => getIt<OrdersBloc>()..add(const OrdersStarted()),
      child: const _OrdersView(),
    );
  }
}

class _OrdersView extends StatefulWidget {
  const _OrdersView();

  @override
  State<_OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<_OrdersView> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) {
        return;
      }
      context.read<OrdersBloc>().add(OrdersSearchChanged(value));
    });
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await context.showAdaptiveConfirm(
      title: 'Выйти из аккаунта?',
      message: 'Неотправленные изменения останутся в очереди и уйдут после повторного входа.',
      confirmLabel: 'Выйти',
    );
    if (!confirmed || !mounted) {
      return;
    }
    await context.read<AuthCubit>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Наряды'),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            onPressed: () =>
                context.read<OrdersBloc>().add(const OrdersRefreshed()),
            icon: const Icon(Icons.refresh_rounded),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                unawaited(_confirmSignOut());
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(value: 'logout', child: Text('Выйти')),
            ],
          ),
        ],
      ),
      body: BlocConsumer<OrdersBloc, OrdersState>(
        listenWhen: (previous, current) =>
            previous.banner != current.banner && current.banner != null,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.banner!)));
        },
        builder: (context, state) {
          return Column(
            children: [
              SyncBanner(
                pendingCount: state.pendingUpdates,
                isSyncing: state.isRefreshing,
                onSyncPressed: () =>
                    context.read<OrdersBloc>().add(const OrdersSyncRequested()),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Номер, адрес, клиент',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Очистить',
                            onPressed: () {
                              _searchController.clear();
                              context.read<OrdersBloc>().add(
                                const OrdersSearchChanged(''),
                              );
                              setState(() {});
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
              ),
              _FilterBar(
                selected: state.statusFilter,
                onSelected: (status) =>
                    context.read<OrdersBloc>().add(OrdersFilterChanged(status)),
              ),
              Expanded(child: _OrdersBody(state: state)),
            ],
          );
        },
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onSelected});

  final OrderStatus? selected;
  final ValueChanged<OrderStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('Все'),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
              showCheckmark: false,
            ),
          ),
          for (final status in OrderStatus.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(status.label),
                selected: selected == status,
                onSelected: (_) => onSelected(status),
                showCheckmark: false,
              ),
            ),
        ],
      ),
    );
  }
}

class _OrdersBody extends StatelessWidget {
  const _OrdersBody({required this.state});

  final OrdersState state;

  @override
  Widget build(BuildContext context) {
    return switch (state.status) {
      OrdersListStatus.initial ||
      OrdersListStatus.loading => const Center(child: AdaptiveProgress()),
      OrdersListStatus.failure => _FailureView(
        message: state.failure?.message ?? 'Не удалось загрузить наряды',
        onRetry: () => context.read<OrdersBloc>().add(const OrdersRefreshed()),
      ),
      OrdersListStatus.ready =>
        state.isEmpty
            ? _EmptyView(
                hasFilters: state.hasFilters,
                onReset: () {
                  context.read<OrdersBloc>()
                    ..add(const OrdersSearchChanged(''))
                    ..add(const OrdersFilterChanged(null));
                },
              )
            : RefreshIndicator.adaptive(
                onRefresh: () async {
                  context.read<OrdersBloc>().add(const OrdersRefreshed());
                },
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: state.visibleOrders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final order = state.visibleOrders[index];
                    return OrderCard(
                      order: order,
                      onTap: () =>
                          context.push(AppRoute.orderDetailsPath(order.id)),
                    );
                  },
                ),
              ),
    };
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.hasFilters, required this.onReset});

  final bool hasFilters;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              hasFilters ? 'Ничего не найдено' : 'Нарядов пока нет',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              hasFilters
                  ? 'Измените запрос или сбросьте фильтры'
                  : 'Новые задания появятся здесь автоматически',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            if (hasFilters) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onReset, child: const Text('Сбросить')),
            ],
          ],
        ),
      ),
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: scheme.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}
