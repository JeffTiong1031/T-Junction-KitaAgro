import 'package:flutter/material.dart';
import '../../core/services/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  // Fetch only reports created by this specific user
  late final Stream<QuerySnapshot> _myReportsStream = FirebaseFirestore.instance
      .collection('pest_reports')
      .where('reporterId', isEqualTo: currentUserId)
      .snapshots();

  Future<void> _markAsCleared(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('pest_reports')
          .doc(docId)
          .update({'status': 'cleared'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).outbreakMarkedCleared),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context).errorClearingOutbreak}: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).myOutbreakReports),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: currentUserId.isEmpty
          ? Center(child: Text(AppLocalizations.of(context).pleaseLoginReports))
          : StreamBuilder<QuerySnapshot>(
              stream: _myReportsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      AppLocalizations.of(context).errorLoadingReports,
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.history, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context).noOutbreaksYet,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Sort reports locally by newest first to avoid needing a complex Firestore index
                docs.sort((a, b) {
                  final dataA = a.data() as Map<String, dynamic>;
                  final dataB = b.data() as Map<String, dynamic>;
                  Timestamp? tA = dataA['timestamp'] as Timestamp?;
                  Timestamp? tB = dataB['timestamp'] as Timestamp?;
                  if (tA == null || tB == null) return 0;
                  return tB.compareTo(tA);
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final String pestName = data['pestName'] ?? 'Unknown Pest';
                    final String status = data['status'] ?? 'active';
                    final Timestamp? timestamp =
                        data['timestamp'] as Timestamp?;

                    String dateString = 'Pending...';
                    if (timestamp != null) {
                      dateString = DateFormat(
                        'MMM d, yyyy - h:mm a',
                      ).format(timestamp.toDate());
                    }

                    final bool isActive = status == 'active';

                    return Card(
                      elevation: isActive ? 3 : 1,
                      margin: const EdgeInsets.only(bottom: 12),
                      color: isActive ? Colors.white : Colors.grey.shade100,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    pestName,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isActive
                                          ? Colors.black87
                                          : Colors.grey,
                                      decoration: isActive
                                          ? null
                                          : TextDecoration.lineThrough,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? Colors.red.shade100
                                        : Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    isActive
                                        ? AppLocalizations.of(context).active
                                        : AppLocalizations.of(context).cleared,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isActive
                                          ? Colors.red.shade800
                                          : Colors.green.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  dateString,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            if (isActive) ...[
                              const Divider(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _markAsCleared(doc.id),
                                  icon: const Icon(
                                    Icons.check_circle_outline,
                                    color: Colors.green,
                                  ),
                                  label: Text(
                                    AppLocalizations.of(context).markAsCleared,
                                    style: const TextStyle(color: Colors.green),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.green),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
}
