import 'package:flutter/material.dart';
import '../blocs/orders/orders_bloc.dart';
import '../config/theme.dart';

void mostrarErrorGuardado(BuildContext context, String mensaje) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.error, color: AppColors.error, size: 48),
      title: const Text('No se guardó el cambio'),
      content: Text(mensaje, style: const TextStyle(fontSize: 17)),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
          ),
          child: const Text('ENTENDIDO'),
        ),
      ],
    ),
  );
}

bool redibujarListaPedidos(OrdersState anterior, OrdersState actual) {
  if (actual is OrderSaveError ||
      actual is OrderUpdated ||
      actual is OrderCreated) {
    return false;
  }
  if (actual is OrdersLoading) {
    return anterior is OrdersInitial || anterior is OrdersError;
  }
  return true;
}
