import 'package:flutter/material.dart';
import 'package:hawalik/assets/widgets/const.dart';
import 'package:hawalik/frontend/screens/homePage.dart';
import 'package:hawalik/frontend/screens/myAllStuts.dart';
import 'package:hawalik/frontend/widgets/categoriesFood.dart';
import 'package:hawalik/frontend/widgets/searchfeild.dart';
import 'package:hawalik/frontend/widgets/currentLocation.dart';

class FoodPage extends StatefulWidget {
  const FoodPage({super.key});

  @override
  State<FoodPage> createState() => _FoodPageState();
}

class _FoodPageState extends State<FoodPage> {
  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          // الخلفية البيضاء تمتد على كامل الشاشة
          Container(color: Colors.white),

          // الخلفية الزرقاء تمتد على جزء من الشاشة
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
                    "حواليك, اقرب مما تتخيل",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: ktext,
                        fontFamily: "Cairo"),
                  ),
                ),
              ),
            ),
          ),

          // مربع البحث العائم
          Positioned(
              top: screenHeight * 0.35 - 80 + statusBarHeight,
              left: 0,
              right: 0,
              child: CustomSearchField()),

          // زر الرجوع
          Positioned(
            top: statusBarHeight + 10,
            left: 10,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const Homepage()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ),

          // زر الطلبات الحالية في أقصى اليمين
          Positioned(
            top: statusBarHeight + 10,
            right: 10,
            child: IconButton(
              icon: const Icon(
                Icons.shopping_cart, // أيقونة سلة الطلبات
                color: Colors.white,
                size: 24,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UserOrdersPage()),
                );
              },
            ),
          ),

          // قائمة المواقع الأفقية مع الظل السفلي
          Positioned(
            top: screenHeight * 0.36 - 0 + statusBarHeight,
            left: 0,
            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    "Trending Hot🔥",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // قائمة المواقع
                const Currentlocation(),
                const SizedBox(height: 30),

                // قسم الفئات (Categories)
                const RestaurantCategories(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
