import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// Model and Provider imports
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';

// Widget and Component imports
import 'package:sales_app_mvp/components/active_list_selector_bottom_sheet.dart';
import 'package:sales_app_mvp/components/shopping_list_bottom_sheet.dart';
import 'package:sales_app_mvp/widgets/category_chip.dart';
import 'package:sales_app_mvp/widgets/image_aspect_ratio.dart';
import 'package:sales_app_mvp/widgets/store_logo.dart';
import 'package:sales_app_mvp/widgets/theme_color.dart';
import 'package:url_launcher/url_launcher.dart';


// --- STEP 1: CONVERTED TO A CONSUMER WIDGET ---
// This allows us to access providers like `activeShoppingListProvider`.
class ProductDetails extends ConsumerWidget {
  final Product product;

  const ProductDetails({super.key, required this.product});

  // --- STEP 2: RESTRUCTURED THE BUILD METHOD ---
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView( // Added to prevent overflow on smaller screens
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Shop Logo (left) | Active List Selector (right)
            _buildHeader(context, ref),
            const SizedBox(height: 16),

            // Row 2: Main Category and Subcategory Chips
            _buildCategoryRows(),
            const SizedBox(height: 16),

            // Row 3: Product Title
            _buildProductName(),
            const SizedBox(height: 12),

            // Row 4: Image
            _buildImageContainer(),
            const SizedBox(height: 20),

            // Row 5: Available From Info
            _buildAvailabilityInfo(),

            // Row 6: Sonderkondition Info
            _buildSonderkonditionInfo(),

            // A divider to visually separate info from prices
            if (product.availableFrom != null || product.sonderkondition != null)
              const Divider(height: 32, color: Colors.white24),

            // Row 7: Price Row
            _buildPriceRow(),
            const SizedBox(height: 24),

            // Row 8: Action Buttons
            _buildActionButtons(context, ref),
          ],
        ),
      ),
    );
  }

  // --- NEW WIDGETS FOR THE OVERHAULED LAYOUT ---

  /// Row 1: Shop Logo (left) | Active List Selector (right)
  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        StoreLogo(storeName: product.store, height: 48),
        const Spacer(), // Pushes the button to the right
        _buildActiveListButton(context, ref),
      ],
    );
  }

  /// The button for the Active List Selector, now inside the details page.
  Widget _buildActiveListButton(BuildContext context, WidgetRef ref) {
    final activeList = ref.watch(activeShoppingListProvider);
    final buttonText = activeList ?? 'Select List';

    return TextButton.icon(
      icon: const Icon(Icons.playlist_add_check, color: AppColors.secondary, size: 20),
      label: Text(
        buttonText,
        style: const TextStyle(color: AppColors.inactive, fontWeight: FontWeight.bold),
        overflow: TextOverflow.ellipsis,
      ),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          useRootNavigator: true,
          backgroundColor: AppColors.background,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) => const ActiveListSelectorBottomSheet(),
        );
      },
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          side: BorderSide(color: AppColors.inactive.withAlpha(128)),
        ),
      ),
    );
  }

  // --- MODIFIED WIDGET ---
  /// Row 2: Category and Subcategory Chips.
  /// These chips expand to fill the available width equally, ensuring a balanced and
  /// responsive layout. The padding between them is fixed and consistent.
  Widget _buildCategoryRows() {
    // A constant for consistent spacing between the chips.
    const double horizontalSpacing = 16.0;

    return Row(
      children: [
        // The main category chip. It expands to fill the available space.
        // If there is no subcategory, it will take up the entire row.
        Expanded(
          child: CategoryChip(categoryName: product.category),
        ),
        // Only show the subcategory and the space between if a subcategory exists.
        if (product.subcategory.isNotEmpty) ...[
          const SizedBox(width: horizontalSpacing),
          // The subcategory chip. It also expands, sharing space equally
          // with the main category chip thanks to the Expanded widget.
          Expanded(
            child: CategoryChip(categoryName: product.subcategory),
          ),
        ],
      ],
    );
  }


  /// Row 5: Displays the "Available From" date if it exists.
  Widget _buildAvailabilityInfo() {
    if (product.availableFrom == null) {
      return const SizedBox.shrink(); // Don't show anything if no date
    }
    // Format the date for German locale, e.g., "15. August 2023"
    final formattedDate = DateFormat.yMMMMd('de_DE').format(product.availableFrom!);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, color: AppColors.inactive, size: 16),
          const SizedBox(width: 8),
          Text(
            'Verfügbar ab: $formattedDate',
            style: const TextStyle(color: AppColors.inactive, fontSize: 14),
          ),
        ],
      ),
    );
  }

  /// Row 6: Displays the "Sonderkondition" text if it exists.
  Widget _buildSonderkonditionInfo() {
    if (product.sonderkondition == null || product.sonderkondition!.isEmpty) {
      return const SizedBox.shrink(); // Don't show if empty or null
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          const Icon(Icons.star_border, color: AppColors.secondary, size: 18),
          const SizedBox(width: 8),
          Expanded( // Use Expanded to allow text to wrap
            child: Text(
              product.sonderkondition!,
              style: const TextStyle(color: AppColors.secondary, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // --- EXISTING WIDGETS (UNCHANGED LOGIC, JUST REPOSITIONED) ---

  /// Row 3: Product Title
  Widget _buildProductName() {
    return SizedBox(
      height: 85.0,
      child: Text(
        product.name,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// Row 4: Image Container
  Widget _buildImageContainer() {
    return Container(
      height: 300,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ImageWithAspectRatio(
          imageUrl: product.imageUrl,
          maxWidth: double.infinity,
          maxHeight: 300,
        ),
      ),
    );
  }

  /// Row 7: Price Row
  Widget _buildPriceRow() {
    final cleanPercentage = product.discountPercentage.replaceAll(RegExp(r'[^0-9.]'), '');
    return Row(
      children: [
        Expanded(child: _priceBox(product.normalPrice.toStringAsFixed(2), Colors.grey.shade300, const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, decoration: TextDecoration.lineThrough, color: Colors.black54,),),),
        const SizedBox(width: 8),
        Expanded(child: _priceBox('$cleanPercentage%', Colors.redAccent, const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white,),),),
        const SizedBox(width: 8),
        Expanded(child: _priceBox(product.currentPrice.toStringAsFixed(2), Colors.yellow.shade600, const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.black,),),),
      ],
    );
  }

  Widget _priceBox(String value, Color bgColor, TextStyle textStyle) {
    return Container(
      height: 75,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
      child: Text(value, style: textStyle, textAlign: TextAlign.center),
    );
  }

  /// Row 8: Action Buttons
  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(child: _buildActionButton(context: context, icon: Icons.open_in_new, label: 'Visit Product', onPressed: () => _launchURL(context, product.url),),),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            context: context,
            icon: Icons.add_shopping_cart,
            label: 'Save to list',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: AppColors.background,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                builder: (_) => ShoppingListBottomSheet(product: product, onConfirm: (String selectedListName) {},),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 20, color: AppColors.primary),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textBlack,),),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.secondary,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _launchURL(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not open product link")));
    }
  }
}