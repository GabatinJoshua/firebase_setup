import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_setup/features/user_auth/firebase_auth_implementation/firebase_auth_services.dart';
import 'package:firebase_setup/features/user_auth/presentation/pages/sign_up_page.dart';
import 'package:firebase_setup/features/user_auth/presentation/widget/font_container_widget.dart';
import 'package:firebase_setup/global/common/toast.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuthService _auth = FirebaseAuthService();

  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  bool _isSigning = false;

  // Track the default color and highlighted color
  final Color _highlightedColor = Colors.blue[600]!; // Color when pressed
  final Color _defaultColor = Colors.blue[800]!;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[100],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'images/vote.png',
                height: 50,
                width: 150,
              ),
              SizedBox(height: 20),
              Text(
                'Login',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              SizedBox(height: 30),
              FormContainerWidget(
                controller: _emailController,
                hintText: "Email",
                isPasswordField: false,
              ),
              SizedBox(height: 10),
              FormContainerWidget(
                controller: _passwordController,
                hintText: "Password",
                isPasswordField: true,
              ),
              SizedBox(height: 20),
              // ElevatedButton with MaterialStateProperty to change color on press
              ElevatedButton(
                onPressed: _signIn,
                style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.resolveWith<Color>((states) {
                    if (states.contains(MaterialState.pressed)) {
                      return _highlightedColor; // Color when pressed
                    }
                    return _defaultColor; // Default color when not pressed
                  }),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  minimumSize: MaterialStateProperty.all(
                      Size(2000, 50)), // Minimum width: 200, height: 50
                  padding: MaterialStateProperty.all(
                      EdgeInsets.symmetric(vertical: 14)),
                ),
                child: _isSigning
                    ? CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : Text(
                        'Login',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account?"),
                  SizedBox(width: 5),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => SignUpPage()),
                        (route) => false,
                      );
                    },
                    child: Text(
                      'Sign Up',
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _signIn() async {
    String email = _emailController.text;
    String password = _passwordController.text;

    setState(() {
      _isSigning = true;
    });

    // Attempt to sign in the user
    User? user = await _auth.signInWithEmailAndPassword(email, password);

    setState(() {
      _isSigning = false;
    });

    if (user != null) {
      // If sign in is successful, check the user's role
      _checkUserRole(user);
      showToast(message: 'Success!!');
    } else {
      showToast(message: 'Sign in failed');
    }
  }

  void _checkUserRole(User user) async {
    // Get user data from Firestore by email or other unique identifier
    final userCollection = FirebaseFirestore.instance.collection("users");

    // Fetch the document of the logged-in user
    final userDoc = await userCollection
        .where("email", isEqualTo: user.email) // Assuming email is unique
        .limit(1) // Limit to 1 document
        .get();

    if (userDoc.docs.isNotEmpty) {
      final userData = userDoc.docs.first;
      final loggedInUser = UserModel.fromSnapshot(userData);

      if (loggedInUser.role == 'admin') {
        // Navigate to admin page if user is admin
        Navigator.pushNamed(context, '/admin');
      } else {
        // Navigate to user home page if not admin
        Navigator.pushNamed(context, '/home');
      }
    } else {
      showToast(message: 'User data not found');
    }
  }
}
