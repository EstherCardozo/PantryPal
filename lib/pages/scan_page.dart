import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'home_page.dart';
import 'category_page.dart';
import 'cart_page.dart';
import 'reminder_page.dart';
import 'package:pantrypal/service/product_service.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _expiryController = TextEditingController();

  String? _selectedUnit = 'g';
  String? _selectedCategory = 'Fruits & Vegetables';
  String? _barcode;
  bool _isLoading = false;
  String? _error;

  final List<String> _units = ['g', 'kg', 'ml', 'l', 'pcs'];
  final List<String> _categories = [
    'Fruits & Vegetables',
    'Dairy Products',
    'Poultry & Meat',
    'Herbs & Spices',
    'Medicines',
    'Cereals & Grains',
    'Snacks',
  ];

  /// 🔹 Robust parser for product name to extract quantity/unit
  Map<String, String> parseNameQuantityUnit(String rawName) {
    final unitMap = {
      'g': 'g', 'grams': 'g', 'gm': 'g',
      'kg': 'kg', 'kilogram': 'kg', 'kgs': 'kg',
      'ml': 'ml', 'millilitre': 'ml', 'milliliters': 'ml',
      'l': 'l', 'liter': 'l', 'litre': 'l',
      'pcs': 'pcs', 'piece': 'pcs', 'pieces': 'pcs',
    };

    final regex = RegExp(r'(\d+(\.\d+)?)\s*([a-zA-Z]+)');
    final matches = regex.allMatches(rawName);

    String? quantity;
    String? unit;
    String name = rawName;

    if (matches.isNotEmpty) {
      for (final m in matches) {
        final numStr = m.group(1)!;
        final unitStr = m.group(3)!.toLowerCase();
        if (unitMap.containsKey(unitStr)) {
          quantity = numStr;
          unit = unitMap[unitStr];
          name = rawName.replaceFirst(m.group(0)!, '').trim();
          break;
        }
      }
    }

    return {
      'name': name,
      'quantity': quantity ?? '',
      'unit': unit ?? 'g',
    };
  }

  /// 🔹 Show popup scanner
  Future<void> _scanBarcode() async {
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        final width = MediaQuery.of(context).size.width * 0.8;
        final height = MediaQuery.of(context).size.height * 0.6;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SizedBox(
            width: width,
            height: height,
            child: Column(
              children: [
                AppBar(
                  title: const Text("Scan Barcode"),
                  automaticallyImplyLeading: false,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Expanded(
                  child: MobileScanner(
                    onDetect: (barcodeCapture) {
                      final String? value = barcodeCapture.barcodes.first.rawValue;
                      if (value != null) {
                        Navigator.pop(context, value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _barcode = result;
        _isLoading = true;
        _error = null;
      });

      final product = await ProductService.fetchProductInfo(result);

      if (product != null && product['product_name'] != null) {
        final parsed = parseNameQuantityUnit(product['product_name']);
        _nameController.text = parsed['name']!;
        _quantityController.text = parsed['quantity']!;
        _selectedUnit = parsed['unit'];

        if (product['categories'] != null && product['categories'].isNotEmpty) {
          final apiCategories = product['categories'].toString().split(',');
          final matchedCategory = _categories.firstWhere(
            (cat) => apiCategories.any(
              (apiCat) => apiCat.toLowerCase().trim().contains(cat.toLowerCase()),
            ),
            orElse: () => _selectedCategory!,
          );
          _selectedCategory = matchedCategory;
        }

        String? expiryStr;
        if (product['expiration_date'] != null) {
          expiryStr = product['expiration_date'].toString();
        } else if (product['best_before_date'] != null) {
          expiryStr = product['best_before_date'].toString();
        }

        if (expiryStr != null) {
          try {
            final parsedDate = DateTime.parse(expiryStr);
            _expiryController.text = DateFormat('yyyy-MM-dd').format(parsedDate);
          } catch (_) {}
        }
      } else {
        _error = "No product found for this barcode.";
      }

      setState(() => _isLoading = false);
    }
  }

  /// 🔹 Save item to Firestore
  Future<void> _addItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not logged in")),
        );
        return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('pantry')
          .add({
        'name': _nameController.text.trim(),
        'quantity': int.tryParse(_quantityController.text.trim()) ?? 0,
        'unit': _selectedUnit,
        'category': _selectedCategory,
        'expiry': _expiryController.text.trim(),
        'barcode': _barcode,
        'added_at': DateTime.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Item added to your pantry ✅")),
      );

      _nameController.clear();
      _quantityController.clear();
      _expiryController.clear();
      setState(() {
        _selectedUnit = 'g';
        _selectedCategory = 'Fruits & Vegetables';
        _barcode = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 🔹 Date picker
  Future<void> _pickExpiryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (picked != null) {
      final formatted = DateFormat('yyyy-MM-dd').format(picked);
      setState(() => _expiryController.text = formatted);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _expiryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Pantry Item"),
        backgroundColor: const Color(0xFFF6FFDE),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _scanBarcode,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text("Scan Barcode"),
              ),
              const SizedBox(height: 12),
              if (_barcode != null)
                Text("Scanned Barcode: $_barcode", style: const TextStyle(fontWeight: FontWeight.bold)),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Item Name'),
                validator: (value) => value == null || value.isEmpty ? 'Enter item name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty ? 'Enter quantity' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedUnit,
                decoration: const InputDecoration(labelText: 'Unit'),
                items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                onChanged: (val) => setState(() => _selectedUnit = val),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _expiryController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Expiry (YYYY-MM-DD)',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: _pickExpiryDate,
                validator: (value) => value == null || value.isEmpty ? 'Select expiry date' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _addItem,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Add Item'),
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
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(2, 2))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavIcon(
              icon: Icons.shopping_cart,
              isActive: false,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage())),
            ),
            _buildNavIcon(
              icon: Icons.home,
              isActive: false,
              onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage())),
            ),
            _buildNavIcon(
              icon: Icons.list,
              isActive: false,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryPage())),
            ),
            _buildNavIcon(
              icon: Icons.camera_alt,
              isActive: true, // Active page
              onTap: () {}, // do nothing
            ),
            _buildNavIcon(
              icon: Icons.alarm, // Reminder icon
              isActive: false,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderPage())),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 Navbar icon with hover + active state
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
