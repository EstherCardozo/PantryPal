import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'inventory_page.dart';
import 'cart_page.dart';
import 'scan_page.dart';
import 'home_page.dart';
import 'reminder_page.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _suggestions = [];

  final List<Map<String, String>> categories = [
    {"name": "Fruits & Vegetables", "image": "pictures/fresh-fruits-and-vegetables.png"},
    {"name": "Dairy Products", "image": "pictures/dairy-products.png"},
    {"name": "Poultry & Meats", "image": "pictures/fresh-meat.png"},
    {"name": "Herbs & Spices", "image": "pictures/spices.png"},
    {"name": "Medicines", "image": "pictures/medicine-capsules.png"},
    {"name": "Cereals & Grains", "image": "pictures/seeds-and-grains.png"},
    {"name": "Snacks", "image": "pictures/snacks.png"},
    {"name": "All", "image": "pictures/all.png"},
  ];

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final pantrySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('pantry')
        .get();

    // 🔹 Filter duplicates to prevent search dropdown flickering
    final seen = <String>{};
    final uniqueItems = <String>[];

    for (var doc in pantrySnapshot.docs) {
      final data = doc.data();
      final name = (data['name'] ?? '').toString();
      final lower = name.toLowerCase();

      if (!seen.contains(lower) && name.isNotEmpty) {
        seen.add(lower);
        uniqueItems.add(name); // keep original casing
      }
    }

    setState(() {
      _suggestions = uniqueItems;
    });
  }

  void _onSearch(String query) {
    if (query.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InventoryPage(
          category: "All",
          searchQuery: query,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FFDE),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 Same header as HomePage
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: ClipOval(
                      child: Image.asset(
                        'pictures/Logo.png',
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: Colors.teal[300]),
                  )
                ],
              ),
              const SizedBox(height: 20),

              // 🔹 Same search bar as HomePage
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF6FFDE),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                child: Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<String>.empty();
                    }
                    final query = textEditingValue.text.toLowerCase();
                    final filteredOptions = _suggestions.where((option) {
                      final words = option.toLowerCase().split(' ');
                      return words.any((word) => word.startsWith(query));
                    });

                    // 🔹 Deduplicate filtered results to prevent flickering
                    final seen = <String>{};
                    final uniqueOptions = <String>[];
                    
                    for (var option in filteredOptions) {
                      final lower = option.toLowerCase();
                      if (!seen.contains(lower)) {
                        seen.add(lower);
                        uniqueOptions.add(option);
                      }
                    }
                    
                    return uniqueOptions;
                  },
                  onSelected: (String selection) {
                    _searchController.text = selection;
                    _onSearch(selection);
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onSubmit) {
                    _searchController.text = controller.text;
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        hintText: "Search...",
                        prefixIcon: Icon(Icons.search, color: Colors.teal[300]),
                        suffixIcon: Icon(Icons.mic, color: Colors.teal[300]),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onSubmitted: _onSearch,
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),

              // 🔹 Categories Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  children: categories.map((cat) {
                    return _buildCategoryCard(context, cat);
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),

      // 🔹 Bottom nav
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
              isActive: true, // 👈 active page
              onTap: () {}, // does nothing
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

  // 🔥 Reusable category card
  Widget _buildCategoryCard(BuildContext context, Map<String, String> cat) {
    final ValueNotifier<bool> isHovered = ValueNotifier(false);

    return MouseRegion(
      onEnter: (_) => isHovered.value = true,
      onExit: (_) => isHovered.value = false,
      child: ValueListenableBuilder<bool>(
        valueListenable: isHovered,
        builder: (context, hovered, _) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: hovered ? Colors.teal[400] : Colors.teal[300],
              borderRadius: BorderRadius.circular(24),
              boxShadow: hovered
                  ? [
                      const BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(2, 4),
                      )
                    ]
                  : [],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                splashColor: Colors.white.withOpacity(0.3),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InventoryPage(category: cat["name"]!),
                    ),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedScale(
                      scale: hovered ? 1.1 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Image.asset(
                        cat["image"]!,
                        width: 130,
                        height: 125,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      cat["name"]!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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
