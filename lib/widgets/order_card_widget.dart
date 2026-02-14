import 'package:flutter/material.dart';
import '../config/theme.dart';

class OrderCardWidget extends StatelessWidget {
  final Map<String, dynamic> order;
  final void Function(int orderId, String newStatus)? onStatusChange;
  final void Function(int orderId)? onDelete;
  final bool isKitchen;

  const OrderCardWidget({
    super.key,
    required this.order,
    this.onStatusChange,
    this.onDelete,
    this.isKitchen = false,
  });

  @override
  Widget build(BuildContext context) {
    final status = order['status'] ?? 'NUEVO';
    final statusColor = AppColors.getStatusColor(status);
    final items = order['items'] as List? ?? [];
    final deliveryType = order['delivery_type'] ?? 'Local';

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
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Text(
                  '#${order['order_number']}',
                  style: TextStyle(
                    fontSize: isKitchen ? 28 : 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                _statusBadge(status, statusColor),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              order['client_name'] ?? 'Sin nombre',
              style: TextStyle(
                fontSize: isKitchen ? 18 : 14,
                color: AppColors.textSecondary,
              ),
            ),

            if (deliveryType != 'Local') ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    _deliveryIcon(deliveryType),
                    size: 16,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    deliveryType,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.info,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],

            const Divider(height: 16),

            // Items
            ...items
                .take(isKitchen ? 20 : 5)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Text(
                          '${item['quantity']}x',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: isKitchen ? 20 : 14,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item['item_name'] ?? '',
                            style: TextStyle(fontSize: isKitchen ? 18 : 14),
                          ),
                        ),
                        if (!isKitchen)
                          Text(
                            '\$${_formatPrice((item['total_price'] ?? 0) as int)}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                  ),
                ),
            if (items.length > (isKitchen ? 20 : 5))
              Text(
                '... +${items.length - 5} más',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),

            if (!isKitchen) ...[
              const Divider(height: 16),
              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '\$${_formatPrice((order['total_amount'] ?? 0) as int)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),
            // Actions
            _buildActions(status),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        AppColors.getStatusLabel(status),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: isKitchen ? 16 : 12,
        ),
      ),
    );
  }

  Widget _buildActions(String status) {
    final nextStatus = _getNextStatus(status);
    if (nextStatus == null && !isKitchen) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (nextStatus != null)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.getStatusColor(nextStatus),
              padding: EdgeInsets.symmetric(
                horizontal: isKitchen ? 24 : 16,
                vertical: isKitchen ? 14 : 10,
              ),
            ),
            onPressed: () =>
                onStatusChange?.call(order['id'] as int, nextStatus),
            icon: Icon(_statusIcon(nextStatus), size: isKitchen ? 24 : 18),
            label: Text(
              AppColors.getStatusLabel(nextStatus),
              style: TextStyle(fontSize: isKitchen ? 16 : 13),
            ),
          ),
        if (!isKitchen && onDelete != null)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
            ),
            onPressed: () => onDelete?.call(order['id'] as int),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Eliminar', style: TextStyle(fontSize: 13)),
          ),
      ],
    );
  }

  String? _getNextStatus(String current) {
    if (isKitchen) {
      switch (current) {
        case 'NUEVO':
          return 'PREP';
        case 'PREP':
          return 'ARMADO';
        case 'ARMADO':
          return 'HORNO';
        case 'HORNO':
          return 'LISTO';
        default:
          return null;
      }
    }
    switch (current) {
      case 'NUEVO':
        return 'PREP';
      case 'PREP':
        return 'ARMADO';
      case 'ARMADO':
        return 'HORNO';
      case 'HORNO':
        return 'LISTO';
      case 'LISTO':
        return 'RETIRADO';
      case 'RETIRADO':
        return 'EN_CAMINO';
      case 'EN_CAMINO':
        return 'ENTREGADO';
      default:
        return null;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'PREP':
        return Icons.restaurant;
      case 'ARMADO':
        return Icons.build;
      case 'HORNO':
        return Icons.local_fire_department;
      case 'LISTO':
        return Icons.check_circle;
      case 'RETIRADO':
        return Icons.handshake;
      case 'EN_CAMINO':
        return Icons.delivery_dining;
      case 'ENTREGADO':
        return Icons.done_all;
      default:
        return Icons.arrow_forward;
    }
  }

  IconData _deliveryIcon(String type) {
    switch (type) {
      case 'Delivery':
        return Icons.delivery_dining;
      case 'Retiro':
        return Icons.store;
      case 'PedidosYa':
        return Icons.shopping_bag;
      case 'UberEats':
        return Icons.fastfood;
      default:
        return Icons.dining;
    }
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
