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
  void _showCreateOrEditItemSheet(BuildContext context, WidgetRef ref, {Product? productToEdit}) {
    final theme = ref.read(themeProvider);
    final l10n = AppLocalizations.of(context)!;
    final isEditing = productToEdit != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Crucial for keyboard handling
      backgroundColor: Colors.transparent, // Allows for custom rounded corners
      builder: (context) {
        return Padding(
          // This padding pushes the sheet up when the keyboard appears
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: theme.background,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView( // Allows scrolling if form content is too tall
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // A "grabber" handle for visual affordance
                    Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: theme.inactive.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    // Title inside the modal sheet
                    Text(
                      isEditing ? l10n.editCustomItem : l10n.createCustomItem,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.secondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // The form widget itself
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
        title: Text(l10n.manageCustomItemsTitle),
        backgroundColor: theme.primary,
        elevation: 0,
        // The TabBar is gone, replaced by a simple action button
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            color: theme.secondary,
            tooltip: l10n.createNew,
            onPressed: () => _showCreateOrEditItemSheet(context, ref), // Calls the modal to create
          ),
        ],
      ),
      // The body is now just the library view
      body: CustomItemsLibraryTab(
        // We pass the function down so the library items can trigger the edit modal
        onEditItem: (product) => _showCreateOrEditItemSheet(context, ref, productToEdit: product),
      ),
    );
  }
}