// lib/pages/main_app_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/generated/app_localizations.dart';
import 'package:sales_app_mvp/models/shopping_list_info.dart';
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
import 'package:sales_app_mvp/pages/manage_shopping_list.dart';
import 'package:sales_app_mvp/providers/user_profile_provider.dart';
import 'package:sales_app_mvp/services/ad_manager.dart';
import 'package:sales_app_mvp/pages/manage_custom_items_page.dart';
import 'package:sales_app_mvp/components/manage_list_items_bottom_sheet.dart';
import 'package:sales_app_mvp/components/organize_list_bottom_sheet.dart';
import 'package:sales_app_mvp/providers/filter_state_provider.dart';
import 'package:sales_app_mvp/widgets/slide_in_page_route.dart';
import 'package:sales_app_mvp/providers/selection_state_provider.dart';

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

  PreferredSizeWidget? _buildAppBarForIndex(
      BuildContext context, int index, AppThemeData theme, WidgetRef ref) {
    final selectionState = ref.watch(selectionStateProvider);

    switch (index) {
      case 0:
        return _buildHomePageAppBar(theme);
      case 1:
        return selectionState.isSelectionModeActive
            ? _buildContextualShoppingListAppBar(context, theme, ref)
            : _buildShoppingListPageAppBar(context, theme, ref);
      default:
        return null;
    }
  }

  PreferredSizeWidget _buildContextualShoppingListAppBar(
      BuildContext context, AppThemeData theme, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selectionNotifier = ref.read(selectionStateProvider.notifier);
    final selectedCount = ref.watch(selectionStateProvider.select((s) => s.selectedItemIds.length));

    return AppBar(
      backgroundColor: theme.background,
      elevation: 4,
      leading: IconButton(
        icon: Icon(Icons.close, color: theme.inactive),
        onPressed: () {
          selectionNotifier.disableSelectionMode();
        },
      ),
      title: Text(
        l10n.itemsSelected(selectedCount),
        style: TextStyle(color: theme.inactive, fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.delete_sweep, color: theme.inactive, size: 28),
          tooltip: l10n.tooltipDeleteSelected,
          onPressed: selectedCount > 0 ? () {
            showDialog(
              context: context,
              builder: (BuildContext dialogContext) {
                return AlertDialog(
                  backgroundColor: theme.background,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Text(
                    l10n.confirmDeletionTitle,
                    style: TextStyle(color: theme.secondary, fontWeight: FontWeight.bold),
                  ),
                  content: Text(
                    l10n.confirmDeletionMessage(selectedCount),
                    style: TextStyle(color: theme.inactive),
                  ),
                  actionsAlignment: MainAxisAlignment.spaceBetween,
                  actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  actions: <Widget>[
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.inactive,
                        // --- FIX: Replaced deprecated withOpacity with withAlpha ---
                        side: BorderSide(color: theme.inactive.withAlpha((255 * 0.5).round())),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: Text(l10n.cancel),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.accent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(l10n.delete),
                      onPressed: () {
                        final selectedIds = ref.read(selectionStateProvider).selectedItemIds;
                        ref.read(shoppingListsProvider.notifier).removeItemsFromList(selectedIds);
                        selectionNotifier.disableSelectionMode();
                        Navigator.of(dialogContext).pop();
                      },
                    ),
                  ],
                );
              },
            );
          } : null,
        ),
      ],
    );
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

  PreferredSizeWidget _buildShoppingListPageAppBar(
      BuildContext context, AppThemeData theme, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;

    final activeListId = ref.watch(activeShoppingListProvider);
    final isListActive = activeListId != null;
    // --- FIX: Replaced deprecated withOpacity with withAlpha ---
    final disabledColor = theme.inactive.withAlpha((255 * 0.4).round());

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
            settingsState.isGridView
                ? Icons.view_list_rounded
                : Icons.grid_view_rounded,
            color: isListActive ? theme.inactive : disabledColor,
          ),
          tooltip: settingsState.isGridView
              ? l10n.tooltipShowAsList
              : l10n.tooltipShowAsGrid,
          onPressed: isListActive
              ? () => ref.read(settingsProvider.notifier).toggleGridView()
              : null,
        ),
        IconButton(
          icon: Icon(Icons.delete,
              color: isListActive ? theme.inactive : disabledColor),
          tooltip: l10n.tooltipManageListItems,
          onPressed: isListActive
              ? () => _showModalSheet(
                (_) => const ManageListItemsBottomSheet(),
          )
              : null,
        ),
        _buildOrganizeListAction(theme, l10n, isEnabled: isListActive),
        _buildShoppingListSettingsAction(theme, isEnabled: isListActive),
      ],
    );
  }

  Widget _buildInfoBar() {
    return Consumer(
      builder: (context, ref, child) {
        final theme = ref.watch(themeProvider);
        final l10n = AppLocalizations.of(context)!;
        final activeListId = ref.watch(activeShoppingListProvider);
        final allLists = ref.watch(allShoppingListsProvider).value ?? [];
        String buttonText;
        if (activeListId == null) {
          buttonText = l10n.noListsExist;
        } else {
          final activeListInfo = allLists.firstWhere(
                (list) => list.id == activeListId,
            orElse: () =>
                ShoppingListInfo(id: '', name: l10n.list, itemCount: 0),
          );
          buttonText = activeListInfo.name;
        }
        final appData = ref.watch(appDataProvider);
        final bool isDataLoaded = appData.status == InitializationStatus.loaded;
        final totalCount = appData.grandTotal;
        final filteredCount = ref
            .watch(homePageProductsProvider)
            .whenData((groups) {
          return groups.fold<int>(
              0, (sum, group) => sum + group.products.length);
        })
            .value ??
            0;

        return Row(
          children: [
            Expanded(
              child: Opacity(
                opacity: isDataLoaded ? 1.0 : 0.5,
                child: Container(
                  decoration: BoxDecoration(
                    // --- FIX: Replaced deprecated withOpacity with withAlpha ---
                    color: theme.background.withAlpha((255 * 0.5).round()),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: InkWell(
                    onTap: isDataLoaded
                        ? () => Navigator.of(context, rootNavigator: true).push(
                      SlidePageRoute(
                        page: const ManageShoppingListsPage(),
                        direction: SlideDirection.rightToLeft,
                      ),
                    )
                        : null,
                    borderRadius: BorderRadius.circular(12.0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.list_alt_rounded,
                              color: theme.secondary, size: 22.0),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              buttonText,
                              style:
                              TextStyle(color: theme.inactive, fontSize: 16),
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
    final l10n = AppLocalizations.of(context)!;
    final activeListId = ref.watch(activeShoppingListProvider);
    final allLists = ref.watch(allShoppingListsProvider).value ?? [];
    String activeListName;
    if (activeListId == null) {
      activeListName = l10n.noListsExist;
    } else {
      final activeListInfo = allLists.firstWhere(
            (list) => list.id == activeListId,
        orElse: () => ShoppingListInfo(id: '', name: l10n.list, itemCount: 0),
      );
      activeListName = activeListInfo.name;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(left: 12.0),
        child: Container(
          decoration: BoxDecoration(
            // --- FIX: Replaced deprecated withOpacity with withAlpha ---
            color: theme.background.withAlpha((255 * 0.5).round()),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: InkWell(
            onTap: () => Navigator.of(context, rootNavigator: true).push(
              SlidePageRoute(
                page: const ManageShoppingListsPage(),
                direction: SlideDirection.rightToLeft,
              ),
            ),
            borderRadius: BorderRadius.circular(12.0),
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Row(
                children: [
                  Icon(Icons.list_alt_rounded,
                      color: theme.secondary, size: 22.0),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      activeListName,
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

  Widget _buildOrganizeListAction(AppThemeData theme, AppLocalizations l10n,
      {required bool isEnabled}) {
    final isFilterActive = ref.watch(shoppingListPageFilterStateProvider
        .select((f) => f.isFilterActiveForShoppingList));
    // --- FIX: Replaced deprecated withOpacity with withAlpha ---
    final disabledColor = theme.inactive.withAlpha((255 * 0.4).round());

    return IconButton(
      icon: Badge(
        isLabelVisible: isEnabled && isFilterActive,
        backgroundColor: theme.secondary,
        label: null,
        child: Icon(Icons.filter_list_alt,
            color: isEnabled ? theme.inactive : disabledColor),
      ),
      tooltip: l10n.organizeList,
      onPressed: isEnabled
          ? () => _showModalSheet(
            (_) => const OrganizeListBottomSheet(),
        isScrollControlled: true,
      )
          : null,
    );
  }

  Widget _buildShoppingListSettingsAction(AppThemeData theme,
      {required bool isEnabled}) {
    // --- FIX: Replaced deprecated withOpacity with withAlpha ---
    final disabledColor = theme.inactive.withAlpha((255 * 0.4).round());

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: IconButton(
        icon: Icon(Icons.add_box,
            color: isEnabled ? theme.inactive : disabledColor),
        tooltip: "Manage custom items",
        onPressed: isEnabled
            ? () => Navigator.of(context, rootNavigator: true).push(
          SlidePageRoute(
            page: const ManageCustomItemsPage(),
            direction: SlideDirection.rightToLeft,
          ),
        )
            : null,
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

  void _showModalSheet(Widget Function(BuildContext) builder,
      {bool isScrollControlled = false}) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: isScrollControlled,
      builder: builder,
    );
  }
}