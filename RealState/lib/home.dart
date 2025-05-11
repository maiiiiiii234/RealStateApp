import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:realstate/profile.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'login.dart';
import 'welcome.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Real Estate App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.orange),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String selectedType = 'All';
  List<Map<String, dynamic>> savedProperties = [];

  final List<String> propertyTypes = ['All', 'Apartment', 'House', 'Villa'];

  @override
  void initState() {
    super.initState();
    _loadSavedProperties();
  }

  _loadSavedProperties() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    if (userId == null) return;

    List<String>? savedData = prefs.getStringList('savedProperties_$userId');
    if (savedData != null) {
      setState(() {
        savedProperties = savedData
            .map((item) => jsonDecode(item) as Map<String, dynamic>)
            .toList();
      });
    }
  }

  _saveProperties() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    if (userId == null) return;

    List<String> encodedData =
        savedProperties.map((prop) => jsonEncode(prop)).toList();
    await prefs.setStringList('savedProperties_$userId', encodedData);
  }

  void toggleSave(Map<String, dynamic> property) {
    setState(() {
      if (savedProperties.any((item) => item['Image'] == property['Image'])) {
        savedProperties
            .removeWhere((item) => item['Image'] == property['Image']);
      } else {
        savedProperties.add(property);
      }
      _saveProperties();
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      HomeScreen(
        savedProperties: savedProperties,
        onSave: toggleSave,
        propertyTypes: propertyTypes,
        selectedType: selectedType,
        onTypeChanged: (value) {
          setState(() {
            selectedType = value;
          });
        },
      ),
      SavedScreen(savedProperties: savedProperties),
      ProfilePage(),
      Center(child: Text("Profile Page")),
      SizedBox(),
    ];

    return Scaffold(
      backgroundColor: Color(0xFFE6E6E6),
      appBar: AppBar(
        centerTitle: false,
        elevation: 4,
        backgroundColor: Color(0xff333231),
        foregroundColor: Color(0xFFE6E6E6),
        title: Image.network(
          'https://morshedy.com/assets/front/images/logo-white.png',
          height: 60,
          fit: BoxFit.contain,
        ),
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xffef5c07),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 3) {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text("Logout"),
                content: Text("Are you sure you want to log out?"),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Cancel")),
                  TextButton(
                    onPressed: () async {
                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      String? userId = prefs.getString('userId');
                      if (userId != null) {
                        // await prefs.remove('savedProperties_$userId');
                        await prefs.remove('userId');
                      }
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => WelcomePage()),
                      );
                    },
                    child: Text("Logout", style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
          } else {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Saved'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Logout'),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final List<Map<String, dynamic>> savedProperties;
  final Function(Map<String, dynamic>) onSave;
  final List<String> propertyTypes;
  final String selectedType;
  final Function(String) onTypeChanged;

  HomeScreen({
    required this.savedProperties,
    required this.onSave,
    required this.propertyTypes,
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: DropdownButton<String>(
            isExpanded: true,
            value: selectedType,
            items: propertyTypes
                .map((type) => DropdownMenuItem<String>(
                      value: type,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(type),
                      ),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) onTypeChanged(value);
            },
            iconSize: 30,
            elevation: 5,
            dropdownColor: Colors.white,
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: selectedType == 'All'
                ? FirebaseFirestore.instance.collection('RealState').snapshots()
                : FirebaseFirestore.instance
                    .collection('RealState')
                    .where('Type', isEqualTo: selectedType)
                    .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              final properties = snapshot.data!.docs
                  .map((doc) => doc.data() as Map<String, dynamic>)
                  .toList();

              if (properties.isEmpty) {
                return Center(
                  child: Text("No ${selectedType.toLowerCase()} found.",
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: properties.length,
                itemBuilder: (context, index) {
                  final property = properties[index];
                  final isSaved = savedProperties
                      .any((item) => item['Image'] == property['Image']);
                  return PropertyCard(
                    image: property['Image'],
                    title: property['Header'],
                    location: property['Location'],
                    price: property['Price'],
                    isSaved: isSaved,
                    onHeartTap: () => onSave(property),
                  );
                },
              );
            },
          ),
        )
      ],
    );
  }
}

class PropertyCard extends StatelessWidget {
  final String image;
  final String title;
  final String location;
  final String price;
  final bool isSaved;
  final VoidCallback onHeartTap;

  const PropertyCard({
    required this.image,
    required this.title,
    required this.location,
    required this.price,
    required this.isSaved,
    required this.onHeartTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  image,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: onHeartTap,
                  child: Icon(
                    isSaved ? Icons.favorite : Icons.favorite_border,
                    color: isSaved ? Colors.red : Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text(location, style: TextStyle(color: Colors.grey[600])),
                SizedBox(height: 8),
                Text(price,
                    style: TextStyle(fontSize: 16, color: Color(0xffef2207))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SavedScreen extends StatelessWidget {
  final List<Map<String, dynamic>> savedProperties;

  SavedScreen({required this.savedProperties});

  @override
  Widget build(BuildContext context) {
    if (savedProperties.isEmpty) {
      return Center(child: Text("No saved properties."));
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: savedProperties.length,
      itemBuilder: (context, index) {
        final property = savedProperties[index];
        return PropertyCard(
          image: property['Image'],
          title: property['Header'],
          location: property['Location'],
          price: property['Price'],
          isSaved: true,
          onHeartTap: () {},
        );
      },
    );
  }
}
