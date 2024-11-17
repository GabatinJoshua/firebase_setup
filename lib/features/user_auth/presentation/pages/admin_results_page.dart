import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'admin_page.dart'; // Import AdminPage
import 'create_poll_page.dart'; // Import CreatePollPage

class AdminResultsPage extends StatefulWidget {
  const AdminResultsPage({super.key});

  @override
  State<AdminResultsPage> createState() => _AdminResultsPageState();
}

class _AdminResultsPageState extends State<AdminResultsPage> {
  int _selectedIndex = 1; // Default to Results page

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
      // Results button does nothing (stay on AdminResultsPage)
      return;
    } else if (index == 2) {
      // Navigate to CreatePollPage
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreatePollPage(),
        ),
      );
    } else if (index == 3) {
      // Logout
      FirebaseAuth.instance.signOut();
      Navigator.pushNamed(context, "/login");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Successfully signed out")),
      );
    }
  }

  Future<void> _clearHistory(BuildContext context) async {
    try {
      var releasedVotes = await FirebaseFirestore.instance
          .collection('votes')
          .where('released', isEqualTo: true)
          .get();

      for (var doc in releasedVotes.docs) {
        await FirebaseFirestore.instance
            .collection('votes')
            .doc(doc.id)
            .delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('History cleared successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to clear history: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[100],
      appBar: AppBar(
        flexibleSpace: Align(
          alignment: Alignment.center, // Center the image
          child: Image.asset(
            'images/vote_alt.png',
            width: double.infinity, // Make the image span the full width
            height: double.infinity, // Make the image span the full height
          ),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blueGrey[100],
        actions: [
          IconButton(
            icon: Icon(Icons.delete_forever, color: Colors.black45),
            onPressed: () async {
              bool? confirmDelete = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text('Clear History'),
                    content:
                        Text('Are you sure you want to clear all history?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text('Clear'),
                      ),
                    ],
                  );
                },
              );

              if (confirmDelete == true) {
                await _clearHistory(context);
              }
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('votes')
            .where('released', isEqualTo: true) // Only show released polls
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var releasedVotes = snapshot.data!.docs;
          if (releasedVotes.isEmpty) {
            return Center(child: Text("No released results yet"));
          }

          return ListView.builder(
            itemCount: releasedVotes.length,
            itemBuilder: (context, index) {
              var voteDoc = releasedVotes[index];
              var candidates = Map<String, dynamic>.from(voteDoc['votes']);
              var candidate1Votes = candidates[voteDoc['candidate1']] ?? 0;
              var candidate2Votes = candidates[voteDoc['candidate2']] ?? 0;

              String winner;
              if (candidate1Votes > candidate2Votes) {
                winner = voteDoc['candidate1'];
              } else if (candidate2Votes > candidate1Votes) {
                winner = voteDoc['candidate2'];
              } else {
                winner = 'Draw';
              }

              return Card(
                margin: EdgeInsets.all(8),
                child: ListTile(
                  title: Text(
                      'Poll: ${voteDoc['candidate1']} vs ${voteDoc['candidate2']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Winner: $winner'),
                      // Display position if available
                      if (voteDoc['position'] != null &&
                          voteDoc['position'].isNotEmpty)
                        Text('Position: ${voteDoc['position']}'),
                    ],
                  ),
                ),
              );
            },
          );
        },
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
            label: 'Home', // Home button goes back to AdminPage
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_turned_in),
            label: 'Results', // Results button stays on AdminResultsPage
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Create Poll',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'Logout',
          ),
        ],
      ),
    );
  }
}
