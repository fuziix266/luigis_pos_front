import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../blocs/orders/orders_bloc.dart';
import '../config/theme.dart';
import '../widgets/order_card_widget.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  bool _showingScheduled = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    if (!_showingScheduled) {
      context.read<OrdersBloc>().add(LoadActiveOrders());
      context.read<OrdersBloc>().add(StartPolling('active'));
    } else {
      context.read<OrdersBloc>().add(LoadScheduledOrders());
      context.read<OrdersBloc>().add(StartPolling('scheduled'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_showingScheduled) {
              setState(() {
                _showingScheduled = false;
              });
              _loadData();
            } else {
              context.read<OrdersBloc>().add(StopPolling());
              context.go('/');
            }
          },
        ),
        title: Text(_showingScheduled
            ? 'Pedidos Programados'
            : 'Gestión de Pedidos Activos'),
        actions: [
          IconButton(
            tooltip: _showingScheduled
                ? 'Ver Pedidos Activos'
                : 'Ver Pedidos Programados',
            icon: Icon(_showingScheduled ? Icons.list_alt : Icons.schedule),
            onPressed: () {
              setState(() {
                _showingScheduled = !_showingScheduled;
              });
              _loadData();
            },
          ),
          IconButton(
            tooltip: 'Refrescar',
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _buildOrdersList(context, _showingScheduled),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/new-order'),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
    );
  }

  Widget _buildOrdersList(BuildContext context, bool isScheduled) {
    return BlocBuilder<OrdersBloc, OrdersState>(
      builder: (context, state) {
        if (state is OrdersLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is OrdersError) {
          return Center(child: Text(state.message));
        }
        if (state is OrdersLoaded) {
          final orders = state.orders;
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isScheduled ? Icons.schedule : Icons.receipt_long,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(
                    isScheduled
                        ? 'No hay pedidos programados'
                        : 'Sin pedidos activos',
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final aspectRatio = constraints.maxHeight > 0
                  ? constraints.maxWidth / constraints.maxHeight
                  : 0.0;
              final isHorizontal = aspectRatio >= (16 / 9);

              return ReorderableListView.builder(
                buildDefaultDragHandles: false,
                scrollDirection: isHorizontal ? Axis.horizontal : Axis.vertical,
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                onReorder: (oldIndex, newIndex) {
                  context
                      .read<OrdersBloc>()
                      .add(ReorderOrders(oldIndex, newIndex));
                },
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return Container(
                    key: ValueKey(order['id']),
                    width: isHorizontal ? 380 : null,
                    margin: EdgeInsets.only(
                      bottom: isHorizontal ? 0 : 8,
                      right: isHorizontal ? 8 : 0,
                    ),
                    alignment: Alignment.topCenter,
                    child: OrderCardWidget(
                      order: order,
                      index: index,
                      onStatusChange: _changeStatus,
                      onDelete: _deleteOrder,
                      onUpdate: _updateOrderData,
                    ),
                  );
                },
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _changeStatus(int orderId, String newStatus) {
    context.read<OrdersBloc>().add(UpdateOrderStatus(orderId, newStatus));
  }

  void _updateOrderData(int orderId, Map<String, dynamic> data) {
    context.read<OrdersBloc>().add(UpdateOrder(orderId, data));
  }

  void _deleteOrder(int orderId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar pedido?'),
        content: const Text('El pedido se moverá al historial como eliminado.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              context.read<OrdersBloc>().add(DeleteOrder(orderId));
              Navigator.pop(context);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
