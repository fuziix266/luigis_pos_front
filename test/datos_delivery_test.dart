import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luigis_pos/widgets/order_card_widget.dart';

Map<String, dynamic> pedidoLocal() => {
      'id': 3776,
      'order_number': '012',
      'client_name': 'PRUEBA',
      'delivery_type': 'Local',
      'payment_method': null,
      'delivery_address': '',
      'address_detail': '',
      'phone': '',
      'status': 'NUEVO',
      'subtotal': 12000,
      'delivery_fee': 0,
      'total_amount': 12000,
      'activation_time': null,
      'time_created': '2026-11-08 22:00:00',
      'time_entered_oven': null,
      'time_completed': null,
      'time_pickup': null,
      'time_delivered': null,
      'is_deleted': false,
      'is_paid': false,
      'notes': '',
      'items': [
        {
          'id': 1,
          'item_type': 'promo',
          'item_name': 'Promo 1',
          'details': 'Napolitana | Coca Cola 1.5L',
          'removed_ingredients': [],
          'quantity': 1,
          'unit_price': 12000,
          'total_price': 12000,
          'comments': 'Napolitana | Coca Cola 1.5L',
          'extras': [],
        }
      ],
    };

void main() {
  testWidgets('DATOS: usa la tarifa de la configuración del servidor local',
      (tester) async {
    final overridesPrevios = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = overridesPrevios);
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final llamadas = <Map<String, dynamic>>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: OrderCardWidget(
            order: pedidoLocal(),
            onUpdate: (id, data) => llamadas.add({'id': id, ...data}),
          ),
        ),
      ),
    ));
    await tester.tap(find.textContaining('Promo 1', findRichText: true).first);
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.text('DATOS'));
      await tester.pump();
      await Future.delayed(const Duration(seconds: 2));
    });
    await tester.pumpAndSettle();
    await tester.tap(find.text('Local').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delivery').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('GUARDAR'));
    await tester.pumpAndSettle();

    final envio = (llamadas.single['items'] as List)
        .firstWhere((i) => i['item_type'] == 'delivery_fee');
    // ignore: avoid_print
    print('ENVIO CON CONFIG LOCAL: ${envio['unit_price']}');
    expect(envio['unit_price'], 3500);
    await tester.pumpWidget(const SizedBox());
  }, tags: ['servidor-local']);

  testWidgets('DATOS: cambiar Local a Delivery manda tipo y envío',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final llamadas = <Map<String, dynamic>>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: OrderCardWidget(
            order: pedidoLocal(),
            onUpdate: (id, data) => llamadas.add({'id': id, ...data}),
          ),
        ),
      ),
    ));

    await tester.tap(find.textContaining('Promo 1', findRichText: true).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('DATOS'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Local').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delivery').last);
    await tester.pumpAndSettle();

    final direccion = find.widgetWithText(TextField, 'Dirección');
    expect(direccion, findsOneWidget);
    await tester.enterText(direccion, 'Cobquecura 1752');
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    await tester.tap(find.text('GUARDAR'));
    await tester.pumpAndSettle();

    expect(llamadas, hasLength(1));
    final enviado = llamadas.single;
    // ignore: avoid_print
    print('ENVIADO: delivery_type=${enviado['delivery_type']} '
        'direccion=${enviado['delivery_address']} '
        'items=${(enviado['items'] as List).map((i) => '${i['item_type']}:${i['unit_price']}').toList()}');
    expect(enviado['delivery_type'], 'Delivery');
    expect(enviado['delivery_address'], 'Cobquecura 1752');
    expect((enviado['items'] as List).any((i) => i['item_type'] == 'delivery_fee'),
        isTrue);
    expect(enviado.containsKey('activation_time'), isFalse);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('DATOS: cambiar Delivery a Retiro quita el envío',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final pedido = pedidoLocal()
      ..['delivery_type'] = 'Delivery'
      ..['delivery_address'] = 'Cobquecura 1752'
      ..['delivery_fee'] = 3500
      ..['total_amount'] = 15500
      ..['activation_time'] = '2026-11-08 21:20:00';
    (pedido['items'] as List).add({
      'id': 2,
      'item_type': 'delivery_fee',
      'item_name': 'Envío',
      'quantity': 1,
      'unit_price': 3500,
      'total_price': 3500,
      'removed_ingredients': [],
      'extras': [],
    });

    final llamadas = <Map<String, dynamic>>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: OrderCardWidget(
            order: pedido,
            onUpdate: (id, data) => llamadas.add({'id': id, ...data}),
          ),
        ),
      ),
    ));

    await tester.tap(find.textContaining('Promo 1', findRichText: true).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('DATOS'));
    await tester.pumpAndSettle();
    expect(find.text('Envío: \$3.500'), findsOneWidget);

    await tester.tap(find.text('Delivery').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retiro').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('GUARDAR'));
    await tester.pumpAndSettle();

    final enviado = llamadas.single;
    expect(enviado['delivery_type'], 'Retiro');
    expect((enviado['items'] as List).any((i) => i['item_type'] == 'delivery_fee'),
        isFalse);
    expect(enviado.containsKey('activation_time'), isFalse);

    await tester.pumpWidget(const SizedBox());
  });
}
