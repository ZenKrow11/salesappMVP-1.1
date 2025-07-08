import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/models/filter_state.dart';
import 'package:sales_app_mvp/providers/filter_state_provider.dart';
import 'package:sales_app_mvp/providers/search_suggestions_provider.dart';
import 'package:sales_app_mvp/widgets/theme_color.dart';

class SearchBarWidget extends ConsumerStatefulWidget {
  const SearchBarWidget({super.key});

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
        print("✅ Focus gained, showing overlay...");
        _showOverlay();
        _fetchSuggestions();
      } else {
        print("❌ Focus lost, removing overlay.");
        _removeOverlay();
      }
    });

    _textController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), () {
        // This now calls the synchronous version.
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

  void _showOverlay() {
    if (_overlayEntry != null) return;
    final OverlayState? overlay = Overlay.of(context, rootOverlay: true);
    if (overlay == null) {
      print("🚨 ERROR: Could not find the root overlay.");
      return;
    }
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 8.0),
          child: _buildSuggestionsOverlay(),
        ),
      ),
    );
    overlay.insert(_overlayEntry!);
    print("✅ Overlay inserted into the UI tree.");
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  // --- THIS METHOD IS NOW CORRECTED ---
  // It is no longer async and does not use .future
  void _fetchSuggestions() {
    if (!_focusNode.hasFocus || !mounted) return;

    final query = _textController.text;
    print("🔎 Fetching suggestions for query: '$query'");

    // Read the result directly from the new synchronous provider.
    final suggestions = ref.read(searchSuggestionsProvider(query));

    print("💡 Received ${suggestions.length} suggestions: $suggestions");

    if (!mounted) return;
    setState(() {
      _lastSuggestions = suggestions;
    });

    _overlayEntry?.markNeedsBuild();
  }
  // --- END OF CORRECTION ---

  void _commitSearch(String query) {
    print("🚀 Committing search for: '$query'");
    _textController.text = query;
    _textController.selection = TextSelection.fromPosition(TextPosition(offset: query.length));
    ref.read(filterStateProvider.notifier).update((state) => state.copyWith(searchQuery: query));
    _focusNode.unfocus();
  }

  void _clearSearch() {
    print("🚀 Clearing search.");
    _textController.clear();
    ref.read(filterStateProvider.notifier).update((state) => state.copyWith(searchQuery: ''));
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
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
          suffixIcon: _textController.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear, color: AppColors.accent),
            onPressed: _clearSearch,
          )
              : null,
          filled: true,
          fillColor: AppColors.primary,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.inactive),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.secondary, width: 2.0),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsOverlay() {
    print("🏗️ Building suggestions overlay with ${_lastSuggestions.length} items.");
    if (_lastSuggestions.isEmpty || !_focusNode.hasFocus) {
      return const SizedBox.shrink();
    }
    return Material(
      elevation: 4.0,
      borderRadius: BorderRadius.circular(12),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        itemCount: _lastSuggestions.length,
        shrinkWrap: true,
        itemBuilder: (context, index) {
          final suggestion = _lastSuggestions[index];
          return ListTile(
            title: Text(suggestion, style: const TextStyle(color: AppColors.textWhite)),
            onTap: () {
              _commitSearch(suggestion);
            },
          );
        },
      ),
    );
  }
}