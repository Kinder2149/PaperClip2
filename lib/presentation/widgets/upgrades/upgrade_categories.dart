import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/upgrades_viewmodel.dart';

class UpgradeCategories extends StatelessWidget {
  const UpgradeCategories({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<UpgradesViewModel>(
      builder: (context, upgradesViewModel, child) {
        final categories = upgradesViewModel.categories;
        final selectedCategory = upgradesViewModel.selectedCategory;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Catégories',
                  style: Theme.of(context).textTheme.headline6,
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.map((category) {
                      final isSelected = category.id == selectedCategory?.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildCategoryChip(
                          context,
                          category,
                          isSelected,
                          () => upgradesViewModel.selectCategory(category.id),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryChip(
    BuildContext context,
    UpgradeCategory category,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            category.icon,
            size: 16,
            color: isSelected ? Colors.white : Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 4),
          Text(
            category.name,
            style: TextStyle(
              color: isSelected ? Colors.white : null,
              fontWeight: isSelected ? FontWeight.bold : null,
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.grey[200],
      selectedColor: Theme.of(context).primaryColor,
      checkmarkColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
    );
  }
} 