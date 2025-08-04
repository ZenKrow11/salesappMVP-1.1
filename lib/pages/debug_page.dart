import 'package:flutter/material.dart';

class DebugPage extends StatelessWidget {
  final Map<String, List<String>> categoryData = {
    'Fruits': ['Apple', 'Banana', 'Orange'],
    'Vegetables': ['Carrot', 'Broccoli', 'Spinach'],
    'Dairy': ['Milk', 'Cheese', 'Yogurt'],
    'Bakery': ['Bread', 'Croissant', 'Muffin'],
  };

  final Map<String, Color> categoryColors = {
    'Fruits': Colors.orange,
    'Vegetables': Colors.green,
    'Dairy': Colors.blue,
    'Bakery': Colors.brown,
  };

  DebugPage({super.key});

  Color darken(Color color, [double amount = .15]) {
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug Page')),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: categoryData.length,
        itemBuilder: (context, index) {
          final category = categoryData.keys.elementAt(index);
          final items = categoryData[category]!;
          final color = categoryColors[category] ?? Colors.grey;
          final darker = darken(color);

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: darker,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Text(
                    category,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                ...items.map((item) => ListTile(
                  title: Text(item),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                )),
              ],
            ),
          );
        },
      ),
    );
  }
}
