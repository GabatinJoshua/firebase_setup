import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'admin_results_page.dart'; // Import AdminResultsPage
import 'create_poll_page.dart'; // Import CreatePollPage

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Page'),
        actions: [
          // Button to navigate to AdminResultsPage
          IconButton(
            icon: Icon(Icons.assignment_turned_in),
            onPressed: () {
              // Navigate to the AdminResultsPage
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminResultsPage(),
                ),
              );
            },
          ),
          // Button to navigate to CreatePollPage
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              // Navigate to the CreatePollPage
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreatePollPage(),
                ),
              );
            },
          ),
        ],
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
                  subtitle: Text('Winner: $winner'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Display vote counts
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
                          // Show dialog to edit the poll
                          await _showEditDialog(voteDoc);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () async {
                          // Show confirmation dialog before deleting
                          bool? confirmDelete =
                              await _showDeleteDialog(voteDoc);
                          if (confirmDelete ?? false) {
                            await FirebaseFirestore.instance
                                .collection('votes')
                                .doc(voteDoc.id)
                                .delete();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Poll deleted!')),
                            );
                          }
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.check),
                        onPressed: () async {
                          // Update the poll with the result and set 'released' to true
                          await FirebaseFirestore.instance
                              .collection('votes')
                              .doc(voteDoc.id)
                              .update({
                            'released': true,
                            'winner': winner,
                          });

                          // Optionally navigate to AdminResultsPage after releasing results
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdminResultsPage(),
                            ),
                          );

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Results released!')),
                          );
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
    );
  }

  // Show edit dialog to modify the poll
  Future<void> _showEditDialog(DocumentSnapshot voteDoc) async {
    TextEditingController candidate1Controller =
        TextEditingController(text: voteDoc['candidate1']);
    TextEditingController candidate2Controller =
        TextEditingController(text: voteDoc['candidate2']);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Poll'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Update the poll with the new candidate names
                await FirebaseFirestore.instance
                    .collection('votes')
                    .doc(voteDoc.id)
                    .update({
                  'candidate1': candidate1Controller.text,
                  'candidate2': candidate2Controller.text,
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Poll updated!')),
                );
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Show confirmation dialog before deleting a poll
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
