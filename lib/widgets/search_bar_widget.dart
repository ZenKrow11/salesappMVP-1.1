import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/providers/filter_state_provider.dart';
import 'package:sales_app_mvp/providers/search_suggestions_provider.dart';
import 'package:sales_app_mvp/widgets/theme_color.dart';

class SearchBarWidget extends ConsumerStatefulWidget {
  // Accepts an optional widget to display at the end (e.g., ItemCountWidget)
  final Widget? trailing;

  const SearchBarWidget({super.key, this.trailing});

  @override
  ConsumerState<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends ConsumerState<SearchBarWidget> {
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
      // Use setState to rebuild the widget and show/hide the clear button
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
    // The listener on the controller will automatically call setState
  }

  @override
  Widget build(BuildContext context) {
    // Determine if the clear button should be visible based on text input
    final bool showClearButton = _textController.text.isNotEmpty;

    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: _textController,
        focusNode: _focusNode,
        onSubmitted: _commitSearch,
        style: const TextStyle(color: AppColors.textWhite),
        decoration: InputDecoration(
          hintText: 'Search products...',
          hintStyle: const TextStyle(color: AppColors.inactive),
          prefixIcon: const Icon(Icons.search, color: AppColors.secondary),

          // --- THE SOLUTION ---
          // A single, well-controlled Row inside suffixIcon handles all trailing elements.
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min, // CRITICAL: Makes the Row only as wide as its children
            crossAxisAlignment: CrossAxisAlignment.center, // CRITICAL: Vertically aligns all items
            children: [
              // 1. CLEAR BUTTON AREA
              // A SizedBox is used to reserve space for the clear button.
              // This prevents the divider and item count from "jumping" when the button appears.
              SizedBox(
                width: 36, // A fixed width for the button's tappable area
                child: showClearButton
                    ? IconButton(
                  // These properties make the icon button compact
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.clear, color: AppColors.accent),
                  onPressed: _clearSearch,
                )
                    : const SizedBox(), // When hidden, an empty box holds the space
              ),

              // 2. DIVIDER
              // The divider is now persistent. It only cares if the trailing widget exists.
              if (widget.trailing != null)
                Container(
                  height: 24.0, // A fixed height is good practice
                  width: 1.0,
                  color: AppColors.secondary.withValues(alpha: 0.5),
                  margin: const EdgeInsets.only(right: 8.0), // Spacing after the divider
                ),

              // 3. TRAILING WIDGET (e.g., ItemCount)
              // This is displayed if it's provided to the SearchBarWidget.
              if (widget.trailing != null) widget.trailing!,

              // 4. FINAL PADDING
              // Ensures the trailing widget doesn't sit flush against the text field's edge.
              const SizedBox(width: 12),
            ],
          ),
          filled: true,
          fillColor: AppColors.primary,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // --- No changes needed to overlay logic below this point ---

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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
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
              style: const TextStyle(color: AppColors.textWhite),
            ),
            onTap: () => _commitSearch(suggestion),
          );
        },
      ),
    );
  }
}