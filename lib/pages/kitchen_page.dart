import 'dart:async'; // Add async import
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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
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
            Text('MONITOR COCINA',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        foregroundColor: Colors.black87,
        elevation: 1,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: ElevatedButton(
              onPressed: () =>
                  context.read<OrdersBloc>().add(LoadKitchenOrders()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFEBEE),
                foregroundColor: const Color(0xFFC62828),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Horno',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<OrdersBloc, OrdersState>(
              builder: (context, state) {
                if (state is OrdersLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                if (state is OrdersError) {
                  return Center(
                    child: Text(state.message),
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
                              color: Colors.black54,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Align(
                    alignment: Alignment.topLeft,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: state.orders.map((order) {
                          return Container(
                            width: 310,
                            margin: const EdgeInsets.only(right: 16),
                            child: OrderCardWidget(
                              order: order,
                              isKitchen: true,
                              onStatusChange: (id, status) {
                                context.read<OrdersBloc>().add(
                                      UpdateOrderStatus(id, status),
                                    );
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          const Divider(height: 1),
          const _KitchenTimersPanel(),
        ],
      ),
    );
  }
}

class _KitchenTimersPanel extends StatelessWidget {
  const _KitchenTimersPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _TimerWidget(label: 'Horno 1'),
          _TimerWidget(label: 'Horno 2'),
          _TimerWidget(label: 'Horno 3'),
        ],
      ),
    );
  }
}

class _TimerWidget extends StatefulWidget {
  final String label;
  const _TimerWidget({required this.label});

  @override
  State<_TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<_TimerWidget> {
  int _seconds = 180; // Default 3 min
  int _initialSeconds = 180; // Memory of the last set time
  Timer? _timer;
  bool _isRunning = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      if (_seconds <= 0) {
        // If 0, reset to initial and start
        setState(() => _seconds = _initialSeconds);
      }
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            if (_seconds > 0) {
              _seconds--;
            } else {
              timer.cancel();
              _isRunning = false;
              _seconds = _initialSeconds; // Auto-reset to memory
            }
          });
        }
      });
    }
  }

  void _adjustTime(bool increase) {
    setState(() {
      if (increase) {
        _seconds = ((_seconds / 10).floor() + 1) * 10;
      } else {
        if (_seconds > 0) {
          _seconds = ((_seconds - 1) / 10).floor() * 10;
        }
      }
      _seconds = _seconds.clamp(0, 3600);

      // If stopped, update the "memory" to the new time
      if (!_isRunning) {
        _initialSeconds = _seconds;
      }
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _seconds = _initialSeconds; // Reset to last configured time
    });
  }

  String _formatTime() {
    final m = (_seconds / 60).floor().toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _isRunning ? Colors.green.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isRunning ? Colors.green : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatTime(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                      color: _isRunning
                          ? Colors.green.shade800
                          : (_seconds > 0 ? Colors.black87 : Colors.grey),
                    ),
                  ),
                  if (!_isRunning && _seconds > 0)
                    InkWell(
                      onTap: _resetTimer,
                      child: const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Text("Reset",
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue,
                                decoration: TextDecoration.underline)),
                      ),
                    )
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TimeControlButton(
                      icon: Icons.remove, onPressed: () => _adjustTime(false)),
                  const SizedBox(width: 4),
                  if (_isRunning)
                    IconButton.filled(
                      onPressed: _toggleTimer,
                      icon: const Icon(Icons.pause, size: 20),
                      style: IconButton.styleFrom(
                          backgroundColor: Colors.orange,
                          minimumSize: const Size(36, 36),
                          padding: EdgeInsets.zero),
                    )
                  else
                    IconButton.filled(
                      onPressed: _seconds > 0 ? _toggleTimer : null,
                      icon: const Icon(Icons.play_arrow, size: 20),
                      style: IconButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: const Size(36, 36),
                          padding: EdgeInsets.zero),
                    ),
                  const SizedBox(width: 4),
                  _TimeControlButton(
                      icon: Icons.add, onPressed: () => _adjustTime(true)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _TimeControlButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }
}
