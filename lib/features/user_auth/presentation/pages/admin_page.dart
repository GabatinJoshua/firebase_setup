import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'admin_results_page.dart'; // Import AdminResultsPage
import 'create_poll_page.dart'; // Import CreatePollPage

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      // Stay on the AdminPage (do nothing)
      return;
    } else if (index == 1) {
      // Navigate to AdminResultsPage
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdminResultsPage(),
        ),
      );
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
      body: StreamBuilder(
        // Query to only show polls that are not released
        stream: FirebaseFirestore.instance
            .collection('votes')
            .where('released', isEqualTo: false) // Exclude released polls
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var votes = snapshot.data!.docs;

          if (votes.isEmpty) {
            // Show this when there are no active polls
            return Center(
              child: Text(
                'No active polls available!',
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
            );
          }

          return ListView.builder(
            itemCount: votes.length,
            itemBuilder: (context, index) {
              var voteDoc = votes[index];
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
                      if (voteDoc['position'] != null &&
                          voteDoc['position'].isNotEmpty)
                        Text('Position: ${voteDoc['position']}'),
                      Text('Winner: $winner'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Votes: $candidate1Votes'),
                          Text('Votes: $candidate2Votes'),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () async {
                          // Check if the poll has any votes

                          if (candidate1Votes > 0 || candidate2Votes > 0) {
                            // Show a message that the poll cannot be edited
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Poll cannot be edited after votes have been cast.')),
                            );
                            return; // Do not allow editing
                          }

                          // If no votes, allow editing
                          await _showEditDialog(voteDoc);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () async {
                          bool? confirmDelete = await showDialog<bool>(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text('Delete Poll'),
                                content: Text(
                                    'Are you sure you want to delete this poll? This action cannot be undone.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(
                                        context, false), // Cancel action
                                    child: Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(
                                        context, true), // Confirm action
                                    child: Text('Delete'),
                                  ),
                                ],
                              );
                            },
                          );

                          if (confirmDelete == true) {
                            try {
                              await FirebaseFirestore.instance
                                  .collection('votes')
                                  .doc(voteDoc.id)
                                  .delete();

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('Poll deleted successfully!')),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Failed to delete poll: $e')),
                              );
                            }
                          }
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.check),
                        onPressed: () async {
                          bool? confirmRelease = await showDialog<bool>(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text('Release Results'),
                                content: Text(
                                    'Are you sure you want to release the results for this poll?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(
                                        context, false), // Cancel action
                                    child: Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(
                                        context, true), // Confirm action
                                    child: Text('Release'),
                                  ),
                                ],
                              );
                            },
                          );

                          if (confirmRelease == true) {
                            await FirebaseFirestore.instance
                                .collection('votes')
                                .doc(voteDoc.id)
                                .update({
                              'released': true,
                              'winner': winner,
                            });

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AdminResultsPage(),
                              ),
                            );

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Results released!')),
                            );
                          }
                        },
                      ),
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
            label: 'Home', // Home button will just stay at the AdminPage
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_turned_in),
            label: 'Results',
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

  Future<void> _showEditDialog(DocumentSnapshot voteDoc) async {
    // Create controllers for the text fields
    TextEditingController positionController =
        TextEditingController(text: voteDoc['position']); // For position
    TextEditingController candidate1Controller =
        TextEditingController(text: voteDoc['candidate1']); // For Candidate 1
    TextEditingController candidate2Controller =
        TextEditingController(text: voteDoc['candidate2']); // For Candidate 2

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Poll'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: positionController, // Use the position controller
                decoration: InputDecoration(labelText: 'Position'),
              ),
              TextField(
                controller: candidate1Controller,
                decoration: InputDecoration(labelText: 'Candidate 1'),
              ),
              TextField(
                controller: candidate2Controller,
                decoration: InputDecoration(labelText: 'Candidate 2'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Update Firestore with the new data
                await FirebaseFirestore.instance
                    .collection('votes')
                    .doc(voteDoc.id)
                    .update({
                  'position': positionController.text, // Update position
                  'candidate1': candidate1Controller.text, // Update Candidate 1
                  'candidate2': candidate2Controller.text, // Update Candidate 2
                });

                Navigator.pop(context); // Close the dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Poll updated!')), // Show confirmation
                );
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showDeleteDialog(DocumentSnapshot voteDoc) async {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Poll'),
          content: Text('Are you sure you want to delete this poll?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
