// lib/components/add_custom_item_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/components/categories_filter_tab.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';
import 'package:sales_app_mvp/providers/user_profile_provider.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:uuid/uuid.dart';

class AddCustomItemDialog extends ConsumerStatefulWidget {
  const AddCustomItemDialog({super.key});

  @override
  ConsumerState<AddCustomItemDialog> createState() =>
      _AddCustomItemDialogState();
}

class _AddCustomItemDialogState extends ConsumerState<AddCustomItemDialog> {
  final _nameController = TextEditingController();
  final _customCategoryController = TextEditingController();
  String? _selectedCategory;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final isPremium = ref.read(userProfileProvider).value?.isPremium ?? false;
      final notifier = ref.read(shoppingListsProvider.notifier);
      const uuid = Uuid();

      final String category;
      final String subcategory;

      if (isPremium && _customCategoryController.text.isNotEmpty) {
        category = 'custom';
        subcategory = _customCategoryController.text.trim();
      } else {
        category = _selectedCategory!;
        subcategory = '';
      }

      // --- FINAL FIX APPLIED HERE ---
      // This constructor now matches all requirements from the error messages.
      final newCustomProduct = Product(
        id: uuid.v4(),
        name: _nameController.text.trim(),
        category: category,
        subcategory: subcategory,
        store: 'custom',
        imageUrl: '',         // CORRECT: Added required 'imageUrl'
        url: '',
        currentPrice: 0.0,
        normalPrice: 0.0,
        discountPercentage: 0,
        nameTokens: [],
      );
      // --- END OF FINAL FIX ---

      notifier.addCustomItemToList(newCustomProduct);

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added "${newCustomProduct.name}" to your list.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final isPremium = ref.watch(userProfileProvider).value?.isPremium ?? false;

    return AlertDialog(
      backgroundColor: theme.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Add Custom Item', style: TextStyle(color: theme.secondary)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: theme.inactive),
                decoration: InputDecoration(
                  labelText: 'Item Name / Description',
                  labelStyle: TextStyle(color: theme.inactive.withOpacity(0.7)),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: theme.inactive.withOpacity(0.5)),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: theme.secondary),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an item name.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              if (isPremium) ...[
                TextFormField(
                  controller: _customCategoryController,
                  style: TextStyle(color: theme.inactive),
                  decoration: InputDecoration(
                    labelText: 'Custom Category (Optional)',
                    labelStyle: TextStyle(color: theme.inactive.withOpacity(0.7)),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: theme.inactive.withOpacity(0.5)),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: theme.secondary),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    'Or select a main category below:',
                    style: TextStyle(color: theme.inactive, fontSize: 14),
                  ),
                ),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    'Select a category:',
                    style: TextStyle(color: theme.inactive, fontSize: 16),
                  ),
                ),
              ],
              Container(
                height: 250,
                width: 300,
                child: CategoriesFilterTab(
                  selectedCategories:
                  _selectedCategory != null ? [_selectedCategory!] : [],
                  onToggleCategory: (categoryFirestoreName) {
                    setState(() {
                      if (_selectedCategory == categoryFirestoreName) {
                        _selectedCategory = null;
                      } else {
                        // --- TYPO FIX APPLIED HERE ---
                        _selectedCategory = categoryFirestoreName;
                        // --- END OF TYPO FIX ---
                      }
                    });
                  },
                ),
              ),
              FormField(
                builder: (FormFieldState<String> state) {
                  if (state.hasError) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        state.errorText ?? '',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                validator: (_) {
                  if (isPremium && _customCategoryController.text.isNotEmpty) {
                    return null;
                  }
                  if (_selectedCategory == null) {
                    return 'Please select a category.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('CANCEL', style: TextStyle(color: theme.inactive)),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.secondary,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text('ADD ITEM', style: TextStyle(color: theme.primary)),
        ),
      ],
    );
  }
}