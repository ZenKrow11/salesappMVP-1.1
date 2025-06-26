import 'package:flutter/material.dart';
import 'package:sales_app_mvp/widgets/image_aspect_ratio.dart';
import 'package:sales_app_mvp/widgets/theme_color.dart';
import '../models/product.dart';

class ProductTile extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductTile({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onTap,
        child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    margin: EdgeInsets.zero,
    child: Container(
    height: 180,
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
    color: AppColors.primary,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
    ),
    child: _buildContent(context),
    ),
    ),
    );
    }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        _buildHeaderRow(),
        const SizedBox(height: 6),
        Expanded(
          child: ClipRect(
            child: ImageWithAspectRatio(
                imageUrl: product.imageUrl,
                maxHeight: double.infinity,
                maxWidth: double.infinity,
            ),
          ),
        ),
        const SizedBox(height: 6),
        _buildPriceRow(),
      ],
    );
  }

  Widget _buildHeaderRow() {
    return Row(
      children: [
        Expanded(
          child: Text(
            product.store,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                color: AppColors.textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: Text(
            product.name,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                color: AppColors.textPrimary),
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow({double fontSize = 12}) {
    return Row(
      children: [
        _priceBox(
          text: '${product.discountPercentage}%',
          bgColor: Colors.red,
          textStyle: TextStyle(
            fontSize: fontSize,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        _priceBox(
          text: product.currentPrice.toStringAsFixed(2),
          bgColor: Colors.yellow[600],
          textStyle: TextStyle(
            fontSize: fontSize + 2,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _priceBox({
    required String text,
    required Color? bgColor,
    required TextStyle textStyle,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: textStyle,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}