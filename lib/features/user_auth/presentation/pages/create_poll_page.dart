import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CreatePollPage extends StatefulWidget {
  const CreatePollPage({super.key});

  @override
  _CreatePollPageState createState() => _CreatePollPageState();
}

class _CreatePollPageState extends State<CreatePollPage> {
  final _candidate1Controller = TextEditingController();
  final _candidate2Controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[100],
      appBar: AppBar(
        backgroundColor: Colors.teal[400],
        title: Text('Create New Poll'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
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
                onPressed: _createPoll,
                child: Text('Create Poll'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Create poll in Firestore
  void _createPoll() async {
    if (_formKey.currentState!.validate()) {
      var candidate1 = _candidate1Controller.text;
      var candidate2 = _candidate2Controller.text;

      // Get the current user's ID
      String userId = FirebaseAuth.instance.currentUser!.uid;

      // Add poll to Firestore
      DocumentReference pollRef =
          await FirebaseFirestore.instance.collection('votes').add({
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
        SnackBar(content: Text('Poll created!')),
      );

      // Go back to AdminPage or another relevant page
      Navigator.pop(context);
    }
  }
}
