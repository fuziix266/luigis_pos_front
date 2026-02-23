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
  @override
  void initState() {
    super.initState();
    context.read<OrdersBloc>().add(LoadActiveOrders());
    context.read<OrdersBloc>().add(StartPolling('active'));
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.read<OrdersBloc>().add(StopPolling());
            context.go('/');
          },
        ),
        title: const Text('Pedidos Activos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<OrdersBloc>().add(LoadActiveOrders()),
          ),
        ],
      ),
      body: BlocBuilder<OrdersBloc, OrdersState>(
        builder: (context, state) {
          if (state is OrdersLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is OrdersError) {
            return Center(child: Text(state.message));
          }
          if (state is OrdersLoaded) {
            if (state.orders.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'Sin pedidos activos',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                // Calculate aspect ratio. Default to vertical if height is 0 to avoid division by zero.
                final aspectRatio = constraints.maxHeight > 0
                    ? constraints.maxWidth / constraints.maxHeight
                    : 0.0;
                // Horizontal layout only if aspect ratio is 16:9 (1.77) or wider
                final isHorizontal = aspectRatio >= (16 / 9);

                return ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  scrollDirection:
                      isHorizontal ? Axis.horizontal : Axis.vertical,
                  padding: const EdgeInsets.all(16),
                  itemCount: state.orders.length,
                  onReorder: (oldIndex, newIndex) {
                    context
                        .read<OrdersBloc>()
                        .add(ReorderOrders(oldIndex, newIndex));
                  },
                  itemBuilder: (context, index) {
                    final order = state.orders[index];
                    return Container(
                      key: ValueKey(order['id']),
                      width: isHorizontal ? 380 : null,
                      margin: EdgeInsets.only(
                        bottom: isHorizontal ? 0 : 8,
                        right: isHorizontal ? 8 : 0,
                      ),
                      // Asegurar alineación superior en horizontal
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/new-order'),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
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
