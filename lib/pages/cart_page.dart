import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart';
import 'category_page.dart';
import 'scan_page.dart';
import 'reminder_page.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  Future<void> _updateQuantity(
      DocumentReference docRef, int currentQty, bool increase) async {
    int newQty = increase ? currentQty + 1 : currentQty - 1;

    if (newQty > 0) {
      await docRef.update({'quantity': newQty});
    }
    // ❌ No delete here — won't remove item at qty=1
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    final cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .orderBy('added_at', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Cart"),
        backgroundColor: const Color(0xFFF6FFDE),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: cartRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final items = snapshot.data?.docs ?? [];

          if (items.isEmpty) {
            return const Center(child: Text("Your cart is empty"));
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final doc = items[index];
              final data = doc.data() as Map<String, dynamic>;
              final name = data['name'] ?? '';
              final quantity = (data['quantity'] ?? 1) as int;
              final unit = data['unit'] ?? '';

              return Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal[300],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    // Product info
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
                          Text("Unit: $unit",
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 14)),
                        ],
                      ),
                    ),

                    // Quantity selector
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.remove_circle,
                            color: quantity > 1
                                ? Colors.white
                                : Colors.white24, // greyed out at 1
                          ),
                          onPressed: quantity > 1
                              ? () async {
                                  await _updateQuantity(
                                      doc.reference, quantity, false);
                                }
                              : null, // disabled at 1
                        ),
                        Text(
                          "$quantity",
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle,
                              color: Colors.white),
                          onPressed: () async {
                            await _updateQuantity(doc.reference, quantity, true);
                          },
                        ),
                      ],
                    ),

                    // Delete button with confirmation
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.white),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: const Color(0xFFF6FFDE),
                            title: const Text("Confirm Delete"),
                            content: Text(
                                "Are you sure you want to remove \"$name\" from your cart?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text(
                                  "Cancel",
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red),
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text(
                                  "Delete",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          try {
                            await doc.reference.delete();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text("$name removed from cart 🗑️")),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error: $e")),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),

      // 🔹 Updated bottom navbar with hover effect
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
              isActive: true, // 👈 active page
              onTap: () {}, // does nothing
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
              isActive: false,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReminderPage()),
              ),
            ),
          ],
        ),
      ),
    );
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
