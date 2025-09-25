// lib/pages/main_app_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sales_app_mvp/providers/app_data_provider.dart';
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';
import 'package:sales_app_mvp/models/products_provider.dart';
import 'package:sales_app_mvp/providers/grouped_products_provider.dart';

import 'package:sales_app_mvp/components/shopping_list_bottom_sheet.dart';
import 'package:sales_app_mvp/widgets/item_count_widget.dart';
import 'package:sales_app_mvp/pages/home_page.dart';
import 'package:sales_app_mvp/pages/shopping_list_page.dart';
import 'package:sales_app_mvp/pages/account_page.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:sales_app_mvp/components/list_options_bottom_sheet.dart';
import 'package:sales_app_mvp/providers/user_profile_provider.dart';
import 'package:sales_app_mvp/widgets/slide_up_page_route.dart';
import 'manage_custom_items_page.dart';

import 'package:sales_app_mvp/widgets/search_button.dart';
import 'package:sales_app_mvp/widgets/filter_button.dart';
import 'package:sales_app_mvp/widgets/sort_button.dart';

class MainAppScreen extends ConsumerStatefulWidget {
  static const routeName = '/main-app';
  const MainAppScreen({super.key});

  @override
  MainAppScreenState createState() => MainAppScreenState();
}

class MainAppScreenState extends ConsumerState<MainAppScreen> {
  int currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const ShoppingListPage(),
    const AccountPage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(appDataProvider).status == InitializationStatus.loading) {
        ref.read(appDataProvider.notifier).initialize();
      }
    });
  }

  void navigateToTab(int index) {
    if (index >= 0 && index < _pages.length) {
      setState(() {
        currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final init = ref.watch(initializationProvider);

    return init.when(
      loading: () => Scaffold(
        backgroundColor: theme.pageBackground,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        backgroundColor: theme.pageBackground,
        body: Center(child: Text('Fatal Error: $err')),
      ),
      data: (_) => GestureDetector(
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Scaffold(
          backgroundColor: theme.pageBackground,
          appBar: _buildAppBarForIndex(currentIndex, theme),
          // ===== FIX #1: REMOVE THE FAB =====
          // The Stack and Positioned FAB are no longer needed here.
          body: _pages[currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: theme.primary,
            currentIndex: currentIndex,
            selectedItemColor: theme.secondary,
            unselectedItemColor: theme.inactive,
            onTap: navigateToTab,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.attach_money, size: 36),
                label: 'All Sales',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.list, size: 36),
                label: 'Lists',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person, size: 36),
                label: 'Account',
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget? _buildAppBarForIndex(int index, AppThemeData theme) {
    switch (index) {
      case 0: // Home Page
        return _buildHomePageAppBar(theme);
      case 1: // Shopping List Page
        return _buildShoppingListPageAppBar(theme);
      default: // All other pages (like Account) have no AppBar
        return null;
    }
  }

  PreferredSizeWidget _buildHomePageAppBar(AppThemeData theme) {
    return AppBar(
      backgroundColor: theme.primary,
      elevation: 0,
      title: _buildInfoBar(),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: _buildActionsBar(),
        ),
      ),
      titleSpacing: 12,
      toolbarHeight: 40,
    );
  }

  PreferredSizeWidget _buildShoppingListPageAppBar(AppThemeData theme) {
    return AppBar(
      backgroundColor: theme.primary,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      leading: _buildListSelectorWidget(ref, theme),
      leadingWidth: 150,
      title: _buildViewToggle(ref, theme),
      centerTitle: true,
      actions: [
        // ===== FIX #2: Call the new settings action widget =====
        _buildShoppingListSettingsAction(theme),
      ],
    );
  }

  Widget _buildInfoBar() {
    return Consumer(
      builder: (context, ref, child) {
        final theme = ref.watch(themeProvider);
        final activeList = ref.watch(activeShoppingListProvider);
        final appData = ref.watch(appDataProvider);
        final bool isDataLoaded = appData.status == InitializationStatus.loaded;
        final buttonText = activeList;
        final totalCount = appData.grandTotal;
        final filteredCount = ref.watch(homePageProductsProvider).whenData((groups) {
          return groups.fold<int>(0, (sum, group) => sum + group.products.length);
        }).value ?? 0;
        final count = ProductCount(filtered: filteredCount, total: totalCount);

        return Row(
          children: [
            Expanded(
              child: Opacity(
                opacity: isDataLoaded ? 1.0 : 0.5,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.background.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: InkWell(
                    onTap: isDataLoaded
                        ? () => _showModalSheet((_) => const ShoppingListBottomSheet(), isScrollControlled: true)
                        : null,
                    borderRadius: BorderRadius.circular(12.0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.list_alt_rounded, color: theme.secondary, size: 22.0),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              buttonText,
                              style: TextStyle(color: theme.inactive, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ItemCountWidget(filtered: count.filtered, total: count.total, showBackground: false,),
          ],
        );
      },
    );
  }

  Widget _buildListSelectorWidget(WidgetRef ref, AppThemeData theme) {
    // ... (This method remains unchanged)
    final activeList = ref.watch(activeShoppingListProvider);
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(left: 12.0),
        child: Container(
          decoration: BoxDecoration(
            color: theme.background.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: InkWell(
            onTap: () => _showModalSheet(
                    (_) => const ShoppingListBottomSheet(), isScrollControlled: true),
            borderRadius: BorderRadius.circular(12.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Row(
                children: [
                  Icon(Icons.list_alt_rounded, color: theme.secondary, size: 22.0),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      activeList,
                      style: TextStyle(color: theme.inactive, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewToggle(WidgetRef ref, AppThemeData theme) {
    // ... (This method remains unchanged)
    final isGridView = ref.watch(shoppingListViewModeProvider);
    Widget buildToggleButton(bool forGridView) {
      final bool isActive = forGridView == isGridView;
      return GestureDetector(
        onTap: () {
          if (!isActive) {
            ref.read(shoppingListViewModeProvider.notifier).state = forGridView;
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isActive ? theme.secondary : theme.background.withOpacity(0.5),
            borderRadius: BorderRadius.circular(9.0),
          ),
          child: Icon(
            forGridView ? Icons.grid_view_rounded : Icons.view_list_rounded,
            color: isActive ? theme.primary : theme.secondary.withOpacity(0.8),
            size: 24,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: theme.background.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildToggleButton(true),
          const SizedBox(width: 4),
          buildToggleButton(false),
        ],
      ),
    );
  }

  // ===== FIX #3: Repurpose this widget to be the settings button =====
  Widget _buildShoppingListSettingsAction(AppThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: IconButton(
        icon: Icon(Icons.settings, color: theme.inactive),
        onPressed: () {
          _showModalSheet(
                (_) => const ListOptionsBottomSheet(),
            isScrollControlled: true,
          );
        },
      ),
    );
  }

  Widget _buildActionsBar() {
    return const Row(
      children: [
        Expanded(
          child: SearchButton(),
        ),
        SizedBox(width: 8),
        Expanded(
          child: FilterButton(),
        ),
        SizedBox(width: 8),
        Expanded(
          child: SortButton(),
        ),
      ],
    );
  }

  void _showModalSheet(Widget Function(BuildContext) builder, {bool isScrollControlled = false}) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: isScrollControlled,
      builder: builder,
    );
  }
}