import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserViewRewardsPage extends StatelessWidget {
  const UserViewRewardsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Available Rewards')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('rewards').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Error loading rewards'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final rewards = snapshot.data!.docs;

          return ListView.builder(
            itemCount: rewards.length,
            itemBuilder: (context, index) {
              final reward = rewards[index];
              return Card(
                child: ListTile(
                  leading: reward['imageUrl'] != null
                      ? Image.network(reward['imageUrl'], width: 50, height: 50)
                      : const Icon(Icons.card_giftcard),
                  title: Text(reward['title']),
                  subtitle: Text('${reward['points']} points'),
                  trailing: ElevatedButton(
                    child: const Text("Redeem"),
                    onPressed: () {
                      _redeemReward(context, reward);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _redeemReward(BuildContext context, QueryDocumentSnapshot reward) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Redemption"),
        content: Text("Redeem '${reward['title']}' for ${reward['points']} points?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Redeem")),
        ],
      ),
    );

    if (confirm == true) {
      // Proceed to redeem
      // Implement point check and redemption logic below
    }
  }
}
