import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/widgets/theme_color.dart';
import 'search_state.dart';

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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextField(
        controller: _controller,
        onChanged: (value) {
          ref.read(searchQueryProvider.notifier).state = value;
        },
        decoration: InputDecoration(
          hintText: 'Search...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: AppColors.cardBackground,
        ),
      ),
    );
  }
}
