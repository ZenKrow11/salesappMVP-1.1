import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/providers/search_state.dart';
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
    // Initialize the controller with the current value from the provider.
    // This ensures the text persists if the widget rebuilds.
    final initialQuery = ref.read(searchQueryProvider);
    _controller = TextEditingController(text: initialQuery);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        controller: _controller,
        onChanged: (value) {
          // Update the provider on every keystroke.
          ref.read(searchQueryProvider.notifier).state = value;
        },
        style: const TextStyle(color: AppColors.textWhite), // Themed text color
        decoration: InputDecoration(
          hintText: 'Search products...',
          hintStyle: const TextStyle(color: AppColors.inactive), // Themed hint text
          prefixIcon: const Icon(Icons.search, color: AppColors.secondary), // Themed icon
          filled: true,
          fillColor: AppColors.primary, // Use background for a seamless look
          // Themed border when the field is not focused
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.inactive),
          ),
          // Themed border when the field is focused
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.secondary, width: 2.0),
          ),
        ),
      ),
    );
  }
}