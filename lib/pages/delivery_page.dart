import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../blocs/orders/orders_bloc.dart';
import '../config/theme.dart';

class DeliveryPage extends StatefulWidget {
  const DeliveryPage({super.key});

  @override
  State<DeliveryPage> createState() => _DeliveryPageState();
}

class _DeliveryPageState extends State<DeliveryPage> {
  @override
  void initState() {
    super.initState();
    context.read<OrdersBloc>().add(LoadDeliveryOrders());
    context.read<OrdersBloc>().add(StartPolling('delivery'));
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
        title: const Text('Delivery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<OrdersBloc>().add(LoadDeliveryOrders()),
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
                    Icon(Icons.delivery_dining, size: 64, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'Sin deliveries activos',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: state.orders.length,
              itemBuilder: (_, i) => _deliveryCard(state.orders[i]),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _deliveryCard(Map<String, dynamic> order) {
    final status = order['status'] ?? 'NUEVO';
    final statusColor = AppColors.getStatusColor(status);
    final phone = order['phone'] ?? '';
    final address = order['delivery_address'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withValues(alpha: 0.3), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  '#${order['order_number']}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  order['client_name'] ?? '',
                  style: const TextStyle(fontSize: 16),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    AppColors.getStatusLabel(status),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Address
            if (address.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 18,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(address, style: const TextStyle(fontSize: 15)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Contact buttons
            Row(
              children: [
                if (phone.isNotEmpty) ...[
                  _contactButton(Icons.phone, 'Llamar', AppColors.success, () {
                    launchUrl(Uri.parse('tel:$phone'));
                  }),
                  const SizedBox(width: 8),
                  _contactButton(
                    Icons.message,
                    'WhatsApp',
                    const Color(0xFF25D366),
                    () {
                      final msg = Uri.encodeComponent(
                        'Hola! Su pedido #${order['order_number']} de Luigi\'s Pizza está en camino.',
                      );
                      launchUrl(Uri.parse('https://wa.me/$phone?text=$msg'));
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                if (address.isNotEmpty)
                  _contactButton(Icons.map, 'Mapa', AppColors.info, () {
                    final q = Uri.encodeComponent('$address, Arica, Chile');
                    launchUrl(
                      Uri.parse(
                        'https://www.google.com/maps/search/?api=1&query=$q',
                      ),
                    );
                  }),
              ],
            ),

            const Divider(height: 20),

            // Total & Payment
            Row(
              children: [
                const Icon(
                  Icons.payment,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  order['payment_method'] ?? 'No definido',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const Spacer(),
                Text(
                  'Total: \$${_formatPrice((order['total_amount'] ?? 0) as int)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            // Status buttons
            _buildStatusButtons(order['id'] as int, status),
          ],
        ),
      ),
    );
  }

  Widget _contactButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusButtons(int orderId, String status) {
    final buttons = <Widget>[];

    if (status == 'LISTO') {
      buttons.add(_statusButton('EN_CAMINO', Icons.delivery_dining, orderId));
    } else if (status == 'EN_CAMINO') {
      buttons.add(_statusButton('ENTREGADO', Icons.done_all, orderId));
    } else if (status == 'RETIRADO') {
      buttons.add(_statusButton('EN_CAMINO', Icons.delivery_dining, orderId));
    }

    return Wrap(spacing: 8, children: buttons);
  }

  Widget _statusButton(String status, IconData icon, int orderId) {
    final color = AppColors.getStatusColor(status);
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(backgroundColor: color),
      onPressed: () {
        context.read<OrdersBloc>().add(UpdateOrderStatus(orderId, status));
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) context.read<OrdersBloc>().add(LoadDeliveryOrders());
        });
      },
      icon: Icon(icon),
      label: Text(AppColors.getStatusLabel(status)),
    );
  }

  String _formatPrice(int price) {
    final str = price.toString();
    if (str.length <= 3) return str;
    final result = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      result.write(str[i]);
      count++;
      if (count % 3 == 0 && i > 0) result.write('.');
    }
    return result.toString().split('').reversed.join();
  }
}
