import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class VoteHistory extends StatefulWidget {
  const VoteHistory({super.key});

  @override
  State<VoteHistory> createState() => _VoteHistoryState();
}

class _VoteHistoryState extends State<VoteHistory> {
  @override
  Widget build(BuildContext context) {
    String userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('Vote History'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('user_votes')
            .doc(userId) // Fetch the user's specific vote history
            .collection('poll_votes')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var userVotes = snapshot.data!.docs;
          if (userVotes.isEmpty) {
            return Center(child: Text("You have not voted on any polls."));
          }

          // List the polls the user has voted on
          return ListView.builder(
            itemCount: userVotes.length,
            itemBuilder: (context, index) {
              var userVoteDoc = userVotes[index];
              String pollId =
                  userVoteDoc['poll_id']; // Poll ID the user voted on

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('votes')
                    .doc(pollId)
                    .get(), // Get the full poll details
                builder: (context, pollSnapshot) {
                  if (!pollSnapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  var voteDoc = pollSnapshot.data!;
                  String winner = 'Poll Not Released';

                  // Show the result if the poll is released
                  if (voteDoc['released'] == true) {
                    var candidates =
                        Map<String, dynamic>.from(voteDoc['votes']);
                    var candidate1Votes = candidates[voteDoc['candidate1']];
                    var candidate2Votes = candidates[voteDoc['candidate2']];

                    if (candidate1Votes > candidate2Votes) {
                      winner = voteDoc['candidate1'];
                    } else if (candidate2Votes > candidate1Votes) {
                      winner = voteDoc['candidate2'];
                    } else {
                      winner = 'Draw';
                    }
                  }

                  String userVote = 'You voted for ${userVoteDoc['voted_for']}';

                  return Card(
                    margin: EdgeInsets.all(8),
                    child: ListTile(
                      title: Text(
                          'Poll: ${voteDoc['candidate1']} vs ${voteDoc['candidate2']}'),
                      subtitle: Text(
                          '$userVote\nReleased: ${voteDoc['released'] ? 'Yes' : 'No'}'),
                      trailing: Text('Winner: $winner'),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
