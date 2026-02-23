import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/catalog/catalog_bloc.dart';
import '../widgets/extra_ingredients_modal.dart';

class PromoOptionsPage extends StatefulWidget {
  final int basePrice; // Price passed from parent

  const PromoOptionsPage({super.key, this.basePrice = 18000});

  @override
  State<PromoOptionsPage> createState() => _PromoOptionsPageState();
}

class _PromoOptionsPageState extends State<PromoOptionsPage> {
  // State for the pizzas. Initialized with 2 pizzas as per Promo 1 definition.
  final List<PromoPizzaState> _pizzas = [
    PromoPizzaState(id: 1, name: 'Pizza 1'),
    PromoPizzaState(id: 2, name: 'Pizza 2'),
  ];

  final List<String> _ingredients = [
    'Salame',
    'Jamon',
    'Pepperoni',
    'Champiñon'
  ];

  bool _allowExtraPizzas = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Promo 1 - Selección'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 1,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: SwitchListTile(
              title: const Text('Más Pizzas',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              value: _allowExtraPizzas,
              activeColor: AppColors.primary,
              onChanged: (val) {
                setState(() {
                  _allowExtraPizzas = val;
                  if (!val && _pizzas.length > 2) {
                    _pizzas.removeRange(2, _pizzas.length);
                  }
                });
              },
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _pizzas.length + (_allowExtraPizzas ? 1 : 0),
              separatorBuilder: (ctx, i) => const SizedBox(height: 16),
              itemBuilder: (ctx, index) {
                if (index == _pizzas.length) {
                  return SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          int nextId =
                              _pizzas.isEmpty ? 1 : _pizzas.last.id + 1;
                          _pizzas.add(PromoPizzaState(
                              id: nextId, name: 'Pizza ${_pizzas.length + 1}'));
                        });
                      },
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Agregar Pizza'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(
                            color: AppColors.primary, width: 2),
                        foregroundColor: AppColors.primary,
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  );
                }
                return _buildPizzaCard(_pizzas[index]);
              },
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildPizzaCard(PromoPizzaState pizza) {
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: Pizza Name
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      pizza.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                if (pizza.id > 2)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _pizzas.remove(pizza);
                      });
                    },
                    tooltip: 'Quitar Pizza',
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Actions: Eliminar, Excepción, Extras
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _actionButton('ELIMINAR', Colors.red, () {
                  _showExceptionDialog(pizza); // Eliminar ingredientes base
                }),
                _actionButton('EXCEPCIÓN', AppColors.secondary, () {
                  _showSpecialIngredientDialog(
                      pizza); // Elegir ingrediente externo
                }),
                _actionButton('EXTRAS', AppColors.textPrimary, () {
                  _showExtrasDialog(pizza);
                }),
              ],
            ),
            const Divider(height: 24, color: Colors.grey),

            // Ingredients List (Filtered or Special)
            if (pizza.isSpecialSelection &&
                pizza.selectedIngredient != null) ...[
              // Show only the special selected ingredient
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      pizza.isSpecialSelection = false;
                      pizza.selectedIngredient = null;
                    });
                  },
                  icon: const Icon(Icons.close, size: 18),
                  label: Text(
                    pizza.selectedIngredient!,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    backgroundColor: Colors.orange.shade50,
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ] else ...[
              // Standard 4 options
              ..._ingredients.map((ing) {
                final isSelected = pizza.selectedIngredient == ing;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          pizza.selectedIngredient = ing;
                          pizza.isSpecialSelection = false;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor:
                            isSelected ? Colors.grey.shade100 : Colors.white,
                        foregroundColor: AppColors.textPrimary,
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.textPrimary
                              : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        ing,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],

            // Display exceptions (removed ingredients)
            if (pizza.exceptions.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...pizza.exceptions.map(
                (ex) => Padding(
                  padding: const EdgeInsets.only(bottom: 4, left: 8),
                  child: Text(
                    '- $ex',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],

            // Display extras (added ingredients)
            if (pizza.extras.isNotEmpty) ...[
              const SizedBox(height: 8),
              ..._groupExtras(pizza.extras).entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 4, left: 8),
                      child: Text(
                        '+ ${entry.key}${entry.value > 1 ? " (x${entry.value})" : ""}',
                        style: const TextStyle(
                          color: AppColors.success, // Green
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
            ],

            const SizedBox(height: 12),
            // Note Field
            const Text(
              'NOTA',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: pizza.noteController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(String label, Color color, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: color,
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
      child: Text(label),
    );
  }

  Widget _buildBottomBar() {
    int totalExtras = 0;
    for (var p in _pizzas) {
      totalExtras += p.extras.length;
    }
    int extraPizzasCount = _pizzas.length > 2 ? _pizzas.length - 2 : 0;
    int currentTotal =
        widget.basePrice + (totalExtras * 2000) + (extraPizzasCount * 6000);

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            // Validate selections
            if (_pizzas.any((p) => p.selectedIngredient == null)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Por favor selecciona los ingredientes')),
              );
              return;
            }

            // Generate result string/object
            // Collect structured data
            final allRemoved = <String>[];
            final allExtras = <Map<String, dynamic>>[];

            for (var p in _pizzas) {
              if (p.exceptions.isNotEmpty) {
                for (var ex in p.exceptions) {
                  allRemoved.add('$ex (${p.name})');
                }
              }
              if (p.extras.isNotEmpty) {
                for (var ex in p.extras) {
                  allExtras.add({
                    'ingredient_name': '$ex (${p.name})',
                    'extra_price': 2000,
                  });
                }
              }
            }

            final parts = _pizzas.map((p) {
              final extrasStr =
                  p.extras.isNotEmpty ? ' (+ ${p.extras.join(", ")})' : '';
              final exceptions = p.exceptions.isNotEmpty
                  ? ' (Sin ${p.exceptions.join(", ")})'
                  : '';
              final note = p.noteController.text.isNotEmpty
                  ? ' [${p.noteController.text}]'
                  : '';
              return '${p.selectedIngredient}$extrasStr$exceptions$note';
            }).toList();

            final description = parts.join(' | ');

            Navigator.of(context).pop({
              'description': description,
              'price': currentTotal,
              'removed': allRemoved,
              'extras': allExtras,
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'CONFIRMAR PEDIDO (\$$currentTotal)',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  void _showExceptionDialog(PromoPizzaState pizza) {
    // Ingredientes base removibles
    final baseIngredients = ['Salsa de tomate', 'Queso', 'Oregano'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(
              'Eliminar Ingredientes - ${pizza.name}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: baseIngredients.map((ing) {
                final isRemoved = pizza.exceptions.contains(ing);
                return CheckboxListTile(
                  title: Text(
                    ing,
                    textAlign: TextAlign.center,
                  ),
                  value: isRemoved,
                  activeColor: Colors.red,
                  onChanged: (val) {
                    setDialogState(() {
                      setState(() {
                        if (val == true) {
                          pizza.exceptions.add(ing);
                        } else {
                          pizza.exceptions.remove(ing);
                        }
                      });
                    });
                  },
                );
              }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('LISTO'),
              ),
            ],
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          );
        },
      ),
    );
  }

  void _showSpecialIngredientDialog(PromoPizzaState pizza) {
    final state = context.read<CatalogBloc>().state;
    if (state is! CatalogLoaded) return;

    // Filter out standard ingredients
    final specialIngredients = state.ingredients
        .where((ing) => ![
              'Salame',
              'Jamon',
              'Pepperoni',
              'Champiñon',
              'Salame',
              'Jamon',
              'Pepperoni',
              'Champinon'
            ].contains(ing['name']))
        .toList();

    // Sort alphabetically
    specialIngredients
        .sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

    // Variable to hold filtered list
    List<dynamic> filteredIngredients = List.from(specialIngredients);
    final searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text(
              'Elegir Ingrediente Especial',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 450, // Increased height for search field
              child: Column(
                children: [
                  // Search Field
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar ingrediente...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          final query = value.toLowerCase();
                          filteredIngredients = specialIngredients.where((ing) {
                            final name = (ing['name'] as String).toLowerCase();
                            return name.contains(query);
                          }).toList();
                        });
                      },
                    ),
                  ),
                  // List
                  Expanded(
                    child: filteredIngredients.isEmpty
                        ? const Center(
                            child: Text(
                              'No se encontraron resultados',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredIngredients.length,
                            itemBuilder: (ctx, i) {
                              final ing = filteredIngredients[i];
                              return ListTile(
                                title: Text(
                                  ing['name'],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
                                ),
                                onTap: () {
                                  setState(() {
                                    pizza.selectedIngredient = ing['name'];
                                    pizza.isSpecialSelection = true;
                                  });
                                  Navigator.of(ctx).pop();
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('CANCELAR'),
              ),
            ],
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          );
        },
      ),
    );
  }

  void _showExtrasDialog(PromoPizzaState pizza) async {
    final state = context.read<CatalogBloc>().state;
    if (state is! CatalogLoaded) return;

    final result = await showDialog<List<String>>(
      context: context,
      builder: (ctx) => ExtraIngredientsModal(
        availableIngredients: state.ingredients,
        initialExtras: pizza.extras,
      ),
    );

    if (result != null) {
      setState(() {
        pizza.extras.clear();
        pizza.extras.addAll(result);
      });
    }
  }

  Map<String, int> _groupExtras(List<String> extras) {
    final map = <String, int>{};
    for (final e in extras) {
      map[e] = (map[e] ?? 0) + 1;
    }
    return map;
  }
}

class PromoPizzaState {
  final int id;
  final String name;
  String? selectedIngredient;
  bool isSpecialSelection = false;
  final List<String> exceptions = [];
  final List<String> extras = [];
  final TextEditingController noteController = TextEditingController();

  PromoPizzaState({required this.id, required this.name});
}
