import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../pages/scan_page.dart';
import '../pages/cart_page.dart';
import '../pages/category_page.dart';
import '../pages/reminder_page.dart';
import '../pages/inventory_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _suggestions = [];

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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Logo + Profile circle
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

              // 🔍 Search bar with autocomplete
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
                  fieldViewBuilder: (context, controller, focusNode, onSubmit) {
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
                            EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onSubmitted: _onSearch,
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),

              // 👇 Grid + tagline scroll together
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Grid
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 360, // tweak for tile size
                          ),
                          child: GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              buildNavButton(
                                context,
                                Icons.camera_alt,
                                "Scan",
                                const ScanPage(),
                              ),
                              buildNavButton(
                                context,
                                Icons.shopping_cart,
                                "Cart",
                                const CartPage(),
                              ),
                              buildNavButton(
                                context,
                                Icons.list,
                                "Pantry",
                                CategoryPage(),
                              ),
                              buildNavButton(
                                context,
                                Icons.alarm,
                                "Reminder",
                                const ReminderPage(),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // 👇 Tagline aligned with left edge of grid
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 360,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Your\nKitchen’s\nSmartest\nCompanion.",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal[900],
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
              isActive: true, // 👈 active page
              onTap: () {}, // does nothing
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

  // 🔥 Button with hover + click effect for grid
  static Widget buildNavButton(
      BuildContext context, IconData icon, String title, Widget page) {
    final ValueNotifier<bool> isHovered = ValueNotifier<bool>(false);

    return MouseRegion(
      onEnter: (_) => isHovered.value = true,
      onExit: (_) => isHovered.value = false,
      child: ValueListenableBuilder<bool>(
        valueListenable: isHovered,
        builder: (context, hovered, child) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: hovered ? Colors.teal[400] : Colors.teal[300],
              borderRadius: BorderRadius.circular(14),
              boxShadow: hovered
                  ? [
                      const BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(2, 4),
                      )
                    ]
                  : [],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                splashColor: Colors.white.withOpacity(0.3),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => page),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: Colors.white, size: 36),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // 🔹 Bottom navbar icon with hover + active state
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
