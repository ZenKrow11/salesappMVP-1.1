// lib/widgets/search_bar_widget.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/providers/filter_state_provider.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';

// --- ADDED IMPORT ---
import 'package:sales_app_mvp/generated/app_localizations.dart';

class SearchBarWidget extends ConsumerStatefulWidget {
  final Widget? trailing;
  final bool hasBorder;

  const SearchBarWidget({
    super.key,
    this.trailing,
    this.hasBorder = true,
  });

  @override
  ConsumerState<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends ConsumerState<SearchBarWidget> {
  final _textController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final initialQuery = ref.read(homePageFilterStateProvider).searchQuery;
    _textController.text = initialQuery;

    _textController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () {
        if (mounted && _textController.text != ref.read(homePageFilterStateProvider).searchQuery) {
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
    ref
        .read(homePageFilterStateProvider.notifier)
        .update((state) => state.copyWith(searchQuery: query));
  }

  void _clearSearch() {
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    // --- GET LOCALIZATIONS ---
    final l10n = AppLocalizations.of(context)!;
    final theme = ref.watch(themeProvider);
    final bool showClearButton = _textController.text.isNotEmpty;

    return TextField(
      controller: _textController,
      onSubmitted: _commitSearch,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        // --- USE LOCALIZED STRING ---
        hintText: l10n.searchProductsHint,
        hintStyle: TextStyle(color: theme.inactive),
        prefixIcon: Icon(Icons.search, color: theme.secondary),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 36,
              child: showClearButton
                  ? IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                icon: Icon(Icons.clear, color: theme.accent),
                onPressed: _clearSearch,
              )
                  : const SizedBox(),
            ),
            if (widget.trailing != null)
              Container(
                height: 24.0,
                width: 1.0,
                color: theme.secondary.withAlpha((255 * 0.5).round()),
                margin: const EdgeInsets.only(right: 8.0),
              ),
            if (widget.trailing != null) widget.trailing!,
            const SizedBox(width: 12),
          ],
        ),
        filled: true,
        fillColor: widget.hasBorder ? theme.primary : Colors.transparent,
        border: widget.hasBorder
            ? OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        )
            : InputBorder.none,
        enabledBorder: widget.hasBorder
            ? OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        )
            : InputBorder.none,
        focusedBorder: widget.hasBorder
            ? OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        )
            : InputBorder.none,
      ),
    );
  }
}