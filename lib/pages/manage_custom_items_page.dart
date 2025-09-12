// lib/pages/manage_custom_items_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
// We will create these two new files in the next steps
import 'package:sales_app_mvp/components/custom_items_library_tab.dart';
import 'package:sales_app_mvp/components/create_custom_item_tab.dart';

class ManageCustomItemsPage extends ConsumerWidget {
  const ManageCustomItemsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.pageBackground,
        appBar: AppBar(
          title: const Text('Manage Custom Items'),
          backgroundColor: theme.primary,
          elevation: 0,
          bottom: TabBar(
            indicatorColor: theme.secondary,
            labelColor: theme.secondary,
            unselectedLabelColor: theme.inactive,
            tabs: const [
              Tab(icon: Icon(Icons.library_books_outlined), text: 'My Items'),
              Tab(icon: Icon(Icons.add_circle_outline), text: 'Create New'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            // This will be the grid view of existing items
            CustomItemsLibraryTab(),
            // This will be the form for creating a new item
            CreateCustomItemTab(),
          ],
        ),
      ),
    );
  }
}