import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart';
import 'category_page.dart';
import 'cart_page.dart';
import 'scan_page.dart';

class ReminderPage extends StatelessWidget {
  const ReminderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    final pantryRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('pantry')
        .orderBy('added_at', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Reminder"),
        backgroundColor: const Color(0xFFF6FFDE),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF6FFDE),
      body: StreamBuilder<QuerySnapshot>(
        stream: pantryRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final today = DateTime.now();
          final items = snapshot.data?.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final expiryStr = data['expiry'] ?? '';
            final expiryDate = DateTime.tryParse(expiryStr);
            if (expiryDate == null) return false;
            final remainingDays = expiryDate.difference(today).inDays;
            return remainingDays < 5;
          }).toList() ?? [];

          if (items.isEmpty) {
            return const Center(child: Text("No items expiring soon"));
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final doc = items[index];
              final data = doc.data() as Map<String, dynamic>;
              final name = data['name'] ?? '';
              final quantity = data['quantity']?.toString() ?? '-';
              final unit = data['unit'] ?? '';
              final expiryStr = data['expiry'] ?? '';
              final expiryDate = DateTime.tryParse(expiryStr);
              final remainingDays = expiryDate != null
                  ? expiryDate.difference(today).inDays
                  : null;
              final expiryColor = remainingDays != null
                  ? getExpiryColor(remainingDays)
                  : const Color.fromARGB(255, 153, 209, 255);

              return buildItemCard(
                context,
                doc.id,
                name,
                quantity,
                unit,
                expiryStr,
                expiryColor,
              );
            },
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blueGrey,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(2, 2)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavIcon(
              icon: Icons.shopping_cart,
              isActive: false,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartPage()),
              ),
            ),
            _buildNavIcon(
              icon: Icons.home,
              isActive: false,
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomePage()),
              ),
            ),
            _buildNavIcon(
              icon: Icons.list,
              isActive: false,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CategoryPage()),
              ),
            ),
            _buildNavIcon(
              icon: Icons.camera_alt,
              isActive: false,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScanPage()),
              ),
            ),
            _buildNavIcon(
              icon: Icons.alarm, // Reminder icon
              isActive: true, // 👈 active page
              onTap: () {}, // does nothing
            ),
          ],
        ),
      ),
    );
  }

  Widget buildItemCard(
    BuildContext context,
    String itemId,
    String name,
    String quantity,
    String unit,
    String expiry,
    Color expiryColor,
  ) {
    final user = FirebaseAuth.instance.currentUser;

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal[300],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 4),
                Text("Qty: $quantity $unit",
                    style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.circle, size: 12, color: expiryColor),
                    const SizedBox(width: 6),
                    Text("Expires in less than 5 days",
                        style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
            onPressed: () async {
              if (user == null) return;
              try {
                final cartRef = FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('cart');

                // 🔍 Look for an existing item with same name (case-insensitive) and unit
                final query = await cartRef
                    .where('unit', isEqualTo: unit)
                    .get();

                final existingDoc = query.docs.cast<QueryDocumentSnapshot<Map<String, dynamic>>?>().firstWhere(
                  (doc) => doc != null && (doc['name'] as String).toLowerCase() == name.toLowerCase(),
                  orElse: () => null,
                );

                if (existingDoc != null) {
                  // ✅ Item exists → increment quantity
                  final currentQuantity = existingDoc['quantity'] ?? 0;
                  await existingDoc.reference.update({
                    'quantity': currentQuantity + 1,
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Quantity updated ✅")),
                  );
                } else {
                  // ➕ Add new item with quantity = 1
                  await cartRef.add({
                    'name': name,
                    'unit': unit,
                    'quantity': 1,
                    'added_at': DateTime.now(),
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Item added to cart ✅")),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: $e")),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Color getExpiryColor(int remainingDays) {
    if (remainingDays < 5) return Colors.red;
    if (remainingDays < 20) return Colors.orange;
    return Colors.blue;
  }

  Widget _buildNavIcon({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return _NavIconWidget(
      icon: icon,
      isActive: isActive,
      onTap: onTap,
    );
  }
}

class _NavIconWidget extends StatefulWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavIconWidget({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavIconWidget> createState() => _NavIconWidgetState();
}

class _NavIconWidgetState extends State<_NavIconWidget> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: widget.isActive ? null : widget.onTap,
        child: Icon(
          widget.icon,
          size: 32,
          color: widget.isActive
              ? Colors.teal[200]
              : isHovered
                  ? Colors.grey[300]
                  : Colors.white,
        ),
      ),
    );
  }
}
