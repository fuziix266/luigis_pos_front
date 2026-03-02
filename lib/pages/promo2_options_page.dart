import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../config/theme.dart';
import '../blocs/catalog/catalog_bloc.dart';
import '../widgets/extra_ingredients_modal.dart';

class Promo2OptionsPage extends StatefulWidget {
  final int basePrice;
  final String initialPizzaVariety; // Nueva propiedad

  const Promo2OptionsPage({
    super.key,
    required this.basePrice,
    this.initialPizzaVariety = 'Napolitana', // Default
  });

  @override
  State<Promo2OptionsPage> createState() => _Promo2OptionsPageState();
}

class _Promo2OptionsPageState extends State<Promo2OptionsPage> {
  // Fixed configuration for Promo 2
  late List<Promo2PizzaState> _pizzas;
  bool _upgradeToParmesan = false;
  bool _noGarlicSticks = false; // Nueva opción
  String _selectedDrink = 'Coca Cola 1.5L';
  final int _parmesanUpgradePrice = 1000;
  final int _noGarlicDiscount = 1000; // Descuento

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Cargar ingredientes iniciales basado en widget.initialPizzaVariety
    final state = context.read<CatalogBloc>().state;
    List<String>? initialIngredients;

    if (state is CatalogLoaded) {
      print(
          'DEBUG: Available Pizzas in Catalog: ${state.pizzas.map((e) => e['name']).toList()}');
      print('DEBUG: Searching for: "${widget.initialPizzaVariety}"');
      final pizza = state.pizzas.firstWhere(
        (p) {
          var pName = p['name'].toString().trim().toLowerCase();
          var target =
              widget.initialPizzaVariety.toString().trim().toLowerCase();

          // Basic normalization for accents/ñ
          pName = pName
              .replaceAll('ñ', 'n')
              .replaceAll('á', 'a')
              .replaceAll('é', 'e')
              .replaceAll('í', 'i')
              .replaceAll('ó', 'o')
              .replaceAll('ú', 'u');

          target = target
              .replaceAll('ñ', 'n')
              .replaceAll('á', 'a')
              .replaceAll('é', 'e')
              .replaceAll('í', 'i')
              .replaceAll('ó', 'o')
              .replaceAll('ú', 'u');

          return pName == target ||
              pName.contains(target) ||
              target.contains(pName);
        },
        orElse: () => null,
      );
      if (pizza == null) {
        print(
            'WARNING: Initial pizza "${widget.initialPizzaVariety}" not found in catalog. Using default ingredients.');
      }
      if (pizza != null && pizza['ingredients'] != null) {
        initialIngredients = (pizza['ingredients'] as List)
            .map((i) => i['name'].toString())
            .toList();
      }
    }

