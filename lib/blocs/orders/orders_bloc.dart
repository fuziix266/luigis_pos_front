import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/api_client.dart';
import '../../services/sound_service.dart';

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

class UpdateOrder extends OrdersEvent {
  final int orderId;
  final Map<String, dynamic> data;
  UpdateOrder(this.orderId, this.data);
  @override
  List<Object?> get props => [orderId, data];
}

class StartPolling extends OrdersEvent {
  final String viewType; // 'active', 'kitchen', 'delivery', 'scheduled'
  StartPolling(this.viewType);
}

class ReorderOrders extends OrdersEvent {
  final int oldIndex;
  final int newIndex;
  ReorderOrders(this.oldIndex, this.newIndex);
  @override
  List<Object?> get props => [oldIndex, newIndex];
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

class OrderUpdated extends OrdersState {
  final Map<String, dynamic> order;
  OrderUpdated(this.order);
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
  final SoundService soundService;
  Timer? _pollTimer;
  Set<int> _lastKitchenIds = {};
  bool _isFirstKitchenLoad = true;
  String _currentViewType = 'active';

  OrdersBloc(this.apiClient, this.soundService) : super(OrdersInitial()) {
    on<LoadActiveOrders>(_onLoadActive);
    on<LoadKitchenOrders>(_onLoadKitchen);
    on<LoadDeliveryOrders>(_onLoadDelivery);
    on<LoadScheduledOrders>(_onLoadScheduled);
    on<LoadHistory>(_onLoadHistory);
    on<CreateOrder>(_onCreateOrder);
    on<UpdateOrder>(_onUpdateOrder);
    on<UpdateOrderStatus>(_onUpdateStatus);
    on<DeleteOrder>(_onDeleteOrder);
    on<StartPolling>(_onStartPolling);
    on<StopPolling>(_onStopPolling);
    on<ReorderOrders>(_onReorderOrders);
  }

  Future<void> _onReorderOrders(
    ReorderOrders event,
    Emitter<OrdersState> emit,
  ) async {
    if (state is! OrdersLoaded) return;
    final currentState = state as OrdersLoaded;
    final activeOrders = List<dynamic>.from(currentState.orders);

    int newIndex = event.newIndex;
    if (event.oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = activeOrders.removeAt(event.oldIndex);
    activeOrders.insert(newIndex, item);

    // Optimistic update
    emit(OrdersLoaded(activeOrders, summary: currentState.summary));

    // Sync with backend
    try {
      final orderIds = activeOrders.map((o) => o['id'] as int).toList();
      await apiClient.updateOrdersSort(orderIds);
    } catch (e) {
      // Revert if needed, but for now just print error
      print('Error reordering: $e');
    }
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

      // Detect new orders for sound alert
      final currentIds = orders.map((o) => (o['id'] as num).toInt()).toSet();
      if (!_isFirstKitchenLoad) {
        final newIds = currentIds.difference(_lastKitchenIds);
        if (newIds.isNotEmpty) {
          soundService.playNewKitchenOrder();
        }
      }
      _lastKitchenIds = currentIds;
      _isFirstKitchenLoad = false;

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
    if (state is! OrdersLoaded) emit(OrdersLoading());
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

  Future<void> _onUpdateOrder(
    UpdateOrder event,
    Emitter<OrdersState> emit,
  ) async {
    emit(OrdersLoading());
    try {
      final order = await apiClient.updateOrder(event.orderId, event.data);
      emit(OrderUpdated(order));
      _reloadCurrentView();
    } catch (e) {
      emit(OrdersError('Error: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateStatus(
    UpdateOrderStatus event,
    Emitter<OrdersState> emit,
  ) async {
    try {
      await apiClient.updateOrderStatus(event.orderId, event.status);
      _reloadCurrentView();
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
      _reloadCurrentView();
    } catch (e) {
      emit(OrdersError(e.toString()));
    }
  }

  void _onStartPolling(StartPolling event, Emitter<OrdersState> emit) {
    _currentViewType = event.viewType;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      switch (event.viewType) {
        case 'kitchen':
          add(LoadKitchenOrders());
          break;
        case 'delivery':
          add(LoadDeliveryOrders());
          break;
        case 'delivery_history':
          final now = DateTime.now();
          final dateStr =
              '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
          add(LoadHistory(
            status: 'Todos',
            deliveryType: 'Delivery',
            date: dateStr,
          ));
          break;
        case 'scheduled':
          add(LoadScheduledOrders());
          break;
        default:
          add(LoadActiveOrders());
      }
    });
  }

  void _onStopPolling(StopPolling event, Emitter<OrdersState> emit) {
    _pollTimer?.cancel();
    _pollTimer = null;
    _lastKitchenIds.clear();
    _isFirstKitchenLoad = true;
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }

  void _reloadCurrentView() {
    switch (_currentViewType) {
      case 'kitchen':
        add(LoadKitchenOrders());
        break;
      case 'delivery':
        add(LoadDeliveryOrders());
        break;
      case 'active':
        add(LoadActiveOrders());
        break;
      case 'scheduled':
        add(LoadScheduledOrders());
        break;
      default:
        // Do nothing for history or unknown views
        break;
    }
  }
}
