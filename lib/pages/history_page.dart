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
          // Filters
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('Todos', null, _statusFilter),
                  _filterChip(
                    'Entregados',
                    'ENTREGADO',
                    _statusFilter,
                    type: 'status',
                  ),
                  _filterChip(
                    'Eliminados',
                    'ELIMINADO',
                    _statusFilter,
                    type: 'status',
                  ),
                  const SizedBox(width: 16),
                  _filterChip(
                    'Efectivo',
                    'Efectivo',
                    _paymentFilter,
                    type: 'payment',
                  ),
                  _filterChip(
                    'Transfer.',
                    'Transferencia',
                    _paymentFilter,
                    type: 'payment',
                  ),
                  _filterChip(
                    'Tarjeta',
                    'Tarjeta',
                    _paymentFilter,
                    type: 'payment',
                  ),
                ],
              ),
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
                    itemBuilder: (_, i) => _historyCard(orders[i]),
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

  Widget _filterChip(
    String label,
    String? value,
    String? currentFilter, {
    String type = 'status',
  }) {
    final isSelected =
        (value == null && currentFilter == null) || currentFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.primary.withValues(alpha: 0.2),
        onSelected: (_) {
          setState(() {
            if (type == 'status')
              _statusFilter = value;
            else if (type == 'payment')
              _paymentFilter = _paymentFilter == value ? null : value;
          });
          _loadHistory();
        },
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

  Widget _historyCard(Map<String, dynamic> order) {
    final status = order['status'] ?? '';
    final statusColor = AppColors.getStatusColor(status);
    final items = order['items'] as List? ?? [];
    final isDeleted = status == 'ELIMINADO';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isDeleted ? Colors.grey.shade50 : Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.1),
          child: Icon(
            isDeleted ? Icons.cancel : Icons.check_circle,
            color: statusColor,
          ),
        ),
        title: Row(
          children: [
            Text(
              '#${order['order_number']}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            Text(
              order['client_name'] ?? '',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              items
                  .map((i) => '${i['quantity']}x ${i['item_name']}')
                  .join(', '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Row(
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
              ],
            ),
          ],
        ),
        trailing: Text(
          '\$${_formatPrice((order['total_amount'] ?? 0) as int)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDeleted ? Colors.grey : AppColors.primary,
            decoration: isDeleted ? TextDecoration.lineThrough : null,
          ),
        ),
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
