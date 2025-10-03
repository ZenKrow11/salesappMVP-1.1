// lib/pages/manage_custom_items_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. IMPORT THE GENERATED LOCALIZATIONS FILE
import 'package:sales_app_mvp/generated/app_localizations.dart';

import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:sales_app_mvp/components/custom_items_library_tab.dart';
import 'package:sales_app_mvp/components/create_custom_item_tab.dart';

class ManageCustomItemsPage extends ConsumerStatefulWidget {
  final String? listId;
  final int initialTabIndex;

  const ManageCustomItemsPage({
    super.key,
    this.listId,
    this.initialTabIndex = 0,
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
      initialIndex: widget.initialTabIndex,
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
    // 2. GET THE LOCALIZATIONS OBJECT
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
        backgroundColor: theme.pageBackground,
        appBar: AppBar(
        // 3. REPLACE HARDCODED TEXT
        title: Text(l10n.manageCustomItemsTitle),
    backgroundColor: theme.primary,
    elevation: 0,
    bottom: TabBar(
    controller: _tabController,
    indicatorColor: theme.secondary,
    labelColor: theme.secondary,
    unselectedLabelColor: theme.inactive,
    // Remove 'const' because the children are now dynamic
    tabs: [
    Tab(icon: const Icon(Icons.library_books_outlined), text: l10n.myItems),
    Tab(icon: const Icon(Icons.add_circle_outline), text: l10n.createNew),
    ],
    ),
    ),
    body: TabBarView(
    controller: _tabController,
    children: [
    const CustomItemsLibraryTab(),
    CreateCustomItemTab(listId: widget.listId),
    ],
    ),
    );
  }
}