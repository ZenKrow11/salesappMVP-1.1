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
  final Product? productToEdit;
  // This listId is passed from the FAB flow
  final String? listId;

  const CreateCustomItemTab({super.key, this.productToEdit, this.listId});

  @override
  ConsumerState<CreateCustomItemTab> createState() =>
      _CreateCustomItemTabState();
}

class _CreateCustomItemTabState extends ConsumerState<CreateCustomItemTab> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _customCategoryController;
  String? _selectedCategory;

  bool get _isEditing => widget.productToEdit != null;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.productToEdit?.name ?? '');
    _customCategoryController = TextEditingController(
        text: (widget.productToEdit?.category == 'custom'
            ? widget.productToEdit?.subcategory
            : '') ?? '');
    final initialCategory = widget.productToEdit?.category;
    if (initialCategory != null && initialCategory != 'custom') {
      _selectedCategory = initialCategory;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final firestoreService = ref.read(firestoreServiceProvider);
    final userProfile = ref
        .read(userProfileProvider)
        .value;
    final customItems = ref
        .read(customItemsProvider)
        .value ?? [];

    if (userProfile == null) return;
    if (!_isEditing &&
        customItems.length >= (userProfile.isPremium ? 45 : 15)) {
      // Handle item limit and show snackbar
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('You have reached your limit of ${(userProfile.isPremium
            ? 45
            : 15)} custom items.'),
        backgroundColor: Theme
            .of(context)
            .colorScheme
            .error,
      ));
      return;
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
        await firestoreService.addCustomItemToStorage(productToSave);

        // ===================== FIX IS HERE =====================
        final targetListId = widget.listId ??
            ref.read(activeShoppingListProvider);

        // We add a simple null check. This satisfies the compiler and is good practice.
        if (targetListId != null) {
          await ref
              .read(shoppingListsProvider.notifier)
              .addToSpecificList(productToSave, targetListId);
        } else {
          // This is a fallback in case something goes wrong, though it's unlikely.
          throw Exception("No target list ID found to add the item to.");
        }
        // ==========================================================
      }

      if (mounted) {
        // If coming from the FAB, always pop the page.
        if (widget.listId != null) {
          Navigator.of(context).pop();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${productToSave.name}" saved successfully.'),
            backgroundColor: Colors.green,
          ),
        );

        // If NOT coming from the FAB, clear the form for another entry.
        if (widget.listId == null && !_isEditing) {
          _formKey.currentState?.reset();
          _nameController.clear();
          _customCategoryController.clear();
          setState(() => _selectedCategory = null);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving item: ${e.toString()}'),
            backgroundColor: Theme
                .of(context)
                .colorScheme
                .error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final isPremium = ref
        .watch(userProfileProvider)
        .value
        ?.isPremium ?? false;
    final allCategories = CategoryService.getAllCategories();
    bool isCustomCategoryEntered = _customCategoryController.text.isNotEmpty;

    // A helper for consistent input decoration
    InputDecoration styledInputDecoration(String label) {
      return InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.inactive.withOpacity(0.7)),
        filled: true,
        fillColor: theme.background.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.secondary, width: 2),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              style: TextStyle(color: theme.inactive),
              decoration: styledInputDecoration('Item Name'),
              validator: (value) =>
              (value == null || value
                  .trim()
                  .isEmpty)
                  ? 'Please enter an item name.'
                  : null,
            ),
            const SizedBox(height: 24),
            if (isPremium) ...[
              TextFormField(
                controller: _customCategoryController,
                style: TextStyle(color: theme.inactive),
                decoration: styledInputDecoration('Custom Category (Premium)'),
                onChanged: (value) {
                  setState(() {});
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 12.0, horizontal: 8.0),
                child: Text(
                  isCustomCategoryEntered
                      ? 'Using custom category above'
                      : 'Or select a main category below:',
                  style: TextStyle(
                      color: theme.inactive.withOpacity(0.7), fontSize: 14),
                ),
              ),
            ],
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              isExpanded: true,
              dropdownColor: theme.background,
              style: TextStyle(color: theme.inactive, fontSize: 16),
              decoration: styledInputDecoration('Select Category')
                  .copyWith(enabled: !isCustomCategoryEntered),
              items: allCategories.map((categoryInfo) {
                return DropdownMenuItem(
                  value: categoryInfo.firestoreName,
                  child: Text(categoryInfo.style.displayName),
                );
              }).toList(),
              onChanged: isCustomCategoryEntered
                  ? null
                  : (newValue) {
                setState(() {
                  _selectedCategory = newValue;
                });
              },
              validator: (_) {
                if (isPremium && isCustomCategoryEntered) return null;
                if (_selectedCategory == null)
                  return 'Please select a category.';
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
                  backgroundColor: theme.secondary,
                  foregroundColor: theme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}