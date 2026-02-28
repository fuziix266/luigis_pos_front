import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../blocs/orders/orders_bloc.dart';
import '../config/theme.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String? _statusFilter;
  String? _paymentFilter;
  String? _deliveryFilter;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    context.read<OrdersBloc>().add(StopPolling());
    _loadHistory();
  }

  void _loadHistory() {
    final dateStr =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    context.read<OrdersBloc>().add(
          LoadHistory(
            status: _statusFilter,
            paymentMethod: _paymentFilter,
            deliveryType: _deliveryFilter,
            date: dateStr,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Historial'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() => _selectedDate = date);
                _loadHistory();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters Dropdowns
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    'Estado',
                    _statusFilter,
                    ['Todos', 'ENTREGADO', 'ELIMINADO'],
                    ['Todos', 'Entregados', 'Eliminados'],
                    (val) => setState(
                        () => _statusFilter = val == 'Todos' ? null : val),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDropdown(
                    'Pago',
                    _paymentFilter,
                    ['Todos', 'Efectivo', 'Transferencia', 'Tarjeta'],
                    ['Pago: Todos', 'Efectivo', 'Transferencia', 'Tarjeta'],
                    (val) => setState(
                        () => _paymentFilter = val == 'Todos' ? null : val),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDropdown(
                    'Entrega',
                    _deliveryFilter,
                    [
                      'Todos',
                      'Local',
                      'Retiro',
                      'Delivery',
                      'PedidosYa',
                      'UberEats'
                    ],
                    [
                      'Entrega: Todas',
                      'Local',
                      'Retiro',
                      'Delivery',
                      'PedidosYa',
                      'UberEats'
                    ],
                    (val) => setState(
                        () => _deliveryFilter = val == 'Todos' ? null : val),
                  ),
                ),
              ],
            ),
          ),

          // Summary
          BlocBuilder<OrdersBloc, OrdersState>(
            builder: (context, state) {
              if (state is OrdersLoaded && state.summary != null) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  color: AppColors.primary.withValues(alpha: 0.05),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _summaryItem(
                        'Pedidos',
                        '${state.summary!['total_orders'] ?? 0}',
                        Icons.receipt,
                      ),
                      _summaryItem(
                        'Entregados',
                        '${state.summary!['total_delivered'] ?? 0}',
                        Icons.check_circle,
                        color: AppColors.success,
                      ),
                      _summaryItem(
                        'Eliminados',
                        '${state.summary!['total_deleted'] ?? 0}',
                        Icons.cancel,
                        color: AppColors.error,
                      ),
                      _summaryItem(
                        'Ventas',
                        '\$${_formatPrice((state.summary!['total_sales'] ?? 0) as int)}',
                        Icons.payments,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Orders list
          Expanded(
            child: BlocBuilder<OrdersBloc, OrdersState>(
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
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 64, color: Colors.grey),
                          SizedBox(height: 12),
                          Text(
                            'Sin registros',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: orders.length,
                    itemBuilder: (context, i) =>
                        _historyCard(context, orders[i]),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String hint,
    String? currentValue,
    List<String> values,
    List<String> labels,
    void Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: currentValue ?? 'Todos',
          icon: const Icon(Icons.arrow_drop_down, size: 20),
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          onChanged: (val) {
            onChanged(val);
            _loadHistory();
          },
          items: List.generate(values.length, (index) {
            return DropdownMenuItem(
              value: values[index],
              child: Text(
                labels[index],
                overflow: TextOverflow.ellipsis,
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _summaryItem(
    String label,
    String value,
    IconData icon, {
    Color color = AppColors.textPrimary,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _historyCard(BuildContext context, Map<String, dynamic> order) {
    final status = order['status'] ?? '';
    final statusColor = AppColors.getStatusColor(status);
    final items = order['items'] as List? ?? [];
    final isDeleted = status == 'ELIMINADO';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isDeleted ? Colors.grey.shade50 : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        collapsedShape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.1),
          child: Icon(
            isDeleted ? Icons.cancel : Icons.check_circle,
            color: statusColor,
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(
                    '#${order['order_number']}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order['client_name'] ?? '',
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '\$${_formatPrice((order['total_amount'] ?? 0) as int)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDeleted ? Colors.grey : AppColors.primary,
                    decoration: isDeleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (!isDeleted)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Eliminar Pedido'),
                          content: Text(
                              '¿Estás seguro de que deseas marcar el pedido #${order['order_number']} como eliminado?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                context.read<OrdersBloc>().add(
                                      UpdateOrderStatus(
                                          order['id'], 'ELIMINADO'),
                                    );
                                Future.delayed(
                                  const Duration(milliseconds: 300),
                                  () => _loadHistory(),
                                );
                              },
                              style:
                                  TextButton.styleFrom(iconColor: Colors.red),
                              child: const Text('Eliminar',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            children: [
              Icon(
                _paymentIcon(order['payment_method'] ?? ''),
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                order['payment_method'] ?? 'N/A',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.access_time,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                _formatTime(
                  order['time_delivered'] ?? order['time_created'] ?? '',
                ),
                style: const TextStyle(fontSize: 12),
              ),
              if (order['phone'] != null &&
                  order['phone'].toString().isNotEmpty) ...[
                const SizedBox(width: 12),
                const Icon(
                  Icons.phone,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  order['phone'].toString(),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
              if (order['delivery_type'] == 'Delivery' &&
                  order['delivery_address'] != null) ...[
                const SizedBox(width: 12),
                const Icon(
                  Icons.location_on,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order['delivery_address'].toString(),
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Wrap(
              children: [
                if (order['time_created'] != null)
                  _timeBadge('Creado', order['time_created']),
                if (order['time_prep'] != null)
                  _timeBadge('Prep', order['time_prep'],
                      startTime: order['time_created']),
                if (order['time_armado'] != null)
                  _timeBadge('Armado', order['time_armado'],
                      startTime: order['time_created']),
                if (order['time_entered_oven'] != null)
                  _timeBadge('Horno', order['time_entered_oven'],
                      startTime: order['time_created']),
                if (order['time_completed'] != null)
                  _timeBadge('Listo', order['time_completed'],
                      startTime: order['time_created']),
                if (order['time_pickup'] != null)
                  _timeBadge(
                      order['delivery_type'] == 'Delivery' ||
                              order['delivery_type'] == 'PedidosYa' ||
                              order['delivery_type'] == 'UberEats'
                          ? 'En Camino'
                          : 'Retirado',
                      order['time_pickup'],
                      startTime: order['time_created']),
                if (order['time_delivered'] != null)
                  _timeBadge('Entregado', order['time_delivered'],
                      startTime: order['time_created']),
              ],
            ),
          ),
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

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item['quantity']}x',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          item['item_name'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
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

                          return Text(
                            line,
                            style: TextStyle(
                              fontSize: 12,
                              color: lineColor,
                              fontWeight: weight,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '\$${_formatPrice((item['total_price'] ?? 0) as int)}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  String _calculateDurationText(String? startTime, String? endTime) {
    if (startTime == null ||
        endTime == null ||
        startTime.isEmpty ||
        endTime.isEmpty) return '';
    try {
      final start = DateTime.parse(startTime);
      final end = DateTime.parse(endTime);
      final diff = end.difference(start);
      if (diff.inMinutes < 0) return '';
      return '(${diff.inMinutes}m)';
    } catch (_) {
      return '';
    }
  }

  Widget _timeBadge(String label, String? time, {String? startTime}) {
    if (time == null || time.isEmpty) return const SizedBox.shrink();

    String durationText = '';
    if (startTime != null) {
      durationText = _calculateDurationText(startTime, time);
    }
    final fullLabel =
        durationText.isNotEmpty ? '$label $durationText:' : '$label:';

    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$fullLabel ',
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.primary),
          ),
          Text(
            _formatTime(time),
            style: const TextStyle(fontSize: 11, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  IconData _paymentIcon(String method) {
    switch (method) {
      case 'Efectivo':
        return Icons.money;
      case 'Transferencia':
        return Icons.account_balance;
      case 'Tarjeta':
        return Icons.credit_card;
      case 'Debito':
        return Icons.credit_card;
      case 'Credito':
        return Icons.credit_score;
      default:
        return Icons.payment;
    }
  }

  String _formatTime(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
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
