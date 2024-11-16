import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminResultsPage extends StatelessWidget {
  const AdminResultsPage({super.key});

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
      backgroundColor: Colors.teal[100],
      appBar: AppBar(
        backgroundColor: Colors.teal[400],
        title: Text('Admin Results'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_forever, color: Colors.white70),
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
              var candidate1Votes = candidates[voteDoc['candidate1']];
              var candidate2Votes = candidates[voteDoc['candidate2']];

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
                ),
              );
            },
          );
        },
      ),
    );
  }
}
