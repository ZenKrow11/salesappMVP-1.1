// lib/components/create_custom_item_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';
import 'package:sales_app_mvp/providers/user_profile_provider.dart';
import 'package:sales_app_mvp/services/category_service.dart';
import 'package:sales_app_mvp/services/firestore_service.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:uuid/uuid.dart';

class CreateCustomItemTab extends ConsumerStatefulWidget {
  // This can be used if you decide to implement editing within the tab as well.
  final Product? productToEdit;

  const CreateCustomItemTab({super.key, this.productToEdit});

  @override
  ConsumerState<CreateCustomItemTab> createState() =>
      _CreateCustomItemTabState();
}

class _CreateCustomItemTabState extends ConsumerState<CreateCustomItemTab> {
  // All state and logic is moved from the old page.
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _customCategoryController;
  String? _selectedCategory;

  bool get _isEditing => widget.productToEdit != null;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.productToEdit?.name ?? '');

    final initialCategory = widget.productToEdit?.category;
    if (initialCategory != null && initialCategory != 'custom') {
      _selectedCategory = initialCategory;
    }

    _customCategoryController = TextEditingController(
        text: widget.productToEdit?.category == 'custom'
            ? widget.productToEdit?.subcategory
            : '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final firestoreService = ref.read(firestoreServiceProvider);
    final userProfile = ref.read(userProfileProvider).value;
    final customItems = ref.read(customItemsProvider).value ?? [];

    if (userProfile == null) return;

    // Check custom item limit before creating
    if (!_isEditing) {
      final limit = userProfile.isPremium ? 45 : 15;
      if (customItems.length >= limit) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('You have reached your limit of $limit custom items.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
        return;
      }
    }

    final String category;
    final String subcategory;
    bool isCustomCategoryEntered = _customCategoryController.text.isNotEmpty;

    if (userProfile.isPremium && isCustomCategoryEntered) {
      category = 'custom';
      subcategory = _customCategoryController.text.trim();
    } else {
      category = _selectedCategory!;
      subcategory = '';
    }

    final productToSave = Product(
      id: _isEditing ? widget.productToEdit!.id : const Uuid().v4(),
      name: _nameController.text.trim(),
      category: category,
      subcategory: subcategory,
      store: 'custom',
      isCustom: true,
      currentPrice: 0.0,
      normalPrice: 0.0,
      discountPercentage: 0,
      url: '',
      imageUrl: '',
      nameTokens: [],
    );

    try {
      if (_isEditing) {
        await firestoreService.updateCustomItemInStorage(productToSave);
      } else {
        // When creating, save to library AND add to active list
        await firestoreService.addCustomItemToStorage(productToSave);
        final activeListId = ref.read(activeShoppingListProvider);
        await ref
            .read(shoppingListsProvider.notifier)
            .addToSpecificList(productToSave, activeListId);
      }

      if (mounted) {
        // On success, close the entire ManageCustomItemsPage
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${productToSave.name}" saved successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving item: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final isPremium = ref.watch(userProfileProvider).value?.isPremium ?? false;
    final allCategories = CategoryService.getAllCategories();
    bool isCustomCategoryEntered = _customCategoryController.text.isNotEmpty;

    // The UI is the Form, wrapped in a SingleChildScrollView
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              style: TextStyle(color: theme.inactive),
              decoration: InputDecoration(
                labelText: 'Item Name',
                labelStyle: TextStyle(color: theme.inactive.withOpacity(0.7)),
              ),
              validator: (value) =>
              (value == null || value.trim().isEmpty)
                  ? 'Please enter an item name.'
                  : null,
            ),
            const SizedBox(height: 24),
            if (isPremium) ...[
              TextFormField(
                controller: _customCategoryController,
                style: TextStyle(color: theme.inactive),
                decoration: InputDecoration(
                  labelText: 'Custom Category (Premium)',
                  labelStyle: TextStyle(color: theme.inactive.withOpacity(0.7)),
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  isCustomCategoryEntered ? 'Using custom category above' : 'Or select a main category below:',
                  style: TextStyle(color: theme.inactive.withOpacity(0.7), fontSize: 14),
                ),
              ),
            ],

            DropdownButtonFormField<String>(
              value: _selectedCategory,
              isExpanded: true,
              dropdownColor: theme.background,
              style: TextStyle(color: theme.inactive, fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Select Category',
                labelStyle: TextStyle(color: theme.inactive.withOpacity(0.7)),
                enabled: !isCustomCategoryEntered,
              ),
              items: allCategories.map((categoryInfo) {
                return DropdownMenuItem(
                  value: categoryInfo.firestoreName,
                  child: Text(categoryInfo.style.displayName),
                );
              }).toList(),
              onChanged: isCustomCategoryEntered ? null : (newValue) {
                setState(() {
                  _selectedCategory = newValue;
                });
              },
              validator: (_) {
                if (isPremium && isCustomCategoryEntered) return null;
                if (_selectedCategory == null) return 'Please select a category.';
                return null;
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.check),
                label: Text(_isEditing ? 'SAVE CHANGES' : 'CREATE & ADD ITEM'),
                onPressed: _submitForm,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}