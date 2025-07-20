import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/providers/filter_state_provider.dart';
import 'package:sales_app_mvp/providers/search_suggestions_provider.dart';
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
  final _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();

  OverlayEntry? _overlayEntry;
  Timer? _debounce;

  // NEW: This now holds the full AsyncValue to track loading/error/data states.
  AsyncValue<List<String>> _suggestionsState = const AsyncValue.data([]);

  @override
  void initState() {
    super.initState();
    final initialQuery = ref.read(filterStateProvider).searchQuery;
    _textController.text = initialQuery;

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _showOverlay();
        // Trigger an initial suggestion fetch when focused.
        _triggerSuggestionFetch();
      } else {
        _removeOverlay();
      }
    });

    _textController.addListener(() {
      // Debounce user input to avoid spamming the provider.
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), () {
        _triggerSuggestionFetch();
      });
      // We still call setState to rebuild the clear button.
      setState(() {});
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    _removeOverlay();
    super.dispose();
  }

  void _triggerSuggestionFetch() {
    if (!_focusNode.hasFocus || !mounted) return;
    final query = _textController.text;

    // --- FIX IS HERE ---
    // 1. Manually read the current state of the provider once.
    // This gives us the initial value immediately (which might be loading, data, etc.).
    final currentState = ref.read(searchSuggestionsProvider(query));
    if (mounted) {
      setState(() {
        _suggestionsState = currentState;
      });
    }

    // 2. Set up the listener for all *future* changes.
    // This will not be called for the initial value we just read, only for subsequent updates.
    ref.listen<AsyncValue<List<String>>>(
      searchSuggestionsProvider(query),
          (previous, next) {
        if (!mounted) return;
        // When the provider emits a new state, update our local state.
        setState(() {
          _suggestionsState = next;
        });
        // We still need to tell the overlay to rebuild itself with the new state.
        _overlayEntry?.markNeedsBuild();
      },
    );
  }

  void _commitSearch(String query) {
    _textController.text = query;
    _textController.selection =
        TextSelection.fromPosition(TextPosition(offset: query.length));
    ref
        .read(filterStateProvider.notifier)
        .update((state) => state.copyWith(searchQuery: query));
    _focusNode.unfocus();
  }

  void _clearSearch() {
    _textController.clear();
    ref
        .read(filterStateProvider.notifier)
        .update((state) => state.copyWith(searchQuery: ''));
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final bool showClearButton = _textController.text.isNotEmpty;

    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: _textController,
        focusNode: _focusNode,
        onSubmitted: _commitSearch,
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
      ),
    );
  }

  // --- OVERLAY LOGIC ---

  void _showOverlay() {
    if (_overlayEntry != null) return;
    final OverlayState? overlay = Overlay.of(context, rootOverlay: true);
    if (overlay == null) return;

    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 8.0),
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(12),
            child: _buildSuggestionsOverlay(),
          ),
        ),
      ),
    );
    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  // THIS METHOD IS NO LONGER NEEDED, its logic is now in `_triggerSuggestionFetch`
  // void _fetchSuggestions() { ... }

  // REFACTORED: This now uses the `_suggestionsState` to build the UI.
  Widget _buildSuggestionsOverlay() {
    // Hide the overlay if the search bar loses focus.
    if (!_focusNode.hasFocus) {
      return const SizedBox.shrink();
    }
    final theme = ref.watch(themeProvider);

    // Use .when to handle the async state gracefully.
    return _suggestionsState.when(
      loading: () => Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: theme.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        // Show a subtle loading indicator.
        child: const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      ),
      error: (err, stack) => Container(
        decoration: BoxDecoration(
          color: theme.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          leading: Icon(Icons.error_outline, color: theme.accent),
          title: Text(
            'Could not load suggestions',
            style: TextStyle(color: theme.accent),
          ),
        ),
      ),
      data: (suggestions) {
        // Don't show the overlay if there are no suggestions.
        if (suggestions.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          decoration: BoxDecoration(
            color: theme.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            itemCount: suggestions.length,
            shrinkWrap: true,
            itemBuilder: (context, index) {
              final suggestion = suggestions[index];
              return ListTile(
                title: Text(suggestion, style: const TextStyle(color: Colors.white)),
                onTap: () => _commitSearch(suggestion),
              );
            },
          ),
        );
      },
    );
  }
}