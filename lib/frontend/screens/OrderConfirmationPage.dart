import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hawalik/assets/widgets/const.dart';
import 'package:hawalik/frontend/screens/SelectLocationPage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OrderConfirmationPage extends StatefulWidget {
  final double totalAmount;
  final String restaurantId;
  final List<Map<String, dynamic>> cartItems; // قائمة المنتجات
  const OrderConfirmationPage({
    super.key,
    required this.totalAmount,
    required this.restaurantId,
    required this.cartItems,
  });

  @override
  State<OrderConfirmationPage> createState() => _OrderConfirmationPageState();
}

class _OrderConfirmationPageState extends State<OrderConfirmationPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  double deliveryFee = 0.0;
  String userName = "";
  String userPhone = "";
  LatLng? userLocation;
  LatLng storeLocation = const LatLng(31.172612290451756, 35.71025390177965);

  @override
  void initState() {
    super.initState();
    _getUserData();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      _getUserLocation();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permission denied")),
      );
    }
  }

  Future<void> _getUserData() async {
    final userDoc =
        await _firestore.collection('users').doc(_auth.currentUser?.uid).get();
    if (userDoc.exists) {
      setState(() {
        userName = userDoc.data()?['firstName'] ?? "Unknown";
        userPhone = userDoc.data()?['email'] ?? "No Phone";
      });
    }
  }

  Future<void> _getUserLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        userLocation = LatLng(position.latitude, position.longitude);
        _calculateDeliveryFee();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Failed to get location. Please enable GPS.")),
      );
    }
  }

  Future<void> _calculateDeliveryFee() async {
    if (userLocation == null) return;

    const String apiKey = "google map api";
    final String url =
        "https://maps.googleapis.com/maps/api/distancematrix/json?origins=${storeLocation.latitude},${storeLocation.longitude}&destinations=${userLocation!.latitude},${userLocation!.longitude}&mode=driving&key=$apiKey";

    try {
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);

      print("Google API Response: ${response.body}");

      if (data["rows"].isNotEmpty &&
          data["rows"][0]["elements"].isNotEmpty &&
          data["rows"][0]["elements"][0]["status"] == "OK") {
        int distanceInMeters =
            data["rows"][0]["elements"][0]["distance"]["value"];
        setState(() {
          deliveryFee = (distanceInMeters / 1000) * 0.45;
        });
      } else {
        print("Error: No valid distance found.");
      }
    } catch (e) {
      print("Error fetching distance: $e");
    }
  }

  Future<void> _confirmOrder() async {
    if (userLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❗ يرجى تحديد موقعك قبل تأكيد الطلب"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      DocumentReference orderRef = await _firestore.collection('orders').add({
        'userId': _auth.currentUser?.uid,
        'userName': userName,
        'userPhone': userPhone,
        'totalAmount': widget.totalAmount + deliveryFee,
        'restaurantId': widget.restaurantId,
        'deliveryFee': deliveryFee,
        'orderAmount': widget.totalAmount,
        'userLocation': {
          'latitude': userLocation!.latitude,
          'longitude': userLocation!.longitude,
        },
        'status': 'قيد التحضير',
        'timestamp': FieldValue.serverTimestamp(),
        'products': widget.cartItems, // إضافة قائمة المنتجات
      });

      String orderId = orderRef.id; // 🔹 حفظ الـ orderId الجديد

      await _clearCartForRestaurant(widget.restaurantId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ تم تأكيد الطلب بنجاح")),
      );

      // 🔹 تمرير orderId عند الانتقال إلى CartPage
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ حدث خطأ أثناء تأكيد الطلب: $e")),
      );
    }
  }

  Future<void> _clearCartForRestaurant(String restaurantId) async {
    try {
      final cartCollection = _firestore
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .collection('cart');

      final cartItems = await cartCollection
          .where('restaurantId', isEqualTo: restaurantId)
          .get();

      for (var doc in cartItems.docs) {
        await doc.reference.delete();
      }

      print("Cart items from restaurant $restaurantId cleared successfully");
    } catch (e) {
      print("Error clearing cart for restaurant $restaurantId: $e");
    }
  }

  void _openMap() async {
    LatLng? selectedLocation = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SelectLocationPage()),
    );

    if (selectedLocation != null) {
      setState(() {
        userLocation = selectedLocation;
      });
      _calculateDeliveryFee();
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalWithDelivery = widget.totalAmount + deliveryFee;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kapp,
        title: const Text(
          "Confirm Order",
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "👤 Name: $userName",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "📞 Phone: $userPhone",
                      style: const TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "🚚 Delivery Fee: JD${deliveryFee.toStringAsFixed(2)}",
                          style:
                              const TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        const Divider(),
                        Text(
                          "💰 Total Price: JD${totalWithDelivery.toStringAsFixed(2)}",
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _openMap,
                  icon: const Icon(Icons.map),
                  label: const Text("Select Location on Map"),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _confirmOrder,
                  icon: const Icon(Icons.check),
                  label: const Text("Confirm Order"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
