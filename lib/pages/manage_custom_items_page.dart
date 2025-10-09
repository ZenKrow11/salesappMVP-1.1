// lib/pages/manage_custom_items_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/generated/app_localizations.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:sales_app_mvp/components/custom_items_library_tab.dart';
import 'package:sales_app_mvp/components/create_custom_item_tab.dart';

class ManageCustomItemsPage extends ConsumerWidget {
  const ManageCustomItemsPage({super.key});

  // Method to show the keyboard-aware bottom modal sheet for creating or editing an item.
  // This method remains unchanged.
  void _showCreateOrEditItemSheet(BuildContext context, WidgetRef ref, {Product? productToEdit}) {
    final theme = ref.read(themeProvider);
    final l10n = AppLocalizations.of(context)!;
    final isEditing = productToEdit != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: theme.background,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: theme.inactive.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Text(
                      isEditing ? l10n.editCustomItem : l10n.createCustomItem,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.secondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CreateCustomItemTab(productToEdit: productToEdit),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.pageBackground,
      appBar: AppBar(
        backgroundColor: theme.primary,
        elevation: 0,
        // CHANGE: Remove the default back arrow.
        automaticallyImplyLeading: false,

        // The title is automatically centered when `leading` is null.
        title: Text(
          l10n.manageCustomItemsTitle,
          style: TextStyle(color: theme.secondary),
        ),

        // CHANGE: The actions list now contains the add and close buttons in order.
        actions: [
          // 1. The Add Button
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.createNew,
            // Use styleFrom for complex button styling
            style: IconButton.styleFrom(
              backgroundColor: theme.secondary,
              foregroundColor: theme.primary, // This sets the icon color
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => _showCreateOrEditItemSheet(context, ref),
          ),

          // 2. The Close Button
          IconButton(
            icon: Icon(Icons.close, color: theme.accent),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: CustomItemsLibraryTab(
        onEditItem: (product) => _showCreateOrEditItemSheet(context, ref, productToEdit: product),
      ),
    );
  }
}