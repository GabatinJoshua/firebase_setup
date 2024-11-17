import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'vote_history_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, bool> _hasVotedForPolls = {};
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkIfUserHasVoted();
  }

  void _checkIfUserHasVoted() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    var userVoteDocs = await FirebaseFirestore.instance
        .collection('user_votes')
        .doc(userId)
        .collection('poll_votes')
        .get();

    for (var userVoteDoc in userVoteDocs.docs) {
      String pollId = userVoteDoc['poll_id'];
      setState(() {
        _hasVotedForPolls[pollId] = true;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => VoteHistory()),
      ).then((_) {
        setState(() {
          _selectedIndex = 0;
        });
      });
    } else if (index == 2) {
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
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('votes')
                    .where('released', isEqualTo: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  var votes = snapshot.data!.docs;

                  if (votes.isEmpty) {
                    return Center(
                      child: Text(
                        "No active polls available",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: votes.length,
                    itemBuilder: (context, index) {
                      var voteDoc = votes[index];
                      String pollId = voteDoc.id;
                      bool hasVoted = _hasVotedForPolls[pollId] ?? false;

                      if (hasVoted) {
                        return Container();
                      }

                      return Card(
                        margin: EdgeInsets.all(8),
                        color: Colors.blueGrey[200],
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            children: [
                              Text(
                                '${voteDoc['position']}',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 20),
                              ),
                              SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text(
                                          voteDoc['candidate1'],
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        SizedBox(height: 5),
                                        ElevatedButton(
                                          onPressed: () {
                                            _showVoteConfirmationDialog(voteDoc,
                                                voteDoc['candidate1'], pollId);
                                          },
                                          style: ButtonStyle(
                                            backgroundColor:
                                                MaterialStateProperty.all(
                                                    Colors.blueGrey),
                                            elevation:
                                                MaterialStateProperty.all(10),
                                            minimumSize:
                                                MaterialStateProperty.all(
                                                    Size(150, 50)),
                                            shape: MaterialStateProperty.all(
                                              RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            padding: MaterialStateProperty.all(
                                              EdgeInsets.symmetric(
                                                  vertical: 15, horizontal: 20),
                                            ),
                                          ),
                                          child: Text(
                                            "Vote",
                                            style: TextStyle(
                                                color: Colors.white70),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text(
                                          voteDoc['candidate2'],
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        SizedBox(height: 5),
                                        ElevatedButton(
                                          onPressed: () {
                                            _showVoteConfirmationDialog(voteDoc,
                                                voteDoc['candidate2'], pollId);
                                          },
                                          style: ButtonStyle(
                                            backgroundColor:
                                                MaterialStateProperty.all(
                                                    Colors.blueGrey),
                                            elevation:
                                                MaterialStateProperty.all(10),
                                            minimumSize:
                                                MaterialStateProperty.all(
                                                    Size(150, 50)),
                                            shape: MaterialStateProperty.all(
                                              RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            padding: MaterialStateProperty.all(
                                              EdgeInsets.symmetric(
                                                  vertical: 15, horizontal: 20),
                                            ),
                                          ),
                                          child: Text(
                                            "Vote",
                                            style: TextStyle(
                                                color: Colors.white70),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10),
                            ],
                          ),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
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

  void _showVoteConfirmationDialog(
      DocumentSnapshot voteDoc, String votedFor, String pollId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Your Vote'),
          content: Text('Are you sure you want to vote for $votedFor?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _submitVote(voteDoc, votedFor, pollId);
              },
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _submitVote(
      DocumentSnapshot voteDoc, String votedFor, String pollId) async {
    String userId = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance
        .collection('votes')
        .doc(voteDoc.id)
        .update({
      'votes.$votedFor': FieldValue.increment(1),
    });

    await FirebaseFirestore.instance
        .collection('user_votes')
        .doc(userId)
        .collection('poll_votes')
        .doc(pollId)
        .set({
      'user_id': userId,
      'voted_for': votedFor,
      'poll_id': pollId,
      'vote_time': Timestamp.now(),
    });

    setState(() {
      _hasVotedForPolls[pollId] = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Your vote for $votedFor has been cast')));
  }
}
