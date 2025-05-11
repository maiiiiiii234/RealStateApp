import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _auth = FirebaseAuth.instance;
  final _picker = ImagePicker();
  late User _user;
  String _email = "";
  Uint8List? _previewBytes;
  Uint8List? _firestoreImageBytes;
  XFile? _pickedFile;

  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      await currentUser.reload();
      _user = _auth.currentUser!;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user.uid)
          .get();

      final base64String = doc.data()?['profile_image'] as String?;
      if (base64String != null) {
        _firestoreImageBytes = base64Decode(base64String);
      }

      setState(() {
        _email = _user.email ?? "No email";
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _pickedFile = picked;
          _previewBytes = bytes;
        });
        await _uploadImageToFirestore(bytes);
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image')),
      );
    }
  }

  Future<void> _uploadImageToFirestore(Uint8List bytes) async {
    try {
      final base64String = base64Encode(bytes);
      final uid = _auth.currentUser!.uid;
      final firestore = FirebaseFirestore.instance;

      await firestore.collection('users').doc(uid).set({
        'profile_image': base64String,
      }, SetOptions(merge: true));

      setState(() {
        _firestoreImageBytes = bytes;
        _previewBytes = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile picture updated')),
      );
    } catch (e) {
      print('Error saving image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save image')),
      );
    }
  }

  Future<void> _changePassword() async {
    try {
      final creds = EmailAuthProvider.credential(
        email: _user.email!,
        password: _oldPasswordController.text,
      );
      await _user.reauthenticateWithCredential(creds);
      await _user.updatePassword(_newPasswordController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password updated')),
      );
    } catch (e) {
      print('Error changing password: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to change password')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayImage = _previewBytes != null
        ? MemoryImage(_previewBytes!)
        : (_firestoreImageBytes != null
            ? MemoryImage(_firestoreImageBytes!)
            : null);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[300],
                backgroundImage: displayImage,
                child: displayImage == null
                    ? Icon(Icons.camera_alt, size: 40, color: Colors.white)
                    : null,
              ),
            ),
            SizedBox(height: 16),
            Text('Email: $_email', style: TextStyle(fontSize: 18)),
            SizedBox(height: 24),
            TextField(
              controller: _oldPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Old Password',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _changePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff333231),
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                  side: BorderSide(color: Colors.transparent), // Optional
                ),
              ),
              child: Text('Change Password',
                  style: TextStyle(color: Colors.white)),
            ),
          ]),
        ),
      ),
    );
  }
}
