// lib/pages/main_app_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/generated/app_localizations.dart';
import 'package:sales_app_mvp/providers/settings_provider.dart';
import 'package:sales_app_mvp/pages/home_page.dart';
import 'package:sales_app_mvp/pages/shopping_list_page.dart';
import 'package:sales_app_mvp/pages/account_page.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';
import 'package:sales_app_mvp/widgets/item_count_widget.dart';
import 'package:sales_app_mvp/providers/app_data_provider.dart';
import 'package:sales_app_mvp/providers/grouped_products_provider.dart';
import 'package:sales_app_mvp/widgets/search_button.dart';
import 'package:sales_app_mvp/widgets/filter_button.dart';
import 'package:sales_app_mvp/widgets/sort_button.dart';
import 'package:sales_app_mvp/components/shopping_list_bottom_sheet.dart';
import 'package:sales_app_mvp/providers/user_profile_provider.dart';
import 'package:sales_app_mvp/services/ad_manager.dart';
import 'package:sales_app_mvp/pages/manage_custom_items_page.dart';
import 'package:sales_app_mvp/widgets/slide_up_page_route.dart';
import 'package:sales_app_mvp/components/manage_list_items_bottom_sheet.dart';



// --- FIX: IMPORT THE NEW WIDGET ---
import 'package:sales_app_mvp/components/organize_list_bottom_sheet.dart';
import 'package:sales_app_mvp/providers/filter_state_provider.dart';


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
      final isPremium = ref.read(isPremiumProvider);
      if (!isPremium) {
        ref.read(adManagerProvider.notifier).initialize();
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
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: theme.pageBackground,
        appBar: _buildAppBarForIndex(context, currentIndex, theme, ref),
        body: IndexedStack(
          index: currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: theme.primary,
          currentIndex: currentIndex,
          selectedItemColor: theme.secondary,
          unselectedItemColor: theme.inactive,
          onTap: navigateToTab,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.percent, size: 36),
              label: l10n.navAllSales,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.list, size: 36),
              label: l10n.navLists,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person, size: 36),
              label: l10n.navAccount,
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget? _buildAppBarForIndex(BuildContext context, int index, AppThemeData theme, WidgetRef ref) {
    switch (index) {
      case 0:
        return _buildHomePageAppBar(theme);
      case 1:
        return _buildShoppingListPageAppBar(context, theme, ref);
      default:
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

  PreferredSizeWidget _buildShoppingListPageAppBar(BuildContext context, AppThemeData theme, WidgetRef ref) {
    // ======================= STEP 1: GET THE STATE OBJECT =======================
    // This line is correct, but we'll rename the variable for clarity.
    final settingsState = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;

    return AppBar(
      backgroundColor: theme.primary,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      leading: _buildListSelectorWidget(ref, theme),
      leadingWidth: 150,
      title: null,
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(
            settingsState.isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
            color: theme.inactive,
          ),
          tooltip: settingsState.isGridView ? l10n.tooltipShowAsList : l10n.tooltipShowAsGrid,
          onPressed: () {
            ref.read(settingsProvider.notifier).toggleGridView();
          },
        ),
        IconButton(
          icon: Icon(Icons.delete, color: theme.inactive),
          tooltip: l10n.tooltipManageListItems, // Use a proper l10n key
          onPressed: () {
            showModalBottomSheet(
              context: context,
              useRootNavigator: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const ManageListItemsBottomSheet(),
            );
          },
        ),
        _buildOrganizeListAction(theme, l10n),
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
            ItemCountWidget(
              filtered: filteredCount,
              total: totalCount,
              showBackground: false,
            ),
          ],
        );
      },
    );
  }

  Widget _buildListSelectorWidget(WidgetRef ref, AppThemeData theme) {
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

  Widget _buildOrganizeListAction(AppThemeData theme, AppLocalizations l10n) {
    // This correctly watches the shopping list's specific filter provider.
    final isFilterActive = ref.watch(shoppingListPageFilterStateProvider.select((f) => f.isFilterActiveForShoppingList));

    return IconButton(
      icon: Badge(
        // This correctly controls when the dot is visible.
        isLabelVisible: isFilterActive,

        // --- ADD THIS LINE ---
        // Set the background color of the dot to your app's secondary color.
        backgroundColor: theme.secondary,

        // Ensure the badge is a small dot by having no label.
        label: null,

        child: Icon(Icons.filter_list_alt, color: theme.inactive),
      ),
      tooltip: l10n.organizeList,
      onPressed: () {
        _showModalSheet(
              (_) => const OrganizeListBottomSheet(),
          isScrollControlled: true,
        );
      },
    );
  }

  Widget _buildShoppingListSettingsAction(AppThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: IconButton(
        // OPTIONAL: You might want to change this icon to Icons.add_box_outlined
        // since it now only goes to "Custom items", but keeping it as settings works too.
        icon: Icon(Icons.add_box, color: theme.inactive),
        tooltip: "Manage custom items", // Helpful tooltip since behavior changed
        onPressed: () {
          // --- CHANGED: Navigate directly to ManageCustomItemsPage ---
          Navigator.of(context, rootNavigator: true).push(
            SlideUpPageRoute(page: const ManageCustomItemsPage()),
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