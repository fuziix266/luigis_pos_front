import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luigis_pos/widgets/order_card_widget.dart';

Map<String, dynamic> pedido({
  String estado = 'NUEVO',
  String napolitana = 'NUEVO',
  String promo = 'NUEVO',
}) =>
    {
      'id': 50,
      'order_number': '012',
      'client_name': 'PRUEBA',
      'delivery_type': 'Local',
      'status': estado,
      'subtotal': 27000,
      'delivery_fee': 0,
      'total_amount': 27000,
      'activation_time': null,
      'time_created': '2026-11-09 21:00:00',
      'is_deleted': false,
      'is_paid': false,
      'notes': '',
      'items': [
        {
          'id': 501,
          'item_type': 'pizza',
          'item_name': 'Napolitana (Familiar)',
          'quantity': 1,
          'unit_price': 12000,
          'total_price': 12000,
          'comments': null,
          'kitchen_status': napolitana,
          'removed_ingredients': [],
          'extras': [],
        },
        {
          'id': 502,
          'item_type': 'promo',
          'item_name': 'Promo 1',
          'quantity': 1,
          'unit_price': 15000,
          'total_price': 15000,
          'comments': 'Pepperoni | Jamon',
          'kitchen_status': promo,
          'removed_ingredients': [],
          'extras': [],
        },
      ],
    };

Widget envolver(Widget hijo, {double ancho = 280}) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: SizedBox(width: ancho, child: hijo)),
      ),
    );

void main() {
  testWidgets('cocina: tocar un producto lo avanza y avisa una sola vez',
      (tester) async {
    final llamadas = <String>[];
    await tester.pumpWidget(envolver(OrderCardWidget(
      order: pedido(),
      isKitchen: true,
      onItemStatusChange: (id, itemId, estado) =>
          llamadas.add('$id/$itemId/$estado'),
    )));

    expect(find.text('P'), findsNothing);
    expect(find.text('A'), findsNothing);
    expect(find.text('H'), findsNothing);

    final napolitana = find.textContaining('Napolitana', findRichText: true);
    final promo = find.textContaining('Promo 1', findRichText: true);

    await tester.tap(napolitana);
    await tester.pump();
    expect(find.text('P'), findsOneWidget);
    expect(llamadas, isEmpty);
    await tester.pump(const Duration(milliseconds: 700));
    expect(llamadas, ['50/501/PREP']);

    await tester.tap(promo);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(promo);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(promo);
    await tester.pump();
    expect(find.text('H'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 700));
    expect(llamadas, ['50/501/PREP', '50/502/HORNO']);

    await tester.longPress(promo);
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('A'), findsOneWidget);
    expect(llamadas.last, '50/502/ARMADO');

    await tester.tap(promo);
    await tester.pump();
    await tester.tap(promo);
    await tester.pump();
    await tester.tap(promo);
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(llamadas.last, '50/502/LISTO');

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('cocina: muestra el estado que viene del servidor',
      (tester) async {
    await tester.pumpWidget(envolver(OrderCardWidget(
      order: pedido(estado: 'PREP', napolitana: 'HORNO', promo: 'PREP'),
      isKitchen: true,
      onItemStatusChange: (_, __, ___) {},
    )));
    expect(find.text('H'), findsOneWidget);
    expect(find.text('P'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('pedidos: el cajero ve el estado de cada producto',
      (tester) async {
    await tester.pumpWidget(envolver(OrderCardWidget(
      order: pedido(estado: 'PREP', napolitana: 'HORNO', promo: 'PREP'),
    ), ancho: 700));
    expect(find.text('En Horno'), findsOneWidget);
    expect(find.text('Preparando'), findsWidgets);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('pedidos: sin chips cuando nada empezó o ya está listo',
      (tester) async {
    await tester.pumpWidget(envolver(OrderCardWidget(order: pedido()), ancho: 700));
    expect(find.text('En Horno'), findsNothing);
    await tester.pumpWidget(envolver(OrderCardWidget(
      order: pedido(estado: 'LISTO', napolitana: 'HORNO', promo: 'LISTO'),
    ), ancho: 700));
    expect(find.text('En Horno'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
