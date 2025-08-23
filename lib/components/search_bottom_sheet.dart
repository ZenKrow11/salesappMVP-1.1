// lib/components/search_bottom_sheet.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/providers/filter_state_provider.dart';
// --- FIX: Added this import to define AppThemeData ---
import 'package:sales_app_mvp/widgets/app_theme.dart';

class SearchBottomSheet extends ConsumerStatefulWidget {
  const SearchBottomSheet({super.key});

  @override
  ConsumerState<SearchBottomSheet> createState() => _SearchBottomSheetState();
}

class _SearchBottomSheetState extends ConsumerState<SearchBottomSheet> {
  final _textController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final initialQuery = ref.read(filterStateProvider).searchQuery;
    _textController.text = initialQuery;

    _textController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () {
        if (mounted && _textController.text != ref.read(filterStateProvider).searchQuery) {
          _commitSearch(_textController.text);
        }
      });
      setState(() {});
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _commitSearch(String query) {
    ref.read(filterStateProvider.notifier).update((state) => state.copyWith(searchQuery: query));
  }

  void _clearSearch() {
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final bool showClearButton = _textController.text.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: theme.background,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(theme),
              const SizedBox(height: 16),
              TextField(
                controller: _textController,
                autofocus: true,
                onSubmitted: (query) {
                  _commitSearch(query);
                  Navigator.pop(context);
                },
                style: TextStyle(color: theme.secondary),
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  hintStyle: TextStyle(color: theme.inactive),
                  prefixIcon: Icon(Icons.search, color: theme.secondary),
                  suffixIcon: showClearButton
                      ? IconButton(
                    icon: Icon(Icons.clear, color: theme.accent),
                    onPressed: _clearSearch,
                  )
                      : null,
                  filled: true,
                  fillColor: theme.inactive.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- FIX: Corrected the type hint from 'AppTheme' to 'AppThemeData' ---
  Widget _buildHeader(AppThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Search Products',
          style: TextStyle(
            fontSize: 20,
            color: theme.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: Icon(Icons.close, color: theme.accent, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}