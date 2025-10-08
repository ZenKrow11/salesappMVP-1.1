// lib/components/create_custom_item_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/generated/app_localizations.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';
import 'package:sales_app_mvp/providers/user_profile_provider.dart'; // The correct provider file is imported
import 'package:sales_app_mvp/services/category_service.dart';
import 'package:sales_app_mvp/services/firestore_service.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:sales_app_mvp/models/category_definitions.dart';
import 'package:uuid/uuid.dart';

class CreateCustomItemTab extends ConsumerStatefulWidget {
  final Product? productToEdit;
  final String? listId;

  const CreateCustomItemTab({
    super.key,
    this.productToEdit,
    this.listId,
  });

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
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    final firestoreService = ref.read(firestoreServiceProvider);
    // --- THIS IS THE FIX ---
    // Changed 'user_profile_provider' to the correct 'userProfileProvider' (camelCase)
    final userProfile = ref.read(userProfileProvider).value;
    final customItems = ref.read(customItemsProvider).value ?? [];

    if (userProfile == null) return;
    final limit = userProfile.isPremium ? 45 : 15;
    if (!_isEditing && customItems.length >= limit) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.customItemLimitReached(limit)),
        backgroundColor: Theme.of(context).colorScheme.error,
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
        // This logic correctly handles adding to a specific list if coming from that flow
        final targetListId = widget.listId ?? ref.read(activeShoppingListProvider);
        if (targetListId != null) {
          await ref
              .read(shoppingListsProvider.notifier)
              .addToSpecificList(productToSave, targetListId);
        }
      }

      if (mounted) {
        // SIMPLIFIED: On success, just pop the modal sheet.
        Navigator.of(context).pop();

        // Show the success message on the underlying page.
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
    final l10n = AppLocalizations.of(context)!;
    final allCategories = categoryDisplayOrder
        .map((firestoreName) => (
    firestoreName: firestoreName,
    style: CategoryService.getLocalizedStyleForGroupingName(
        firestoreName, l10n)
    ))
        .toList();
    bool isCustomCategoryEntered = _customCategoryController.text.isNotEmpty;

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

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Important for BottomSheet
        children: [
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            isExpanded: true,
            dropdownColor: theme.background,
            style: TextStyle(color: theme.inactive, fontSize: 16),
            decoration: styledInputDecoration(l10n.selectCategory)
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
              if (_selectedCategory == null) return l10n.pleaseSelectCategory;
              return null;
            },
          ),
          if (isPremium) ...[
            const SizedBox(height: 24),
            TextFormField(
              controller: _customCategoryController,
              style: TextStyle(color: theme.inactive),
              decoration: styledInputDecoration(l10n.customCategoryPremium),
              onChanged: (value) {
                setState(() {});
              },
            ),
            Padding(
              padding:
              const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
              child: Text(
                isCustomCategoryEntered
                    ? l10n.usingCustomCategoryAbove
                    : l10n.orSelectMainCategory,
                style: TextStyle(
                    color: theme.inactive.withOpacity(0.7), fontSize: 14),
              ),
            ),
          ],
          const SizedBox(height: 24),
          TextFormField(
            controller: _nameController,
            style: TextStyle(color: theme.inactive),
            decoration: styledInputDecoration(l10n.itemName),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? l10n.pleaseEnterItemName
                : null,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.check),
              label:
              Text(_isEditing ? l10n.saveChanges : l10n.createAndAddItem),
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
    );
  }
}