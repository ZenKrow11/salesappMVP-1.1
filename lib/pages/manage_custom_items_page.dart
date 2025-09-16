// lib/pages/manage_custom_items_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:sales_app_mvp/components/custom_items_library_tab.dart';
import 'package:sales_app_mvp/components/create_custom_item_tab.dart';

// Changed to a StatefulWidget to manage the TabController
class ManageCustomItemsPage extends ConsumerStatefulWidget {
  final String? listId;
  final int initialTabIndex;

  const ManageCustomItemsPage({
    super.key,
    this.listId,
    this.initialTabIndex = 0, // Default to the 'My Items' tab
  });

  @override
  ConsumerState<ManageCustomItemsPage> createState() =>
      _ManageCustomItemsPageState();
}

class _ManageCustomItemsPageState extends ConsumerState<ManageCustomItemsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex, // Use the passed-in index
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: theme.pageBackground,
      appBar: AppBar(
        title: const Text('Manage Custom Items'),
        backgroundColor: theme.primary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController, // Assign the controller
          indicatorColor: theme.secondary,
          labelColor: theme.secondary,
          unselectedLabelColor: theme.inactive,
          tabs: const [
            Tab(icon: Icon(Icons.library_books_outlined), text: 'My Items'),
            Tab(icon: Icon(Icons.add_circle_outline), text: 'Create New'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController, // Assign the controller
        children: [
          const CustomItemsLibraryTab(),
          // Pass the listId down to the create tab
          CreateCustomItemTab(listId: widget.listId),
        ],
      ),
    );
  }
}