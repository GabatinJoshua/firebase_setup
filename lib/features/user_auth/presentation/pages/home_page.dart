import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_setup/global/common/toast.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'vote_history_page.dart';

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
      backgroundColor: Colors.teal[100],
      appBar: AppBar(
        backgroundColor: Colors.teal[400],
        title: Text('Home Page'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(
              Icons.history,
              color: Colors.white70,
            ), // This is the icon for the button
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      VoteHistory(), // Navigate to VoteHistory page
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(
              Icons.logout,
              color: Colors.white70,
            ),
            onPressed: () async {
              FirebaseAuth.instance.signOut();
              Navigator.pushNamed(context, "/login");
              showToast(message: "Successfully signed out");
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
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

                  // Check if there are no active polls available
                  if (votes.isEmpty) {
                    return Center(
                      child: Text(
                        "No active polls available",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    );
                  }

                  // If there are polls but they are not released, show a message

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

                      // Check if the results are released
                      bool resultsReleased = voteDoc['released'];

                      return Card(
                        margin: EdgeInsets.all(8),
                        child: Column(
                          children: [
                            ListTile(
                              leading: FaIcon(
                                FontAwesomeIcons
                                    .checkToSlot, // Add the Font Awesome icon here
                                color: Colors.blue, // Icon color
                                size: 30, // Icon size
                              ),
                              trailing: FaIcon(
                                FontAwesomeIcons
                                    .checkToSlot, // Add the Font Awesome icon here
                                color: Colors.blue, // Icon color
                                size: 30, // Icon size
                              ),
                              title: Center(
                                child: Text(
                                  'Vote for ${voteDoc['candidate1']} vs ${voteDoc['candidate2']}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20),
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                _submitVote(
                                    voteDoc, voteDoc['candidate1'], pollId);
                              },
                              style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.all(
                                    Colors.blueAccent), // Bright color
                                elevation: MaterialStateProperty.all(
                                    10), // Increased elevation (shadow)
                                shape: MaterialStateProperty.all(
                                    RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            12))), // Rounded corners
                                padding: MaterialStateProperty.all(
                                    EdgeInsets.symmetric(
                                        vertical: 15,
                                        horizontal:
                                            20)), // Larger padding for better size
                              ),
                              child: Text(
                                "Vote for ${voteDoc['candidate1']}",
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                            SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () {
                                _submitVote(
                                    voteDoc, voteDoc['candidate2'], pollId);
                              },
                              style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.all(
                                    Colors.blueAccent), // Bright color
                                elevation: MaterialStateProperty.all(
                                    10), // Increased elevation (shadow)
                                shape: MaterialStateProperty.all(
                                    RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            12))), // Rounded corners
                                padding: MaterialStateProperty.all(
                                    EdgeInsets.symmetric(
                                        vertical: 15,
                                        horizontal:
                                            20)), // Larger padding for better size
                              ),
                              child: Text("Vote for ${voteDoc['candidate2']}",
                                  style: TextStyle(color: Colors.white70)),
                            ),
                            SizedBox(height: 10),
                            // After voting, show the result status
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
