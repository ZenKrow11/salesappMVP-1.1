import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/providers/search_state.dart'; // Assuming this is your provider's location
import 'package:sales_app_mvp/widgets/theme_color.dart';

class SearchBarWidget extends ConsumerStatefulWidget {
  const SearchBarWidget({super.key});

  @override
  ConsumerState<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends ConsumerState<SearchBarWidget> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final initialQuery = ref.read(searchQueryProvider);
    _controller = TextEditingController(text: initialQuery);

    // Add a listener to rebuild the widget when text changes,
    // so we can show/hide the clear button.
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clearSearch() {
    // 1. Clear the text field's content
    _controller.clear();
    // 2. Update the state provider so the rest of the app reacts
    ref.read(searchQueryProvider.notifier).state = '';
    // 3. Unfocus the text field to dismiss the keyboard
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    // Note: We are no longer using SizedBox or Padding here,
    // as the TextField's decoration handles it better.
    return TextField(
      controller: _controller,
      onChanged: (value) {
        // Update the provider on every keystroke.
        // (This is where you'll add debouncing tomorrow)
        ref.read(searchQueryProvider.notifier).state = value;
      },
      style: const TextStyle(color: AppColors.textWhite),
      decoration: InputDecoration(
        hintText: 'Search products...',
        hintStyle: const TextStyle(color: AppColors.inactive),
        prefixIcon: const Icon(Icons.search, color: AppColors.secondary),

        // --- NEW ---: Add a clear button as the suffix icon
        // It only appears if there is text in the controller.
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
          icon: const Icon(Icons.clear, color: AppColors.accent),
          onPressed: _clearSearch, // Call our new clear function
        )
            : null, // Render nothing if the field is empty

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
    );
  }
}