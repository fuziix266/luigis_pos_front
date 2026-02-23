import 'package:flutter/material.dart';
import '../config/theme.dart';

class ExtraIngredientsModal extends StatefulWidget {
  final List<dynamic> availableIngredients;
  final List<String> initialExtras;

  const ExtraIngredientsModal({
    super.key,
    required this.availableIngredients,
    required this.initialExtras,
  });

  @override
  State<ExtraIngredientsModal> createState() => _ExtraIngredientsModalState();
}

class _ExtraIngredientsModalState extends State<ExtraIngredientsModal> {
  late List<dynamic> _filteredIngredients;
  final TextEditingController _searchController = TextEditingController();
  // Map to track quantities: 'Pollo' => 2
  final Map<String, int> _selectedQuantities = {};

  @override
  void initState() {
    super.initState();
    _filteredIngredients = List.from(widget.availableIngredients);
    // Sort alphabetically
    _filteredIngredients
        .sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

    // Initialize quantities from initialExtras
    for (var extra in widget.initialExtras) {
      _selectedQuantities[extra] = (_selectedQuantities[extra] ?? 0) + 1;
    }
  }

  void _filterIngredients(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredIngredients = List.from(widget.availableIngredients);
      } else {
        _filteredIngredients = widget.availableIngredients.where((ing) {
          final name = (ing['name'] as String).toLowerCase();
          return name.contains(query.toLowerCase());
        }).toList();
      }
      _filteredIngredients
          .sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        height: 600,
        child: Column(
          children: [
            // Title
            const Text(
              'Agregar Extras',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Search
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar ingrediente...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: _filterIngredients,
            ),
            const SizedBox(height: 12),

            // List
            Expanded(
              child: ListView.builder(
                itemCount: _filteredIngredients.length,
                itemBuilder: (ctx, i) {
                  final ing = _filteredIngredients[i];
                  final name = ing['name'] as String;
                  final qty = _selectedQuantities[name] ?? 0;

                  return Card(
                    elevation: 0,
                    color: Colors.grey.shade50,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          ),
                          // Stepper
                          if (qty > 0)
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline,
                                  color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  if (qty > 0) {
                                    _selectedQuantities[name] = qty - 1;
                                    if (_selectedQuantities[name] == 0) {
                                      _selectedQuantities.remove(name);
                                    }
                                  }
                                });
                              },
                            ),
                          if (qty > 0)
                            Text(
                              '$qty',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          IconButton(
                            icon: const Icon(Icons.add_circle,
                                color: AppColors.success),
                            onPressed: () {
                              setState(() {
                                _selectedQuantities[name] = qty + 1;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('CANCELAR',
                      style: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    // Flatten map to list: {'Pollo': 2} -> ['Pollo', 'Pollo']
                    final List<String> result = [];
                    _selectedQuantities.forEach((name, count) {
                      for (int k = 0; k < count; k++) {
                        result.add(name);
                      }
                    });
                    Navigator.of(context).pop(result);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('CONFIRMAR EXTRAS'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
