// lib/pages/main_app_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sales_app_mvp/providers/app_data_provider.dart';
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';
import 'package:sales_app_mvp/models/products_provider.dart';
import 'package:sales_app_mvp/providers/grouped_products_provider.dart';

import 'package:sales_app_mvp/components/filter_bottom_sheet.dart';
import 'package:sales_app_mvp/components/search_bottom_sheet.dart';
import 'package:sales_app_mvp/components/shopping_list_bottom_sheet.dart';
import 'package:sales_app_mvp/widgets/item_count_widget.dart';
import 'package:sales_app_mvp/widgets/sort_button_widget.dart';
import 'package:sales_app_mvp/pages/home_page.dart';
import 'package:sales_app_mvp/pages/shopping_list_page.dart';
import 'package:sales_app_mvp/pages/account_page.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:sales_app_mvp/components/list_options_bottom_sheet.dart';
import 'package:sales_app_mvp/providers/user_profile_provider.dart';

import '../widgets/slide_up_page_route.dart';
import 'manage_custom_items_page.dart';

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

          // ===================== REFACTOR START =====================
          // The body is wrapped in a Stack to layer the FAB on top.
          body: Stack(
            children: [
              // This is the main content of your page (HomePage, ShoppingListPage, etc.)
              _pages[currentIndex],

              // The FAB is now a settings button for the "Lists" tab (index 1).
              // It has been moved up to avoid covering the summary bar.
              if (currentIndex == 1)
                Positioned(
                  bottom: 80.0, // Raised to be above the summary bar
                  right: 16.0,
                  child: FloatingActionButton(
                    backgroundColor: theme.secondary,
                    foregroundColor: theme.primary,
                    onPressed: () {
                      // Opens the List Options bottom sheet, replacing the old FAB functionality.
                      _showModalSheet(
                            (_) => const ListOptionsBottomSheet(),
                        isScrollControlled: true,
                      );
                    },
                    child: const Icon(Icons.settings), // Icon changed to settings
                  ),
                ),
            ],
          ),
          // ====================== REFACTOR END ======================

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
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
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
      automaticallyImplyLeading: false, // Prevents back button
      titleSpacing: 0, // Fine-tune spacing

      // LEFT side of the AppBar
      leading: _buildListSelectorWidget(ref, theme),
      leadingWidth: 140, // Give it enough space for longer list names

      // CENTER of the AppBar
      title: _buildViewToggle(ref, theme),
      centerTitle: true,

      // RIGHT side of the AppBar
      actions: [
        _buildListActionsWidget(ref, theme),
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
            Opacity(
              opacity: isDataLoaded ? 1.0 : 0.5,
              child: InkWell(
                onTap: isDataLoaded
                    ? () => _showModalSheet((_) => const ShoppingListBottomSheet(), isScrollControlled: true)
                    : null,
                child: Row(
                  children: [
                    Icon(Icons.list_alt_rounded, color: theme.secondary, size: 24.0),
                    const SizedBox(width: 8),
                    Text(buttonText, style: TextStyle(color: theme.inactive, fontSize: 16), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),
            const Spacer(),
            ItemCountWidget(filtered: count.filtered, total: count.total),
          ],
        );
      },
    );
  }

  Widget _buildListSelectorWidget(WidgetRef ref, AppThemeData theme) {
    final activeList = ref.watch(activeShoppingListProvider);
    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: InkWell(
        onTap: () => _showModalSheet(
                (_) => const ShoppingListBottomSheet(), isScrollControlled: true),
        child: Row(
          children: [
            Icon(Icons.list_alt_rounded, color: theme.secondary, size: 24.0),
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
    );
  }

  Widget _buildViewToggle(WidgetRef ref, AppThemeData theme) {
    final isGridView = ref.watch(shoppingListViewModeProvider);

    // The background container is now removed.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Grid Button
        IconButton(
          icon: const Icon(Icons.grid_view),
          color: isGridView ? theme.secondary : theme.inactive.withOpacity(0.7),
          iconSize: 24, // Slightly larger for better tap area
          splashRadius: 20,
          onPressed: () {
            ref.read(shoppingListViewModeProvider.notifier).state = true;
          },
        ),
        const SizedBox(width: 8), // Spacing between the icons
        // List Button
        IconButton(
          icon: const Icon(Icons.view_list),
          color: !isGridView ? theme.secondary : theme.inactive.withOpacity(0.7),
          iconSize: 24,
          splashRadius: 20,
          onPressed: () {
            ref.read(shoppingListViewModeProvider.notifier).state = false;
          },
        ),
      ],
    );
  }

  Widget _buildListActionsWidget(WidgetRef ref, AppThemeData theme) {
    final products = ref.watch(shoppingListWithDetailsProvider).value ?? [];
    final itemCount = products.length;
    final isPremium = ref.watch(userProfileProvider).value?.isPremium ?? false;
    // You can change '∞' back to '60' if you prefer a hard limit for premium
    final itemLimit = isPremium ? '60' : '30';

    // The settings icon has been removed and its functionality moved to the FAB.
    return Padding(
      padding: const EdgeInsets.only(right: 16.0), // Right padding for spacing
      child: Text(
        '$itemCount/$itemLimit',
        style: TextStyle(
          color: theme.inactive,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionsBar() {
    final theme = ref.watch(themeProvider);
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            theme: theme,
            icon: Icons.search,
            label: 'Search',
            onPressed: () => _showModalSheet((_) => const SearchBottomSheet(), isScrollControlled: true),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _actionButton(
            theme: theme,
            icon: Icons.filter_alt,
            label: 'Filter',
            onPressed: () => _showModalSheet((_) => const FilterBottomSheet(), isScrollControlled: true),
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: SortButton(),
        ),
      ],
    );
  }

  Widget _actionButton({
    required AppThemeData theme,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: theme.secondary, size: 22.0),
      label: Text(label, style: TextStyle(color: theme.inactive), overflow: TextOverflow.ellipsis),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.background.withOpacity(0.5),
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
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