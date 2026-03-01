import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../widgets/pizza_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../data/api_client.dart';
import '../blocs/catalog/catalog_bloc.dart';
import '../blocs/orders/orders_bloc.dart';
import '../config/theme.dart';
import 'promo_options_page.dart';
import 'promo2_options_page.dart';
import 'package:flutter/services.dart';

class NewOrderPage extends StatefulWidget {
  final Map<String, dynamic>? existingOrder;
  const NewOrderPage({super.key, this.existingOrder});

  @override
  State<NewOrderPage> createState() => _NewOrderPageState();
}

class _NewOrderPageState extends State<NewOrderPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<Map<String, dynamic>> _cartItems = [];
  String? _deliveryType;
  String? _paymentMethod;
  String _clientName = '';
  String _phone = '';
  String _address = '';
  String _deliveryZone = 'Base (\$3.000)';
  bool _userChangedZoneManually = false;
  Timer? _debounce;
  bool _isGeocoding = false;

  bool _isPointInPolygon(double lat, double lng, List<List<double>> polygon) {
    bool c = false;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      if (((polygon[i][1] > lng) != (polygon[j][1] > lng)) &&
          (lat <
              (polygon[j][0] - polygon[i][0]) *
                      (lng - polygon[i][1]) /
                      (polygon[j][1] - polygon[i][1]) +
                  polygon[i][0])) {
        c = !c;
      }
    }
    return c;
  }

  Future<void> _geocodeAddress(
      String address, void Function(void Function()) setDialogState) async {
    if (address.length < 5) {
      if (mounted) setState(() => _isGeocoding = false);
      setDialogState(() {});
      return;
    }

    try {
      final dio = Dio();
      final url = '${ApiClient.baseUrl}/api/delivery/geocode';
      final response = await dio.post(url,
          data: {'address': address},
          options: Options(
            headers: {'Content-Type': 'application/json'},
            validateStatus: (status) => true,
          ));

      String newZone = 'Base (\$3.000)';

      final rawData = response.data;
      final Map<String, dynamic>? responseMap = (rawData is String)
          ? jsonDecode(rawData)
          : rawData as Map<String, dynamic>?;

      if (responseMap != null && responseMap['success'] == true) {
        final data = responseMap['data'];
        final lat = double.tryParse(data['lat']?.toString() ?? '0') ?? 0.0;
        final lng = double.tryParse(data['lng']?.toString() ?? '0') ?? 0.0;
        print("Backend Proxy Geocoded [\$address] -> lat: \$lat, lng: \$lng");

        final zone3500 = <List<double>>[
          [-18.442889, -70.282444],
          [-18.444583, -70.299083],
          [-18.426583, -70.296944],
          [-18.426361, -70.281167],
        ];

        final zone4000 = <List<double>>[
          [-18.425806, -70.295000],
          [-18.425889, -70.287556],
          [-18.421056, -70.287583],
          [-18.421056, -70.295806],
        ];

        // Validar si retornó algo en null
        if (lat == 0.0 && lng == 0.0) {
          print("API returned 0.0/null for lat/lng");
          newZone = 'Base (\$3.000)';
        } else if (_isPointInPolygon(lat, lng, zone4000)) {
          print("Inside 4000 zone");
          newZone = 'Pasado Capitán Ávalos/Interior (\$4.000)';
        } else if (_isPointInPolygon(lat, lng, zone3500)) {
          print("Inside 3500 zone");
          newZone = 'Norte/Pasado Yerbas Buenas (\$3.500)';
        } else {
          print("Not inside any polygon");
        }
      } else {
        print("No geocode result from proxy for \$address");
      }

      // Keyword fallback logic
      if (newZone == 'Base (\$3.000)') {
        final lower = address.toLowerCase();
        if (lower.contains('avalos') ||
            lower.contains('ávalos') ||
            lower.contains('capitan') ||
            lower.contains('capitán') ||
            lower.contains('interior') ||
            lower.contains('cerro') ||
            lower.contains('lluta') ||
            lower.contains('azapa')) {
          newZone = 'Pasado Capitán Ávalos/Interior (\$4.000)';
        } else if (lower.contains('yerbas buenas') || lower.contains('norte')) {
          newZone = 'Norte/Pasado Yerbas Buenas (\$3.500)';
        }
      }

      print("Final Zone: \$newZone");

      if (mounted) {
        // VISUAL DEBUG ACTIVATED FOR USER
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("MAPA: \$newZone"),
            duration: const Duration(seconds: 4),
            backgroundColor:
                newZone.contains('3.000') ? Colors.orange : Colors.blue,
          ),
        );

        if (_deliveryZone != newZone) {
          setState(() {
            _deliveryZone = newZone;
            _updateDeliveryFee();
          });
        }
      }
    } catch (e) {
      print("Geocoding error: \$e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error local: \$e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeocoding = false);
        setDialogState(() {});
      }
    }
  }

  void _updateDeliveryFee() {
    _cartItems.removeWhere((item) => item['item_type'] == 'delivery_fee');

    if (_deliveryType != 'Delivery') return;

    int fee = 3000;
    if (_deliveryZone.contains('3.500')) fee = 3500;
    if (_deliveryZone.contains('4.000')) fee = 4000;

    _cartItems.add({
      'item_name': 'Envío',
      'item_type': 'delivery_fee',
      'unit_price': fee,
      'quantity': 1,
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    if (widget.existingOrder != null) {
      _loadExistingOrder();
    }
  }

  void _loadExistingOrder() {
    final order = widget.existingOrder!;
    _clientName = order['client_name'] ?? '';
    _phone = order['phone'] ?? '';
    _address = order['delivery_address'] ?? '';
    _deliveryType = order['delivery_type'];
    _paymentMethod = order['payment_method'];

    final items = order['items'] as List? ?? [];
    for (var item in items) {
      if (item['item_type'] == 'delivery_fee') {
        _userChangedZoneManually = true; // prevent auto-override on load
        final fee = item['unit_price'] as int;
        if (fee >= 4000) {
          _deliveryZone = 'Pasado Capitán Ávalos/Interior (\$4.000)';
        } else if (fee >= 3500) {
          _deliveryZone = 'Norte/Pasado Yerbas Buenas (\$3.500)';
        } else {
          _deliveryZone = 'Base (\$3.000)';
        }
      }

      _cartItems.add({
        'item_name': item['item_name'],
        'item_type': item['item_type'] ?? 'unknown',
        'unit_price': item['unit_price'] ?? 0,
        'quantity': item['quantity'] ?? 1,
        'comments': item['comments'],
        'details': item['comments'] ?? item['details'],
        'removed_ingredients': item['removed_ingredients'],
        'extras': item['extras'],
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int? _manualSubtotal;

  int get _subtotal {
    if (_manualSubtotal != null) return _manualSubtotal!;
    return _cartItems.fold(
      0,
      (sum, item) =>
          sum + ((item['unit_price'] as int) * (item['quantity'] as int)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrdersBloc, OrdersState>(
      listener: (context, state) {
        if (state is OrderCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Pedido ${int.tryParse(state.order['order_number']?.toString() ?? '') ?? state.order['order_number']} creado'),
              backgroundColor: AppColors.success,
            ),
          );
          context.go('/orders');
        } else if (state is OrderUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pedido actualizado correctamente'),
              backgroundColor: AppColors.success,
            ),
          );
          // Force navigation back to orders
          Future.delayed(const Duration(milliseconds: 100), () {
            if (context.mounted) context.go('/orders');
          });
        } else if (state is OrdersError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset:
            false, // Prevent keyboard from hiding bottom bar
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/'),
          ),
          title: const Text('Nuevo Pedido'),
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: const [
              Tab(icon: Icon(Icons.local_offer), text: 'Promos'),
              Tab(icon: Icon(Icons.local_pizza), text: 'Pizzas'),
              Tab(icon: Icon(Icons.local_drink), text: 'Otros y Bebidas'),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: BlocBuilder<CatalogBloc, CatalogState>(
                builder: (context, catalogState) {
                  if (catalogState is CatalogLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (catalogState is CatalogError) {
                    return Center(child: Text(catalogState.message));
                  }
                  if (catalogState is! CatalogLoaded) {
                    return const Center(child: Text('Cargando catálogo...'));
                  }

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPromosTab(catalogState),
                      _buildPizzasTab(catalogState),
                      _buildDrinksTab(catalogState),
                    ],
                  );
                },
              ),
            ),
            // Live Cart List
            _buildLiveCartList(),
            // Summary Footer
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveCartList() {
    if (_cartItems.isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(maxHeight: 250),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _cartItems.length,
        separatorBuilder: (ctx, i) =>
            Divider(height: 1, color: Colors.grey.shade100),
        itemBuilder: (ctx, i) {
          final item = _cartItems[i];
          final price = item['unit_price'] as int;
          final quantity = item['quantity'] as int;
          final total = price * quantity;

          // Basic splitting logic for Name vs Description if strictly needed
          // Assuming name contains description details sometimes
          String name = item['item_name'];

          // Heuristic: Split by first " (" or " - " or line break?
          // For now, displaying it cleanly.

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '\$${_formatPrice(total)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // If we stored separate description, use it.
                      // Currently using name for everything, so maybe show quantity logic?
                      if (quantity > 1)
                        Text('x$quantity',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                      // Here we could parse the name to show "Salame | Jamon" in grey if it was part of the string
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () {
                    setState(() {
                      if (quantity > 1) {
                        _cartItems[i]['quantity'] = quantity - 1;
                      } else {
                        _cartItems.removeAt(i);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red, // Per image red circle
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.remove, color: Colors.white, size: 16),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPromosTab(CatalogLoaded catalog) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        ...catalog.promos.where((p) {
          final name = p['name'].toString();
          final isPromoDia = name.contains('Dia') || name.contains('Día');
          // Miércoles no hay Promo del Día
          if (isPromoDia && DateTime.now().weekday == 3) return false;
          return true;
        }).map(
          (p) {
            final name = p['name'].toString();
            final isPromoDia = name.contains('Dia') || name.contains('Día');

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _promoCard(
                isPromoDia ? 'Promo del Día (${_getPizzaDelDia()})' : p['name'],
                p['base_price'],
                'promo',
                onTap: name == 'Promo 1'
                    ? () => _showPromo1Dialog(p['base_price'] as int)
                    : name == 'Promo 2'
                        ? () => _showPromo2Dialog(p['base_price'] as int)
                        : isPromoDia
                            ? () => _showPromoDelDiaDialog(p)
                            : null,
              ),
            );
          },
        ),
      ],
    );
  }

  // Mapa de día de la semana -> pizza
  static const Map<int, String?> _pizzasPorDia = {
    1: "Di'Pollo", // Lunes
    2: 'Nápoles', // Martes
    3: null, // Miércoles - sin promo
    4: 'Española', // Jueves
    5: 'Hawaiana', // Viernes
    6: 'Vegetariana', // Sábado
    7: 'Barbecue', // Domingo
  };

  String _getPizzaDelDia() {
    return _pizzasPorDia[DateTime.now().weekday] ?? 'Napolitana';
  }

  Future<void> _showPromoDelDiaDialog(Map<String, dynamic> promo) async {
    await showDialog(
        context: context,
        builder: (ctx) {
          final pizzaVariety = _getPizzaDelDia();
          String? selectedDrink;
          final price =
              (promo['base_price'] ?? promo['promo_price'] ?? 17000) as int;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: StatefulBuilder(
                builder: (ctx, setDialogState) {
                  return AlertDialog(
                    backgroundColor: Colors.white,
                    surfaceTintColor: Colors.white,
                    title: const Text(
                      'Promo del Día',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade100),
                          ),
                          child: Text(
                            '$pizzaVariety F x2 + Palitos de Ajo + Bebida',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Button: Choose Drink
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () async {
                              final drink = await _showDrinkSelectionDialog();
                              if (drink != null) {
                                setDialogState(() {
                                  selectedDrink = drink;
                                });
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              selectedDrink ?? 'Elegir Bebida',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Button: More Options
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              Navigator.of(ctx).pop();
                              final result = await showDialog(
                                context: context,
                                builder: (context) => Promo2OptionsPage(
                                    basePrice: price,
                                    initialPizzaVariety: pizzaVariety),
                              );

                              if (result != null && result is Map) {
                                final desc = result['description'] as String;
                                final finalPrice = result['price'] as int;
                                final removed =
                                    result['removed'] as List<String>?;
                                final extras = result['extras']
                                    as List<Map<String, dynamic>>?;

                                _addToCart(
                                  'Promo del Día',
                                  finalPrice,
                                  'promo',
                                  details: desc,
                                  removedIngredients: removed,
                                  extras: extras,
                                );
                              }
                            },
                            icon: const Icon(Icons.settings),
                            label: const Text(
                              'Más Opciones',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Button: Add
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              final drink = selectedDrink ?? 'Coca Cola';
                              final desc =
                                  '$pizzaVariety x2 | Palitos de ajo | $drink 1.5L';
                              _addToCart('Promo del Día', price, 'promo',
                                  details: desc);
                            },
                            icon: const Icon(Icons.add_shopping_cart),
                            label: const Text(
                              'Agregar',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  );
                },
              ),
            ),
          );
        }); // Close builder
  }

  Widget _promoCard(String title, int price, String type,
      {VoidCallback? onTap}) {
    return Card(
      elevation: 2,
      surfaceTintColor: Colors.white,
      color: Colors.white,
      child: InkWell(
        onTap: onTap ?? () => _addToCart(title, price, type),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showPromo1Dialog(int basePrice) {
    const ingredients = ['Salame', 'Jamon', 'Pepperoni', 'Champinon'];
    // Ordered list of selections: index 0 = pizza 1, index 1 = pizza 2, etc.
    final List<String> selections = [];
    bool allowExtraPizzas = false;

    showDialog(
      context: context,
      builder: (ctx) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: StatefulBuilder(
            builder: (ctx, setDialogState) {
              return AlertDialog(
                title: const Text(
                  'Promo 1',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...ingredients.map(
                      (ing) {
                        final int count =
                            selections.where((s) => s == ing).length;
                        final isSelected = count > 0;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                setDialogState(() {
                                  if (!allowExtraPizzas &&
                                      selections.length >= 2) {
                                    // Si está limitado a 2, botamos el más antiguo para hacer espacio al nuevo
                                    selections.removeAt(0);
                                  }
                                  selections.add(ing);
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSelected
                                    ? AppColors.primary
                                    : Colors.grey.shade200,
                                foregroundColor: isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: isSelected ? 2 : 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (count > 0)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '$count',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  Text(
                                    ing,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const Divider(
                        height: 24, thickness: 1, color: Color(0xFFEEEEEE)),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setDialogState(() {
                            allowExtraPizzas = !allowExtraPizzas;
                            if (!allowExtraPizzas && selections.length > 2) {
                              selections.removeRange(2, selections.length);
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: allowExtraPizzas
                              ? AppColors.primary
                              : Colors.grey.shade200,
                          foregroundColor: allowExtraPizzas
                              ? Colors.white
                              : AppColors.textPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: allowExtraPizzas ? 2 : 0,
                        ),
                        child: const Text(
                          'Más Pizzas',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final result = await showDialog(
                            context: context,
                            builder: (context) =>
                                PromoOptionsPage(basePrice: basePrice),
                          );
                          if (result != null && mounted) {
                            Navigator.of(context).pop(); // Close the dialog
                            if (result is Map) {
                              _addToCart(
                                'Promo 1',
                                result['price'] as int,
                                'promo',
                                details: result['description'] as String?,
                                removedIngredients:
                                    result['removed'] as List<String>?,
                                extras: result['extras']
                                    as List<Map<String, dynamic>>?,
                              );
                            } else {
                              // Fallback just in case
                              _addToCart(
                                'Promo 1',
                                basePrice,
                                'promo',
                                details: result.toString(),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.settings),
                        label: const Text(
                          'Más Opciones',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: selections.length >= 2
                            ? () {
                                Navigator.of(ctx).pop();

                                // Group by name for description
                                final counts = <String, int>{};
                                for (var s in selections) {
                                  counts[s] = (counts[s] ?? 0) + 1;
                                }

                                final descParts = counts.entries.map((e) {
                                  if (e.value > 1)
                                    return '${e.key} x${e.value}';
                                  return e.key;
                                }).toList();

                                final desc = descParts.join(' | ');

                                int finalPrice = basePrice;
                                if (selections.length > 2) {
                                  finalPrice += (selections.length - 2) * 6000;
                                }

                                _addToCart('Promo 1', finalPrice, 'promo',
                                    details: desc);
                              }
                            : null,
                        icon: const Icon(Icons.add_shopping_cart),
                        label: Text(
                          'Agregar' +
                              (selections.length > 2
                                  ? ' (\$${basePrice + (selections.length - 2) * 6000})'
                                  : ''),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          disabledForegroundColor: Colors.grey.shade500,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
              );
            },
          ),
        ),
      ),
    );
  }

  void _showPromo2Dialog(int price) {
    String? selectedDrink;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text(
              'Promo 2',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: const Text(
                    'Napolitana F x2 + Palitos de Ajo + Bebida',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Button: Choose Drink
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      final drink = await _showDrinkSelectionDialog();
                      if (drink != null) {
                        setDialogState(() {
                          selectedDrink = drink;
                        });
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: selectedDrink != null
                            ? AppColors.primary
                            : Colors.grey.shade300,
                        width: selectedDrink != null ? 2 : 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      selectedDrink ?? 'Elegir Bebida',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: selectedDrink != null
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Button: More Options (Placeholder)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      final result = await showDialog(
                        context: context,
                        builder: (context) =>
                            Promo2OptionsPage(basePrice: price),
                      );

                      if (result != null && result is Map) {
                        final desc = result['description'] as String;
                        final finalPrice = result['price'] as int;
                        final removed = result['removed'] as List<String>?;
                        final extras =
                            result['extras'] as List<Map<String, dynamic>>?;

                        _addToCart(
                          'Promo 2',
                          finalPrice,
                          'promo',
                          details: desc,
                          removedIngredients: removed,
                          extras: extras,
                        );
                      }
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text(
                      'Más Opciones',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Button: Add
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      final drink = selectedDrink ?? 'Coca Cola';
                      final desc =
                          'Napolitana x2 | Palitos de ajo | $drink 1.5L';
                      _addToCart('Promo 2', price, 'promo', details: desc);
                    },
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text(
                      'Agregar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
          );
        },
      ),
    );
  }

  Future<String?> _showDrinkSelectionDialog() {
    final state = context.read<CatalogBloc>().state;
    if (state is! CatalogLoaded) return Future.value(null);

    return showDialog<String>(
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
              'Seleccionar Bebida',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: state.drinks.length,
                itemBuilder: (ctx, i) {
                  final drink = state.drinks[i];
                  return ListTile(
                    title: Text(drink['name'], textAlign: TextAlign.center),
                    onTap: () => Navigator.of(ctx).pop(drink['name']),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPizzasTab(CatalogLoaded catalog) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;
            // Show 2 columns if width is greater than 800 (typical tablet landscape/desktop)
            final int cols = width > 800 ? 2 : 1;
            final double spacing = 12;
            final double itemWidth = (width - (cols - 1) * spacing) / cols;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: catalog.pizzas.where((pizza) {
                final name = pizza['name'].toString().toLowerCase();
                const excluded = [
                  'clasica salame',
                  'clasica jamon',
                  'clasica champi',
                  'clasica pepperoni'
                ];
                return !excluded.any((ex) => name.contains(ex));
              }).map((pizza) {
                return SizedBox(
                  width: itemWidth,
                  child: _pizzaCard(pizza),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _pizzaCard(Map<String, dynamic> pizza) {
    return PizzaCard(
      pizza: pizza,
      onAddToCart: (size, price, comments, {removed, extras}) {
        _addToCart(
          '${pizza['name']} ($size)',
          price,
          'pizza',
          details: comments.isNotEmpty ? comments : null,
          removedIngredients: removed,
          extras: extras,
        );
      },
    );
  }

  Widget _buildDrinksTab(CatalogLoaded catalog) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Acompañamientos primero (incluye Palitos de ajo)
        if (catalog.sides.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              'Acompañamientos',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          ...catalog.sides.map(
            (s) {
              final price = (s['price'] ??
                  s['base_price'] ??
                  s['unit_price'] ??
                  0) as int;
              return Card(
                elevation: 2,
                surfaceTintColor: Colors.white,
                color: Colors.white,
                child: ListTile(
                  leading: const Icon(
                    Icons.restaurant_menu,
                    color: AppColors.warning,
                  ),
                  title: Text(s['name'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('\$${_formatPrice(price)}',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold)),
                  trailing: IconButton.filledTonal(
                    onPressed: () => _addToCart(s['name'], price, 'side'),
                    icon: const Icon(Icons.add),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  onTap: () => _addToCart(s['name'], price, 'side'),
                ),
              );
            },
          ),
        ],
        const SizedBox(height: 24),
        // Bebidas después
        if (catalog.drinks.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              'Bebidas',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          ...catalog.drinks.map(
            (d) {
              final price = (d['price'] ??
                  d['base_price'] ??
                  d['unit_price'] ??
                  0) as int;
              return Card(
                elevation: 2,
                surfaceTintColor: Colors.white,
                color: Colors.white,
                child: ListTile(
                  leading: const Icon(Icons.local_drink, color: AppColors.info),
                  title: Text(d['name'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('\$${_formatPrice(price)}',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold)),
                  trailing: IconButton.filledTonal(
                    onPressed: () => _addToCart(d['name'], price, 'drink'),
                    icon: const Icon(Icons.add),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  onTap: () => _addToCart(d['name'], price, 'drink'),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  void _showOrderSummary() {
    final nameCtrl = TextEditingController(text: _clientName);
    final phoneCtrl = TextEditingController(text: _phone);
    final addressCtrl = TextEditingController(text: _address);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Confirmar Pedido'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: [
                  // Items del carrito
                  if (_cartItems.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('El carrito está vacío',
                          textAlign: TextAlign.center),
                    )
                  else
                    ...List.generate(_cartItems.length, (i) {
                      final item = _cartItems[i];
                      return Card(
                        child: ListTile(
                          title: Text(
                            item['item_name'],
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '\$${_formatPrice(item['unit_price'] as int)} x ${item['quantity']}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '\$${_formatPrice((item['unit_price'] as int) * (item['quantity'] as int))}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              if (item['item_type'] != 'delivery_fee')
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: AppColors.error,
                                  ),
                                  onPressed: () {
                                    setDialogState(() {
                                      setState(() => _cartItems.removeAt(i));
                                    });
                                  },
                                ),
                            ],
                          ),
                        ),
                      );
                    }),

                  const Divider(height: 32),

                  // Datos de entrega
                  Text('Datos', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Nombre cliente',
                      prefixIcon: const Icon(Icons.person),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.paste, size: 20),
                        onPressed: () async {
                          try {
                            final data =
                                await Clipboard.getData(Clipboard.kTextPlain);
                            if (data?.text != null) {
                              nameCtrl.text = data!.text!;
                              _clientName = data.text!;
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Por HTTP usa Pegar de sistema (Mante presionado -> Pegar o Ctrl+V)')),
                            );
                          }
                        },
                      ),
                    ),
                    onChanged: (v) => _clientName = v,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: phoneCtrl,
                    decoration: InputDecoration(
                      labelText: 'Teléfono',
                      prefixIcon: const Icon(Icons.phone),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.paste, size: 20),
                        onPressed: () async {
                          try {
                            final data =
                                await Clipboard.getData(Clipboard.kTextPlain);
                            if (data?.text != null) {
                              phoneCtrl.text = data!.text!;
                              _phone = data.text!;
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Por HTTP usa Pegar de sistema (Mante presionado -> Pegar o Ctrl+V)')),
                            );
                          }
                        },
                      ),
                    ),
                    onChanged: (v) => _phone = v,
                  ),
                  const SizedBox(height: 8),

                  // Tipo de entrega
                  DropdownButtonFormField<String>(
                    value: _deliveryType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo entrega',
                      prefixIcon: Icon(Icons.local_shipping),
                    ),
                    items: [
                      'Local',
                      'Retiro',
                      'Delivery',
                      'PedidosYa',
                      'UberEats'
                    ]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) {
                      setDialogState(() {
                        setState(() {
                          _deliveryType = v;
                          _updateDeliveryFee();
                        });
                      });
                    },
                  ),
                  const SizedBox(height: 8),

                  if (_deliveryType == 'Delivery') ...[
                    TextField(
                      controller: addressCtrl,
                      decoration: InputDecoration(
                        labelText: 'Dirección',
                        prefixIcon: const Icon(Icons.location_on),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (_isGeocoding)
                              Container(
                                width: 20,
                                height: 20,
                                margin: const EdgeInsets.only(right: 8),
                                child: const CircularProgressIndicator(
                                    strokeWidth: 2),
                              ),
                            IconButton(
                              icon: const Icon(Icons.paste, size: 20),
                              onPressed: () async {
                                try {
                                  final data = await Clipboard.getData(
                                      Clipboard.kTextPlain);
                                  if (data?.text != null) {
                                    addressCtrl.text = data!.text!;
                                    _address = data.text!;
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Por HTTP usa Pegar de sistema (Mante presionado -> Pegar o Ctrl+V)')),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      onChanged: (v) {
                        _address = v;

                        if (!_userChangedZoneManually) {
                          if (_debounce?.isActive ?? false) _debounce!.cancel();

                          // Fast keyword fallback first
                          final lower = v.toLowerCase();
                          String newZone = 'Base (\$3.000)';

                          if (lower.contains('avalos') ||
                              lower.contains('ávalos') ||
                              lower.contains('capitan') ||
                              lower.contains('capitán') ||
                              lower.contains('interior') ||
                              lower.contains('cerro') ||
                              lower.contains('lluta') ||
                              lower.contains('azapa')) {
                            newZone =
                                'Pasado Capitán Ávalos/Interior (\$4.000)';
                          } else if (lower.contains('yerbas buenas') ||
                              lower.contains('norte')) {
                            newZone = 'Norte/Pasado Yerbas Buenas (\$3.500)';
                          }

                          if (_deliveryZone != newZone) {
                            setDialogState(() {
                              setState(() {
                                _deliveryZone = newZone;
                                _updateDeliveryFee();
                              });
                            });
                          }

                          // GPS Geocoding verification with polygon coords
                          _debounce = Timer(const Duration(milliseconds: 1500),
                              () async {
                            if (mounted) {
                              setState(() => _isGeocoding = true);
                              setDialogState(() {});
                              await _geocodeAddress(v, setDialogState);
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _deliveryZone,
                      decoration: const InputDecoration(
                        labelText: 'Zona de Reparto',
                        prefixIcon: Icon(Icons.map),
                      ),
                      items: [
                        'Base (\$3.000)',
                        'Norte/Pasado Yerbas Buenas (\$3.500)',
                        'Pasado Capitán Ávalos/Interior (\$4.000)'
                      ]
                          .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e,
                                  style: const TextStyle(fontSize: 14))))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          _userChangedZoneManually = true;
                          setDialogState(() {
                            setState(() {
                              _deliveryZone = v;
                              _updateDeliveryFee();
                            });
                          });
                        }
                      },
                    ),
                  ],
                  const SizedBox(height: 8),

                  // Pago
                  DropdownButtonFormField<String>(
                    value: _paymentMethod,
                    decoration: const InputDecoration(
                      labelText: 'Método pago',
                      prefixIcon: Icon(Icons.payment),
                    ),
                    items: [
                      'Efectivo',
                      'Transferencia',
                      'Tarjeta',
                    ]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setDialogState(
                        () => setState(() => _paymentMethod = v)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL:',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                        ),
                        onPressed: () => _showEditTotalDialog(setDialogState),
                        icon: const Icon(Icons.edit, size: 16),
                        label: Text(
                          '\$${_formatPrice(_subtotal)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('CANCELAR'),
              ),
              if (_cartItems.isNotEmpty)
                TextButton(
                  onPressed: () async {
                    final selectedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                      helpText: 'Programar para HOY a las:',
                    );

                    if (selectedTime != null) {
                      if (context.mounted) Navigator.of(ctx).pop();

                      final now = DateTime.now();
                      var scheduledDate = DateTime(
                        now.year,
                        now.month,
                        now.day,
                        selectedTime.hour,
                        selectedTime.minute,
                      );

                      // Si la hora es menor a la actual, asume el día siguiente
                      if (scheduledDate.isBefore(now)) {
                        scheduledDate =
                            scheduledDate.add(const Duration(days: 1));
                      }

                      final isDelivery = ['Delivery', 'PedidosYa', 'UberEats']
                          .contains(_deliveryType);
                      final subtractMinutes = isDelivery ? 40 : 20;

                      final activationTime = scheduledDate
                          .subtract(Duration(minutes: subtractMinutes));

                      _submitOrder(
                          activationTime: activationTime,
                          deliveryTime: selectedTime);
                    }
                  },
                  child: const Text('PROGRAMAR',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.blue)),
                ),
              ElevatedButton(
                onPressed: _cartItems.isEmpty
                    ? null
                    : () {
                        Navigator.of(ctx).pop();
                        _submitOrder();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
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

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TOTAL',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                InkWell(
                  onTap: () => _showEditTotalDialog((f) => setState(f)),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Row(
                      children: [
                        Text(
                          '\$${_formatPrice(_subtotal)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.edit, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              width: 160,
              child: ElevatedButton(
                onPressed: _cartItems.isEmpty
                    ? null
                    : () {
                        if (widget.existingOrder != null) {
                          _submitOrder();
                        } else {
                          _showOrderSummary();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2ECC71), // Green per image
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  widget.existingOrder != null ? 'ACTUALIZAR' : 'FINALIZAR',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addToCart(String name, int price, String type,
      {String? details,
      List<String>? removedIngredients,
      List<Map<String, dynamic>>? extras}) {
    setState(() {
      // Check if item already exists (exact match)
      final existing = _cartItems.indexWhere((i) =>
          i['item_name'] == name &&
          i['comments'] == details &&
          _areListsEqual(i['removed_ingredients'], removedIngredients) &&
          _areListsEqualExtras(i['extras'], extras));

      if (existing >= 0) {
        _cartItems[existing]['quantity'] =
            (_cartItems[existing]['quantity'] as int) + 1;
      } else {
        _cartItems.add({
          'item_name': name,
          'item_type': type,
          'unit_price': price,
          'quantity': 1,
          'comments': details,
          'details': details,
          'removed_ingredients': removedIngredients,
          'extras': extras,
        });
      }
    });
  }

  void _submitOrder({DateTime? activationTime, TimeOfDay? deliveryTime}) {
    final data = <String, dynamic>{
      'client_name': _clientName, // Allow empty string
      'delivery_type': _deliveryType, // Allow null
      'payment_method': _paymentMethod, // Allow null
      'phone': _phone,
      'delivery_address': _address,
      'items': _cartItems,
    };

    if (activationTime != null) {
      data['activation_time'] =
          activationTime.toIso8601String().split('T').join(' ').split('.')[0];

      if (deliveryTime != null) {
        String twoDigits(int n) => n.toString().padLeft(2, "0");
        final formattedTime =
            '${twoDigits(deliveryTime.hour)}:${twoDigits(deliveryTime.minute)}';
        data['notes'] =
            'Programado para entregar/retirar a las: $formattedTime';
      }
    }

    if (_manualSubtotal != null) {
      data['manual_total'] = _manualSubtotal;
    }

    if (widget.existingOrder != null) {
      context.read<OrdersBloc>().add(
            UpdateOrder(
              widget.existingOrder!['id'] as int,
              data,
            ),
          );
    } else {
      context.read<OrdersBloc>().add(CreateOrder(data));
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

  bool _areListsEqual(List? a, List? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool _areListsEqualExtras(List? a, List? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;

    // Sort or assuming order matters. If order doesn't matter, it's harder.
    // Let's assume order matters for simplicity, or just stringify.
    final strA = a.map((e) => e['ingredient_name'].toString()).join(',');
    final strB = b.map((e) => e['ingredient_name'].toString()).join(',');
    return strA == strB;
  }

  void _showEditTotalDialog(void Function(void Function()) setParentState) {
    int currentTotal = _subtotal;
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
              setParentState(() {
                _manualSubtotal = null; // Reset to auto
              });
              Navigator.of(ctx).pop();
            },
            child: const Text('RESTAURAR AUTO'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(txtController.text.trim());
              if (val != null) {
                setParentState(() {
                  _manualSubtotal = val;
                });
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
}
