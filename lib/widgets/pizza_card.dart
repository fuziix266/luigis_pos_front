import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/catalog/catalog_bloc.dart';
import 'extra_ingredients_modal.dart';

class PizzaCard extends StatefulWidget {
  final Map<String, dynamic> pizza;
  final Function(String size, int price, String comments,
      {List<String>? removed, List<Map<String, dynamic>>? extras}) onAddToCart;

  const PizzaCard({
    super.key,
    required this.pizza,
    required this.onAddToCart,
  });

  @override
  State<PizzaCard> createState() => _PizzaCardState();
}

class _PizzaCardState extends State<PizzaCard> {
  String? _selectedSizeKey;
  final TextEditingController _commentController = TextEditingController();
  final Set<String> _removedIngredients = {};
  final Set<String> _replacements = {};
  final List<String> _extras = [];
  final List<String> _customIngredients = [];
  bool _showOptions = false;

  bool get _isClasica =>
      widget.pizza['name'].toString().toLowerCase().contains('clasica');
  bool get _isArmaTuPizza =>
      widget.pizza['name'].toString().toLowerCase().contains('arma tu pizza');

  // ... (existing initState / _initializeDefaultSize)

  void _showChooseIngredientDialog() async {
    final state = context.read<CatalogBloc>().state;
    if (state is! CatalogLoaded) return;

    List<dynamic> candidates = [];
    bool allowMultiple = false;

    if (_isClasica) {
      // Choose 1 from: Salame, Jamon, Pepperoni, Champiñon (matches specific list)
      // Added variations for safety
      final specific = [
        'Salame',
        'Jamon',
        'Pepperoni',
        'Champiñon',
        'Champinon',
        'Champiñones'
      ];
      candidates =
          state.ingredients.where((i) => specific.contains(i['name'])).toList();
      allowMultiple = false;
    } else if (_isArmaTuPizza) {
      // Choose from all
      candidates = List.from(state.ingredients);
      allowMultiple = true;
    }

    candidates
        .sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

    bool isExceptionMode = false;
    String searchQuery = '';

    // Show dialog
    await showDialog(
      context: context,
      builder: (ctx) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: StatefulBuilder(builder: (ctx, setDialogState) {
            List<dynamic> displayCandidates = candidates;

            if (isExceptionMode) {
              displayCandidates = List.from(state.ingredients);
            }

            if (searchQuery.isNotEmpty) {
              displayCandidates = displayCandidates
                  .where((ing) => (ing['name'] as String)
                      .toLowerCase()
                      .contains(searchQuery.toLowerCase()))
                  .toList();
            }

            displayCandidates.sort(
                (a, b) => (a['name'] as String).compareTo(b['name'] as String));

            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text(
                _isClasica ? 'Elige tu ingrediente' : 'Arma tu pizza',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isExceptionMode || _isArmaTuPizza) ...[
                      TextField(
                        decoration: const InputDecoration(
                          hintText: 'Buscar ingrediente...',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (val) {
                          setDialogState(() {
                            searchQuery = val;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: displayCandidates.length,
                        itemBuilder: (ctx, i) {
                          final ingName =
                              displayCandidates[i]['name'] as String;
                          final int count = _customIngredients
                              .where((s) => s == ingName)
                              .length;
                          final isSelected = count > 0;

                          if (!allowMultiple) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    setDialogState(() {
                                      _customIngredients.clear();
                                      _customIngredients.add(ingName);
                                    });
                                    this.setState(
                                        () {}); // Update parent UI immediately
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isSelected
                                        ? AppColors.primary
                                        : Colors.grey.shade200,
                                    foregroundColor: isSelected
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: isSelected ? 2 : 0,
                                  ),
                                  child: Text(
                                    ingName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          } else {
                            return ListTile(
                              title: Text(ingName),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (count > 0)
                                    IconButton(
                                      icon: const Icon(
                                          Icons.remove_circle_outline,
                                          color: Colors.red),
                                      onPressed: () {
                                        setDialogState(() {
                                          _customIngredients.remove(
                                              ingName); // Removes first instance
                                        });
                                        this.setState(() {});
                                      },
                                    ),
                                  if (count > 0)
                                    Text('$count',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline,
                                        color: Colors.green),
                                    onPressed: () {
                                      setDialogState(() {
                                        _customIngredients.add(ingName);
                                      });
                                      this.setState(() {});
                                    },
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    if (_isClasica && !isExceptionMode) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setDialogState(() {
                              isExceptionMode = true;
                            });
                          },
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text(
                            'Excepción',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            side: const BorderSide(color: Colors.orange),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
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
                        child: const Text(
                          'Listo',
                          style: TextStyle(
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
          }),
        ),
      ),
    );
  }

  void _showExtrasDialog() async {
    final state = context.read<CatalogBloc>().state;
    if (state is! CatalogLoaded) return;

    // Use existing ExtraIngredientsModal logic
    final result = await showDialog<List<String>>(
      context: context,
      builder: (ctx) => ExtraIngredientsModal(
        availableIngredients: state.ingredients,
        initialExtras: _extras,
      ),
    );

    if (result != null) {
      setState(() {
        _extras.clear();
        _extras.addAll(result);
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

  void _showReemplazoDialog() {
    final ingredientsRaw = widget.pizza['ingredients'] as List<dynamic>? ?? [];
    // Ingredientes reemplazables: Todos los base MENOS Salsa, Queso, Oregano (si aplica)
    final replaceableIngredients = ingredientsRaw
        .map((i) => i['name'].toString())
        .where((ing) => !['Salsa de tomate', 'Queso', 'Oregano'].contains(ing))
        .toSet()
        .toList()
      ..sort();

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
                              for (final rep in _replacements) {
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
                                  // Select new ingredient
                                  final newIngredient =
                                      await _selectReplacementIngredient();
                                  if (newIngredient != null &&
                                      newIngredient != ing) {
                                    setDialogState(() {
                                      // Update internal state
                                      setState(() {
                                        // Remove existing replacement for this ingredient if any
                                        _replacements.removeWhere(
                                            (rep) => rep.startsWith('$ing ->'));
                                        // Add new replacement
                                        _replacements
                                            .add('$ing -> $newIngredient');
                                      });
                                    });
                                  }
                                },
                                trailing: currentReplacement != null
                                    ? IconButton(
                                        icon: const Icon(Icons.clear,
                                            color: Colors.red),
                                        onPressed: () {
                                          setDialogState(() {
                                            setState(() {
                                              _replacements.removeWhere((rep) =>
                                                  rep.startsWith('$ing ->'));
                                            });
                                          });
                                        },
                                      )
                                    : const Icon(Icons.arrow_forward_ios,
                                        size: 16),
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
                    borderRadius: BorderRadius.circular(16)),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<String?> _selectReplacementIngredient() async {
    final state = context.read<CatalogBloc>().state;
    if (state is! CatalogLoaded) return null;

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

  @override
  void initState() {
    super.initState();
    // No default selection by user request
  }

  void _showEliminarDialog() {
    final ingredientsRaw = widget.pizza['ingredients'] as List<dynamic>? ?? [];
    // Extract names and sort
    final baseIngredients = ingredientsRaw
        .map((i) => i['name'].toString())
        .toSet() // deduplicate just in case
        .toList()
      ..sort();

    if (baseIngredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay ingredientes para eliminar')),
      );
      return;
    }

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
                  'Eliminar Ingredientes - ${widget.pizza['name']}',
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
                              final isRemoved =
                                  _removedIngredients.contains(ing);
                              return CheckboxListTile(
                                title: Text(ing),
                                value: isRemoved,
                                activeColor: Colors.red,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                onChanged: (val) {
                                  setDialogState(() {
                                    if (val == true) {
                                      _removedIngredients.add(ing);
                                    } else {
                                      _removedIngredients.remove(ing);
                                    }
                                  });
                                  // Update parent widget to show red text changes immediately?
                                  // setState inside dialog only updates dialog.
                                  // We also want to update the PizzaCard background if we show "Sin X"
                                  this.setState(() {});
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
                    borderRadius: BorderRadius.circular(16)),
              );
            },
          ),
        ),
      ),
    );
  }

  String _getSizeLabel(String sizeName) {
    final lower = sizeName.toLowerCase();
    if (lower.contains('ind') || lower.contains('chi') || lower.contains('peq'))
      return 'C';
    if (lower.contains('med')) return 'M';
    if (lower.contains('fam')) return 'F';
    return sizeName.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final prices = widget.pizza['prices'] as Map<String, dynamic>? ?? {};
    final availableSizes = prices.entries.toList()
      ..sort((a, b) =>
          (a.value['price'] as int).compareTo(b.value['price'] as int));

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              widget.pizza['name'].toString().toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto', // Or standard
              ),
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Size Buttons
                Row(
                  children: availableSizes.map((entry) {
                    final sizeKey = entry.key;
                    final sizeData = entry.value as Map<String, dynamic>;
                    final label = _getSizeLabel(sizeData['size_name']);
                    final isSelected = _selectedSizeKey == sizeKey;

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedSizeKey = sizeKey;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.success
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.success
                                            .withValues(alpha: 0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : null,
                              border: isSelected
                                  ? Border.all(
                                      color: AppColors.success, width: 2)
                                  : Border.all(color: Colors.grey.shade300),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color:
                                    isSelected ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 8),

                if (_isClasica || _isArmaTuPizza) ...[
                  SizedBox(
                    width: double.infinity,
                    child: _buildActionButton(
                        'ELEGIR INGREDIENTE', _showChooseIngredientDialog),
                  ),
                  const SizedBox(height: 8),
                ],

                // Display Custom Ingredients (Blue chips) ALWAYS VISIBLE
                if (_customIngredients.isNotEmpty) ...[
                  Wrap(
                    spacing: 4,
                    children: _groupExtras(_customIngredients).entries.map((e) {
                      return Chip(
                        label: Text(
                            e.value > 1 ? '${e.value}x ${e.key}' : e.key,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10)),
                        backgroundColor: Colors.blueAccent,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        onDeleted: () {
                          setState(() {
                            _customIngredients.remove(e.key);
                          });
                        },
                        deleteIconColor: Colors.white,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                ],

                // Toggle Options Button
                InkWell(
                  onTap: () {
                    setState(() {
                      _showOptions = !_showOptions;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _showOptions
                              ? 'Ocultar opciones'
                              : 'Opciones adicionales',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _showOptions
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: Colors.black54,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),

                if (_showOptions) ...[
                  const SizedBox(height: 12),

                  // Action Buttons (Eliminar / Reemplazo)
                  Row(
                    children: [
                      Expanded(
                        child:
                            _buildActionButton('ELIMINAR', _showEliminarDialog),
                      ),
                      const SizedBox(width: 8),
                      if (!_isClasica && !_isArmaTuPizza)
                        Expanded(
                          child: _buildActionButton(
                              'REEMPLAZO', _showReemplazoDialog),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Extras Button (Hidden for Arma Tu Pizza)
                  if (!_isArmaTuPizza)
                    SizedBox(
                      width: double.infinity,
                      child: _buildActionButton('EXTRAS', _showExtrasDialog),
                    ),

                  // Display Extras
                  if (_extras.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      children: _groupExtras(_extras).entries.map((e) {
                        return Chip(
                          label: Text(
                              '+ ${e.key} ${e.value > 1 ? "(x${e.value})" : ""}',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 10)),
                          backgroundColor: AppColors.success,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          onDeleted: () {
                            setState(() {
                              _extras.remove(e.key); // removes one instance
                            });
                          },
                          deleteIconColor: Colors.white,
                        );
                      }).toList(),
                    ),
                  ],

                  // Display Removed Ingredients
                  if (_removedIngredients.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      children: _removedIngredients
                          .map((ing) => Chip(
                                label: Text('Sin $ing',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 10)),
                                backgroundColor: Colors.redAccent,
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                                onDeleted: () {
                                  setState(() {
                                    _removedIngredients.remove(ing);
                                  });
                                },
                                deleteIconColor: Colors.white,
                              ))
                          .toList(),
                    ),
                  ],

                  // Display Replacements
                  if (_replacements.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      children: _replacements.map((rep) {
                        final parts = rep.split(
                            ' -> '); // used for display purposes if needed
                        return Chip(
                          label: Text(rep,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 10)),
                          backgroundColor: Colors.orangeAccent,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          onDeleted: () {
                            setState(() {
                              // If user deletes the chip, remove the replacement but keep the underlying ingredient?
                              // Or restore the original?
                              // In Promo2, replacements are just strings.
                              _replacements.remove(rep);
                            });
                          },
                          deleteIconColor: Colors.white,
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Comment Field (Mockup only as per image)
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        hintText: 'Nota...',
                      ),
                    ),
                  ),
                ], // if _showOptions
              ],
            ),
          ),

          // Add Button
          InkWell(
            onTap: () {
              if (_selectedSizeKey != null) {
                final prices = widget.pizza['prices'] as Map<String, dynamic>;
                final sizeData = prices[_selectedSizeKey];

                // Construct comments including removed ingredients, replacements, and extras
                final note = _commentController.text.trim();
                final removedStr = _removedIngredients.isNotEmpty
                    ? 'Sin: ${_removedIngredients.join(", ")}'
                    : '';
                final replacedStr = _replacements.isNotEmpty
                    ? 'Reemplazo: ${_replacements.join(", ")}'
                    : '';

                String customStr = '';
                if (_customIngredients.isNotEmpty) {
                  if (_isArmaTuPizza) {
                    final counts = _groupExtras(_customIngredients);
                    final formatted = counts.entries
                        .map(
                            (e) => e.value > 1 ? '${e.value}x ${e.key}' : e.key)
                        .join(' | ');
                    customStr = '($formatted)';
                  } else {
                    customStr = _customIngredients.join(", ");
                  }
                }

                final extrasMap = _groupExtras(_extras);
                final extrasStr = extrasMap.isNotEmpty
                    ? '(+ ${extrasMap.entries.map((e) => "${e.key}${e.value > 1 ? "(x${e.value})" : ""}").join(", ")})'
                    : '';

                final fullComments = [
                  note,
                  customStr,
                  removedStr,
                  replacedStr,
                  extrasStr
                ].where((s) => s.isNotEmpty).join('. ');

                // Calculate extra price
                int extraPrice = 0;
                // Determine extra unit price based on size
                int extraUnitPrice = 2000; // Default F
                final sizeLabel = _getSizeLabel(sizeData['size_name']);
                if (sizeLabel == 'C')
                  extraUnitPrice = 900;
                else if (sizeLabel == 'M')
                  extraUnitPrice = 1300;
                else if (sizeLabel == 'F') extraUnitPrice = 2000;

                if (_isArmaTuPizza) {
                  // ATP Logic: Base includes 3. 4th+ adds extraUnitPrice (assuming F price applies as base size logic suggests, or follows size rule)
                  // User said: "F = 11000 but if 4th adds 2000". This matches F extra price.
                  final ingCount = _customIngredients.length;
                  final payableExtras = (ingCount > 3) ? (ingCount - 3) : 0;
                  extraPrice = payableExtras * extraUnitPrice;
                } else {
                  // Standard Pizza: Each extra * unit price
                  // "Clasica" logic: 1 ingredient selected (custom), extras are in _extras list.
                  // Wait, Clasica uses _customIngredients for the main choice (1 allowed). Does that count as extra?
                  // No, "Clasica" base price covers the 1 ingredient. _extras list covers additional payed extras.
                  // Standard pizzas use _extras list.

                  // Count total items in _extras (x2 count as 2)
                  int totalExtrasCount = 0;
                  // _extras contains simple list with duplicates for x2
                  totalExtrasCount = _extras.length;

                  extraPrice = totalExtrasCount * extraUnitPrice;
                }

                final removedList = _removedIngredients.toList();
                removedList.addAll(_replacements);

                final extrasList = _extras
                    .map((e) =>
                        {'ingredient_name': e, 'extra_price': extraUnitPrice})
                    .toList();

                widget.onAddToCart(
                  sizeData['size_name'],
                  (sizeData['price'] as int) + extraPrice,
                  fullComments,
                  removed: removedList,
                  extras: extrasList,
                );
              }
            },
            child: Container(
              color: _selectedSizeKey != null
                  ? AppColors.success
                  : const Color(0xFFE0E0E0),
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              child: Text(
                'AGREGAR',
                style: TextStyle(
                  color:
                      _selectedSizeKey != null ? Colors.white : Colors.black54,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, VoidCallback onTap) {
    // ... existing implementation
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
