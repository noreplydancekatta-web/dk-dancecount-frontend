import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'batch_details_screen.dart';
import 'create_batch.dart';
import 'profile_screen.dart';
import 'addpage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart';

// ... (same imports)
class Batch {
  final String id;
  final String batchName;
  final String branchId;
  final String branchName;
  final String styleId;
  final String styleName;
  final String levelId;
  final String levelName;
  final String startTime;
  final String endTime;
  final List<String> days;

  Batch({
    required this.id,
    required this.batchName,
    required this.branchId,
    required this.branchName,
    required this.styleId,
    required this.styleName,
    required this.levelId,
    required this.levelName,
    required this.startTime,
    required this.endTime,
    required this.days,
  });

  factory Batch.fromJson(Map<String, dynamic> json) {
    return Batch(
      id: json['_id'] ?? '',
      batchName: json['batchName'] ?? '',
      branchId: json['branch']?['_id'] ?? '',
      branchName: json['branch']?['name'] ?? '',
      styleId: json['style']?['_id'] ?? '',
      styleName: json['style']?['name'] ?? '',
      levelId: json['level']?['_id'] ?? '',
      levelName: json['level']?['name'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      days: List<String>.from(json['days'] ?? []),
    );
  }
}


class BatchListScreen extends StatefulWidget {
  const BatchListScreen({super.key});

  @override
  State<BatchListScreen> createState() => _BatchListScreenState();
}

class _BatchListScreenState extends State<BatchListScreen> {
  int _selectedIndex = -1;
  List<Batch> batches = [];
  List<Batch> filteredBatches = [];

  Map<String, String> branchIdToName = {};
  Map<String, String> styleIdToName = {};
  Map<String, String> levelIdToName = {};

  @override
  void initState() {
    super.initState();
    fetchMetaData();
    fetchBatches();
  }

  Future<void> fetchMetaData() async {
    final prefs = await SharedPreferences.getInstance();
    final studioId = prefs.getString('studio_id');
    if (studioId == null) return;

    try {
      final response = await http.post(
        Uri.parse("http://147.93.19.17:4000/api/meta"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"studioId": studioId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          branchIdToName = {for (var b in data['branches']) b['_id']: b['name']};
          styleIdToName = {for (var s in data['styles']) s['_id']: s['name']};
          levelIdToName = {for (var l in data['levels']) l['_id']: l['name']};
        });
      }
    } catch (e) {
      print('❌ Error fetching meta: $e');
    }
  }

  Future<void> fetchBatches() async {
    final prefs = await SharedPreferences.getInstance();
    final studioId = prefs.getString('studio_id');

    if (studioId == null) {
      print('❌ Studio ID not found in SharedPreferences');
      return;
    }

    try {
      final response = await http.get(
  Uri.parse('http://147.93.19.17:4000/batchlist?studioId=$studioId'),
  headers: {"Content-Type": "application/json"},
);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          batches = data.map((batchJson) => Batch.fromJson(batchJson)).toList();
          filteredBatches = batches;
        });
      } else {
        print('❌ Error status: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
      }
    } catch (e) {
      print('❌ Exception during fetch: $e');
    }
  }

  void _searchBatches(String query) {
    setState(() {
      filteredBatches = batches
          .where((batch) => batch.batchName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch'),
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
                hintText: "Search batch",
                hintStyle: const TextStyle(fontSize: 14),
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
          Expanded(
            child: filteredBatches.isEmpty
                ? const Center(
                    child: Text(
                      '        Oops!\n no results found',
                      style: TextStyle(fontStyle: FontStyle.italic),
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
                        padding: const EdgeInsets.fromLTRB(20, 30, 60, 20), // More spacing vertically

                        child: InkWell(
                          onTap: () async {
  final updated = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => BatchDetailScreen(batchId: batch.id),
    ),
  );
  if (updated == true) {
    // If detail screen told us something was updated, refresh list
    await fetchBatches();
  }
},

                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.primaries[index % Colors.primaries.length].shade400,
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
                                      batch.branchName,

                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "${batch.startTime} - ${batch.endTime}",
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: batch.days.map((day) {
                                      final dayShortMap = {
                                        'Mon': 'M',
                                        'Tue': 'Tu',
                                        'Wed': 'W',
                                        'Thu': 'Th',
                                        'Fri': 'F',
                                        'Sat': 'Sa',
                                        'Sun': 'Su',
                                      };
                                      final short = dayShortMap[day] ??
    (day.length >= 2
        ? day[0].toUpperCase() + day[1].toLowerCase()
        : day.toUpperCase());

                                      return Container(
                                        width: 32,
                                        height: 32,
                                        alignment: Alignment.center,
                                        decoration: const BoxDecoration(
                                          color: Colors.indigo,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          short,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w100,
                                            fontSize: 12,
                                          ),
                                        ),
                                      );
                                    }).toList(),
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
      
     floatingActionButton: Padding(
  padding: const EdgeInsets.only(bottom: 16.0, right: 16.0),
  child: FloatingActionButton(
    onPressed: () async {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CreateBatch()),
      );
      // If a new batch was created, refresh the list
      if (result == true) {
        await fetchBatches();
      }
    },
    backgroundColor: Colors.pinkAccent.shade200,
    shape: const CircleBorder(),
    child: const Icon(
      Icons.add,
      color: Colors.white,
      size: 34,
    ),
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
