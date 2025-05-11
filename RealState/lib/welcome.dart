import 'package:flutter/material.dart';
import 'login.dart'; // Make sure this defines LoginPage and it's routed as '/login'
import 'signup.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomePage extends StatelessWidget {
  static const loginSignupScreen = 'signup_login_screen';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        height: double.infinity,
        width: double.infinity,
        color: Color(0xFFE6E6E6), // background color
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                width: 220,
                height: 120,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: NetworkImage(
                      'https://morshedy.com/assets/front/images/logo-black.png',
                    ),
                  ),
                ),
              ),
              Text(
                "REGISTER YOUR PROPERTY",
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  color: Colors.black,
                  fontSize: 26,
                  fontWeight: FontWeight.normal,
                ),
              ),
              Column(
                children: [
                  ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: // MaterialStateProperty for the hoover color
                          MaterialStateProperty.resolveWith<Color>((states) {
                        if (states.contains(MaterialState.hovered)) {
                          return Color(0xfffdb397); // <-- hover color
                        }
                        return Colors.white; // normal color
                      }),
                      foregroundColor: MaterialStateProperty.all(Colors.black),
                      minimumSize: MaterialStateProperty.all(
                          const Size(double.infinity, 50)),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              8), // Apply BorderRadius through shape
                        ),
                      ),
                    ),
                    onPressed: () {
                      // Add Sign Up navigation here
                      Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (_) => SignupPage()));
                    },
                    child: const Text("SIGNUP"),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: // MaterialStateProperty for the hoover color
                          MaterialStateProperty.resolveWith<Color>((states) {
                        if (states.contains(MaterialState.hovered)) {
                          return Color(0xffef5c07); // <-- hover color
                        }
                        return Color(0xff333231); // normal color
                      }),
                      foregroundColor: MaterialStateProperty.all(Colors.white),
                      minimumSize: MaterialStateProperty.all(
                          const Size(double.infinity, 50)),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              8), // Apply BorderRadius through shape
                        ),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    child: const Text("LOGIN"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
