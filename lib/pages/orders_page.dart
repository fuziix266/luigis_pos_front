import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../blocs/orders/orders_bloc.dart';
import '../config/theme.dart';
import '../widgets/aviso_error_guardado.dart';
import '../widgets/order_card_widget.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

enum _Filtro { todos, enCocina, listos }

class _OrdersPageState extends State<OrdersPage> {
  bool _showingScheduled = false;
  _Filtro _filtro = _Filtro.todos;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    if (!_showingScheduled) {
      context.read<OrdersBloc>().add(LoadActiveOrders());
      context.read<OrdersBloc>().add(StartPolling('active'));
    } else {
      context.read<OrdersBloc>().add(LoadScheduledOrders());
      context.read<OrdersBloc>().add(StartPolling('scheduled'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_showingScheduled) {
              setState(() {
                _showingScheduled = false;
              });
              _loadData();
            } else {
              context.read<OrdersBloc>().add(StopPolling());
              context.go('/');
            }
          },
        ),
        title: Text(_showingScheduled
            ? 'Pedidos Programados'
            : 'Gestión de Pedidos Activos'),
        actions: [
          IconButton(
            tooltip: _showingScheduled
                ? 'Ver Pedidos Activos'
                : 'Ver Pedidos Programados',
            icon: Icon(_showingScheduled ? Icons.list_alt : Icons.schedule),
            onPressed: () {
              setState(() {
                _showingScheduled = !_showingScheduled;
              });
              _loadData();
            },
          ),
          IconButton(
            tooltip: 'Refrescar',
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _buildOrdersList(context, _showingScheduled),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/new-order'),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
    );
  }

  static const _estadosEnCocina = ['NUEVO', 'PREP', 'ARMADO', 'HORNO'];

  bool _pasaFiltro(dynamic order) {
    final status = order['status']?.toString() ?? '';
    switch (_filtro) {
      case _Filtro.enCocina:
        return _estadosEnCocina.contains(status);
      case _Filtro.listos:
        return status == 'LISTO';
      case _Filtro.todos:
        return true;
    }
  }

  Widget _buildFiltros(List<dynamic> todos) {
    final enCocina = todos
        .where((o) => _estadosEnCocina.contains(o['status']?.toString()))
        .length;
    final listos = todos.where((o) => o['status'] == 'LISTO').length;

    Widget pestana(_Filtro filtro, String texto, int cantidad, Color color) {
      final activa = _filtro == filtro;
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Material(
            color: activa ? color : Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _filtro = filtro),
              child: Container(
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color, width: 2),
                ),
                child: Text(
                  '$texto ($cantidad)',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: activa ? Colors.white : color,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Row(
        children: [
          pestana(_Filtro.todos, 'Todos', todos.length, AppColors.textPrimary),
          pestana(_Filtro.enCocina, 'En cocina', enCocina, AppColors.statusHorno),
          pestana(_Filtro.listos, 'Listos', listos, AppColors.statusListo),
        ],
      ),
    );
  }

  Widget _buildOrdersList(BuildContext context, bool isScheduled) {
    return BlocConsumer<OrdersBloc, OrdersState>(
      listenWhen: (_, actual) => actual is OrderSaveError,
      listener: (context, state) {
        if (state is OrderSaveError) {
          mostrarErrorGuardado(context, state.message);
        }
      },
      buildWhen: redibujarListaPedidos,
      builder: (context, state) {
        if (state is OrdersLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is OrdersError) {
          return Center(child: Text(state.message));
        }
        if (state is OrdersLoaded) {
          if (isScheduled) {
            return _buildLista(state.orders, isScheduled, reordenable: true);
          }
          final filtrados = state.orders.where(_pasaFiltro).toList();
          return Column(
            children: [
              _buildFiltros(state.orders),
              Expanded(
                child: _buildLista(filtrados, isScheduled,
                    reordenable: _filtro == _Filtro.todos),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLista(List<dynamic> orders, bool isScheduled,
      {required bool reordenable}) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isScheduled ? Icons.schedule : Icons.receipt_long,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(
                    isScheduled
                        ? 'No hay pedidos programados'
                        : switch (_filtro) {
                            _Filtro.listos => 'No hay pedidos listos',
                            _Filtro.enCocina => 'No hay pedidos en cocina',
                            _Filtro.todos => 'Sin pedidos activos',
                          },
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final aspectRatio = constraints.maxHeight > 0
                  ? constraints.maxWidth / constraints.maxHeight
                  : 0.0;
              final isHorizontal = aspectRatio >= (16 / 9);
              final direccion = isHorizontal ? Axis.horizontal : Axis.vertical;

              Widget tarjeta(int index) {
                final order = orders[index];
                return Container(
                  key: ValueKey(order['id']),
                  width: isHorizontal ? 380 : null,
                  margin: EdgeInsets.only(
                    bottom: isHorizontal ? 0 : 8,
                    right: isHorizontal ? 8 : 0,
                  ),
                  alignment: Alignment.topCenter,
                  child: OrderCardWidget(
                    order: order,
                    index: reordenable ? index : null,
                    onStatusChange: _changeStatus,
                    onDelete: _deleteOrder,
                    onUpdate: _updateOrderData,
                  ),
                );
              }

              if (!reordenable) {
                return ListView.builder(
                  scrollDirection: direccion,
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) => tarjeta(index),
                );
              }

              return ReorderableListView.builder(
                buildDefaultDragHandles: false,
                scrollDirection: direccion,
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                onReorder: (oldIndex, newIndex) {
                  context
                      .read<OrdersBloc>()
                      .add(ReorderOrders(oldIndex, newIndex));
                },
                itemBuilder: (context, index) => tarjeta(index),
              );
            },
          );
  }

  void _changeStatus(int orderId, String newStatus) {
    context.read<OrdersBloc>().add(UpdateOrderStatus(orderId, newStatus));
  }

  void _updateOrderData(int orderId, Map<String, dynamic> data) {
    context.read<OrdersBloc>().add(UpdateOrder(orderId, data));
  }

  void _deleteOrder(int orderId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar pedido?'),
        content: const Text('El pedido se moverá al historial como eliminado.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              context.read<OrdersBloc>().add(DeleteOrder(orderId));
              Navigator.pop(context);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
