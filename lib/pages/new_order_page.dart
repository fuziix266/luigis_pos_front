import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../blocs/catalog/catalog_bloc.dart';
import '../blocs/orders/orders_bloc.dart';
import '../config/theme.dart';

class NewOrderPage extends StatefulWidget {
  const NewOrderPage({super.key});

  @override
  State<NewOrderPage> createState() => _NewOrderPageState();
}

class _NewOrderPageState extends State<NewOrderPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<Map<String, dynamic>> _cartItems = [];
  String _deliveryType = 'Local';
  String _paymentMethod = 'Efectivo';
  String _clientName = '';
  String _phone = '';
  String _address = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int get _subtotal => _cartItems.fold(
    0,
    (sum, item) =>
        sum + ((item['unit_price'] as int) * (item['quantity'] as int)),
  );

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrdersBloc, OrdersState>(
      listener: (context, state) {
        if (state is OrderCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pedido #${state.order['order_number']} creado'),
              backgroundColor: AppColors.success,
            ),
          );
          context.go('/orders');
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
              Tab(icon: Icon(Icons.local_drink), text: 'Bebidas'),
              Tab(icon: Icon(Icons.shopping_cart), text: 'Carrito'),
            ],
          ),
        ),
        body: BlocBuilder<CatalogBloc, CatalogState>(
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
                _buildCartTab(),
              ],
            );
          },
        ),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  Widget _buildPromosTab(CatalogLoaded catalog) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (catalog.promoToday != null &&
            catalog.promoToday!['is_closed'] != true) ...[
          _promoCard(
            '🍕 Promo del Día - ${catalog.promoToday!['day_name'] ?? ''}',
            catalog.promoToday!['pizza']?['name'] ?? 'Pizza del día',
            catalog.promoToday!['promo_price'] ?? 17000,
            'promo',
          ),
          const SizedBox(height: 8),
        ],
        ...catalog.promos.map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _promoCard(
              p['name'],
              p['description'] ?? '',
              p['base_price'],
              'promo',
            ),
          ),
        ),
      ],
    );
  }

  Widget _promoCard(String title, String description, int price, String type) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.local_offer, color: AppColors.warning),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(description),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '\$${_formatPrice(price)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 32,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onPressed: () => _addToCart(title, price, type),
                child: const Icon(Icons.add, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPizzasTab(CatalogLoaded catalog) {
    final categories = <String, List<dynamic>>{};
    for (final pizza in catalog.pizzas) {
      final cat = pizza['category']?['display_name'] ?? 'Otra';
      categories.putIfAbsent(cat, () => []).add(pizza);
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: categories.entries
          .expand(
            (entry) => [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  entry.key,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              ...entry.value.map((pizza) => _pizzaCard(pizza, catalog.sizes)),
            ],
          )
          .toList(),
    );
  }

  Widget _pizzaCard(Map<String, dynamic> pizza, List<dynamic> sizes) {
    final prices = pizza['prices'] as Map<String, dynamic>? ?? {};
    final smallPrice = prices['small']?['price'] ?? 0;

    return Card(
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.local_pizza, color: AppColors.primary),
        ),
        title: Text(
          pizza['name'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('Desde \$${_formatPrice(smallPrice as int)}'),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ingredientes
                if (pizza['ingredients'] != null &&
                    (pizza['ingredients'] as List).isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: (pizza['ingredients'] as List)
                        .map<Widget>(
                          (ing) => Chip(
                            label: Text(
                              ing['name'] ?? '',
                              style: const TextStyle(fontSize: 11),
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        )
                        .toList(),
                  ),
                const SizedBox(height: 12),
                // Tamaños
                Row(
                  children: prices.entries.map((e) {
                    final sizeData = e.value as Map<String, dynamic>;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            side: const BorderSide(color: AppColors.primary),
                          ),
                          onPressed: () => _addToCart(
                            '${pizza['name']} (${sizeData['size_name']})',
                            sizeData['price'] as int,
                            'pizza',
                          ),
                          child: Column(
                            children: [
                              Text(
                                sizeData['size_name'] ?? e.key,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '\$${_formatPrice(sizeData['price'] as int)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrinksTab(CatalogLoaded catalog) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (catalog.drinks.isNotEmpty) ...[
          Text('Bebidas', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...catalog.drinks.map(
            (d) => Card(
              child: ListTile(
                leading: const Icon(Icons.local_drink, color: AppColors.info),
                title: Text(d['name'] ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '\$${_formatPrice(d['price'] as int)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle,
                        color: AppColors.primary,
                      ),
                      onPressed: () =>
                          _addToCart(d['name'], d['price'] as int, 'drink'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (catalog.sides.isNotEmpty) ...[
          Text(
            'Acompañamientos',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ...catalog.sides.map(
            (s) => Card(
              child: ListTile(
                leading: const Icon(
                  Icons.restaurant_menu,
                  color: AppColors.warning,
                ),
                title: Text(s['name'] ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '\$${_formatPrice(s['price'] as int)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle,
                        color: AppColors.primary,
                      ),
                      onPressed: () =>
                          _addToCart(s['name'], s['price'] as int, 'side'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCartTab() {
    return _cartItems.isEmpty
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 12),
                Text(
                  'Carrito vacío',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                Text(
                  'Agrega items desde las otras pestañas',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          )
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // Items del carrito
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
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: AppColors.error,
                          ),
                          onPressed: () =>
                              setState(() => _cartItems.removeAt(i)),
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
                decoration: const InputDecoration(
                  labelText: 'Nombre cliente',
                  prefixIcon: Icon(Icons.person),
                ),
                onChanged: (v) => _clientName = v,
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  prefixIcon: Icon(Icons.phone),
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
                items: ['Local', 'Retiro', 'Delivery', 'PedidosYa', 'UberEats']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _deliveryType = v ?? 'Local'),
              ),
              const SizedBox(height: 8),

              if (_deliveryType == 'Delivery')
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Dirección',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  onChanged: (v) => _address = v,
                ),
              const SizedBox(height: 8),

              // Pago
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Método pago',
                  prefixIcon: Icon(Icons.payment),
                ),
                items:
                    [
                          'Efectivo',
                          'Transferencia',
                          'Tarjeta',
                          'Debito',
                          'Credito',
                        ]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                onChanged: (v) =>
                    setState(() => _paymentMethod = v ?? 'Efectivo'),
              ),
              const SizedBox(height: 80),
            ],
          );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_cartItems.length} items',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                Text(
                  'Total: \$${_formatPrice(_subtotal)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _cartItems.isEmpty ? null : _submitOrder,
              icon: const Icon(Icons.check),
              label: const Text('Confirmar'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addToCart(String name, int price, String type) {
    setState(() {
      // Check if item already exists
      final existing = _cartItems.indexWhere((i) => i['item_name'] == name);
      if (existing >= 0) {
        _cartItems[existing]['quantity'] =
            (_cartItems[existing]['quantity'] as int) + 1;
      } else {
        _cartItems.add({
          'item_name': name,
          'item_type': type,
          'unit_price': price,
          'quantity': 1,
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name agregado'),
        duration: const Duration(seconds: 1),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _submitOrder() {
    context.read<OrdersBloc>().add(
      CreateOrder({
        'client_name': _clientName.isEmpty ? 'Sin nombre' : _clientName,
        'delivery_type': _deliveryType,
        'payment_method': _paymentMethod,
        'phone': _phone,
        'delivery_address': _address,
        'items': _cartItems,
      }),
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
}
