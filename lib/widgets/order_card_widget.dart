import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/catalog/catalog_bloc.dart';
import '../config/theme.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

class OrderCardWidget extends StatefulWidget {
  final Map<String, dynamic> order;
  final void Function(int orderId, String newStatus)? onStatusChange;
  final void Function(int orderId)? onDelete;
  final bool isKitchen;

  final void Function(int orderId, Map<String, dynamic> data)? onUpdate;
  final int? index;

  const OrderCardWidget({
    super.key,
    required this.order,
    this.onStatusChange,
    this.onDelete,
    this.onUpdate,
    this.isKitchen = false,
    this.index,
  });

  @override
  State<OrderCardWidget> createState() => _OrderCardWidgetState();
}

class _OrderCardWidgetState extends State<OrderCardWidget> {
  bool _showConfirmation = false;
  bool _showActions = false;
  Timer? _timer;
  String _elapsedTime = '';

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _updateElapsedTime();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      _updateElapsedTime();
    });
  }

  void _updateElapsedTime() {
    final startTimeStr = widget.order['time_created'] as String?;
    if (startTimeStr == null || startTimeStr.isEmpty) return;
    try {
      final start = DateTime.parse(startTimeStr);
      final now = DateTime.now();
      final diff = now.difference(start);
      if (diff.inMinutes < 0) return;

      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;

      String newElapsed = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';

      if (newElapsed != _elapsedTime && mounted) {
        setState(() {
          _elapsedTime = newElapsed;
        });
      }
    } catch (_) {}
  }

  static const _drinkKeywords = [
    'Coca Cola',
    'Coca',
    'Fanta',
    'Sprite',
    'Nordic',
    'Bebida',
    'Lata',
    '1.5L',
    '2.5L',
    'Con Gas',
    'Sin Gas',
    'Nectar',
    'Agua'
  ];

  bool _isDrinkDetail(String text) {
    return _drinkKeywords.any(
      (kw) => text.toLowerCase().contains(kw.toLowerCase()),
    );
  }

  bool _isPromoItem(String itemName) {
    return itemName.contains('Promo 2') ||
        itemName.contains('Promo del Día') ||
        itemName.contains('Promo del Dia');
  }

  Future<void> _showDrinkPickerForItem(
      Map<String, dynamic> item, String currentDrinkDetail) async {
    final catalogState = context.read<CatalogBloc>().state;
    if (catalogState is! CatalogLoaded) return;

    final drinks = catalogState.drinks;

    final newDrink = await showDialog<String>(
      context: context,
      builder: (ctx) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text(
              'Cambiar Bebida',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: drinks.length,
                itemBuilder: (ctx, i) => ListTile(
                  title: Text(drinks[i]['name'] as String,
                      textAlign: TextAlign.center),
                  onTap: () =>
                      Navigator.of(ctx).pop(drinks[i]['name'] as String),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (newDrink == null || !mounted) return;

    // Rebuild the full items list replacing the drink in this item's description
    final allItems =
        List<Map<String, dynamic>>.from(widget.order['items'] as List);

    final updatedItems = allItems.map((it) {
      if (it == item) {
        // Replace drink in comments/details
        final raw = (it['comments'] ?? it['details'] ?? '') as String;
        final parts = raw.split(RegExp(r'\s*\|\s*'));
        final updatedParts = parts.map((part) {
          final trimmed = part.trim();
          if (_drinkKeywords
              .any((kw) => trimmed.toLowerCase().contains(kw.toLowerCase()))) {
            if (trimmed.contains('1.5L')) return '$newDrink 1.5L';
            if (trimmed.contains('2.5L')) return '$newDrink 2.5L';
            return newDrink;
          }
          return trimmed;
        }).toList();
        final newDesc = updatedParts.join(' | ');
        return {
          ...it,
          'comments': newDesc,
          'details': newDesc,
        };
      }
      return it;
    }).toList();

    final orderId = widget.order['id'] as int;
    widget.onUpdate?.call(orderId, {'items': updatedItems});
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isKitchen) {
      return _buildKitchenCard(context);
    }
    return _buildActiveOrderCard(context);
  }

  Widget _buildActiveOrderCard(BuildContext context) {
    final items = widget.order['items'] as List? ?? [];
    final total = widget.order['total_amount'] ?? 0;

    final clientName = widget.order['client_name']?.toString().trim() ?? '';
    final hasClient = clientName.isNotEmpty &&
        clientName.toLowerCase() != 'sin nombre' &&
        clientName.toLowerCase() != 'null';
    final orderNum =
        int.tryParse(widget.order['order_number']?.toString() ?? '') ??
            widget.order['order_number'];
    final headerText = hasClient ? '$orderNum - $clientName' : '$orderNum';

    final status = widget.order['status']?.toString() ?? '';
    final isNew = status == 'NUEVO';
    final statusColor = AppColors.getStatusColor(status);

    return Card(
      elevation: 4,
      surfaceTintColor: isNew ? Colors.white : Colors.transparent,
      color: isNew ? Colors.white : statusColor.withOpacity(0.15),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isNew
            ? BorderSide(color: Colors.grey.shade300, width: 1.0)
            : BorderSide(color: statusColor.withOpacity(0.5), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Header: Orden # (Time)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: widget.index != null
                      ? ReorderableDragStartListener(
                          index: widget.index!,
                          child: Row(
                            children: [
                              const Icon(Icons.drag_indicator,
                                  color: Colors.grey, size: 20),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  headerText,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Text(
                          headerText,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_elapsedTime.isNotEmpty &&
                        widget.order['activation_time'] == null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.timer,
                                size: 12, color: Colors.amber.shade900),
                            const SizedBox(width: 4),
                            Text(
                              _elapsedTime,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (widget.order['activation_time'] != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.schedule,
                                size: 12, color: Colors.purple.shade900),
                            const SizedBox(width: 4),
                            Text(
                              'Prog: ${(widget.order['activation_time'] as String).substring(11, 16)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (widget.order['is_paid'] == true) ...[
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                    ],
                    _buildStatusBadge(widget.order['status']),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 2. Items Container (Light Grey)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA), // Light grey
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Items List
                  ...items.map((item) {
                    final comments = item['comments'] as String?;
                    final details = item['details'] as String?;

                    // Use comments (persisted) or details (local)
                    final description = comments ?? details ?? '';

                    // Parse description into sub-lines
                    final descLines = description.isNotEmpty
                        ? description
                            .split(RegExp(r'\s*[|/]\s*'))
                            .where((s) => s.trim().isNotEmpty)
                            .map((s) => s.trim())
                            .toList()
                        : <String>[];

                    const drinkKw = [
                      'Coca Cola',
                      'Coca',
                      'Fanta',
                      'Sprite',
                      'Nordic',
                      'Bebida',
                      'Lata',
                      '1.5L',
                      '2.5L',
                      'Con Gas',
                      'Sin Gas',
                      'Nectar',
                      'Agua'
                    ];
                    final isPromo = _isPromoItem(item['item_name'] ?? '');

                    // Separate drink from other lines
                    String? drinkLine;
                    final otherLines = <String>[];
                    for (final line in descLines) {
                      if (drinkKw.any((kw) =>
                          line.toLowerCase().contains(kw.toLowerCase()))) {
                        drinkLine = line;
                      } else {
                        otherLines.add(line);
                      }
                    }

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
                          // Name and Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Item name + non-drink detail lines
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      if (item['quantity'] != null &&
                                          (item['quantity'] as int) > 1)
                                        TextSpan(
                                          text: '${item['quantity']}x ',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 16,
                                            color: Colors.orange,
                                          ),
                                        ),
                                      TextSpan(
                                        text: item['item_name'] ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      if (otherLines.isNotEmpty)
                                        const TextSpan(text: '   '),
                                      ...List.generate(otherLines.length,
                                          (index) {
                                        final line = otherLines[index];
                                        Color lineColor = Colors.black54;
                                        FontWeight weight = FontWeight.w500;
                                        if (line.contains('Sin') ||
                                            line.contains('Reemplazo') ||
                                            line.contains('->') ||
                                            line.contains('Excepci') ||
                                            line.contains('Parmesano')) {
                                          lineColor = Colors.red;
                                          weight = FontWeight.w600;
                                        } else if (line.contains('+')) {
                                          lineColor = const Color(0xFF2E7D32);
                                          weight = FontWeight.w600;
                                        }
                                        return TextSpan(
                                          children: [
                                            TextSpan(
                                              text: line,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: lineColor,
                                                fontWeight: weight,
                                              ),
                                            ),
                                            if (index < otherLines.length - 1)
                                              const TextSpan(
                                                text: '  |  ',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                          ],
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                                // Drink line — tappable chip for promos
                                if (drinkLine != null) ...[
                                  const SizedBox(height: 4),
                                  isPromo
                                      ? InkWell(
                                          onTap: () => _showDrinkPickerForItem(
                                              item, drinkLine!),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.blue.shade200),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              color: Colors.blue.shade50,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.local_drink_outlined,
                                                    size: 13,
                                                    color:
                                                        Colors.blue.shade400),
                                                const SizedBox(width: 4),
                                                Text(
                                                  drinkLine!,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.blue.shade700,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Icon(Icons.edit_outlined,
                                                    size: 12,
                                                    color:
                                                        Colors.blue.shade300),
                                              ],
                                            ),
                                          ),
                                        )
                                      : Text(
                                          drinkLine!,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.black54,
                                          ),
                                        ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '\$${_formatPrice((item['total_price'] ?? 0) as int)}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 12),

                  // Total
                  Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: () => _showEditTotalDialog(),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.edit,
                                size: 16, color: Colors.orange),
                            const SizedBox(width: 6),
                            Text(
                              'Total: \$${_formatPrice(total as int)}',
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 2b. Client Info Tags
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.order['phone'] != null &&
                      widget.order['phone'].toString().isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.phone,
                            size: 14, color: Colors.blueAccent),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.order['phone'].toString(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (widget.order['delivery_type'] != null &&
                          widget.order['delivery_type'].toString().isNotEmpty)
                        _buildMiniTag(
                          Icons.local_shipping,
                          widget.order['delivery_type'],
                          Colors.orange,
                        ),
                      if (widget.order['payment_method'] != null &&
                          widget.order['payment_method'].toString().isNotEmpty)
                        _buildMiniTag(
                          Icons.payment,
                          widget.order['payment_method'],
                          Colors.green,
                        ),
                      InkWell(
                        onTap: () {
                          final currentPaid = widget.order['is_paid'] == true;
                          widget.onUpdate?.call(widget.order['id'] as int,
                              {'is_paid': !currentPaid});
                        },
                        child: _buildMiniTag(
                          widget.order['is_paid'] == true
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          'PAGADO',
                          widget.order['is_paid'] == true
                              ? Colors.green
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  if (widget.order['delivery_type'] == 'Delivery' &&
                      widget.order['delivery_address'] != null &&
                      widget.order['delivery_address']
                          .toString()
                          .isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on,
                            size: 14, color: Colors.red),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.order['delivery_address'].toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Botón ancho inferior para expandir/colapsar acciones
            InkWell(
              onTap: () => setState(() => _showActions = !_showActions),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300, width: 1.0),
                ),
                child: Icon(
                  _showActions
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.black54,
                ),
              ),
            ),
            const SizedBox(height: 12),

            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState: _showActions
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Column(
                children: [
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                context.push('/new-order', extra: widget.order);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFF4A90E2), // Blue
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                              child: const Text('ORDEN',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _showClientData(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFFF5A623), // Orange
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                              child: const Text('DATOS',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _showChangeCalculator(
                                  context, widget.order['total_amount'] ?? 0),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                              child: const Text('VUELTO',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => widget.onDelete
                                  ?.call(widget.order['id'] as int),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE74C3C), // Red
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                              child: const Text('ELIMINAR',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 4. Status Button (Footer) with Inline Confirmation
                  SizedBox(
                    width: double.infinity,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _showConfirmation
                          ? Row(
                              key: const ValueKey('confirm'),
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => setState(
                                        () => _showConfirmation = false),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.grey,
                                      side:
                                          const BorderSide(color: Colors.grey),
                                      minimumSize:
                                          const Size(double.infinity, 50),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                    child: const Text('Cancelar'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      widget.onStatusChange?.call(
                                          widget.order['id'] as int,
                                          'ENTREGADO');
                                      setState(() => _showConfirmation = false);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.success,
                                      foregroundColor: Colors.white,
                                      minimumSize:
                                          const Size(double.infinity, 50),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                    child: const Text('Confirmar'),
                                  ),
                                ),
                              ],
                            )
                          : ElevatedButton(
                              key: const ValueKey('button'),
                              onPressed: () =>
                                  setState(() => _showConfirmation = true),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 50),
                                backgroundColor:
                                    AppColors.success.withOpacity(0.2),
                                foregroundColor: AppColors.success,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Entregado',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKitchenCard(BuildContext context) {
    final status = widget.order['status'] ?? 'NUEVO';
    final items = (widget.order['items'] as List? ?? []).where((item) {
      final name = (item['item_name']?.toString() ?? '').toLowerCase();
      // Remover "Envio" y "Envío" con tilde, o similares, para que no salgan en cocina
      return !name.contains('envio') && !name.contains('envío');
    }).toList();

    final clientName = widget.order['client_name']?.toString().trim() ?? '';
    final hasClient = clientName.isNotEmpty &&
        clientName.toLowerCase() != 'sin nombre' &&
        clientName.toLowerCase() != 'null';
    final orderNum =
        int.tryParse(widget.order['order_number']?.toString() ?? '') ??
            widget.order['order_number'];
    final headerText = hasClient ? '$orderNum - $clientName' : '$orderNum';

    final isNew = status == 'NUEVO';
    final statusColor = AppColors.getStatusColor(status);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      surfaceTintColor: isNew ? Colors.white : Colors.transparent,
      color: isNew ? Colors.white : statusColor.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isNew
            ? const BorderSide(color: Colors.transparent, width: 0)
            : BorderSide(color: statusColor.withOpacity(0.5), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            // 1. Header: Number and Timer Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$orderNum',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (_elapsedTime.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.timer,
                            size: 12, color: Colors.amber.shade900),
                        const SizedBox(width: 4),
                        Text(
                          _elapsedTime,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            // 2. Client and Status Row
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (hasClient)
                    Expanded(
                      child: Text(
                        clientName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  // Mover la etiqueta de estado aquí
                  _buildStatusBadge(widget.order['status']),
                ],
              ),
            ),

            const Divider(height: 12),

            // Items
            ...items.map((item) {
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

              // Logic to parse Title, Size, and Details separately
              String name = item['item_name'] ?? '';
              String title = name;
              String? sizeInfo;
              List<String> detailsList = [];

              // 1. Extract Size if present in parenthesis, e.g. "Española (Familiar)"
              if (title.contains('(') && title.contains(')')) {
                final start = title.indexOf('(');
                final end = title.lastIndexOf(')');
                sizeInfo = title.substring(start + 1, end);
                title =
                    title.substring(0, start).trim(); // Remove size from title
              }

              // 2. Handle " - " separator (common in Promos)
              if (title.contains(' - ')) {
                final parts = title.split(' - ');
                title = parts[0];
                detailsList.addAll(parts.sublist(1));
              }

              // 3. Add description lines (parsed from comments) to details, removing separating chars
              for (var line in descLines) {
                // Split existing pipes or slashes in comments too
                final subParts = line.split(RegExp(r'\s*[|/]\s*'));
                detailsList.addAll(subParts);
              }

              // 4. DRINKS — only shown in active orders view (not kitchen)
              // Extract drink details into separate list for tappable rendering
              const drinkKeywords = [
                'Coca Cola',
                'Coca',
                'Fanta',
                'Sprite',
                'Nordic',
                'Bebida',
                'Lata',
                '1.5L',
                '2.5L',
                'Con Gas',
                'Sin Gas',
                'Nectar',
                'Agua'
              ];

              // Separate drink lines from regular details
              final drinkDetails = <String>[];
              detailsList.removeWhere((line) {
                final isDrink = drinkKeywords
                    .any((kw) => line.toLowerCase().contains(kw.toLowerCase()));
                if (isDrink) {
                  drinkDetails.add(line.trim());
                }
                // Always remove from detailsList (drinks rendered separately below)
                return isDrink;
              });

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TITLE (Product Name)
                        Text.rich(
                          TextSpan(
                            children: [
                              if (item['quantity'] != null &&
                                  (item['quantity'] as int) > 1)
                                TextSpan(
                                  text: '${item['quantity']}x ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 26,
                                    color: Colors.orange,
                                  ),
                                ),
                              TextSpan(
                                text: title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 24, // Even bigger
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // SIZE (e.g. Familiar)
                        if (sizeInfo != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              sizeInfo,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.normal, // Regular weight
                                color: Colors.black87,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),

                        const SizedBox(height: 8),

                        // DETAILS LIST (Ingredients / Sub-items) - One per line
                        ...detailsList.map((detail) {
                          Color color = Colors.black87;
                          FontWeight weight = FontWeight.w500;
                          String text = detail.trim();

                          // Color coding logic
                          if (text.contains('Sin') ||
                              text.contains('Reemplazo') ||
                              text.contains('->') ||
                              text.contains('Excepci') ||
                              text.contains('Parmesano')) {
                            color = Colors.red;
                            weight = FontWeight.bold;
                          } else if (text.contains('+') ||
                              text.startsWith('Extra')) {
                            color = const Color(0xFF2E7D32);
                            weight = FontWeight.bold;
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              text,
                              style: TextStyle(
                                fontSize: 18,
                                color: color,
                                fontWeight: weight,
                              ),
                            ),
                          );
                        }),

                        // DRINK DETAILS — shown as tappable button for promos
                        if (!widget.isKitchen && drinkDetails.isNotEmpty)
                          ...drinkDetails.map((drinkText) {
                            final isPromo =
                                _isPromoItem(item['item_name'] ?? '');
                            if (isPromo) {
                              return Padding(
                                padding:
                                    const EdgeInsets.only(top: 4, bottom: 4),
                                child: InkWell(
                                  onTap: () =>
                                      _showDrinkPickerForItem(item, drinkText),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.blue.shade200,
                                          width: 1),
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.blue.shade50,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.local_drink_outlined,
                                            size: 16,
                                            color: Colors.blue.shade400),
                                        const SizedBox(width: 6),
                                        Text(
                                          drinkText,
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.blue.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Icon(Icons.edit_outlined,
                                            size: 14,
                                            color: Colors.blue.shade400),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }
                            // Non-promo items: show drink as normal text
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                drinkText,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                  // DIVIDER (except for last item)
                  if (item != items.last)
                    const Divider(
                        height: 24, thickness: 1.5, color: Colors.grey),
                ],
              );
            }),

            const SizedBox(height: 4),

            // Status Buttons Row
            Row(
              children: [
                _kitchenStatusButton('P', 'PREP', status),
                const SizedBox(width: 8),
                _kitchenStatusButton('A', 'ARMADO', status),
                const SizedBox(width: 8),
                _kitchenStatusButton('H', 'HORNO', status),
              ],
            ),
            const SizedBox(height: 8),

            // Listo Button - Adapted to full width
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () {
                  if (_showConfirmation) {
                    widget.onStatusChange
                        ?.call(widget.order['id'] as int, 'LISTO');
                    setState(() => _showConfirmation = false);
                  } else {
                    setState(() => _showConfirmation = true);
                    Future.delayed(const Duration(seconds: 3), () {
                      if (mounted && _showConfirmation) {
                        setState(() => _showConfirmation = false);
                      }
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _showConfirmation
                      ? Colors.orange.shade800
                      : (status == 'LISTO'
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFC8E6C9)),
                  foregroundColor: _showConfirmation
                      ? Colors.white
                      : (status == 'LISTO'
                          ? Colors.white
                          : const Color(0xFF2E7D32)),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _showConfirmation ? 'CONFIRMAR' : 'Listo',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _kitchenStatusButton(
      String label, String targetStatus, String currentStatus) {
    final isActive = currentStatus == targetStatus;
    final isPast = _statusOrder(currentStatus) > _statusOrder(targetStatus);

    Color bgColor;
    Color textColor;

    if (isActive) {
      // Current active status
      switch (targetStatus) {
        case 'PREP':
          bgColor = const Color(0xFFE8E8E8);
          textColor = Colors.black54;
          break;
        case 'ARMADO':
          bgColor = const Color(0xFFFFF3E0);
          textColor = const Color(0xFFE65100);
          break;
        case 'HORNO':
          bgColor = const Color(0xFFFFEBEE);
          textColor = const Color(0xFFC62828);
          break;
        default:
          bgColor = Colors.grey.shade200;
          textColor = Colors.black54;
      }
    } else if (isPast) {
      bgColor = Colors.grey.shade100;
      textColor = Colors.grey;
    } else {
      bgColor = Colors.grey.shade100;
      textColor = Colors.black45;
    }

    return Expanded(
      child: SizedBox(
        height: 50,
        child: ElevatedButton(
          onPressed: () {
            widget.onStatusChange
                ?.call(widget.order['id'] as int, targetStatus);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: bgColor,
            foregroundColor: textColor,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            elevation: 0,
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  int _statusOrder(String status) {
    switch (status) {
      case 'NUEVO':
        return 0;
      case 'PREP':
        return 1;
      case 'ARMADO':
        return 2;
      case 'HORNO':
        return 3;
      case 'LISTO':
        return 4;
      default:
        return -1;
    }
  }

  void _showClientData(BuildContext context) {
    String name = widget.order['client_name']?.toString() ?? '';
    String phone = widget.order['phone']?.toString() ?? '';
    String address = widget.order['delivery_address']?.toString() ?? '';
    String payMethod = widget.order['payment_method'] ?? 'Efectivo';
    String delType = widget.order['delivery_type'] ?? 'Local';

    final nameCtrl = TextEditingController(text: name);
    final phoneCtrl = TextEditingController(text: phone);
    final addressCtrl = TextEditingController(text: address);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Editar Datos Cliente'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Nombre',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.paste, size: 20),
                        onPressed: () async {
                          try {
                            final data =
                                await Clipboard.getData(Clipboard.kTextPlain);
                            if (data?.text != null) {
                              nameCtrl.text = data!.text!;
                              setState(() => name = data.text!);
                            }
                          } catch (e) {
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Por HTTP usa Pegar de sistema (Mantén presionado -> Pegar o Ctrl+V)')),
                              );
                            }
                          }
                        },
                      ),
                    ),
                    onChanged: (v) => name = v,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    decoration: InputDecoration(
                      labelText: 'Teléfono',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.paste, size: 20),
                        onPressed: () async {
                          try {
                            final data =
                                await Clipboard.getData(Clipboard.kTextPlain);
                            if (data?.text != null) {
                              phoneCtrl.text = data!.text!;
                              setState(() => phone = data.text!);
                            }
                          } catch (e) {
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Por HTTP usa Pegar de sistema (Mantén presionado -> Pegar o Ctrl+V)')),
                              );
                            }
                          }
                        },
                      ),
                    ),
                    onChanged: (v) => phone = v,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: [
                      'Local',
                      'Retiro',
                      'Delivery',
                      'PedidosYa',
                      'UberEats'
                    ].contains(delType)
                        ? delType
                        : 'Local',
                    decoration:
                        const InputDecoration(labelText: 'Tipo Entrega'),
                    items: [
                      'Local',
                      'Retiro',
                      'Delivery',
                      'PedidosYa',
                      'UberEats'
                    ]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => delType = v!),
                  ),
                  const SizedBox(height: 12),
                  if (delType == 'Delivery')
                    TextField(
                      controller: addressCtrl,
                      decoration: InputDecoration(
                        labelText: 'Dirección',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.paste, size: 20),
                          onPressed: () async {
                            try {
                              final data =
                                  await Clipboard.getData(Clipboard.kTextPlain);
                              if (data?.text != null) {
                                addressCtrl.text = data!.text!;
                                setState(() => address = data.text!);
                              }
                            } catch (e) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Por HTTP usa Pegar de sistema (Mantén presionado -> Pegar o Ctrl+V)')),
                                );
                              }
                            }
                          },
                        ),
                      ),
                      onChanged: (v) => address = v,
                    ),
                  if (delType == 'Delivery') const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: ['Efectivo', 'Transferencia', 'Tarjeta']
                            .contains(payMethod)
                        ? payMethod
                        : 'Efectivo',
                    decoration: const InputDecoration(labelText: 'Método Pago'),
                    items: ['Efectivo', 'Transferencia', 'Tarjeta']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => payMethod = v!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCELAR')),
              ElevatedButton(
                onPressed: () {
                  final updatedOrder = Map<String, dynamic>.from(widget.order);
                  updatedOrder['client_name'] = name;
                  updatedOrder['phone'] = phone;
                  updatedOrder['delivery_address'] = address;
                  updatedOrder['delivery_type'] = delType;
                  updatedOrder['payment_method'] = payMethod;

                  // Keep items valid, backend might need them or not, but UpdateOrder usually sends full object or partial.
                  // OrdersBloc uses apiClient.updateOrder(id, data).

                  widget.onUpdate
                      ?.call(widget.order['id'] as int, updatedOrder);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('GUARDAR'),
              )
            ],
          );
        },
      ),
    );
  }

  void _showEditTotalDialog() {
    int currentTotal = widget.order['total_amount'] ?? 0;
    final txtController = TextEditingController(text: currentTotal.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modificar Total'),
        content: TextField(
          controller: txtController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Nuevo total (\$)',
            prefixIcon: Icon(Icons.attach_money),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              // En este caso "restaurar auto" implicaría probablemente recalcular el subtotal,
              // pero como estamos en Active Orders, el backend ya calculó el total_price por ítem.
              // Simulamos la suma de items aquí para "restaurar auto".
              int autoTotal = 0;
              final items = widget.order['items'] as List? ?? [];
              for (var item in items) {
                autoTotal += (item['total_price'] ?? 0) as int;
              }
              final updatedOrder = Map<String, dynamic>.from(widget.order);
              updatedOrder['manual_total'] = autoTotal;
              widget.onUpdate?.call(widget.order['id'] as int, updatedOrder);
              Navigator.of(ctx).pop();
            },
            child: const Text('RESTAURAR AUTO'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(txtController.text.trim());
              if (val != null) {
                final updatedOrder = Map<String, dynamic>.from(widget.order);
                updatedOrder['manual_total'] = val;
                widget.onUpdate?.call(widget.order['id'] as int, updatedOrder);
                Navigator.of(ctx).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('APLICAR'),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniTag(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
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

  Widget _buildStatusBadge(dynamic statusRaw) {
    if (statusRaw == null) return const SizedBox.shrink();
    final status = statusRaw.toString().toUpperCase();
    if (!['PREP', 'ARMADO', 'HORNO', 'LISTO', 'RETIRADO', 'EN_CAMINO']
        .contains(status)) {
      return const SizedBox.shrink();
    }

    Color bgColor = Colors.grey;
    String label = status;

    if (status == 'PREP') {
      bgColor = Colors.orange;
      label = 'PREPARANDO';
    } else if (status == 'ARMADO') {
      bgColor = Colors.blue;
    } else if (status == 'HORNO') {
      bgColor = Colors.red;
    } else if (status == 'LISTO') {
      bgColor = Colors.green;
    } else if (status == 'RETIRADO') {
      bgColor = const Color(0xFF7B1FA2); // Purple
    } else if (status == 'EN_CAMINO') {
      bgColor = const Color(0xFF1565C0); // Blue dark
      label = 'EN CAMINO';
    }

    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );

    if (status == 'HORNO') {
      return _BlinkingLabel(child: badge);
    }
    return badge;
  }

  void _showChangeCalculator(BuildContext context, int totalAmount) {
    showDialog(
      context: context,
      builder: (ctx) => _ChangeCalculatorDialog(totalToPay: totalAmount),
    );
  }
}

class _BlinkingLabel extends StatefulWidget {
  final Widget child;
  const _BlinkingLabel({required this.child});

  @override
  State<_BlinkingLabel> createState() => _BlinkingLabelState();
}

class _BlinkingLabelState extends State<_BlinkingLabel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 1.0, end: 0.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: widget.child,
    );
  }
}

class _ChangeCalculatorDialog extends StatefulWidget {
  final int totalToPay;
  const _ChangeCalculatorDialog({required this.totalToPay});

  @override
  State<_ChangeCalculatorDialog> createState() =>
      _ChangeCalculatorDialogState();
}

class _ChangeCalculatorDialogState extends State<_ChangeCalculatorDialog> {
  final TextEditingController _controller = TextEditingController();
  int _change = 0;
  int _payment = 0;

  @override
  void initState() {
    super.initState();
    _payment = widget.totalToPay;
    _controller.text = _payment.toString();
    _calculateChange();
  }

  void _calculateChange() {
    setState(() {
      _change = _payment - widget.totalToPay;
    });
  }

  void _updatePayment(int val) {
    setState(() {
      _payment = val;
      _controller.text = val.toString();
      _calculateChange();
    });
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Calcular Vuelto'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Total a Pagar: \$${_formatPrice(widget.totalToPay)}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Pago Rápido:',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              alignment: WrapAlignment.center,
              children: [10000, 15000, 20000].map((amt) {
                return ElevatedButton(
                  onPressed: () => _updatePayment(amt),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.black,
                    elevation: 0,
                  ),
                  child: Text('\$${amt ~/ 1000}k'),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monto Recibido',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                final p = int.tryParse(val);
                if (p != null) {
                  setState(() {
                    _payment = p;
                    _calculateChange();
                  });
                }
              },
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _change >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _change >= 0 ? Colors.green : Colors.red,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _change >= 0 ? 'VUELTO' : 'FALTA',
                    style: TextStyle(
                      color: _change >= 0
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${_formatPrice(_change.abs())}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: _change >= 0
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
