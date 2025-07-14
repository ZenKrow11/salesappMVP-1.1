import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  void _showOverlay() {
    if (_overlayEntry != null) return;
    final OverlayState? overlay = Overlay.of(context, rootOverlay: true);
    if (overlay == null) {
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

          // --- THIS IS THE CORRECTED PART ---
          // Define a single border that applies to all states.
          // This ensures the fillColor is clipped to the border's shape.
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0), // Apply your desired radius here
            borderSide: BorderSide.none, // No visible outline
          ),

          // The specific 'enabledBorder' and 'focusedBorder' are no longer needed.
        ),
      ),
    );
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
            onTap: () {
              _commitSearch(suggestion);
            },
          );
        },
      ),
    );
  }
}