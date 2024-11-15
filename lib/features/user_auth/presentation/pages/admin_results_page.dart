import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminResultsPage extends StatelessWidget {
  const AdminResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Results'),
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
