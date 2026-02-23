import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'package:go_router/go_router.dart';

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
    final headerText = hasClient
        ? 'Orden ${widget.order['order_number']} - $clientName'
        : 'Orden ${widget.order['order_number']}';

    final status = widget.order['status']?.toString() ?? '';
    final isNew = status == 'NUEVO';
    final statusColor = AppColors.getStatusColor(status);

    return Card(
      elevation: 4,
      surfaceTintColor: isNew ? Colors.white : Colors.transparent,
      color: isNew ? Colors.white : statusColor.withValues(alpha: 0.15),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isNew
            ? BorderSide(color: Colors.grey.shade300, width: 1.0)
            : BorderSide(color: statusColor.withValues(alpha: 0.5), width: 1.5),
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
                    _buildStatusBadge(widget.order['status']),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => setState(() => _showActions = !_showActions),
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _showActions
                              ? Icons.expand_less
                              : Icons.keyboard_arrow_down,
                          size: 24,
                          color: Colors.black54,
                        ),
                      ),
                    ),
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
                            child: Text.rich(
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
                                  if (descLines.isNotEmpty)
                                    const TextSpan(
                                        text: '   '), // Space before details
                                  ...List.generate(descLines.length, (index) {
                                    final line = descLines[index];
                                    Color lineColor = Colors.black54;
                                    FontWeight weight = FontWeight.w500;

                                    if (line.contains('Sin') ||
                                        line.contains('Reemplazo') ||
                                        line.contains('->')) {
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
                                        if (index < descLines.length - 1)
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
                    child: Text(
                      'Total: \$${_formatPrice(total as int)}',
                      style: const TextStyle(
                        color: Color(0xFF2ECC71), // Green
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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
                  if (widget.order['delivery_type'] != null ||
                      widget.order['payment_method'] != null)
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
                            widget.order['payment_method']
                                .toString()
                                .isNotEmpty)
                          _buildMiniTag(
                            Icons.payment,
                            widget.order['payment_method'],
                            Colors.green,
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
            const SizedBox(height: 16),

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
    final items = widget.order['items'] as List? ?? [];

    final clientName = widget.order['client_name']?.toString().trim() ?? '';
    final hasClient = clientName.isNotEmpty &&
        clientName.toLowerCase() != 'sin nombre' &&
        clientName.toLowerCase() != 'null';
    final headerText = hasClient
        ? 'Orden ${widget.order['order_number']} - $clientName'
        : 'Orden ${widget.order['order_number']}';

    final isNew = status == 'NUEVO';
    final statusColor = AppColors.getStatusColor(status);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      surfaceTintColor: isNew ? Colors.white : Colors.transparent,
      color: isNew ? Colors.white : statusColor.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isNew
            ? const BorderSide(color: Colors.transparent, width: 0)
            : BorderSide(color: statusColor.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            // 1. Header: Orden # (Time)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  headerText,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                _buildStatusBadge(widget.order['status']),
              ],
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

              // 4. FILTER DRINKS (For Kitchen View)
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
              detailsList.removeWhere((line) {
                // Check if line contains any keyword (case insensitive somewhat, or just direct match)
                // Use strict containment to avoid false positives if possible, but drinks are usually distinct.
                return drinkKeywords
                    .any((kw) => line.toLowerCase().contains(kw.toLowerCase()));
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
                              text.contains('->')) {
                            color = Colors.red;
                            weight = FontWeight.bold;
                          } else if (text.contains('+') ||
                              text.startsWith('Extra')) {
                            color = const Color(0xFF2E7D32); // Green
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
                _kitchenStatusButton('Preparando', 'PREP', status),
                const SizedBox(width: 6),
                _kitchenStatusButton('Armado', 'ARMADO', status),
                const SizedBox(width: 6),
                _kitchenStatusButton('Horno', 'HORNO', status),
              ],
            ),
            const SizedBox(height: 6),

            // Listo Button
            // Listo Button with confirmation
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_showConfirmation) {
                    widget.onStatusChange
                        ?.call(widget.order['id'] as int, 'LISTO');
                    setState(() => _showConfirmation = false);
                  } else {
                    setState(() => _showConfirmation = true);
                    // Auto-cancel after 3 seconds
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
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _showConfirmation ? '¿CONFIRMAR LISTO?' : 'Listo',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _showConfirmation
                        ? Colors.white
                        : (status == 'LISTO'
                            ? Colors.white
                            : const Color(0xFF2E7D32)),
                  ),
                ),
              ),
            ),
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
      child: ElevatedButton(
        onPressed: () {
          widget.onStatusChange?.call(widget.order['id'] as int, targetStatus);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
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
    String name = widget.order['client_name'] ?? '';
    String phone = widget.order['phone'] ?? '';
    String address = widget.order['delivery_address'] ?? '';
    String payMethod = widget.order['payment_method'] ?? 'Efectivo';
    String delType = widget.order['delivery_type'] ?? 'Local';

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
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    controller: TextEditingController(text: name)
                      ..selection = TextSelection.fromPosition(
                          TextPosition(offset: name.length)),
                    onChanged: (v) => name = v,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Teléfono'),
                    controller: TextEditingController(text: phone)
                      ..selection = TextSelection.fromPosition(
                          TextPosition(offset: phone.length)),
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
                      decoration: const InputDecoration(labelText: 'Dirección'),
                      controller: TextEditingController(text: address)
                        ..selection = TextSelection.fromPosition(
                            TextPosition(offset: address.length)),
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
