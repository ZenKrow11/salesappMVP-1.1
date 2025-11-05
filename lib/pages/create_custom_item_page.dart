// lib/pages/create_custom_item_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:sales_app_mvp/generated/app_localizations.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/models/user_profile.dart'; // <-- Import the UserProfile model
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';
import 'package:sales_app_mvp/providers/user_profile_provider.dart';
import 'package:sales_app_mvp/services/category_service.dart';
import 'package:sales_app_mvp/services/firestore_service.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:sales_app_mvp/services/notification_manager.dart';


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
  String? _selectedCategory;

  bool get _isEditing => widget.productToEdit != null;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.productToEdit?.name ?? '');

    final initialCategory = widget.productToEdit?.category;
    if (initialCategory != null && initialCategory.isNotEmpty) {
      _selectedCategory = initialCategory;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // --- FIX 1: CHANGE THE METHOD SIGNATURE TO ACCEPT THE LOADED PROFILE ---
  Future<void> _submitForm(UserProfile userProfile) async {
    final l10n = AppLocalizations.of(context)!;
    final shoppingListNotifier = ref.read(shoppingListsProvider.notifier);

    if (!_formKey.currentState!.validate() || _isSaving) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSaving = true;
    });

    try {
      final firestoreService = ref.read(firestoreServiceProvider);

      // --- FIX 2: USE THE PASSED-IN userProfile DIRECTLY ---
      // No need to check for null here, because the button's logic guarantees it's available.
      if (!_isEditing) {
        final customItems = ref.read(customItemsProvider).value ?? [];
        final limit = userProfile.isPremium ? 45 : 15;
        if (customItems.length >= limit) {
          throw Exception(l10n.customItemLimitReached(limit));
        }
      }

      final productToSave = Product(
        id: _isEditing ? widget.productToEdit!.id : const Uuid().v4(),
        name: _nameController.text.trim(),
        category: _selectedCategory!,
        subcategory: '',
        store: 'custom',
        isCustom: true,
        currentPrice: 0.0,
        normalPrice: 0.0,
        discountPercentage: 0,
        url: '',
        imageUrl: '',
        nameTokens: [],
      );

      if (_isEditing) {
        await shoppingListNotifier.updateCustomItem(productToSave);
      } else {
        await shoppingListNotifier.createAndAddCustomItem(productToSave, context);
      }

      if (mounted) {
        Navigator.of(context).pop();
        NotificationManager.show(context, l10n.itemSavedSuccessfully(productToSave.name));
        // ========================================================
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
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final l10n = AppLocalizations.of(context)!;

    // --- FIX 3: WATCH THE PROVIDER AND GET THE ACTUAL DATA OBJECT ---
    final userProfileAsync = ref.watch(userProfileProvider);
    // This will be the UserProfile object when loaded, or null otherwise.
    final UserProfile? userProfile = userProfileAsync.value;

    final allCategoriesForDropdown = CategoryService.getAllCategoriesForDropdown();

    InputDecoration _buildInputDecoration(String label) {
      return InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.inactive.withOpacity(0.7)),
        filled: true,
        fillColor: theme.background.withOpacity(0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.secondary, width: 2),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.pageBackground,
      appBar: AppBar(
        backgroundColor: theme.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: theme.secondary, size: 32),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isEditing ? l10n.editCustomItem : l10n.createCustomItem,
          style: TextStyle(color: theme.secondary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ... TextFormField and DropdownButtonFormField are unchanged ...
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: theme.inactive),
                decoration: _buildInputDecoration(l10n.itemName),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? l10n.pleaseEnterItemName
                    : null,
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                isExpanded: true,
                dropdownColor: theme.background,
                style: TextStyle(color: theme.inactive, fontSize: 16),
                decoration: _buildInputDecoration(l10n.selectCategory),
                items: allCategoriesForDropdown.map((categoryInfo) {
                  return DropdownMenuItem(
                    value: categoryInfo.firestoreName,
                    child: Text(
                      CategoryService.getLocalizedCategoryName(
                        categoryInfo.firestoreName,
                        l10n,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
                validator: (_) {
                  if (_selectedCategory == null) {
                    return l10n.pleaseSelectCategory;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                icon: _isSaving
                    ? Container(
                  width: 24,
                  height: 24,
                  padding: const EdgeInsets.all(2.0),
                  child: CircularProgressIndicator(
                    color: theme.primary,
                    strokeWidth: 3,
                  ),
                )
                    : Icon(Icons.check, color: theme.primary),
                label: Text(
                  _isEditing ? l10n.saveChanges : l10n.createItem,
                  style: TextStyle(color: theme.primary),
                ),
                // --- FIX 4: THE ULTIMATE SAFETY CHECK ---
                // The button is disabled if we are saving OR if the userProfile object is null (i.e., still loading).
                // When pressed, it passes the guaranteed-to-be-loaded userProfile to the submit function.
                onPressed: (_isSaving || userProfile == null)
                    ? null
                    : () => _submitForm(userProfile),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}