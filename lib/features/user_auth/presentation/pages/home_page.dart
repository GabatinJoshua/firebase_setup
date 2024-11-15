import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'vote_history_page.dart'; // Import the VoteHistory Page

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, bool> _hasVotedForPolls =
      {}; // Track if the user has voted for specific polls

  @override
  void initState() {
    super.initState();
    _checkIfUserHasVoted();
  }

  // Check if the user has already voted in each poll
  void _checkIfUserHasVoted() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;

    var userVoteDocs = await FirebaseFirestore.instance
        .collection('user_votes')
        .doc(userId) // Fetch user's vote history
        .collection('poll_votes')
        .get();

    // Track the votes for each poll the user voted on
    for (var userVoteDoc in userVoteDocs.docs) {
      String pollId = userVoteDoc['poll_id'];
      setState(() {
        _hasVotedForPolls[pollId] = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 30),

              // Button to navigate to Vote History page
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          VoteHistory(), // Navigate to VoteHistory page
                    ),
                  );
                },
                child: Text('View Vote History'),
              ),

              SizedBox(height: 20),

              // StreamBuilder to display voting options
              StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('votes')
                    .where('released',
                        isEqualTo:
                            false) // Only show polls that are not released yet
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  var votes = snapshot.data!.docs;
                  if (votes.isEmpty) {
                    return Center(child: Text("No active polls available"));
                  }

                  // Use ListView to show all polls
                  return ListView.builder(
                    shrinkWrap:
                        true, // Makes the ListView take only necessary space
                    itemCount: votes.length,
                    itemBuilder: (context, index) {
                      var voteDoc = votes[index];
                      String pollId = voteDoc.id;

                      // Check if user has voted for this specific poll
                      bool hasVoted = _hasVotedForPolls[pollId] ?? false;

                      // Skip rendering this poll if the user has already voted for it
                      if (hasVoted) {
                        return Container(); // Return an empty container to hide it
                      }

                      return Card(
                        margin: EdgeInsets.all(8),
                        child: Column(
                          children: [
                            ListTile(
                              title: Text(
                                  'Vote for ${voteDoc['candidate1']} vs ${voteDoc['candidate2']}'),
                            ),
                            SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () {
                                _submitVote(
                                    voteDoc, voteDoc['candidate1'], pollId);
                              },
                              child: Text("Vote for ${voteDoc['candidate1']}"),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                _submitVote(
                                    voteDoc, voteDoc['candidate2'], pollId);
                              },
                              child: Text("Vote for ${voteDoc['candidate2']}"),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Submit vote method
  void _submitVote(
      DocumentSnapshot voteDoc, String votedFor, String pollId) async {
    String userId = FirebaseAuth.instance.currentUser!.uid;

    // Update the vote count in Firestore for the selected candidate
    await FirebaseFirestore.instance
        .collection('votes')
        .doc(voteDoc.id)
        .update({
      'votes.$votedFor':
          FieldValue.increment(1), // Increment the vote count for the candidate
    });

    // Store the user's vote to prevent multiple votes in the same poll
    await FirebaseFirestore.instance
        .collection('user_votes')
        .doc(userId)
        .collection('poll_votes')
        .doc(pollId)
        .set({
      'user_id': userId, // Store user ID
      'voted_for': votedFor, // Store the voted candidate
      'poll_id': pollId, // Store the poll ID
      'vote_time': Timestamp.now(), // Store the time of the vote
    });

    // Update the local state to reflect the user's vote
    setState(() {
      _hasVotedForPolls[pollId] = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Your vote for $votedFor has been cast')));
  }
}
