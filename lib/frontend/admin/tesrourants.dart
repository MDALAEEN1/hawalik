import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // تهيئة Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'إدارة المطاعم',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: RestaurantsPage(),
    );
  }
}

class RestaurantsPage extends StatefulWidget {
  @override
  _RestaurantsPageState createState() => _RestaurantsPageState();
}

class _RestaurantsPageState extends State<RestaurantsPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();

  void _addRestaurant() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إضافة مطعم جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'اسم المطعم'),
            ),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(labelText: 'الموقع'),
            ),
            TextField(
              controller: _imageUrlController,
              decoration: InputDecoration(labelText: 'رابط الصورة'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: _saveRestaurant,
            child: Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _saveRestaurant() async {
    if (_nameController.text.isNotEmpty &&
        _locationController.text.isNotEmpty &&
        _imageUrlController.text.isNotEmpty) {
      await FirebaseFirestore.instance.collection('restaurants').add({
        'name': _nameController.text,
        'imageUrl': _imageUrlController.text,
        'location': _locationController.text,
        'createdAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إضافة المطعم بنجاح!')),
      );

      _nameController.clear();
      _locationController.clear();
      _imageUrlController.clear();
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('يرجى إدخال جميع البيانات')),
      );
    }
  }

  void _confirmDelete(String restaurantId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('حذف المطعم'),
        content: Text(
            'هل أنت متأكد أنك تريد حذف هذا المطعم؟ لا يمكن التراجع عن هذه العملية.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteRestaurant(restaurantId);
              Navigator.pop(context);
            },
            child: Text('حذف', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  void _deleteRestaurant(String restaurantId) async {
    await FirebaseFirestore.instance
        .collection('restaurants')
        .doc(restaurantId)
        .delete();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم حذف المطعم بنجاح!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('إدارة المطاعم')),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection('restaurants').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ أثناء تحميل البيانات'));
          }

          final restaurants = snapshot.data!.docs;

          return ListView.builder(
            itemCount: restaurants.length,
            itemBuilder: (context, index) {
              final restaurant = restaurants[index];
              final restaurantId = restaurant.id;
              final restaurantName = restaurant['name'];
              final restaurantImage = restaurant['imageUrl'];
              final restaurantLocation = restaurant['location'];

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  leading: Image.network(
                    restaurantImage,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.broken_image,
                          size: 50, color: Colors.grey);
                    },
                  ),
                  title: Text(
                    restaurantName,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Text(restaurantLocation),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDelete(restaurantId),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addRestaurant,
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
