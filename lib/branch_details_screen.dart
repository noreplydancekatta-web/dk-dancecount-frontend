import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'models/branch.dart';
import 'branch_edit_delete.dart';
import 'profile_screen.dart';
import 'addpage.dart';
import 'home.dart';

class Batch {
  final String id;
  final String batchName;
  final String trainer;
  final String branch;
  final String style;
  final String level;
  final String fee;
  final String capacity;
  final String fromDate;
  final String toDate;
  final String startTime;
  final String endTime;
  final List<String> days;
  final List<String> enrolledStudents;

  Batch({
    required this.id,
    required this.batchName,
    required this.trainer,
    required this.branch,
    required this.style,
    required this.level,
    required this.fee,
    required this.capacity,
    required this.fromDate,
    required this.toDate,
    required this.startTime,
    required this.endTime,
    required this.days,
    required this.enrolledStudents,
  });

  factory Batch.fromJson(Map<String, dynamic> json) {
    return Batch(
      id: json['_id']?.toString() ?? '',
      batchName: json['batchName'] ?? '',
      trainer: json['trainer'] ?? '',
      branch: json['branch'] is Map ? json['branch']['name'] ?? '' : json['branch'] ?? '',
      style: json['style'] is Map ? json['style']['name'] ?? '' : json['style'] ?? '',
      level: json['level'] is Map ? json['level']['name'] ?? '' : json['level'] ?? '',
      fee: json['fee'] ?? '',
      capacity: json['capacity'] ?? '',
      fromDate: json['fromDate'] ?? '',
      toDate: json['toDate'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      days: List<String>.from(json['days'] ?? []),
      enrolledStudents: List<String>.from(json['enrolled_students'] ?? []),
    );
  }
}

class BranchDetailScreen extends StatefulWidget {
  final Branch branch;
  const BranchDetailScreen({super.key, required this.branch});

  @override
  State<BranchDetailScreen> createState() => _BranchDetailScreenState();
}

class _BranchDetailScreenState extends State<BranchDetailScreen> {
  List<Batch> batches = [];
  Set<int> expandedBatches = {};
  int _selectedIndex = -1;
  bool isLoading = true;
  int _imageTimestamp = 0;


  // ✅ add mutable copy
  Branch? currentBranch;

  @override
  void initState() {
    super.initState();
    currentBranch = widget.branch;
    fetchBatches();
  }

  String buildImagePath(String imageUrl) {
  if (imageUrl.isEmpty) return '';
  final base = imageUrl.startsWith('/uploads/')
      ? 'http://147.93.19.17:4000$imageUrl'
      : 'http://147.93.19.17:4000/uploads/$imageUrl';
  return _imageTimestamp != 0 ? '$base?t=$_imageTimestamp' : base;
}


