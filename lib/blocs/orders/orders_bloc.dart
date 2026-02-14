import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/api_client.dart';

// Events
abstract class OrdersEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadActiveOrders extends OrdersEvent {}

class LoadKitchenOrders extends OrdersEvent {}

class LoadDeliveryOrders extends OrdersEvent {}

class LoadScheduledOrders extends OrdersEvent {}

class LoadHistory extends OrdersEvent {
  final String? status;
  final String? paymentMethod;
  final String? deliveryType;
  final String? date;
  LoadHistory({this.status, this.paymentMethod, this.deliveryType, this.date});
  @override
  List<Object?> get props => [status, paymentMethod, deliveryType, date];
}

class CreateOrder extends OrdersEvent {
  final Map<String, dynamic> data;
  CreateOrder(this.data);
}

class UpdateOrderStatus extends OrdersEvent {
  final int orderId;
  final String status;
  UpdateOrderStatus(this.orderId, this.status);
  @override
  List<Object?> get props => [orderId, status];
}

class DeleteOrder extends OrdersEvent {
  final int orderId;
  DeleteOrder(this.orderId);
  @override
  List<Object?> get props => [orderId];
}

class StartPolling extends OrdersEvent {
  final String viewType; // 'active', 'kitchen', 'delivery'
  StartPolling(this.viewType);
}

class StopPolling extends OrdersEvent {}

// States
abstract class OrdersState extends Equatable {
  @override
  List<Object?> get props => [];
}

class OrdersInitial extends OrdersState {}

class OrdersLoading extends OrdersState {}

class OrdersLoaded extends OrdersState {
  final List<dynamic> orders;
  final Map<String, dynamic>? summary;
  OrdersLoaded(this.orders, {this.summary});
  @override
  List<Object?> get props => [orders, summary];
}

class OrderCreated extends OrdersState {
  final Map<String, dynamic> order;
  OrderCreated(this.order);
}

class OrdersError extends OrdersState {
  final String message;
  OrdersError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final ApiClient apiClient;
  Timer? _pollTimer;

  OrdersBloc(this.apiClient) : super(OrdersInitial()) {
    on<LoadActiveOrders>(_onLoadActive);
    on<LoadKitchenOrders>(_onLoadKitchen);
    on<LoadDeliveryOrders>(_onLoadDelivery);
    on<LoadScheduledOrders>(_onLoadScheduled);
    on<LoadHistory>(_onLoadHistory);
    on<CreateOrder>(_onCreateOrder);
    on<UpdateOrderStatus>(_onUpdateStatus);
    on<DeleteOrder>(_onDeleteOrder);
    on<StartPolling>(_onStartPolling);
    on<StopPolling>(_onStopPolling);
  }

  Future<void> _onLoadActive(
    LoadActiveOrders event,
    Emitter<OrdersState> emit,
  ) async {
    if (state is! OrdersLoaded) emit(OrdersLoading());
    try {
      final orders = await apiClient.getActiveOrders();
      emit(OrdersLoaded(orders));
    } catch (e) {
      emit(OrdersError(e.toString()));
    }
  }

  Future<void> _onLoadKitchen(
    LoadKitchenOrders event,
    Emitter<OrdersState> emit,
  ) async {
    if (state is! OrdersLoaded) emit(OrdersLoading());
    try {
      final orders = await apiClient.getKitchenOrders();
      emit(OrdersLoaded(orders));
    } catch (e) {
      emit(OrdersError(e.toString()));
    }
  }

  Future<void> _onLoadDelivery(
    LoadDeliveryOrders event,
    Emitter<OrdersState> emit,
  ) async {
    if (state is! OrdersLoaded) emit(OrdersLoading());
    try {
      final orders = await apiClient.getDeliveryOrders();
      emit(OrdersLoaded(orders));
    } catch (e) {
      emit(OrdersError(e.toString()));
    }
  }

  Future<void> _onLoadScheduled(
    LoadScheduledOrders event,
    Emitter<OrdersState> emit,
  ) async {
    if (state is! OrdersLoaded) emit(OrdersLoading());
    try {
      final orders = await apiClient.getScheduledOrders();
      emit(OrdersLoaded(orders));
    } catch (e) {
      emit(OrdersError(e.toString()));
    }
  }

  Future<void> _onLoadHistory(
    LoadHistory event,
    Emitter<OrdersState> emit,
  ) async {
    emit(OrdersLoading());
    try {
      final data = await apiClient.getHistory(
        status: event.status,
        paymentMethod: event.paymentMethod,
        deliveryType: event.deliveryType,
        date: event.date,
      );
      emit(OrdersLoaded(data['orders'] ?? [], summary: data['summary']));
    } catch (e) {
      emit(OrdersError(e.toString()));
    }
  }

  Future<void> _onCreateOrder(
    CreateOrder event,
    Emitter<OrdersState> emit,
  ) async {
    emit(OrdersLoading());
    try {
      final order = await apiClient.createOrder(event.data);
      emit(OrderCreated(order));
    } catch (e) {
      emit(OrdersError('Error creando pedido: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateStatus(
    UpdateOrderStatus event,
    Emitter<OrdersState> emit,
  ) async {
    try {
      await apiClient.updateOrderStatus(event.orderId, event.status);
      add(LoadActiveOrders());
    } catch (e) {
      emit(OrdersError(e.toString()));
    }
  }

  Future<void> _onDeleteOrder(
    DeleteOrder event,
    Emitter<OrdersState> emit,
  ) async {
    try {
      await apiClient.deleteOrder(event.orderId);
      add(LoadActiveOrders());
    } catch (e) {
      emit(OrdersError(e.toString()));
    }
  }

  void _onStartPolling(StartPolling event, Emitter<OrdersState> emit) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      switch (event.viewType) {
        case 'kitchen':
          add(LoadKitchenOrders());
          break;
        case 'delivery':
          add(LoadDeliveryOrders());
          break;
        default:
          add(LoadActiveOrders());
      }
    });
  }

  void _onStopPolling(StopPolling event, Emitter<OrdersState> emit) {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }
}
