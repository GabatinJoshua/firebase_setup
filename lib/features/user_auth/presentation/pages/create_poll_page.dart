import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'admin_page.dart';
import 'admin_results_page.dart';

class CreatePollPage extends StatefulWidget {
  const CreatePollPage({super.key});

  @override
  _CreatePollPageState createState() => _CreatePollPageState();
}

class _CreatePollPageState extends State<CreatePollPage> {
  final _candidate1Controller = TextEditingController();
  final _candidate2Controller = TextEditingController();
  final _positionController =
      TextEditingController(); // Controller for position
  final _formKey = GlobalKey<FormState>();
  int _selectedIndex = 2; // Default to CreatePollPage

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      // Navigate to AdminPage (Home)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AdminPage(),
        ),
      );
    } else if (index == 1) {
      // Navigate to AdminResultsPage (Results)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdminResultsPage(),
        ),
      );
    } else if (index == 2) {
      // Stay on CreatePollPage
      return;
    } else if (index == 3) {
      // Logout
      FirebaseAuth.instance.signOut();
      Navigator.pushNamed(context, "/login");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Successfully signed out")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[100],
      appBar: AppBar(
        backgroundColor: Colors.blueGrey[100],
        flexibleSpace: Align(
          alignment: Alignment.center, // Center the image
          child: Image.asset(
            'images/vote_alt.png',
            width: double.infinity, // Make the image span the full width
            height: double.infinity, // Make the image span the full height
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _positionController,
                decoration:
                    InputDecoration(labelText: 'Position (e.g., President)'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the position for the poll';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _candidate1Controller,
                decoration: InputDecoration(labelText: 'Candidate 1'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name for Candidate 1';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _candidate2Controller,
                decoration: InputDecoration(labelText: 'Candidate 2'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name for Candidate 2';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Check if the candidates' names are the same
                  if (_candidate1Controller.text ==
                      _candidate2Controller.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('Candidates cannot have the same name!')),
                    );
                  } else if (_positionController.text.isEmpty ||
                      _candidate1Controller.text.isEmpty ||
                      _candidate2Controller.text.isEmpty) {
                    // If any field is empty, show a Snackbar with an error message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please fill in all the fields')),
                    );
                  } else {
                    _showConfirmationDialog(); // Proceed to show the confirmation dialog if all fields are filled
                  }
                },
                child: Text('Create Poll'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.blueGrey[500], // Set the background color
        selectedItemColor: Colors.white, // Color for the selected icon
        unselectedItemColor: Colors.white70, // Color for unselected icons
        type: BottomNavigationBarType
            .fixed, // Fix the nav bar when there are 4 items
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home', // Home button goes to AdminPage
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_turned_in),
            label: 'Results', // Results button goes to AdminResultsPage
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Create Poll', // Stay on CreatePollPage
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'Logout',
          ),
        ],
      ),
    );
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Poll Creation'),
          content: Text('Are you sure you want to create a new poll?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _createPoll(); // Call the create poll function if confirmed
              },
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  // Create poll in Firestore
  void _createPoll() async {
    if (_formKey.currentState!.validate()) {
      var position = _positionController.text;
      var candidate1 = _candidate1Controller.text;
      var candidate2 = _candidate2Controller.text;

      // Get the current user's ID
      String userId = FirebaseAuth.instance.currentUser!.uid;

      // Add poll to Firestore
      DocumentReference pollRef =
          await FirebaseFirestore.instance.collection('votes').add({
        'position': position, // Add the position field
        'candidate1': candidate1,
        'candidate2': candidate2,
        'votes': {
          candidate1: 0,
          candidate2: 0,
        },
        'released': false, // Poll is initially not released
        'winner': '', // Placeholder for the winner, which will be filled later
        'createdAt':
            Timestamp.now(), // Timestamp to track when the poll was created
      });

      // Store the user's vote history in the `user_votes` collection (sub-collection under the user's document)
      await FirebaseFirestore.instance
          .collection('user_votes')
          .doc(userId) // User ID
          .collection('poll_votes')
          .doc(pollRef.id) // Poll ID
          .set({
        'voted_for': '',
        'poll_id': pollRef.id,
        'vote_time': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Poll for $position created!')),
      );

      // Go back to AdminPage or another relevant page
      Navigator.pop(context);
    }
  }
}
