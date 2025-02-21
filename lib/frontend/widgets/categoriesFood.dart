import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class RestaurantCategories extends StatelessWidget {
  const RestaurantCategories({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> categories = [
      {
        "name": "Pizza",
        "icon": "lib/assets/icons/pizza.png",
        "iconColor": Colors.orange
      },
      {
        "name": "Burger",
        "icon": "lib/assets/icons/burger.png",
        "iconColor": Colors.red
      },
      {
        "name": "Fish",
        "icon": "lib/assets/icons/fish.png",
        "iconColor": Colors.blue
      },
      {
        "name": "Pasta",
        "icon": "lib/assets/icons/spaghetti.png",
        "iconColor": Colors.green
      },
      {
        "name": "Dessert",
        "icon": "lib/assets/icons/cake.png",
        "iconColor": Colors.pink
      },
      {
        "name": "Drinks",
        "icon": "lib/assets/icons/drink.png",
        "iconColor": Colors.purple
      },
      {
        "name": "Breakfast",
        "icon": "lib/assets/icons/breakfast.png",
        "iconColor": Colors.amber
      },
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              const Text(
                "Categories",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: GestureDetector(
                  onTap: () {
                    // التنقل إلى صفحة FilterPage وتمرير اسم الفئة
                    Navigator.pushNamed(
                      context,
                      '/filterPage',
                      arguments: {"category": category["name"]},
                    );
                  },
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.grey[300], // خلفية رمادية
                        child: category["icon"] is String
                            ? Image.asset(category["icon"],
                                width: 40, height: 40)
                            : Icon(category["icon"],
                                color: category["iconColor"], size: 40),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category["name"],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
