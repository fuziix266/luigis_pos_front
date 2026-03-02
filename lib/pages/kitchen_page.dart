import 'dart:async'; // Add async import
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import '../blocs/orders/orders_bloc.dart';
import '../widgets/order_card_widget.dart';

class KitchenPage extends StatefulWidget {
  const KitchenPage({super.key});

  @override
  State<KitchenPage> createState() => _KitchenPageState();
}

class _KitchenPageState extends State<KitchenPage> {
  bool _showTimers = false;
  bool _isLandscapeManual = false;

  @override
  void initState() {
    super.initState();
    // Permitir cualquier orientación en cocina
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    context.read<OrdersBloc>().add(LoadKitchenOrders());
    context.read<OrdersBloc>().add(StartPolling('kitchen'));
  }

  @override
  void dispose() {
    // Volver a vertical al salir si se prefiere
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  void _toggleOrientation() {
    setState(() {
      _isLandscapeManual = !_isLandscapeManual;
    });

    // Intentar bloquear orientación si es posible (nativos)
    if (_isLandscapeManual) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      // En modo cuadrícula permitimos que el sistema decida o forzamos portrait si se prefiere
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFC62828),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.read<OrdersBloc>().add(StopPolling());
            context.go('/');
          },
        ),
        title: const Row(
          children: [
            Icon(Icons.restaurant, size: 24, color: Colors.white),
            SizedBox(width: 8),
            Text('MONITOR COCINA',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          IconButton(
            icon: Icon(_isLandscapeManual ? Icons.grid_view : Icons.view_column,
                color: Colors.white),
            tooltip:
                _isLandscapeManual ? 'Vista Cuadrícula' : 'Vista Horizontal',
            onPressed: _toggleOrientation,
          ),
          IconButton(
            icon: Icon(_showTimers ? Icons.timer : Icons.timer_outlined,
                color: _showTimers ? Colors.amber : Colors.white),
            tooltip: 'Mostrar/Ocultar Temporizadores',
            onPressed: () => setState(() => _showTimers = !_showTimers),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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

                  // Si está activado el modo "Landscape" (Manual), mostramos en FILA horizontal
                  // Si no, podemos usar una cuadrícula para aprovechar mejor el espacio en tablets
                  if (!_isLandscapeManual) {
                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 350,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio:
                            0.55, // Ajustado para el alto de las cartas de cocina
                      ),
                      itemCount: state.orders.length,
                      itemBuilder: (context, index) {
                        return OrderCardWidget(
                          order: state.orders[index],
                          isKitchen: true,
                          onStatusChange: (id, status) {
                            context.read<OrdersBloc>().add(
                                  UpdateOrderStatus(id, status),
                                );
                          },
                        );
                      },
                    );
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(state.orders.length, (index) {
                        return Container(
                          width: 280, // Aumentado para mejor visualización
                          margin: const EdgeInsets.only(right: 16),
                          child: OrderCardWidget(
                            order: state.orders[index],
                            isKitchen: true,
                            onStatusChange: (id, status) {
                              context.read<OrdersBloc>().add(
                                    UpdateOrderStatus(id, status),
                                  );
                            },
                          ),
                        );
                      }),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          if (_showTimers) ...[
            const Divider(height: 1),
            const _KitchenTimersPanel(),
          ],
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
          _TimerWidget(),
          _TimerWidget(),
          _TimerWidget(),
        ],
      ),
    );
  }
}

class _TimerWidget extends StatefulWidget {
  const _TimerWidget();

  @override
  State<_TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<_TimerWidget> {
  int _seconds = 180; // Default 3 min
  int _initialSeconds = 180; // Memory of the last set time
  Timer? _timer;
  bool _isRunning = false;
  bool _isAlarming = false;
  int _alarmSeconds = 60;

  @override
  void dispose() {
    if (_isAlarming) {
      context.read<OrdersBloc>().soundService.stopTimerAlarm();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isAlarming) {
      _stopAlarm();
      return;
    }

    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      if (_seconds <= 0) {
        setState(() {
          _seconds = _initialSeconds;
          _isAlarming = false;
          _alarmSeconds = 60;
        });
      }
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() {
          if (_seconds > 0) {
            _seconds--;
            if (_seconds == 0) {
              _isAlarming = true;
              _alarmSeconds = 60;
              context.read<OrdersBloc>().soundService.playTimerAlarm();
            }
          } else if (_isAlarming) {
            _alarmSeconds--;
            if (_alarmSeconds <= 0) {
              _stopAlarm();
            }
          }
        });
      });
    }
  }

  void _stopAlarm() {
    if (_isAlarming) {
      context.read<OrdersBloc>().soundService.stopTimerAlarm();
    }
    _timer?.cancel();
    setState(() {
      _isAlarming = false;
      _isRunning = false;
      _seconds = _initialSeconds;
      _alarmSeconds = 60;
    });
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

  String _formatTime() {
    final m = (_seconds / 60).floor().toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _isAlarming
            ? (_alarmSeconds % 2 == 0 ? Colors.red.shade100 : Colors.white)
            : (_isRunning ? Colors.green.shade50 : Colors.grey.shade50),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isAlarming
              ? Colors.red
              : (_isRunning ? Colors.green : Colors.grey.shade300),
          width: 3,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isAlarming ? 'ALERTA' : _formatTime(),
                    style: TextStyle(
                      fontSize: _isAlarming ? 32 : 42, // Increased font size
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                      color: _isAlarming
                          ? Colors.red
                          : (_isRunning
                              ? Colors.green.shade800
                              : (_seconds > 0 ? Colors.black87 : Colors.grey)),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TimeControlButton(
                      icon: Icons.remove, onPressed: () => _adjustTime(false)),
                  const SizedBox(width: 8),
                  if (_isRunning || _isAlarming)
                    IconButton.filled(
                      onPressed: _toggleTimer,
                      icon: const Icon(Icons.pause, size: 28),
                      style: IconButton.styleFrom(
                          backgroundColor:
                              _isAlarming ? Colors.red : Colors.orange,
                          minimumSize: const Size(48, 48),
                          padding: EdgeInsets.zero),
                    )
                  else
                    IconButton.filled(
                      onPressed: _seconds > 0 ? _toggleTimer : null,
                      icon: const Icon(Icons.play_arrow, size: 28),
                      style: IconButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: const Size(48, 48),
                          padding: EdgeInsets.zero),
                    ),
                  const SizedBox(width: 8),
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
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 24),
      ),
    );
  }
}
