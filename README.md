# PantryPal 🥘

PantryPal is a comprehensive Flutter-based mobile application designed to help users efficiently manage their pantry inventory, shopping lists, and food expiration dates. With features like barcode scanning, categorized inventory management, and expiration reminders, PantryPal makes kitchen organization seamless and intuitive.

## Features 🌟

### User Authentication 🔐
- Secure login and registration system
- Firebase Authentication integration
- Email-based authentication
- Password strength validation

### Inventory Management 📦
- Add items manually or via barcode scanning
- Organize items by categories
- Track quantities and units
- Set and monitor expiration dates
- Search functionality with auto-suggestions
- View all items or filter by category

### Barcode Scanning 📱
- Integration with OpenFoodFacts API
- Automatic product information retrieval
- Smart category assignment
- Unit and quantity parsing

### Shopping Cart 🛒
- Add items from inventory
- Adjust quantities easily
- Smart duplicate handling
- Organized by addition date
- Quick access to frequently bought items

### Categories 📑
- Fruits & Vegetables
- Dairy Products
- Poultry & Meats
- Herbs & Spices
- Medicines
- Cereals & Grains
- Snacks

### Expiration Reminders ⏰
- Track expiration dates
- Visual indicators for expiring items
- Sorted view of items by expiration
- Prevent food waste

## Technical Stack 💻

- **Frontend**: Flutter
- **Backend**: Firebase
- **Database**: Cloud Firestore
- **Authentication**: Firebase Auth
- **API Integration**: OpenFoodFacts
- **State Management**: Flutter StatefulWidget

## Prerequisites 📋

Before running the application, ensure you have the following installed:

- Flutter (latest version)
- Dart SDK
- Firebase CLI
- Android Studio / Xcode (for mobile deployment)
- Git

## Setup Instructions 🚀

1. **Clone the Repository**
   ```bash
   git clone <repository-url>
   cd pantrypal
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration**
   - Create a new Firebase project
   - Enable Authentication and Firestore
   - Download and add Firebase configuration files:
     - `google-services.json` for Android
     - `GoogleService-Info.plist` for iOS

4. **Run the App**
   ```bash
   flutter run
   ```

## Project Structure 📁

```
lib/
├── main.dart                 # App entry point
├── service/
│   └── product_service.dart  # API integration
└── pages/
    ├── login_page.dart       # User authentication
    ├── register_page.dart    # User registration
    ├── home_page.dart        # Main dashboard
    ├── category_page.dart    # Category listing
    ├── inventory_page.dart   # Inventory management
    ├── cart_page.dart        # Shopping cart
    ├── scan_page.dart        # Barcode scanning
    └── reminder_page.dart    # Expiration reminders
```

## Usage Guide 📱

1. **Registration/Login**
   - Create an account using email
   - Login with registered credentials

2. **Adding Items**
   - Use barcode scanner for quick addition
   - Manually enter item details
   - Set quantity, unit, and expiration date

3. **Managing Inventory**
   - Browse by categories
   - Search for specific items
   - Update quantities
   - Remove expired items

4. **Shopping Cart**
   - Add items from inventory
   - Adjust quantities
   - Remove items when purchased

5. **Expiration Tracking**
   - Monitor expiration dates
   - Receive notifications for expiring items
   - Sort items by expiration date

## Contributing 🤝

1. Fork the repository
2. Create a new branch
3. Make your changes
4. Submit a pull request

## License 📄

This project is licensed under the MIT License - see the LICENSE file for details.

## Contact 📧

For any queries or suggestions contanct tanishullas04@gmail.com

## Acknowledgments 🙏

- OpenFoodFacts API for product database
- Firebase for backend services
- Flutter team for the amazing framework
