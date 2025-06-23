import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/filter_providers.dart';
import '../providers/product_provider.dart';

class FilterSheet extends ConsumerWidget {
  const FilterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(paginatedProductsProvider);

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: productsAsync.when(
            data: (products) {
              final storeList = ref.watch(storeListProvider);
              final categoryList = ref.watch(categoryListProvider);
              final subcategoryList = ref.watch(subcategoryListProvider);
              final selectedStore = ref.watch(storeFilterProvider);
              final selectedCategory = ref.watch(categoryFilterProvider);
              final selectedSubcategory = ref.watch(subcategoryFilterProvider);

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          FilterDropdown<String>(
                            title: 'Store',
                            items: storeList,
                            selectedValue: selectedStore,
                            onChanged: (value) =>
                            ref.read(storeFilterProvider.notifier).state = value,
                            onClear: selectedStore != null
                                ? () => ref.read(storeFilterProvider.notifier).state = null
                                : null,
                          ),
                          FilterDropdown<String>(
                            title: 'Category',
                            items: categoryList,
                            selectedValue: selectedCategory,
                            onChanged: (value) =>
                            ref.read(categoryFilterProvider.notifier).state = value,
                            onClear: selectedCategory != null
                                ? () => ref.read(categoryFilterProvider.notifier).state = null
                                : null,
                          ),
                          FilterDropdown<String>(
                            title: 'Subcategory',
                            items: subcategoryList,
                            selectedValue: selectedSubcategory,
                            onChanged: (value) =>
                            ref.read(subcategoryFilterProvider.notifier).state = value,
                            onClear: selectedSubcategory != null
                                ? () => ref.read(subcategoryFilterProvider.notifier).state = null
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(storeFilterProvider.notifier).state = null;
                      ref.read(categoryFilterProvider.notifier).state = null;
                      ref.read(subcategoryFilterProvider.notifier).state = null;
                    },
                    child: const Text('Clear All Filters'),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error loading filters: $error'),
                  ElevatedButton(
                    onPressed: () => ref.refresh(paginatedProductsProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FilterDropdown<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final T? selectedValue;
  final void Function(T?) onChanged;
  final VoidCallback? onClear;

  const FilterDropdown({
    super.key,
    required this.title,
    required this.items,
    required this.selectedValue,
    required this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Filter by $title', style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              if (selectedValue != null && onClear != null)
                IconButton(
                  icon: Icon(Icons.close, size: 20,),
                  tooltip: 'Clear $title filter',
                  onPressed: onClear,
                ),
            ],
          ),
          const SizedBox(height: 4),
          DropdownButton<T>(
            value: selectedValue,
            hint: Text('Select $title'),
            isExpanded: true,
            menuMaxHeight: 540,
            items: items
                .map((item) => DropdownMenuItem<T>(
              value: item,
              child: Text(item.toString()),
            ))
                .toList(),
            onChanged: items.isNotEmpty ? onChanged : null,
          ),
        ],
      ),
    );
  }
}
