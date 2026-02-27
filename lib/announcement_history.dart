import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:timeago/timeago.dart' as timeago;
import 'addpage.dart';
import 'profile_screen.dart';
import 'home.dart';

class AnnouncementHistoryScreen extends StatefulWidget {
  const AnnouncementHistoryScreen({super.key});

  @override
  State<AnnouncementHistoryScreen> createState() => _AnnouncementHistoryScreenState();
}

class _AnnouncementHistoryScreenState extends State<AnnouncementHistoryScreen> {
  List<dynamic> history = [];
  bool isLoading = true;
  int _selectedIndex = -1;

  @override
  void initState() {
    super.initState();
    fetchHistory();
  }

  Future<void> fetchHistory() async {
    final url = Uri.parse("http://147.93.19.17:4000/announcements");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        data.sort((a, b) =>
            DateTime.parse(b['createdAt']).compareTo(DateTime.parse(a['createdAt'])));

        setState(() {
          history = data;
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load announcements");
      }
    } catch (e) {
      print('❌ Error fetching announcements: $e');
      setState(() => isLoading = false);
    }
  }

  Widget buildAnnouncementCard(Map<String, dynamic> ann) {
    final createdAtStr = ann['createdAt'];
    String timeAgo = '';

    if (createdAtStr != null) {
      final parsedDate = DateTime.tryParse(createdAtStr);
      if (parsedDate != null) {
        timeAgo = timeago.format(parsedDate);
      } else {
        timeAgo = 'Unknown time';
      }
    }

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ann['title'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              ann['message'] ?? '',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              timeAgo,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Announcement History"),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : history.isEmpty
              ? const Center(child: Text("No announcements yet."))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: ListView.builder(
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final ann = history[index];
                      return buildAnnouncementCard(ann);
                    },
                  ),
                ),
      bottomNavigationBar: BottomNavigationBar(
  currentIndex: _selectedIndex == -1 ? 0 : _selectedIndex, // fallback to 0 to avoid crash
  selectedItemColor: _selectedIndex == -1 ? Colors.indigo.shade200 : Colors.indigo, // inactive color when none selected
  unselectedItemColor: Colors.indigo.shade200,
  onTap: (index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AddScreen()));
    } else if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
    } else if (index == 0) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  },
  items: const [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Add'),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
  ],
),

    );
  }
}
