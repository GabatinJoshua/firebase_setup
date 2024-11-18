import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'admin_results_page.dart';
import 'create_poll_page.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int _selectedIndex = 0;
  bool _hasActivePolls = false; // Track if there are active polls

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      return; // Stay on the AdminPage
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdminResultsPage(),
        ),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreatePollPage(),
        ),
      );
    } else if (index == 3) {
      FirebaseAuth.instance.signOut();
      Navigator.pushNamed(context, "/login");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Successfully signed out")),
      );
    }
  }

  Future<void> _releaseAllPolls() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Release All Polls'),
          content: Text('Are you sure you want to release all polls?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Close the dialog
                try {
                  var polls = await FirebaseFirestore.instance
                      .collection('votes')
                      .where('released',
                          isEqualTo: false) // Only unreleased polls
                      .get();

                  for (var poll in polls.docs) {
                    await FirebaseFirestore.instance
                        .collection('votes')
                        .doc(poll.id)
                        .update({'released': true});
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("All polls have been released")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error releasing polls: $e")),
                  );
                }
              },
              child: Text('Release All'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAllPolls() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete All Polls'),
          content: Text(
              'Are you sure you want to delete all polls? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Close the dialog
                try {
                  var polls = await FirebaseFirestore.instance
                      .collection('votes')
                      .where('released',
                          isEqualTo: false) // Only unreleased polls
                      .get();

                  for (var poll in polls.docs) {
                    await FirebaseFirestore.instance
                        .collection('votes')
                        .doc(poll.id)
                        .delete();
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("All polls have been deleted")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error deleting polls: $e")),
                  );
                }
              },
              child: Text('Delete All'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[100],
      appBar: AppBar(
        backgroundColor: Colors.blueGrey[100],
        flexibleSpace: Align(
          alignment: Alignment.center,
          child: Image.asset(
            'images/vote_alt.png',
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.check_box),
            onPressed: _hasActivePolls
                ? _releaseAllPolls
                : null, // Disable when no active polls
            tooltip: 'Release All Polls',
          ),
          IconButton(
            icon: Icon(Icons.delete_forever),
            onPressed: _hasActivePolls
                ? _deleteAllPolls
                : null, // Disable when no active polls
            tooltip: 'Delete All Polls',
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('votes')
            .where('released', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var votes = snapshot.data!.docs;

          // Update the state of _hasActivePolls based on active polls
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _hasActivePolls = votes.isNotEmpty;
            });
          });

          if (votes.isEmpty) {
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
              if (candidate1Votes == 0 && candidate2Votes == 1 ||
                  candidate1Votes == 1 && candidate2Votes == 0) {
                winner = 'Not Enough Data';
              } else if (candidate1Votes > candidate2Votes) {
                winner = voteDoc['candidate1'];
              } else if (candidate2Votes > candidate1Votes) {
                winner = voteDoc['candidate2'];
              } else if (candidate1Votes == 0 && candidate2Votes == 0) {
                winner = 'No votes yet';
              } else {
                winner = 'Draw';
              }

              bool canEdit = candidate1Votes == 0 && candidate2Votes == 0;

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
                          Text('${voteDoc['candidate1']}: $candidate1Votes'),
                          Text('${voteDoc['candidate2']}: $candidate2Votes'),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: canEdit
                            ? () async {
                                await _showEditDialog(voteDoc);
                              }
                            : null, // Disable edit button if votes are cast
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
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: Text('Cancel')),
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: Text('Delete')),
                                  ],
                                );
                              });

                          if (confirmDelete == true) {
                            try {
                              await FirebaseFirestore.instance
                                  .collection('votes')
                                  .doc(voteDoc.id)
                                  .delete();

                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text('Poll deleted successfully!')));
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text('Failed to delete poll: $e')));
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
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: Text('Cancel')),
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: Text('Release')),
                                  ],
                                );
                              });

                          if (confirmRelease == true) {
                            await FirebaseFirestore.instance
                                .collection('votes')
                                .doc(voteDoc.id)
                                .update({'released': true});
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content:
                                    Text('Poll results have been released')));
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

  Future<void> _showEditDialog(DocumentSnapshot voteDoc) async {
    // Create controllers for the text fields
    TextEditingController positionController =
        TextEditingController(text: voteDoc['position']);
    TextEditingController candidate1Controller =
        TextEditingController(text: voteDoc['candidate1']);
    TextEditingController candidate2Controller =
        TextEditingController(text: voteDoc['candidate2']);

    // Open the dialog for editing
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Poll'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: positionController,
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
                // Fetch the updated vote document to check the current vote state
                var updatedVoteDoc = await FirebaseFirestore.instance
                    .collection('votes')
                    .doc(voteDoc.id)
                    .get();

                // Get the current vote counts
                var currentVotes =
                    Map<String, dynamic>.from(updatedVoteDoc['votes']);
                int candidate1Votes = currentVotes[voteDoc['candidate1']] ?? 0;
                int candidate2Votes = currentVotes[voteDoc['candidate2']] ?? 0;

                // Prevent updates if votes have already been cast
                if (candidate1Votes > 0 || candidate2Votes > 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Poll cannot be edited after votes have been cast.'),
                    ),
                  );
                  Navigator.pop(context); // Close the dialog
                  return; // Exit without saving the update
                }

                // If no votes have been cast, proceed to update the poll while retaining vote counts
                await FirebaseFirestore.instance
                    .collection('votes')
                    .doc(voteDoc.id)
                    .update({
                  'position': positionController.text,
                  'candidate1': candidate1Controller.text,
                  'candidate2': candidate2Controller.text,
                  // Keep the current vote counts intact
                  'votes': {
                    voteDoc['candidate1']: candidate1Votes,
                    voteDoc['candidate2']: candidate2Votes
                  },
                });

                Navigator.pop(context); // Close the dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Poll updated successfully!')),
                );
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
