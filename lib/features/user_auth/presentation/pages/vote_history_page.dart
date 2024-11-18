import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_setup/global/common/toast.dart';
import 'package:flutter/material.dart';

class VoteHistory extends StatefulWidget {
  const VoteHistory({super.key});

  @override
  State<VoteHistory> createState() => _VoteHistoryState();
}

class _VoteHistoryState extends State<VoteHistory> {
  int _selectedIndex = 1; // Highlight "History" on VoteHistory page

  // Function to handle bottom nav bar item taps
  void _onNavBarItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      // Navigate back to HomePage
      Navigator.pop(context);
    } else if (index == 2) {
      // Handle logout
      FirebaseAuth.instance.signOut();
      Navigator.pushNamed(context, "/login");
      showToast(message: "Successfully signed out");
    }
  }

  @override
  Widget build(BuildContext context) {
    String userId = FirebaseAuth.instance.currentUser!.uid;

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
            return Center(
              child: Text(
                "No poll history.",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: userVotes.length,
            itemBuilder: (context, index) {
              var userVoteDoc = userVotes[index];
              String pollId = userVoteDoc['poll_id'];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('votes')
                    .doc(pollId)
                    .get(),
                builder: (context, pollSnapshot) {
                  if (pollSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!pollSnapshot.hasData || !pollSnapshot.data!.exists) {
                    // Poll is no longer available
                    return Card(
                      margin: EdgeInsets.all(8),
                      child: ListTile(
                        title: Text('Poll no longer available'),
                        subtitle: Text(
                            'The poll you voted on has been removed or does not exist.'),
                        trailing: IconButton(
                          icon: Icon(Icons.cancel),
                          onPressed: () => _deleteVote(
                              userVoteDoc.id), // Delete specific vote
                        ),
                      ),
                    );
                  }

                  var voteDoc = pollSnapshot.data!;
                  bool isReleased = voteDoc['released'] ?? false;

                  String candidate1 = voteDoc['candidate1'] ?? 'Unknown';
                  String candidate2 = voteDoc['candidate2'] ?? 'Unknown';
                  String position = voteDoc['position'] ?? 'No position';

                  String pollName = '$candidate1 vs $candidate2';

                  // Get the vote count for each candidate
                  var candidates =
                      Map<String, dynamic>.from(voteDoc['votes'] ?? {});
                  var candidate1Votes = candidates[candidate1] ?? 0;
                  var candidate2Votes = candidates[candidate2] ?? 0;

                  // Set the minimum number of votes for each candidate to be considered
                  int minVotesForCandidate1 = 0;
                  int minVotesForCandidate2 = 0;

                  // Debug print to check the vote count
                  print(
                      'Candidate1: $candidate1Votes, Candidate2: $candidate2Votes');

                  // Check if both candidates have enough votes
                  if (candidate1Votes <= minVotesForCandidate1 &&
                      candidate2Votes <= minVotesForCandidate2) {
                    print('Not enough data for both candidates');
                    return Card(
                      margin: EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(pollName),
                        subtitle: Text('Not enough data'),
                      ),
                    );
                  }

                  return Card(
                    margin: EdgeInsets.all(8),
                    child: ListTile(
                      title: Text(pollName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Position: $position',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('You voted for ${userVoteDoc['voted_for']}'),
                          if (!isReleased)
                            Text(
                              'Results are not out',
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic),
                            ),
                          if (isReleased)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Winner: ${_getWinner(voteDoc)}',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '$candidate1: $candidate1Votes votes',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '$candidate2: $candidate2Votes votes',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavBarItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'Logout',
          ),
        ],
      ),
    );
  }

  // Helper function to get the winner
  // Helper function to get the winner
  String _getWinner(DocumentSnapshot voteDoc) {
    var candidates = Map<String, dynamic>.from(voteDoc['votes'] ?? {});
    var candidate1Votes = candidates[voteDoc['candidate1']] ?? 0;
    var candidate2Votes = candidates[voteDoc['candidate2']] ?? 0;

    // Debug print to check the vote count
    print(
        'Checking winner: Candidate1: $candidate1Votes, Candidate2: $candidate2Votes');

    // Check if either candidate has 1 vote and the other has 0
    if ((candidate1Votes == 1 && candidate2Votes == 0) ||
        (candidate1Votes == 0 && candidate2Votes == 1)) {
      return 'Not enough data';
    }

    // If candidate 1 has 2 or more votes and candidate 2 has 0, declare candidate 1 as the winner
    if (candidate1Votes >= 2 && candidate2Votes == 0) {
      return voteDoc['candidate1'];
    }

    // If candidate 2 has 2 or more votes and candidate 1 has 0, declare candidate 2 as the winner
    if (candidate2Votes >= 2 && candidate1Votes == 0) {
      return voteDoc['candidate2'];
    }

    // General Voting Logic for when both candidates have votes:
    if (candidate1Votes > candidate2Votes) {
      return voteDoc['candidate1'];
    } else if (candidate2Votes > candidate1Votes) {
      return voteDoc['candidate2'];
    } else {
      return 'Draw';
    }
  }

  // Function to delete a specific vote history
  void _deleteVote(String voteHistoryId) async {
    String userId = FirebaseAuth.instance.currentUser!.uid;

    try {
      await FirebaseFirestore.instance
          .collection('user_votes')
          .doc(userId)
          .collection('poll_votes')
          .doc(voteHistoryId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vote history deleted successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete vote history.')),
      );
    }
  }
}
