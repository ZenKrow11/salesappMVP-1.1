// lib/pages/create_custom_item_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. IMPORT THE GENERATED LOCALIZATIONS FILE
import 'package:sales_app_mvp/generated/app_localizations.dart';

import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';
import 'package:sales_app_mvp/providers/user_profile_provider.dart';
import 'package:sales_app_mvp/services/category_service.dart';
import 'package:sales_app_mvp/services/firestore_service.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:uuid/uuid.dart';

class CreateCustomItemPage extends ConsumerStatefulWidget {
  final Product? productToEdit;

  const CreateCustomItemPage({super.key, this.productToEdit});

  @override
  ConsumerState<CreateCustomItemPage> createState() =>
      _CreateCustomItemPageState();
}

class _CreateCustomItemPageState extends ConsumerState<CreateCustomItemPage> {
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
    // 2. GET LOCALIZATIONS FOR SNACKBARS
    final l10n = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final firestoreService = ref.read(firestoreServiceProvider);
    final userProfile = ref.read(userProfileProvider).value;
    final customItems = ref.read(customItemsProvider).value ?? [];

    if (userProfile == null) return;

    if (!_isEditing) {
      final limit = userProfile.isPremium ? 45 : 15;
      if (customItems.length >= limit) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          // 3. USE LOCALIZED, PARAMETERIZED STRINGS
          content: Text(l10n.customItemLimitReached(limit)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
        return;
      }
    }

    // ... (rest of the logic is unchanged)
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
        final activeListId = ref.read(activeShoppingListProvider);
        await ref
            .read(shoppingListsProvider.notifier)
            .addToSpecificList(productToSave, activeListId, context);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.itemSavedSuccessfully(productToSave.name)),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorSavingItem(e.toString())),
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

    // GET LOCALIZATIONS FOR THE BUILD METHOD
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.pageBackground,
      appBar: AppBar(
        // 4. REPLACE ALL HARDCODED STRINGS IN THE UI
        title: Text(_isEditing ? l10n.editCustomItem : l10n.createCustomItem),
        backgroundColor: theme.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: theme.inactive),
                decoration: InputDecoration(
                  labelText: l10n.itemName,
                  labelStyle: TextStyle(color: theme.inactive.withOpacity(0.7)),
                ),
                validator: (value) =>
                (value == null || value.trim().isEmpty)
                    ? l10n.pleaseEnterItemName
                    : null,
              ),
              const SizedBox(height: 24),
              if (isPremium) ...[
                TextFormField(
                  controller: _customCategoryController,
                  style: TextStyle(color: theme.inactive),
                  decoration: InputDecoration(
                    labelText: l10n.customCategoryPremium,
                    labelStyle: TextStyle(color: theme.inactive.withOpacity(0.7)),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    isCustomCategoryEntered ? l10n.usingCustomCategoryAbove : l10n.orSelectMainCategory,
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
                  labelText: l10n.selectCategory,
                  labelStyle: TextStyle(color: theme.inactive.withOpacity(0.7)),
                  enabled: !isCustomCategoryEntered,
                ),
                items: allCategories.map((categoryInfo) {
                  return DropdownMenuItem(
                    value: categoryInfo.firestoreName,
                    child: Text(categoryInfo.style.displayName), // This part remains, as it comes from your CategoryService
                  );
                }).toList(),
                onChanged: isCustomCategoryEntered ? null : (newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
                validator: (_) {
                  if (isPremium && isCustomCategoryEntered) return null;
                  if (_selectedCategory == null) return l10n.pleaseSelectCategory;
                  return null;
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.check),
                  label: Text(_isEditing ? l10n.saveChanges : l10n.createItem),
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
      ),
    );
  }
}