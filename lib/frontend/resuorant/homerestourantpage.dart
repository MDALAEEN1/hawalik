import 'package:flutter/material.dart';
import 'package:hawalik/assets/widgets/const.dart';
import 'package:hawalik/frontend/resuorant/OrdersPage.dart';
import 'package:hawalik/frontend/resuorant/RestaurantMenuAdminPage.dart';
import 'package:lucide_icons/lucide_icons.dart'; // مكتبة أيقونات جميلة

class Homepage extends StatelessWidget {
  final String restaurantId;
  const Homepage({super.key, required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          // الخلفية البيضاء
          Container(color: Colors.white),

          // الخلفية الزرقاء
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.32,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: klistappColor,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    "bomba",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: ktext,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // قائمة الفئات
          Positioned(
            top: screenHeight * 0.32 + statusBarHeight,
            left: 0,
            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    "Categories",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 1),
                SizedBox(
                  height: screenHeight * 0.5,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        GridItem(
                          title: "My Items",
                          icon: LucideIcons.pizza,
                          color: Colors.blueAccent, // لون أزرق فاتح
                          screen: RestaurantMenuPage(
                            restaurantId: restaurantId,
                          ),
                        ),
                        GridItem(
                          title: "Orders",
                          icon: LucideIcons.truck,
                          color: Colors.lightBlue, // لون أزرق فاتح آخر
                          screen: OrdersPage(
                            restaurantId: restaurantId,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GridItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget screen;

  const GridItem({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.screen,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // التنقل إلى الشاشة المحددة
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
      borderRadius: BorderRadius.circular(15),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
