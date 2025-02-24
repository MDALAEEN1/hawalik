import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdsPage extends StatefulWidget {
  @override
  _AdsPageState createState() => _AdsPageState();
}

class _AdsPageState extends State<AdsPage> {
  final TextEditingController _imageUrlController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _addAd() async {
    if (_imageUrlController.text.isNotEmpty) {
      await _firestore
          .collection('ads')
          .add({'imageUrl': _imageUrlController.text});
      _imageUrlController.clear();
      Navigator.pop(context); // إغلاق الـ Dialog بعد إضافة الإعلان
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ تم إضافة الإعلان بنجاح!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ يرجى إدخال رابط الصورة")),
      );
    }
  }

  void _confirmDelete(DocumentReference adRef) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الإعلان'),
        content: const Text(
            'هل أنت متأكد أنك تريد حذف هذا الإعلان؟ لا يمكن التراجع عن هذه العملية.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              adRef.delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("🗑️ تم حذف الإعلان")),
              );
            },
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  void _showAddAdDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("إضافة إعلان جديد"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _imageUrlController,
              decoration:
                  const InputDecoration(labelText: "🔗 أدخل رابط الصورة"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: _addAd,
            child: const Text("➕ إضافة إعلان"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("إدارة الإعلانات")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('ads').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var ads = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: ads.length,
                    itemBuilder: (context, index) {
                      var ad = ads[index];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        child: ListTile(
                          leading: Image.network(
                            ad['imageUrl'],
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.broken_image,
                                  size: 50, color: Colors.grey);
                            },
                          ),
                          title: Text("📢 إعلان رقم ${index + 1}"),
                          subtitle: Text(ad['imageUrl'],
                              overflow: TextOverflow.ellipsis),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDelete(ad.reference),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAdDialog,
        child: const Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