    _pizzas = [
      Promo2PizzaState(
        id: 1,
        name: 'Pizza 1',
        variety: widget.initialPizzaVariety,
        initialIngredients: initialIngredients,
      ),
      Promo2PizzaState(
        id: 2,
        name: 'Pizza 2',
        variety: widget.initialPizzaVariety,
        initialIngredients: initialIngredients,
      ),
    ];
  }

  int get _totalPrice {
    int price = widget.basePrice;
    if (_upgradeToParmesan) price += _parmesanUpgradePrice;
    if (_noGarlicSticks) price -= _noGarlicDiscount;
    return price;
  }

  @override
  Widget build(BuildContext context) {
    // DEBUG: Check if pizzas have ingredients
    final state = context.read<CatalogBloc>().state;
    if (state is CatalogLoaded && state.pizzas.isNotEmpty) {
      print('DEBUG PIZZA STRUCTURE: ${state.pizzas.first}');
    }

    return Dialog(
      backgroundColor: Colors.grey.shade50,
      surfaceTintColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 800,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text('PROMO 2 + EXTRAS',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('CONFIGURANDO COMBO',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Pizza Cards
                  ..._pizzas.map((pizza) => _buildPizzaCard(pizza)),

                  const SizedBox(height: 24),
                  // Acompañamientos
                  const Center(
                    child: Text(
                      'ACOMPAÑAMIENTOS',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _noGarlicSticks = !_noGarlicSticks;
                                if (_noGarlicSticks) {
                                  _upgradeToParmesan = false;
                                }
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _noGarlicSticks
                                  ? Colors.red
                                  : Colors.grey.shade200,
                              foregroundColor: _noGarlicSticks
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: _noGarlicSticks ? 2 : 0,
                            ),
                            child: Text(
                              'Sin Palitos (-\$1.000)',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _upgradeToParmesan = !_upgradeToParmesan;
                                if (_upgradeToParmesan) {
                                  _noGarlicSticks = false;
                                }
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _upgradeToParmesan
                                  ? AppColors.primary
                                  : Colors.grey.shade200,
                              foregroundColor: _upgradeToParmesan
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: _upgradeToParmesan ? 2 : 0,
                            ),
                            child: Text(
                              'Palitos Parm. (+\$1.000)',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  // Bebida
                  const Center(
                    child: Text(
                      'BEBIDA',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          _selectedDrink,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _selectDrink,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade200,
                            foregroundColor: AppColors.textPrimary,
                            elevation: 0,
                          ),
                          child: const Text('CAMBIAR'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildPizzaCard(Promo2PizzaState pizza) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              pizza.name.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              pizza.variety,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Action Buttons
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _optionButton('EXTRAS', () => _showExtrasDialog(pizza)),
                _optionButton('ELIMINAR', () => _showEliminarDialog(pizza)),
                _optionButton('REEMPLAZO', () => _showReemplazoDialog(pizza)),
                _optionButton('EXCEPCIÓN', () => _showExceptionDialog(pizza)),
              ],
            ),
            // Display Results (Extras, Exceptions)
            if (pizza.exceptions.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...pizza.exceptions.map((ex) => Text('- $ex (Sin)',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold))),
            ],
            // Replacements
            if (pizza.replacements.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...pizza.replacements.map((rep) => Text(rep,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold))),
            ],
            if (pizza.extras.isNotEmpty) ...[
              const SizedBox(height: 8),
              ..._groupExtras(pizza.extras).entries.map((e) => Text(
                  '+ ${e.key} ${e.value > 1 ? "(x${e.value})" : ""}',
                  style: const TextStyle(
                      color: AppColors.success, fontWeight: FontWeight.bold))),
            ],

            const SizedBox(height: 16),
            TextField(
              controller: pizza.noteController,
              decoration: InputDecoration(
                hintText: 'Nota para ${pizza.name}...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.orange.shade200),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionButton(String label, VoidCallback onTap) {
    // Style mimicking text buttons in the row
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.redAccent, // Or closest color from image
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('\$$_totalPrice',
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Generate result logic
                final pizzaDescs = <String>[];
                for (var p in _pizzas) {
                  final sb = StringBuffer(
                      p.variety != widget.initialPizzaVariety
                          ? 'Excepci\u00f3n: ${p.variety}'
                          : p.variety);
                  if (p.extras.isNotEmpty) {
                    final extrasMap = _groupExtras(p.extras);
                    final extrasStr = extrasMap.entries
                        .map((e) =>
                            "+${e.key}${e.value > 1 ? "(x${e.value})" : ""}")
                        .join(", ");
                    sb.write(' ($extrasStr)');
                  }
                  if (p.exceptions.isNotEmpty) {
                    sb.write(' (Sin: ${p.exceptions.join(", ")})');
                  }
                  if (p.replacements.isNotEmpty) {
                    sb.write(' (${p.replacements.join(', ')})');
                  }
                  if (p.noteController.text.isNotEmpty) {
                    sb.write(' [${p.noteController.text}]');
                  }
                  pizzaDescs.add(sb.toString());
                }

                // Group identical pizzas
                final parts = <String>[];
                if (pizzaDescs.length == 2 && pizzaDescs[0] == pizzaDescs[1]) {
                  parts.add('${pizzaDescs[0]} x2');
                } else {
                  parts.addAll(pizzaDescs);
                }

                if (_upgradeToParmesan) {
                  parts.add('Palitos Parmesano');
                } else if (_noGarlicSticks) {
                  parts.add('Sin Palitos de ajo');
                } else {
                  parts.add('Palitos de ajo');
                }
                parts.add(_selectedDrink);
                final description = parts.join(' | ');

                // Calculate total extras price (always $2000 for Promos as they are size F)
                int extrasCount = 0;
                for (var p in _pizzas) {
                  extrasCount += p.extras.length;
                }
                final finalPrice = _totalPrice + (extrasCount * 2000);

                // Calculate structured data
                final allRemoved = <String>[];
                final allExtras = <Map<String, dynamic>>[];

                // Global extras/notes
                if (_upgradeToParmesan) {
                  // Upgrading is a modification
                }
                if (_noGarlicSticks) {
                  allRemoved.add('Palitos de ajo');
                }

                for (var p in _pizzas) {
                  // Removed
                  for (var ex in p.exceptions) {
                    allRemoved.add('$ex (${p.name})');
                  }
                  // Replacements (Display in RED as requested)
                  for (var rep in p.replacements) {
                    allRemoved.add('$rep (${p.name})');
                  }

                  // Extras
                  for (var ex in p.extras) {
                    allExtras.add({
                      'ingredient_name': '$ex (${p.name})',
                      'extra_price': 2000,
                    });
                  }
                }

                Navigator.of(context).pop({
                  'description': description,
                  'price': finalPrice, // Includes base + parmesan + extras
                  'removed': allRemoved,
                  'extras': allExtras,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('CONFIRMAR PROMO',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // --- Logic Helpers ---

  Future<void> _selectDrink() async {
    final state = context.read<CatalogBloc>().state;
    if (state is! CatalogLoaded) return;

    final result = await showDialog<String>(
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
                itemBuilder: (ctx, i) => ListTile(
                  title: Text(state.drinks[i]['name'],
                      textAlign: TextAlign.center),
                  onTap: () => Navigator.of(ctx).pop(state.drinks[i]['name']),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (result != null) {
      setState(() => _selectedDrink = result);
    }
  }

  void _showExtrasDialog(Promo2PizzaState pizza) async {
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

  void _showExceptionDialog(Promo2PizzaState pizza) {
    final state = context.read<CatalogBloc>().state;
    if (state is! CatalogLoaded) return;

    // Filter out current pizza variety
    final allPizzas = state.pizzas;
    final availablePizzas =
        allPizzas.where((p) => p['name'] != pizza.variety).toList();

    // Check if 'Napolitana' is the base one, maybe filter it?
    // Usually 'Exception' means changing the base pizza, so filtering the base 'Napolitana' makes sense if it's the default.
    final filteredPizzas = availablePizzas.where((p) {
      final name = (p['name'] as String).trim();
      return !['Clasica', 'Arma Tu Pizza'].contains(name);
    }).toList();
    filteredPizzas
        .sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

    // Search logic
    List<dynamic> displayedPizzas = List.from(filteredPizzas);

    showDialog(
        context: context,
        builder: (ctx) => Center(
                child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: StatefulBuilder(
                builder: (ctx, setDialogState) {
                  return AlertDialog(
                    backgroundColor: Colors.white,
                    surfaceTintColor: Colors.white,
                    title: const Text(
                      'Cambiar Pizza',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    content: SizedBox(
                      width: double.maxFinite,
                      height: 450,
                      child: Column(
                        children: [
                          TextField(
                            decoration: const InputDecoration(
                              hintText: 'Buscar pizza...',
                              prefixIcon: Icon(Icons.search),
                            ),
                            onChanged: (val) {
                              setDialogState(() {
                                displayedPizzas = filteredPizzas
                                    .where((p) => (p['name'] as String)
                                        .toLowerCase()
                                        .contains(val.toLowerCase()))
                                    .toList();
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: ListView.builder(
                              itemCount: displayedPizzas.length,
                              itemBuilder: (ctx, i) {
                                final p = displayedPizzas[i];
                                return ListTile(
                                  title: Text(p['name'],
                                      textAlign: TextAlign.center),
                                  onTap: () {
                                    setState(() {
                                      pizza.variety = p['name'];

                                      // Actualizar ingredientes base
                                      final ingreds =
                                          p['ingredients'] as List<dynamic>?;
                                      if (ingreds != null) {
                                        pizza.baseIngredients = ingreds
                                            .map((i) => i['name'].toString())
                                            .toList();
                                      } else {
                                        pizza.baseIngredients = [];
                                      }

                                      // Resetear modificaciones
                                      pizza.replacements.clear();
                                      pizza.exceptions.clear();
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
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  );
                },
              ),
            )));
  }

  void _showEliminarDialog(Promo2PizzaState pizza) {
    // Usar ingredientes base dinámicos de la pizza
    final baseIngredients = List<String>.from(pizza.baseIngredients);
    baseIngredients.sort();

    showDialog(
      context: context,
      builder: (ctx) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: StatefulBuilder(
            builder: (ctx, setDialogState) {
              return AlertDialog(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
                title: Text(
                  'Eliminar Ingredientes - ${pizza.name}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: baseIngredients.map((ing) {
                              final isRemoved = pizza.exceptions.contains(ing);
                              return CheckboxListTile(
                                title: Text(ing, textAlign: TextAlign.center),
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
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Listo',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showReemplazoDialog(Promo2PizzaState pizza) {
    // Ingredientes reemplazables: Todos los base MENOS Salsa, Queso, Oregano
    final replaceableIngredients = pizza.baseIngredients
        .where((ing) => !['Salsa de tomate', 'Queso', 'Oregano'].contains(ing))
        .toList();
    replaceableIngredients.sort();

    showDialog(
      context: context,
      builder: (ctx) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            title: const Text(
              'Reemplazar ingrediente',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: replaceableIngredients.map((ing) {
                          // Check if already replaced
                          String? currentReplacement;
                          for (final rep in pizza.replacements) {
                            if (rep.startsWith('$ing ->')) {
                              currentReplacement = rep.split(' -> ')[1];
                              break;
                            }
                          }

                          return ListTile(
                            title: Text(ing, textAlign: TextAlign.center),
                            subtitle: currentReplacement != null
                                ? Text(
                                    'Actual: $currentReplacement',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        color: Colors.red, fontSize: 12),
                                  )
                                : null,
                            onTap: () async {
                              Navigator.of(ctx).pop();
                              // Select new ingredient
                              final newIngredient =
                                  await _selectReplacementIngredient();
                              if (newIngredient != null) {
                                setState(() {
                                  // Remove existing replacement for this ingredient if any
                                  pizza.replacements.removeWhere(
                                      (rep) => rep.startsWith('$ing ->'));
                                  // Add new replacement
                                  pizza.replacements
                                      .add('$ing -> $newIngredient');
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Listo',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Future<String?> _selectReplacementIngredient() async {
    final state = context.read<CatalogBloc>().state;
    if (state is! CatalogLoaded) return null;

    // Use a dialog with search similar to Promo 1
    // Filter logic if needed
    List<dynamic> allIngredients = List.from(state.ingredients);
    allIngredients
        .sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    List<dynamic> filtered = List.from(allIngredients);

    return showDialog<String>(
      context: context,
      builder: (ctx) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: StatefulBuilder(
            builder: (ctx, setDialogState) {
              return AlertDialog(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
                title: const Text(
                  'Seleccionar nuevo ingrediente',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        decoration: const InputDecoration(
                          hintText: 'Buscar...',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (val) {
                          setDialogState(() {
                            filtered = allIngredients
                                .where((ing) => (ing['name'] as String)
                                    .toLowerCase()
                                    .contains(val.toLowerCase()))
                                .toList();
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: filtered.length,
                          itemBuilder: (ctx, i) {
                            final name = filtered[i]['name'];
                            return ListTile(
                              title: Text(name),
                              onTap: () => Navigator.of(ctx).pop(name),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancelar',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Map<String, int> _groupExtras(List<String> extras) {
    final map = <String, int>{};
    for (final e in extras) {
      map[e] = (map[e] ?? 0) + 1;
    }
    return map;
  }
}

class Promo2PizzaState {
  final int id;
  final String name;
  String variety; // e.g. "Napolitana"
  List<String> baseIngredients; // Ingredientes base actuales de esta pizza
  final List<String> extras = [];
  final List<String> exceptions = []; // Removed ingredients
  final List<String> replacements = []; // "Original -> New"
  final TextEditingController noteController = TextEditingController();

  Promo2PizzaState({
    required this.id,
    required this.name,
    required this.variety,
    List<String>? initialIngredients, // Opcional
  }) : baseIngredients = initialIngredients ??
            [
              'Aceitunas',
              'Jamon',
              'Pimenton',
              'Queso',
              'Salsa de tomate',
              'Oregano'
            ]; // Default Napolitana ingredients (from JSON)
}
