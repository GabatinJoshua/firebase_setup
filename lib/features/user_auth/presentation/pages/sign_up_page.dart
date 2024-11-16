import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_setup/features/user_auth/firebase_auth_implementation/firebase_auth_services.dart';
import 'package:firebase_setup/features/user_auth/presentation/pages/login_page.dart';
import 'package:firebase_setup/features/user_auth/presentation/widget/font_container_widget.dart';
import 'package:flutter/material.dart';

import '../../../../global/common/toast.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final FirebaseAuthService _auth = FirebaseAuthService();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final Color _highlightedColor = Colors.blue[600]!; // Color when pressed
  final Color _defaultColor = Colors.blue[800]!; // Default color

  bool _isSigning = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[100],
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Sign Up',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    )),
                SizedBox(height: 30),
                FormContainerWidget(
                  controller: _usernameController,
                  hintText: "Username",
                  isPasswordField: false,
                ),
                SizedBox(height: 10),
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
                SizedBox(height: 10),
                FormContainerWidget(
                  controller: _confirmPasswordController,
                  hintText: "Confirm Password",
                  isPasswordField: true,
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _signUp,
                  style: ButtonStyle(
                    backgroundColor:
                        WidgetStateProperty.resolveWith<Color>((states) {
                      if (states.contains(WidgetState.pressed)) {
                        return _highlightedColor; // Color when pressed
                      }
                      return _defaultColor; // Default color when not pressed
                    }),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    minimumSize: WidgetStateProperty.all(
                        Size(2000, 50)), // Minimum width: 200, height: 50
                    padding: WidgetStateProperty.all(
                        EdgeInsets.symmetric(vertical: 14)),
                  ),
                  child: _isSigning
                      ? CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : Text(
                          'Sign Up',
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
                    Text("Already have an account?"),
                    SizedBox(width: 5),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => LoginPage()),
                          (route) => false,
                        );
                      },
                      child: Text(
                        'Login',
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
      ),
    );
  }

  void _signUp() async {
    String email = _emailController.text;
    String password = _passwordController.text;
    String confirmPassword = _confirmPasswordController.text;

    setState(() {
      _isSigning = true;
    });

    if (password != confirmPassword) {
      setState(() {
        _isSigning = false;
      });
      showToast(message: 'Passwords do not match');
      return;
    }

    // Proceed with user creation
    User? user = await _auth.signUpWithEmailAndPassword(email, password);

    if (user != null) {
      _createData(UserModel(
        email: _emailController.text,
        username: _usernameController.text,
        role: "user",
      ));
      showToast(message: "Sign Up Success");
      Navigator.pushNamed(context, "/login");
    } else {
      showToast(message: "Error Occurred");
    }

    setState(() {
      _isSigning = false;
    });
  }
}

void _createData(UserModel userModel) {
  final userCollection = FirebaseFirestore.instance.collection("users");

  String id = userCollection.doc().id;

  final newUser = UserModel(
          username: userModel.username,
          role: userModel.role,
          email: userModel.email,
          id: id)
      .toJson();

  userCollection.doc(id).set(newUser);
}

class UserModel {
  final String? username;
  final String? role;
  final String? email;
  final String? id;

  UserModel({this.username, this.role, this.email, this.id});

  static UserModel fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> snapshot) {
    return UserModel(
        email: snapshot["email"],
        username: snapshot["username"],
        role: snapshot["role"],
        id: snapshot["id"]);
  }

  Map<String, dynamic> toJson() {
    return {"username": username, "role": role, "email": email, "id": id};
  }
}
