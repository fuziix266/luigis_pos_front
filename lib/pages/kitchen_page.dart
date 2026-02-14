import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../blocs/orders/orders_bloc.dart';
import '../widgets/order_card_widget.dart';

class KitchenPage extends StatefulWidget {
  const KitchenPage({super.key});

  @override
  State<KitchenPage> createState() => _KitchenPageState();
}

class _KitchenPageState extends State<KitchenPage> {
  @override
  void initState() {
    super.initState();
    context.read<OrdersBloc>().add(LoadKitchenOrders());
    context.read<OrdersBloc>().add(StartPolling('kitchen'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.read<OrdersBloc>().add(StopPolling());
            context.go('/');
          },
        ),
        title: const Row(
          children: [
            Icon(Icons.restaurant, size: 24),
            SizedBox(width: 8),
            Text('Monitor Cocina'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<OrdersBloc>().add(LoadKitchenOrders()),
          ),
        ],
      ),
      body: BlocBuilder<OrdersBloc, OrdersState>(
        builder: (context, state) {
          if (state is OrdersLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
          if (state is OrdersError) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.white),
              ),
            );
          }
          if (state is OrdersLoaded) {
            if (state.orders.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 80,
                      color: Colors.green,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Sin pedidos en cocina',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final crossCount = constraints.maxWidth > 1200
                    ? 4
                    : constraints.maxWidth > 800
                    ? 3
                    : constraints.maxWidth > 500
                    ? 2
                    : 1;

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossCount,
                    childAspectRatio: 0.75,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  itemCount: state.orders.length,
                  itemBuilder: (_, i) => Theme(
                    data: ThemeData.dark().copyWith(
                      cardTheme: CardThemeData(
                        color: const Color(0xFF16213E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    child: OrderCardWidget(
                      order: state.orders[i],
                      isKitchen: true,
                      onStatusChange: (id, status) {
                        context.read<OrdersBloc>().add(
                          UpdateOrderStatus(id, status),
                        );
                        // Reload kitchen view specifically
                        Future.delayed(const Duration(milliseconds: 500), () {
                          if (mounted)
                            context.read<OrdersBloc>().add(LoadKitchenOrders());
                        });
                      },
                    ),
                  ),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
