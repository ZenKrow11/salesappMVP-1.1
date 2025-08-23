// lib/pages/main_app_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- FIX: Added these imports to resolve provider errors ---
import 'package:sales_app_mvp/providers/home_page_state_provider.dart';
import 'package:sales_app_mvp/models/products_provider.dart';
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';
// --- END FIX ---

import 'package:sales_app_mvp/components/filter_bottom_sheet.dart';
import 'package:sales_app_mvp/components/search_bottom_sheet.dart';
import 'package:sales_app_mvp/components/shopping_list_bottom_sheet.dart';
import 'package:sales_app_mvp/widgets/item_count_widget.dart';
import 'package:sales_app_mvp/widgets/sort_button_widget.dart';
import 'package:sales_app_mvp/pages/home_page.dart';
import 'package:sales_app_mvp/pages/shopping_list_page.dart';
import 'package:sales_app_mvp/pages/account_page.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';

import '../providers/grouped_products_provider.dart';


class MainAppScreen extends ConsumerStatefulWidget {
  static const routeName = '/main-app';
  const MainAppScreen({super.key});

  @override
  ConsumerState<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends ConsumerState<MainAppScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const ShoppingListPage(),
    const AccountPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);

    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        backgroundColor: theme.pageBackground,
        appBar: _currentIndex == 0 ? _buildHomePageAppBar(theme) : null,
        body: _pages[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: theme.primary,
          currentIndex: _currentIndex,
          selectedItemColor: theme.secondary,
          unselectedItemColor: theme.inactive,
          onTap: (index) => setState(() => _currentIndex = index),
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
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: _buildActionsBar(),
        ),
      ),
      titleSpacing: 12,
      toolbarHeight: 40,
    );
  }

  Widget _buildInfoBar() {
    return Consumer(
      builder: (context, ref, child) {
        final theme = ref.watch(themeProvider);
        final activeList = ref.watch(activeShoppingListProvider);
        final buttonText = activeList ?? 'Select List';

        final count = ref.watch(homePageProductsProvider).whenData((groups) {
          final filtered = groups.fold<int>(0, (sum, group) => sum + group.products.length);
          final total = ref.read(initialProductsProvider).value?.length ?? 0;
          return ProductCount(filtered: filtered, total: total);
        }).value ?? ProductCount(filtered: 0, total: 0);

        return Row(
          children: [
            InkWell(
              onTap: () => _showModalSheet((_) => const ShoppingListBottomSheet(), isScrollControlled: true),
              child: Row(
                children: [
                  Icon(Icons.list_alt_rounded, color: theme.secondary, size: 24.0),
                  const SizedBox(width: 8),
                  Text(buttonText, style: TextStyle(color: theme.inactive, fontSize: 16), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Spacer(),
            ItemCountWidget(filtered: count.filtered, total: count.total),
          ],
        );
      },
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