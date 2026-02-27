import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'announcement_form.dart';
import 'announcement_history.dart';
import 'home.dart';
import 'addpage.dart';
import 'profile_screen.dart';

class Batch {
 final String id;
  final String batchName;
  final String branchName;
  final String branchArea;
  final String branchCity;
  final String style;
  final String level;
  final String startTime;
  final String endTime;
  final List<String> days;

  Batch({
   required this.id,
    required this.batchName,
    required this.branchName,
    required this.branchArea,
    required this.branchCity,
    required this.style,
    required this.level,
    required this.startTime,
    required this.endTime,
    required this.days,
  });

  factory Batch.fromJson(Map<String, dynamic> json) {
    final branch = json['branch'] ?? {};
    return Batch(
      id: json['_id'] ?? '',
      batchName: json['batchName'] ?? '',
      branchName: branch['name'] ?? '',
      branchArea: branch['area'] ?? '',
      branchCity: branch['city'] ?? '',
      style: json['style']?['name'] ?? '',
      level: json['level']?['name'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      days: List<String>.from(json['days'] ?? []),
    );
  }
}

class AnnouncementScreen extends StatefulWidget {
  const AnnouncementScreen({super.key});

  @override
  State<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreen> {
  List<Batch> batches = [];
  List<Batch> filteredBatches = [];
  bool isLoading = false;
  int _selectedIndex = -1;
  

  @override
  void initState() {
    super.initState();
    //fetchMetaData();
    fetchBatches();
  }

  

  Future<void> fetchBatches() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final studioId = prefs.getString('studio_id');
    if (studioId == null) {
      print('❌ Studio ID not found');
      setState(() => isLoading = false);
      return;
    }

   try {
  final uri = Uri.parse('http://147.93.19.17:4000/batchlist?studioId=$studioId');

final response = await http.get(
  uri,
  headers: {"Content-Type": "application/json"},
);

  print('Response body: ${response.body}'); // <-- add this

  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    setState(() {
      batches = data.map((json) => Batch.fromJson(json)).toList();
      filteredBatches = batches;
      isLoading = false;
    });
  } else {
    print('❌ Error status: ${response.statusCode}');
    print('❌ Response body: ${response.body}');
    setState(() => isLoading = false);
  }
} catch (e) {
  print('❌ Exception during fetch: $e');
  setState(() => isLoading = false);
}

  }

  void _searchBatches(String query) {
    setState(() {
      filteredBatches = batches
          .where((b) => b.batchName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Announcement"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search a batch for announcement",
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _searchBatches,
            ),
          ),

          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AnnouncementHistoryScreen()),
                  );
                },
                child: const Text(
                  "Previous Announcements",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredBatches.isEmpty
                    ? const Center(
                        child: Text(
                          'Oops!\n no results found',
                          style: TextStyle(fontStyle: FontStyle.italic),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: filteredBatches.length,
                        itemBuilder: (context, index) {
                          final batch = filteredBatches[index];
                          final initial = batch.batchName.isNotEmpty
                              ? batch.batchName[0].toUpperCase()
                              : '?';

                          return Padding(
                            padding: const EdgeInsets.fromLTRB(20, 30, 60, 20),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        AnnouncementForm(batchName: batch.batchName),
                                  ),
                                );
                              },
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: Colors.primaries[index % Colors.primaries.length]
                                          .shade400,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      initial,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 40),
                                  Expanded(
                                    child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(
      batch.batchName,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    ),
    const SizedBox(height: 2),
    Text(
      "${batch.branchArea}, ${batch.branchCity}",
      style: const TextStyle(
        fontSize: 13,
        color: Colors.black54,
      ),
    ),
    const SizedBox(height: 2),
    Text(
      batch.branchName,
      style: const TextStyle(
        fontSize: 13,
        color: Colors.black54,
      ),
    ),
  ],
),

                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
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
