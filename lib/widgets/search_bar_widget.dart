import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/providers/filter_state_provider.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';

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
    // Initialize the text field with the current search query from the provider.
    final initialQuery = ref.read(filterStateProvider).searchQuery;
    _textController.text = initialQuery;

    // Listen to text changes to update the UI (e.g., show/hide clear button).
    _textController.addListener(() {
      // Use a debounce so that we only commit the search after the user has stopped typing.
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () {
        // Only commit the search if the text has actually changed from the provider's state.
        if (mounted && _textController.text != ref.read(filterStateProvider).searchQuery) {
          _commitSearch(_textController.text);
        }
      });
      // Call setState to rebuild the widget and show/hide the clear button.
      setState(() {});
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  /// Commits the search query to the central state provider.
  void _commitSearch(String query) {
    ref
        .read(filterStateProvider.notifier)
        .update((state) => state.copyWith(searchQuery: query));
  }

  /// Clears the search text and updates the central state provider.
  void _clearSearch() {
    _textController.clear();
    // No need to call _commitSearch here, clearing the controller will trigger the listener.
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final bool showClearButton = _textController.text.isNotEmpty;

    return TextField(
      controller: _textController,
      onSubmitted: _commitSearch, // Also allow committing by pressing 'enter'.
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Search products...',
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
                color: theme.secondary.withOpacity(0.5),
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