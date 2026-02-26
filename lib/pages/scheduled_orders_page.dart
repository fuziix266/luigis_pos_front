import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../blocs/orders/orders_bloc.dart';
import '../config/theme.dart';
import '../widgets/order_card_widget.dart';

class ScheduledOrdersPage extends StatefulWidget {
  const ScheduledOrdersPage({super.key});

  @override
  State<ScheduledOrdersPage> createState() => _ScheduledOrdersPageState();
}

class _ScheduledOrdersPageState extends State<ScheduledOrdersPage> {
  @override
  void initState() {
    super.initState();
    context.read<OrdersBloc>().add(LoadScheduledOrders());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/orders'),
        ),
        title: const Text('Pedidos Programados'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<OrdersBloc>().add(LoadScheduledOrders()),
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
            final scheduledOrders = state.orders;

            if (scheduledOrders.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.schedule, size: 64, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'No hay pedidos programados',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: scheduledOrders.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 400,
                childAspectRatio: 0.85,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemBuilder: (context, index) {
                final order = scheduledOrders[index];
                return OrderCardWidget(
                  order: order,
                  index: index,
                  onStatusChange: (id, status) => context
                      .read<OrdersBloc>()
                      .add(UpdateOrderStatus(id, status)),
                  onDelete: _deleteOrder,
                  onUpdate: (id, data) =>
                      context.read<OrdersBloc>().add(UpdateOrder(id, data)),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
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
