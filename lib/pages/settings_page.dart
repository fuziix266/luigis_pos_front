import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/api_client.dart';
import '../config/theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  String _searchQuery = '';
  late TabController _tabController;

  List<dynamic> _pizzas = [];
  List<dynamic> _drinks = [];
  List<dynamic> _sides = [];
  List<dynamic> _promos = [];
  List<dynamic> _sizes = [];
  Map<String, dynamic> _config = {};

  // Almacenaremos las actualizaciones pendientes aquí
  // Formato: Map<String, dynamic> update = {'type': ..., 'price': ...}
  final Map<String, Map<String, dynamic>> _updates = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final futures = await Future.wait([
        _api.getPizzas(),
        _api.getDrinks(),
        _api.getSides(),
        _api.getPromos(),
        _api.getSizes(),
        _api.getConfig(),
      ]);
      setState(() {
        _pizzas = futures[0] as List<dynamic>;
        _drinks = futures[1] as List<dynamic>;
        _sides = futures[2] as List<dynamic>;
        _promos = futures[3] as List<dynamic>;
        _sizes = futures[4] as List<dynamic>;
        _config = futures[5] as Map<String, dynamic>;
        _updates.clear();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _markUpdate(String key, Map<String, dynamic> updateData) {
    setState(() {
      _updates[key] = updateData;
    });
  }

  Future<void> _saveChanges() async {
    if (_updates.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await _api.updatePrices(_updates.values.toList());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Precios actualizados exitosamente'), backgroundColor: AppColors.success),
        );
      }
      _updates.clear();
      await _loadData(); // recargar
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración - Precios'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Pizzas'),
            Tab(text: 'Bebidas'),
            Tab(text: 'Acompañamientos'),
            Tab(text: 'Promos'),
            Tab(text: 'Extras y Delivery'),
          ],
        ),
        actions: [
          if (_updates.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Guardar Cambios'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                ),
                onPressed: _saveChanges,
              ),
            )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar producto...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.toLowerCase();
                      });
                    },
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPizzasList(),
                      _buildItemsList(_drinks, 'drink'),
                      _buildItemsList(_sides, 'side'),
                      _buildItemsList(_promos, 'promo', nameField: 'name', priceField: 'base_price'),
                      _buildExtrasAndDeliveryList(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPizzasList() {
    final filtered = _pizzas.where((p) {
      final name = (p['name'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery);
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final pizza = filtered[index];
        final Map<String, dynamic> prices = pizza['prices'] ?? {};
        
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pizza['name'],
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...prices.values.map((sizeData) {
                  final sizeName = sizeData['size_name'];
                  final currentPrice = sizeData['price'];
                  final pizzaId = pizza['id'];
                  final sizeId = sizeData['size_id'];
                  final key = 'pizza_${pizzaId}_$sizeId';
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(sizeName, style: const TextStyle(fontSize: 16)),
                        ),
                        const SizedBox(width: 16),
                        const Text('\$'),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: currentPrice.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) {
                              final newPrice = int.tryParse(val);
                              if (newPrice != null && newPrice != currentPrice) {
                                _markUpdate(key, {
                                  'type': 'pizza_price',
                                  'pizza_id': pizzaId,
                                  'size_id': sizeId,
                                  'price': newPrice,
                                });
                              } else if (newPrice == currentPrice) {
                                setState(() {
                                  _updates.remove(key);
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildItemsList(List<dynamic> items, String updateType, {String nameField = 'name', String priceField = 'price'}) {
    final filtered = items.where((i) {
      final name = (i[nameField] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery);
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        final currentPrice = item[priceField];
        final id = item['id'];
        final key = '${updateType}_$id';

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    item[nameField],
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                const Text('\$'),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    initialValue: currentPrice.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      final newPrice = int.tryParse(val);
                      if (newPrice != null && newPrice != currentPrice) {
                        _markUpdate(key, {
                          'type': updateType,
                          'id': id,
                          'price': newPrice,
                        });
                      } else if (newPrice == currentPrice) {
                        setState(() {
                          _updates.remove(key);
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExtrasAndDeliveryList() {
    final feeBase = int.tryParse(_config['delivery_base_fee']?['value']?.toString() ?? '3000') ?? 3000;
    final feeZone2 = int.tryParse(_config['delivery_zone2_fee']?['value']?.toString() ?? '3500') ?? 3500;
    final feeZone3 = int.tryParse(_config['delivery_zone3_fee']?['value']?.toString() ?? '4000') ?? 4000;

    Widget buildFeeRow(String title, String configKey, int currentFee) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(title, style: const TextStyle(fontSize: 16)),
            ),
            const Text('\$'),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: TextFormField(
                initialValue: currentFee.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  final newPrice = int.tryParse(val);
                  if (newPrice != null && newPrice != currentFee) {
                    _markUpdate('config_$configKey', {
                      'type': 'config',
                      'key': configKey,
                      'price': newPrice,
                    });
                  } else if (newPrice == currentFee) {
                    setState(() => _updates.remove('config_$configKey'));
                  }
                },
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Tarifas Generales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                buildFeeRow('Delivery Zona Base (Centro)', 'delivery_base_fee', feeBase),
                buildFeeRow('Delivery Zona Norte/Yerbas Buenas', 'delivery_zone2_fee', feeZone2),
                buildFeeRow('Delivery Zona Interior/Ávalos', 'delivery_zone3_fee', feeZone3),
              ],
            ),
          ),
        ),
        const Text('Precio de Ingrediente Extra (por tamaño)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ..._sizes.map((size) {
          final currentExtra = size['extra_price'];
          final id = size['id'];
          final key = 'size_extra_$id';

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text('Extra para tamaño: ${size['display_name']}', style: const TextStyle(fontSize: 16)),
                  ),
                  const Text('\$'),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      initialValue: currentExtra.toString(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) {
                        final newPrice = int.tryParse(val);
                        if (newPrice != null && newPrice != currentExtra) {
                          _markUpdate(key, {
                            'type': 'size_extra',
                            'id': id,
                            'price': newPrice,
                          });
                        } else if (newPrice == currentExtra) {
                          setState(() => _updates.remove(key));
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
