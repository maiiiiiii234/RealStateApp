import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home.dart';
import 'signup.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _obscureText = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Method to save login state (userId) to shared_preferences
  Future<void> saveLoginState(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'userId', userId); // Save user ID to shared_preferences
  }

  // Method to clear login state (userId) when logging out
  Future<void> clearLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId'); // Clear the saved user ID
  }

  // Method to retrieve login state (userId)
  Future<String?> getUserLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs
        .getString('userId'); // Retrieve saved user ID from shared_preferences
  }

  // Method to save the saved properties list to shared_preferences
  Future<void> saveSavedProperties(
      List<Map<String, dynamic>> savedProperties) async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = await getUserLoginState(); // Get current user's userId
    if (userId == null) return;

    // Save properties for the specific user by storing them in a user-specific key
    List<String> propertiesJson =
        savedProperties.map((property) => jsonEncode(property)).toList();
    await prefs.setStringList('savedProperties_$userId',
        propertiesJson); // Use userId as part of the key
  }

  // Method to retrieve saved properties list for the current user
  Future<List<Map<String, dynamic>>> getSavedProperties() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = await getUserLoginState(); // Get current user's userId
    if (userId == null) return []; // Return empty list if user is not logged in

    List<String>? propertiesJson = prefs.getStringList(
        'savedProperties_$userId'); // Use userId as part of the key
    if (propertiesJson == null) return [];
    return propertiesJson
        .map((jsonStr) => jsonDecode(jsonStr) as Map<String, dynamic>)
        .toList();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      String email = emailController.text.trim();
      String password = passwordController.text.trim();

      try {
        // Sign in
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        String uid = userCredential.user!.uid;

        // Save user login state
        await saveLoginState(uid);
        print(uid);

        // Check if user exists in Firestore
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance.collection('Users').doc(uid).get();

        if (userDoc.exists) {
          // Show success alert with green text
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text('Login Successful',
                  style: TextStyle(color: Colors.green)),
              content: Text(
                'Welcome back, ${userCredential.user!.email}!',
                style: TextStyle(color: Colors.black),
              ),
            ),
          );

          // Wait for the alert to close before navigating to the HomePage
          Future.delayed(Duration(seconds: 2), () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => HomePage()),
            );
          });
        } else {
          // Not found in Firestore
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text('User Not Found'),
              content: Text(
                  'You are authenticated but not registered in our database.'),
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Login Failed', style: TextStyle(color: Colors.red)),
            content: Text(
              e.message ?? 'Unknown error occurred',
              style: TextStyle(color: Colors.black),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
        backgroundColor: Color(0xff333231),
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Color(0xFFE6E6E6),
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 600),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Welcome Back!',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff333231),
                      ),
                    ),
                    SizedBox(height: 20),
                    // Email field
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email, color: Color(0xff333231)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(vertical: 16.0),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) =>
                          value == null || !value.contains('@')
                              ? 'Enter a valid email'
                              : null,
                    ),
                    SizedBox(height: 16),
                    // Password field
                    TextFormField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock, color: Color(0xff333231)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureText
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Color(0xff333231),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(vertical: 16.0),
                      ),
                      obscureText: _obscureText,
                      validator: (value) => value == null || value.length < 6
                          ? 'Password must be 6+ characters'
                          : null,
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _login,
                      child: Text('Login', style: TextStyle(fontSize: 18)),
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.resolveWith<Color>((states) {
                          if (states.contains(MaterialState.hovered)) {
                            return Color(0xffef5c07);
                          }
                          return Color(0xff333231);
                        }),
                        foregroundColor:
                            MaterialStateProperty.all(Colors.white),
                        minimumSize: MaterialStateProperty.all(
                            const Size(double.infinity, 50)),
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(context,
                            MaterialPageRoute(builder: (_) => SignupPage()));
                        // Navigate to signup page
                      },
                      child: Text(
                        'Don\'t have an account? Sign Up',
                        style: GoogleFonts.montserrat(
                          color: Colors.black,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
