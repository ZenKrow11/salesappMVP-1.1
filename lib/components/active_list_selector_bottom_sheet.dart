import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/create_list_bottom_sheet.dart';
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';
import 'package:sales_app_mvp/widgets/theme_color.dart';

class ActiveListSelectorBottomSheet extends ConsumerWidget {
  const ActiveListSelectorBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the providers for the list of all shopping lists and the currently active one.
    final shoppingLists = ref.watch(shoppingListsProvider); // TODO - this needs to be a list of quicksave lists, not all shopping lists
    final activeList = ref.watch(activeShoppingListProvider); // TODO - this needs to be the active quicksave list

    return Scaffold(
      // Use Scaffold to easily place the FAB
      backgroundColor: AppColors.primary, // Set background color to match theme
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Make the sheet only as tall as its content
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Select a Quicksave List',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary)),
                IconButton(
                  // Close button
                  icon: const Icon(Icons.close, size: 32.0,),
                  color: AppColors.accent, // Set the color of the icon itself
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the current bottom sheet
                  },
                ),
              ],
            ),
            const Divider(height: 24),

            // Handle the case where no lists exist yet.
            if (shoppingLists.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.0),
                  child: Text(
                    "No lists exist yet.\nPlease create one from the 'Lists' page.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.inactive),
                  ),
                ),
              )
            else
              // Use Flexible and ListView for a scrollable list of items.
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true, // Important for ListView inside a Column
                  itemCount: shoppingLists.length,
                  itemBuilder: (context, index) {
                    final list = shoppingLists[index];
                    final bool isActive = list.name == activeList;

                    return Card(
                      elevation: isActive ? 2 : 0,
                      color: isActive ? AppColors.secondary : Colors.transparent,
                      child: ListTile(
                        title: Text(
                          list.name,
                          style: TextStyle(
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            color: isActive ? AppColors.primary : AppColors.inactive, // Text color
                          ),
                        ),
                        // When a list is tapped, set it as active and close the sheet.
                        onTap: () async {
                          ref
                              .read(activeShoppingListProvider.notifier)
                              .setActiveList(list.name);
                          // Intentionally not closing the bottom sheet here.
                        },
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.secondary,
        label: const Text('Create New List', style: TextStyle(color: AppColors.primary)),
        icon: const Icon(Icons.add, color: AppColors.primary), // Added icon to the extended FAB
        onPressed: () {
          Navigator.of(context).pop(); // Close the current bottom sheet
          showModalBottomSheet(
            context: context,
            isScrollControlled: true, // Allows the sheet to take up more screen space
            builder: (context) => const CreateListBottomSheet(),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}