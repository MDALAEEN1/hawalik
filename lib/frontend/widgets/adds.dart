import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddsinHomepage extends StatefulWidget {
  const AddsinHomepage({super.key});

  @override
  _AddsinHomepageState createState() => _AddsinHomepageState();
}

class _AddsinHomepageState extends State<AddsinHomepage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PageController _pageController = PageController();
  List<String> _adsImages = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchAds();
    _startAutoScroll();
  }

  /// 🔹 **جلب الصور من Firestore**
  Future<void> _fetchAds() async {
    var snapshot = await _firestore.collection('ads').get();
    setState(() {
      _adsImages =
          snapshot.docs.map((doc) => doc['imageUrl'] as String).toList();
    });
  }

  /// 🔹 **تغيير الصورة تلقائياً كل 5 ثوانٍ**
  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 5), () {
      if (_adsImages.isNotEmpty && mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _adsImages.length;
          _pageController.animateToPage(
            _currentIndex,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        });
        _startAutoScroll();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: _adsImages.isEmpty
          ? const Center(
              child:
                  CircularProgressIndicator()) // في حال لم يتم تحميل الصور بعد
          : PageView.builder(
              controller: _pageController,
              itemCount: _adsImages.length,
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: Image.network(_adsImages[index], fit: BoxFit.cover),
                );
              },
            ),
    );
  }
}
