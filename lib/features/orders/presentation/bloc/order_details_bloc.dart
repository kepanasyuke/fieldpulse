import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fieldpulse/core/error/failure.dart';
import 'package:fieldpulse/core/models/coordinates.dart';
import 'package:fieldpulse/core/native/location_service.dart';
import 'package:fieldpulse/features/orders/domain/entities/order.dart';
import 'package:fieldpulse/features/orders/domain/repositories/order_repository.dart';
import 'package:fieldpulse/features/orders/domain/usecases/attach_photo.dart';

sealed class OrderDetailsEvent {
  const OrderDetailsEvent();
}

final class OrderDetailsStarted extends OrderDetailsEvent {
  const OrderDetailsStarted(this.orderId);

  final String orderId;
}

final class OrderDetailsRefreshed extends OrderDetailsEvent {
  const OrderDetailsRefreshed();
}

final class OrderDetailsStatusRequested extends OrderDetailsEvent {
  const OrderDetailsStatusRequested(this.status);

  final OrderStatus status;
}

final class OrderDetailsPhotoRequested extends OrderDetailsEvent {
  const OrderDetailsPhotoRequested();
}

final class OrderDetailsAmountChanged extends OrderDetailsEvent {
  const OrderDetailsAmountChanged(this.amount);

  final int amount;
}

class OrderDetailsState extends Equatable {
  const OrderDetailsState({
    this.order,
    this.isLoading = true,
    this.isBusy = false,
    this.error,
    this.message,
    this.checkIn,
    this.amount = 0,
  });

  final Order? order;
  final bool isLoading;
  final bool isBusy;
  final Failure? error;
  final String? message;
  final Coordinates? checkIn;
  final int amount;

  bool get canChangeStatus => order != null && !isBusy;

  OrderDetailsState copyWith({
    Order? order,
    bool? isLoading,
    bool? isBusy,
    Failure? error,
    String? message,
    Coordinates? checkIn,
    int? amount,
    bool clearError = false,
    bool clearMessage = false,
  }) => OrderDetailsState(
    order: order ?? this.order,
    isLoading: isLoading ?? this.isLoading,
    isBusy: isBusy ?? this.isBusy,
    error: clearError ? null : error ?? this.error,
    message: clearMessage ? null : message ?? this.message,
    checkIn: checkIn ?? this.checkIn,
    amount: amount ?? this.amount,
  );

  @override
  List<Object?> get props => [
    order,
    isLoading,
    isBusy,
    error,
    message,
    checkIn,
    amount,
  ];
}

class OrderDetailsBloc extends Bloc<OrderDetailsEvent, OrderDetailsState> {
  OrderDetailsBloc({
    required OrderRepository repository,
    required AttachPhoto attachPhoto,
    required LocationService locationService,
  }) : _repository = repository,
       _attachPhoto = attachPhoto,
       _locationService = locationService,
       super(const OrderDetailsState()) {
    on<OrderDetailsStarted>(_onStarted);
    on<OrderDetailsRefreshed>(_onRefreshed);
    on<OrderDetailsStatusRequested>(_onStatusRequested);
    on<OrderDetailsPhotoRequested>(_onPhotoRequested);
    on<OrderDetailsAmountChanged>(_onAmountChanged);
  }

  final OrderRepository _repository;
  final AttachPhoto _attachPhoto;
  final LocationService _locationService;

  StreamSubscription<void>? _subscription;
  String _orderId = '';

  Future<void> _onStarted(
    OrderDetailsStarted event,
    Emitter<OrderDetailsState> emit,
  ) async {
    _orderId = event.orderId;

    _subscription ??= _repository.watchCachedOrders().listen((orders) {
      final matches = orders.where((order) => order.id == _orderId);
      if (matches.isNotEmpty && !isClosed) {
        emit(state.copyWith(order: matches.first, isLoading: false));
      }
    });

    final result = await _repository.fetchOrder(_orderId);
    if (isClosed) {
      return;
    }
    result.fold(
      ok: (order) => emit(
        state.copyWith(order: order, isLoading: false, clearError: true),
      ),
      err: (failure) => emit(state.copyWith(isLoading: false, error: failure)),
    );
  }

  Future<void> _onRefreshed(
    OrderDetailsRefreshed event,
    Emitter<OrderDetailsState> emit,
  ) async {
    final result = await _repository.fetchOrder(_orderId);
    final failure = result.failureOrNull;
    if (failure != null) {
      return;
    }
    emit(
      state.copyWith(
        order: result.valueOrNull ?? state.order,
        isLoading: false,
        clearError: true,
      ),
    );
  }

  Future<void> _onStatusRequested(
    OrderDetailsStatusRequested event,
    Emitter<OrderDetailsState> emit,
  ) async {
    final order = state.order;
    if (order == null || state.isBusy) {
      return;
    }
    emit(state.copyWith(isBusy: true, clearError: true, clearMessage: true));

    Coordinates? checkIn;
    if (event.status == OrderStatus.inProgress ||
        event.status == OrderStatus.done) {
      final position = await _locationService.currentPosition();
      checkIn = position.valueOrNull;
      final failure = position.failureOrNull;
      if (checkIn == null && failure != null) {
        emit(
          state.copyWith(
            isBusy: false,
            error: failure is PermissionFailure || failure is GeolocationFailure
                ? const ValidationFailure(
                    'Для этого шага нужна геолокация: включите доступ в настройках',
                  )
                : failure,
          ),
        );
        return;
      }
    }

    final result = await _repository.changeStatus(
      orderId: order.id,
      status: event.status,
      checkIn: checkIn,
    );

    result.fold(
      ok: (_) => emit(
        state.copyWith(
          isBusy: false,
          checkIn: checkIn,
          message: order.hasPendingUpdate || checkIn == null
              ? 'Статус сохранён, отправим при появлении связи'
              : 'Статус обновлён: ${event.status.label}',
        ),
      ),
      err: (failure) => emit(state.copyWith(isBusy: false, error: failure)),
    );
  }

  Future<void> _onPhotoRequested(
    OrderDetailsPhotoRequested event,
    Emitter<OrderDetailsState> emit,
  ) async {
    final order = state.order;
    if (order == null || state.isBusy) {
      return;
    }
    emit(state.copyWith(isBusy: true, clearError: true, clearMessage: true));

    final result = await _attachPhoto(order.id);
    result.fold(
      ok: (_) => emit(
        state.copyWith(isBusy: false, message: 'Фото прикреплено к наряду'),
      ),
      err: (failure) => emit(state.copyWith(isBusy: false, error: failure)),
    );
  }

  void _onAmountChanged(
    OrderDetailsAmountChanged event,
    Emitter<OrderDetailsState> emit,
  ) {
    emit(state.copyWith(amount: event.amount));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