  Widget _buildRow(String label, String value) { /* unchanged */ 
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _batchRow(String label, String value) { /* unchanged */ 
    return Row(
      children: [
        SizedBox(
          width: 160,
          child: Text("$label ", style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 14,fontWeight: FontWeight.w400)),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) { /* unchanged */ 
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _daysChips(List<String> days) { /* unchanged */ 
    final Map<String, String> dayShortMap = {
      'Mon': 'M', 'Tue': 'Tu', 'Wed': 'W', 'Thu': 'Th', 'Fri': 'F', 'Sat': 'Sa', 'Sun': 'Su',
    };
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 160,
            child: Text("Days ", style: TextStyle(fontSize: 14, color: Colors.grey)),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: days.map((day) {
              final short = dayShortMap[day] ?? (day.length >= 2
                  ? day[0].toUpperCase() + day[1].toLowerCase()
                  : day.toUpperCase());
              return Container(
                width: 36, height: 36, alignment: Alignment.center,
                decoration: const BoxDecoration(color: Colors.indigo, shape: BoxShape.circle),
                child: Text(short, style: const TextStyle(fontWeight: FontWeight.w100, fontSize: 13, color: Colors.white)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> fetchBatches() async { /* unchanged */ 
    try {
      final uri = Uri.parse('http://147.93.19.17:4000/api/byBranch');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'studioId': currentBranch?.studioId, 'branchId': currentBranch?.id}),
      );
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        final loaded = data.map((e) => Batch.fromJson(e)).toList();
        setState(() {
          batches = loaded;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        print('❌ Failed to load batches: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => isLoading = false);
      print('❌ Error fetching batches: $e');
    }
  }

  Widget _buildChip(String label) { /* unchanged */ 
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.indigo, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        title: const Text("Branch", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 20)),
        backgroundColor: Colors.white, elevation: 0,
      ),
      body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
               ClipRRect(
  borderRadius: BorderRadius.circular(8),
  child: () {
    final imagePath = buildImagePath(currentBranch?.imageUrl ?? '');
    return currentBranch != null && currentBranch!.imageUrl.isNotEmpty
        ? Image.network(
            imagePath,
            key: ValueKey(imagePath), // ensures rebuild when path changes
            height: 160,
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) =>
                loadingProgress == null
                    ? child
                    : Container(
                        height: 160,
                        width: double.infinity,
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(),
                      ),
            errorBuilder: (context, error, stackTrace) => Container(
              height: 160,
              color: Colors.grey[300],
              child: const Icon(Icons.image, size: 48, color: Colors.white),
            ),
          )
        : Container(
            height: 160,
            width: double.infinity,
            color: Colors.grey[300],
            child: const Center(child: Text("No Image")),
          );
  }(),
),

                
        
                const SizedBox(height: 16),
                _infoRow("Branch Name", currentBranch?.name ?? ''),
                const SizedBox(height: 12),
                _infoRow("Address", currentBranch?.address ?? ''),
                const SizedBox(height: 12),
                _infoRow("Contact Number", currentBranch?.contactNo ?? ''),
                const SizedBox(height: 16),
                _infoRow("No. of batches", "${batches.length}"),
                const SizedBox(height: 16),
                if (batches.isNotEmpty)
                  ...batches.asMap().entries.map((entry) {
                    final index = entry.key;
                    final b = entry.value;
                    final isExpanded = expandedBatches.contains(index);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                if (isExpanded) {
                                  expandedBatches.remove(index);
                                } else {
                                  expandedBatches.add(index);
                                }
                              });
                            },
                            child: Row(
                              children: [
                                Text(b.batchName, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 15)),
                                const Spacer(),
                                Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 20, color: Colors.indigo),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (isExpanded) ...[
                            _batchRow("Time", "${b.startTime} - ${b.endTime}"),
                            const SizedBox(height: 10),
                            _batchRow("Trainer", b.trainer),
                            const SizedBox(height: 10),
                            _batchRow("Style", b.style),
                            const SizedBox(height: 10),
                            _batchRow("Level", b.level),
                            const SizedBox(height: 10),
                            _batchRow("Enrolled", "${b.enrolledStudents.length} of ${b.capacity}"),
                            const SizedBox(height: 10),
                            _daysChips(b.days),
                          ],
                          const Divider(),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 32),
                Align(
                  alignment: Alignment.center,
                  child: ElevatedButton.icon(
  onPressed: () async {
  final updatedBranch = await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => BranchForm(branch: currentBranch)),
  );

  if (updatedBranch != null && updatedBranch is Branch) {
    setState(() {
      currentBranch = updatedBranch;
      _imageTimestamp = DateTime.now().millisecondsSinceEpoch; // force cache-bust
    });
  }

  await fetchBatches();
},

  label: const Text("Edit branch", style: TextStyle(fontSize: 16, color: Colors.white)),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.indigo,
    foregroundColor: Colors.indigo,
    padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 14),
    side: const BorderSide(color: Colors.indigo),
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
  ),
),

                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex == -1 ? 0 : _selectedIndex,
        selectedItemColor: _selectedIndex == -1 ? Colors.indigo.shade200 : Colors.indigo,
        unselectedItemColor: Colors.indigo.shade200,
        onTap: (index) {
          setState(() { _selectedIndex = index; });
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
