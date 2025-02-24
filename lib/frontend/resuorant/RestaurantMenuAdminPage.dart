import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RestaurantMenuPage extends StatefulWidget {
  final String restaurantId;

  const RestaurantMenuPage({super.key, required this.restaurantId});

  @override
  _RestaurantMenuPageState createState() => _RestaurantMenuPageState();
}

class _RestaurantMenuPageState extends State<RestaurantMenuPage> {
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _productDescriptionController =
      TextEditingController();
  final TextEditingController _productPriceController = TextEditingController();
  final TextEditingController _productImageController = TextEditingController();
  final TextEditingController _ingredientsController = TextEditingController();

  String _selectedCategory = ''; // 🔹 الفئة الافتراضية

  final List<String> _categories = [
    'Pizza',
    'Burger',
    'Fish',
    'Pasta',
    'Dessert',
    'Drinks',
    'Breakfast'
  ];

  // إضافة منتج جديد
  void _addProduct() async {
    final name = _productNameController.text;
    final description = _productDescriptionController.text;
    final price = _productPriceController.text;
    final imageUrl = _productImageController.text;
    final ingredients =
        _ingredientsController.text.split(',').map((e) => e.trim()).toList();

    if (name.isEmpty ||
        description.isEmpty ||
        price.isEmpty ||
        imageUrl.isEmpty ||
        ingredients.isEmpty) {
      _showSnackBar('يرجى ملء جميع الحقول');
      return;
    }

    await FirebaseFirestore.instance
        .collection('restaurants')
        .doc(widget.restaurantId)
        .collection('menu')
        .add({
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'ingredients': ingredients,
      'category': _selectedCategory, // 🔹 تخزين الفئة المختارة
    });

    _clearTextFields();
  }

  // حذف منتج
  void _deleteProduct(String productId) async {
    await FirebaseFirestore.instance
        .collection('restaurants')
        .doc(widget.restaurantId)
        .collection('menu')
        .doc(productId)
        .delete();
  }

  // تعديل منتج
  void _editProduct(String productId) async {
    final productRef = FirebaseFirestore.instance
        .collection('restaurants')
        .doc(widget.restaurantId)
        .collection('menu')
        .doc(productId);

    final productData = await productRef.get();
    final product = productData.data();

    if (product != null) {
      _productNameController.text = product['name'];
      _productDescriptionController.text = product['description'];
      _productPriceController.text = product['price'];
      _productImageController.text = product['imageUrl'];
      _ingredientsController.text = product['ingredients'].join(', ');
      _selectedCategory =
          product['category'] ?? 'pizza'; // 🔹 تعبئة الفئة الحالية

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('تعديل المنتج'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTextField(_productNameController, 'الاسم'),
                  _buildTextField(_productDescriptionController, 'الوصف'),
                  _buildTextField(_productPriceController, 'السعر'),
                  _buildTextField(_productImageController, 'رابط الصورة'),
                  _buildTextField(
                      _ingredientsController, 'المكونات (فصلها بفواصل)'),
                  const SizedBox(height: 10),
                  _buildCategoryDropdown(), // 🔹 إضافة القائمة المنسدلة
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  productRef.update({
                    'name': _productNameController.text,
                    'description': _productDescriptionController.text,
                    'price': _productPriceController.text,
                    'imageUrl': _productImageController.text,
                    'ingredients': _ingredientsController.text
                        .split(',')
                        .map((e) => e.trim())
                        .toList(),
                    'category': _selectedCategory, // 🔹 تحديث الفئة
                  });

                  _clearTextFields();
                  Navigator.pop(context);
                },
                child: const Text('حفظ التعديلات'),
              ),
            ],
          );
        },
      );
    }
  }

  // مسح الحقول
  void _clearTextFields() {
    _productNameController.clear();
    _productDescriptionController.clear();
    _productPriceController.clear();
    _productImageController.clear();
    _ingredientsController.clear();
    setState(() {
      _selectedCategory = 'pizza'; // 🔹 إعادة ضبط الفئة
    });
  }

  // عرض رسالة SnackBar
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // بناء حقل إدخال
  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
      ),
    );
  }

  // بناء القائمة المنسدلة
  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _categories.contains(_selectedCategory)
          ? _selectedCategory
          : _categories.first, // ✅ التأكد من أن القيمة موجودة
      items: _categories.map((category) {
        return DropdownMenuItem<String>(
          value: category,
          child: Text(category.toUpperCase()),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategory = value!;
        });
      },
      decoration: const InputDecoration(
        labelText: 'نوع المنتج',
        border: OutlineInputBorder(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المنتجات'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // قسم إضافة منتج
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTextField(_productNameController, 'الاسم'),
                _buildTextField(_productDescriptionController, 'الوصف'),
                _buildTextField(_productPriceController, 'السعر'),
                _buildTextField(_productImageController, 'رابط الصورة'),
                _buildTextField(
                    _ingredientsController, 'المكونات (فصلها بفواصل)'),
                const SizedBox(height: 10),
                _buildCategoryDropdown(), // 🔹 إضافة القائمة المنسدلة
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _addProduct,
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all(Colors.lightBlue),
                  ),
                  child: const Text('إضافة منتج'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // قسم عرض المنتجات
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('restaurants')
                  .doc(widget.restaurantId)
                  .collection('menu')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final products = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index].data();
                    final productId = products[index].id;
                    return ListTile(
                      title: Text(
                          "${product['name']} (${product['category']})"), // 🔹 عرض الفئة
                      subtitle: Text('السعر: ${product['price']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editProduct(productId)),
                          IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteProduct(productId)),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
