import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';
import 'package:sales_app_mvp/widgets/theme_color.dart';

// This widget is now self-contained and reusable.
// It will pop with the new list's name on success, or null on failure/cancel.
class CreateListBottomSheet extends ConsumerStatefulWidget {
  const CreateListBottomSheet({super.key});

  @override
  ConsumerState<CreateListBottomSheet> createState() =>
      _CreateListBottomSheetState();
}

class _CreateListBottomSheetState extends ConsumerState<CreateListBottomSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _createList() {
    final listName = _controller.text.trim();
    final notifier = ref.read(shoppingListsProvider.notifier);
    final currentLists = ref.read(shoppingListsProvider);

    if (listName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('List name cannot be empty'), duration: Duration(seconds: 1)),
      );
      return;
    }

    if (currentLists.any((list) => list.name.toLowerCase() == listName.toLowerCase()) ||
        listName.toLowerCase() == favoritesListName.toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('List name already exists'), duration: Duration(seconds: 1)),
      );
      return;
    }

    notifier.addEmptyList(listName);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Created "$listName"'), duration: const Duration(seconds: 1)),
    );
    // Pop with the new list name so the caller can react to it
    Navigator.of(context).pop(listName);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background, // Set the background color here
      child: Padding(
        // This padding moves the sheet up when the keyboard appears
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Create New List',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.accent),
                  // Pop with null to indicate cancellation
                  onPressed: () => Navigator.of(context).pop(null),
                )
              ],
            ),
            const Divider(thickness: 1, height: 24),

            // Input Field
            TextField(
              controller: _controller,
              autofocus: true,
              style: const TextStyle(color: AppColors.primary),
              onSubmitted: (_) => _createList(), // Allow creating with enter key
              decoration: InputDecoration(
                labelText: 'List name',
                labelStyle: const TextStyle(color: AppColors.inactive),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.inactive.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(8.0)),
                focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: AppColors.inactive),
                    borderRadius: BorderRadius.circular(8.0)),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.accent, // Adjusted button color for visibility
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.of(context).pop(null),
                    child: const Text('CANCEL', style: TextStyle(color: AppColors.primary,
                        fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary, // Adjusted button color for visibility
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _createList,
                    child: const Text('CREATE', style: TextStyle(color: AppColors.primary,
                        fontWeight: FontWeight.bold)), // Adjusted text color
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}