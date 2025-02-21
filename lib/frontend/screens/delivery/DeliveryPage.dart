import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hawalik/assets/widgets/const.dart';
import '../SelectLocationPage.dart';

class DeliveryPage extends StatefulWidget {
  @override
  _DeliveryPageState createState() => _DeliveryPageState();
}

class _DeliveryPageState extends State<DeliveryPage> {
  LatLng? pickupLocation;
  LatLng? dropoffLocation;
  double deliveryCost = 0.0;
  String selectedProductType = 'Food';
  String paymentOption = 'Receiver';
  TextEditingController senderPhoneController = TextEditingController();
  TextEditingController receiverPhoneController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    senderPhoneController.dispose();
    receiverPhoneController.dispose();
    super.dispose();
  }

  Future<void> _selectLocation(bool isPickup) async {
    LatLng? selectedLocation = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SelectLocationPage()),
    );

    if (selectedLocation != null) {
      setState(() {
        if (isPickup) {
          pickupLocation = selectedLocation;
        } else {
          dropoffLocation = selectedLocation;
        }
      });
      _calculateCost();
    }
  }

  Future<double> _calculateDistance() async {
    if (pickupLocation == null || dropoffLocation == null) return 0.0;
    double distanceInMeters = Geolocator.distanceBetween(
      pickupLocation!.latitude,
      pickupLocation!.longitude,
      dropoffLocation!.latitude,
      dropoffLocation!.longitude,
    );
    return distanceInMeters / 1000; // Convert to kilometers
  }

  Future<void> _calculateCost() async {
    if (pickupLocation == null || dropoffLocation == null) return;
    setState(() => isLoading = true);
    double distance = await _calculateDistance();
    double costPerKm = 0.6;
    setState(() {
      deliveryCost = distance * costPerKm;
      isLoading = false;
    });
  }

  bool _isValidJordanianPhoneNumber(String phoneNumber) {
    // Check if the phone number starts with 07 and has 10 digits
    return phoneNumber.startsWith('07') && phoneNumber.length == 10;
  }

  Future<void> _saveOrderToFirestore() async {
    if (pickupLocation == null || dropoffLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Please select both pickup and drop-off locations.")),
      );
      return;
    }

    if (senderPhoneController.text.isEmpty ||
        receiverPhoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text("Please enter both sender and receiver phone numbers.")),
      );
      return;
    }

    if (!_isValidJordanianPhoneNumber(senderPhoneController.text) ||
        !_isValidJordanianPhoneNumber(receiverPhoneController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter valid Jordanian phone numbers.")),
      );
      return;
    }

    setState(() => isLoading = true);
    await _calculateCost();
    try {
      DocumentReference orderRef =
          FirebaseFirestore.instance.collection('orders').doc();
      await orderRef.set({
        'orderId': orderRef.id,
        'pickupLocation': {
          'latitude': pickupLocation!.latitude,
          'longitude': pickupLocation!.longitude,
        },
        'dropoffLocation': {
          'latitude': dropoffLocation!.latitude,
          'longitude': dropoffLocation!.longitude,
        },
        'senderPhone': senderPhoneController.text,
        'receiverPhone': receiverPhoneController.text,
        'productType': selectedProductType,
        'paymentOption': paymentOption,
        'deliveryCost': deliveryCost,
        'timestamp': FieldValue.serverTimestamp(),
      });

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Success"),
            content: Text(
                "Order successfully sent! Cost: ${deliveryCost.toStringAsFixed(2)} JD"),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("OK")),
            ],
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send order: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: screenHeight * 0.32,
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
                    "Track your orders in real time",
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildLocationSelector('Pickup Location', true),
                  SizedBox(height: 16),
                  _buildLocationSelector('Drop-off Location', false),
                  SizedBox(height: 16),
                  _buildTextField('Sender Phone Number', senderPhoneController),
                  SizedBox(height: 16),
                  _buildTextField(
                      'Receiver Phone Number', receiverPhoneController),
                  SizedBox(height: 16),
                  _buildDropdown(
                      "Product Type",
                      ['Food', 'Documents', 'Electronics', 'Clothes'],
                      selectedProductType, (value) {
                    setState(() => selectedProductType = value!);
                  }),
                  SizedBox(height: 16),
                  _buildDropdown(
                      "Payment Option", ['Receiver', 'Sender'], paymentOption,
                      (value) {
                    setState(() => paymentOption = value!);
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Container(
          color: kbackground,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Cost: ${deliveryCost.toStringAsFixed(2)} JD",
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              ElevatedButton(
                style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all(Colors.lightBlue)),
                onPressed: isLoading ? null : _saveOrderToFirestore,
                child: isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Confirm Order',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSelector(String title, bool isPickup) {
    return GestureDetector(
      onTap: () => _selectLocation(isPickup),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(10),
          color: Colors.grey[200],
        ),
        child: Text(
          isPickup
              ? (pickupLocation != null
                  ? "Pickup: ${pickupLocation!.latitude}, ${pickupLocation!.longitude}"
                  : "Tap to select pickup location")
              : (dropoffLocation != null
                  ? "Drop-off: ${dropoffLocation!.latitude}, ${dropoffLocation!.longitude}"
                  : "Tap to select drop-off location"),
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration:
          InputDecoration(labelText: label, border: OutlineInputBorder()),
      keyboardType: TextInputType.phone,
    );
  }

  Widget _buildDropdown(String label, List<String> items, String selectedValue,
      ValueChanged<String?> onChanged) {
    return DropdownButtonFormField(
      value: selectedValue,
      onChanged: onChanged,
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      decoration:
          InputDecoration(labelText: label, border: OutlineInputBorder()),
    );
  }
}
