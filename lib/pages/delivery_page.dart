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
    final status = (order['status'] ?? 'NUEVO').toString();
    final statusColor = AppColors.getStatusColor(status);
    final phone = (order['phone'] ?? '').toString();
    final address = (order['delivery_address'] ?? '').toString();
    final clientName = (order['client_name'] ?? '').toString();
    final orderNumber = (order['order_number'] ?? '').toString();
    final paymentMethod = (order['payment_method'] ?? 'No definido').toString();
    final totalAmount = int.tryParse(order['total_amount'].toString()) ?? 0;

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
                  '#$orderNumber',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  clientName,
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
                        'Hola! Su pedido #$orderNumber de Luigi\'s Pizza está en camino.',
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

            const SizedBox(height: 12),
            const Divider(),
            _buildOrderItems(order['items'] as List<dynamic>? ?? []),
            const Divider(), // Keep existing divider or merge

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
                  paymentMethod,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const Spacer(),
                Text(
                  'Total: \$${_formatPrice(totalAmount)}',
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
    // Solo mostrar botones cuando cocina marcó como LISTO o posterior
    if (!['LISTO', 'RETIRADO', 'EN_CAMINO'].contains(status)) {
      return const SizedBox.shrink();
    }

    final buttons = <Widget>[];

    if (status == 'LISTO') {
      buttons.add(_statusButton(
        'RETIRADO',
        Icons.shopping_bag,
        orderId,
        const Color(0xFF7B1FA2), // Purple
      ));
      buttons.add(_statusButton(
        'EN_CAMINO',
        Icons.delivery_dining,
        orderId,
        const Color(0xFF1565C0), // Blue
      ));
    } else if (status == 'RETIRADO') {
      buttons.add(_statusButton(
        'EN_CAMINO',
        Icons.delivery_dining,
        orderId,
        const Color(0xFF1565C0),
      ));
    } else if (status == 'EN_CAMINO') {
      buttons.add(_statusButton(
        'ENTREGADO',
        Icons.done_all,
        orderId,
        const Color(0xFF2E7D32), // Green
      ));
    }

    return Wrap(spacing: 8, children: buttons);
  }

  Widget _statusButton(String status, IconData icon, int orderId,
      [Color? customColor]) {
    final color = customColor ?? AppColors.getStatusColor(status);
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(backgroundColor: color),
      onPressed: () {
        context.read<OrdersBloc>().add(UpdateOrderStatus(orderId, status));
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

  Widget _buildOrderItems(List<dynamic> items) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ...items.map<Widget>((item) {
            final comments = item['comments'] as String?;
            final details = item['details'] as String?;
            final description = comments ?? details ?? '';

            final descLines = description.isNotEmpty
                ? description
                    .split(RegExp(r'\s*[|/]\s*'))
                    .where((s) => s.trim().isNotEmpty)
                    .map((s) => s.trim())
                    .toList()
                : <String>[];

            final itemName = (item['item_name'] ?? 'Producto').toString();
            final totalPrice =
                int.tryParse((item['total_price'] ?? 0).toString()) ?? 0;

            return Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itemName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                        ...descLines.map((line) {
                          Color lineColor = Colors.black54;
                          FontWeight weight = FontWeight.normal;

                          if (line.contains('Sin') ||
                              line.contains('Reemplazo') ||
                              line.contains('->')) {
                            lineColor = Colors.red;
                            weight = FontWeight.w600;
                          } else if (line.contains('+')) {
                            lineColor = const Color(0xFF2E7D32);
                            weight = FontWeight.w600;
                          }

                          return Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              line,
                              style: TextStyle(
                                fontSize: 13,
                                color: lineColor,
                                fontWeight: weight,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '\$${_formatPrice(totalPrice)}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
