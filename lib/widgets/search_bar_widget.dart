// lib/widgets/search_bar_widget.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/providers/filter_state_provider.dart';
import 'package:sales_app_mvp/providers/search_suggestions_provider.dart';
// NEW: Import the theme provider
import 'package:sales_app_mvp/widgets/app_theme.dart';

class SearchBarWidget extends ConsumerStatefulWidget {
  final Widget? trailing;
  // NEW: Add a property to control the border/background visibility
  final bool hasBorder;

  const SearchBarWidget({
    super.key,
    this.trailing,
    this.hasBorder = true, // Default to true for backward compatibility
  });

  @override
  ConsumerState<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends ConsumerState<SearchBarWidget> {
  // ... (all your existing state variables like _textController etc. are unchanged)
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();

  OverlayEntry? _overlayEntry;
  Timer? _debounce;
  List<String> _lastSuggestions = [];

  @override
  void initState() {
    super.initState();
    final initialQuery = ref.read(filterStateProvider).searchQuery;
    _textController.text = initialQuery;

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _showOverlay();
        _fetchSuggestions();
      } else {
        _removeOverlay();
      }
    });

    _textController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), () {
        _fetchSuggestions();
      });
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

  void _commitSearch(String query) {
    _textController.text = query;
    _textController.selection =
        TextSelection.fromPosition(TextPosition(offset: query.length));
    ref.read(filterStateProvider.notifier).update((state) => state.copyWith(searchQuery: query));
    _focusNode.unfocus();
  }

  void _clearSearch() {
    _textController.clear();
    ref.read(filterStateProvider.notifier).update((state) => state.copyWith(searchQuery: ''));
  }


  @override
  Widget build(BuildContext context) {
    // NEW: Get theme for colors
    final theme = ref.watch(themeProvider);
    final bool showClearButton = _textController.text.isNotEmpty;

    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: _textController,
        focusNode: _focusNode,
        onSubmitted: _commitSearch,
        // CHANGED: Use white for text color
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search products...',
          // CHANGED: Use theme color
          hintStyle: TextStyle(color: theme.inactive),
          // CHANGED: Use theme color
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
                  // CHANGED: Use theme color
                  icon: Icon(Icons.clear, color: theme.accent),
                  onPressed: _clearSearch,
                )
                    : const SizedBox(),
              ),
              if (widget.trailing != null)
                Container(
                  height: 24.0,
                  width: 1.0,
                  // CHANGED: Use theme color
                  color: theme.secondary.withOpacity(0.5),
                  margin: const EdgeInsets.only(right: 8.0),
                ),
              if (widget.trailing != null) widget.trailing!,
              const SizedBox(width: 12),
            ],
          ),
          filled: true,
          // CHANGED: Fill color is now conditional
          fillColor: widget.hasBorder ? theme.primary : Colors.transparent,
          // CHANGED: Border is now conditional
          border: widget.hasBorder
              ? OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          )
              : InputBorder.none, // No border when it's part of the panel
          // NEW: Ensure no extra border appears when focused
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

  // ... (Overlay logic below is unchanged but updated to use theme colors)
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

  void _fetchSuggestions() {
    if (!_focusNode.hasFocus || !mounted) return;
    final query = _textController.text;
    final suggestions = ref.read(searchSuggestionsProvider(query));
    if (!mounted) return;
    setState(() {
      _lastSuggestions = suggestions;
    });
    _overlayEntry?.markNeedsBuild();
  }

  Widget _buildSuggestionsOverlay() {
    if (_lastSuggestions.isEmpty || !_focusNode.hasFocus) {
      return const SizedBox.shrink();
    }
    final theme = ref.watch(themeProvider); // Get theme for overlay
    return Container(
      decoration: BoxDecoration(
        color: theme.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        itemCount: _lastSuggestions.length,
        shrinkWrap: true,
        itemBuilder: (context, index) {
          final suggestion = _lastSuggestions[index];
          return ListTile(
            title: Text(
              suggestion,
              style: const TextStyle(color: Colors.white),
            ),
            onTap: () => _commitSearch(suggestion),
          );
        },
      ),
    );
  }
}