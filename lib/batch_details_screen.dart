import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'batch_edit_delete.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_screen.dart';
import 'addpage.dart';
import 'home.dart';


class BatchDetailScreen extends StatefulWidget {
  final String batchId;

  const BatchDetailScreen({super.key, required this.batchId});

  @override
  _BatchDetailScreenState createState() => _BatchDetailScreenState();
}

class _BatchDetailScreenState extends State<BatchDetailScreen> {
  Batch? batch;
  bool batchUpdated = false;
   int _selectedIndex = -1;
  Map<String, String> branchIdToName = {};
  Map<String, String> styleIdToName = {};
  Map<String, String> levelIdToName = {};

  @override
  void initState() {
    super.initState();
    fetchMetaDataAndBatch();
  }

  Color getStyleColor(String styleId) {
    final styleName = styleIdToName[styleId] ?? styleId;
    final index =
        styleName.codeUnits.fold(0, (prev, e) => prev + e) % Colors.primaries.length;
    return Colors.primaries[index].shade300;
  }

  Future<void> fetchMetaDataAndBatch() async {
    final prefs = await SharedPreferences.getInstance();
    final studioId = prefs.getString('studio_id');
    if (studioId == null) return;

    try {
      final response = await http.get(
  Uri.parse("http://147.93.19.17:4000/api/meta?studioId=$studioId"),
);


      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          branchIdToName = {
  for (var b in data['branches']) b['_id']: jsonEncode({
    'name': b['name'],
    'area': b['area'],
    'city': b['city'],
  })
};

          styleIdToName = {for (var s in data['styles']) s['_id']: s['name']};
          levelIdToName = {for (var l in data['levels']) l['_id']: l['name']};
        });
      }
    } catch (e) {
      print('❌ Error fetching meta: $e');
    }

    await fetchBatchDetails();
  }

 Future<void> fetchBatchDetails() async {
  try {
    final response = await http.get(
      Uri.parse('http://147.93.19.17:4000/batchdetails?id=${widget.batchId}'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      setState(() {
        batch = Batch.fromJson(jsonDecode(response.body));
      });
    } else {
      print('❌ Error: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Exception: $e');
  }
}


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, batchUpdated);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text("Batch", style: TextStyle(color: Colors.black)),
          leading: const BackButton(color: Colors.black),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: batch == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: getStyleColor(batch!.style),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        (styleIdToName[batch!.style] ?? batch!.style).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "${batch!.batchName} ",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _infoRow("Start date",batch!.fromDate.split('T').first),
                    
                    _infoRow("End date", batch!.toDate.split('T').first),
                  
                    _infoRow("Trainer", batch!.trainer),
                    
                    if (branchIdToName.containsKey(batch!.branch)) ...[
  Builder(builder: (_) {
    final branchJson = jsonDecode(branchIdToName[batch!.branch]!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow("Branch", branchJson['name']),
        
        _infoRow("Location", "${branchJson['area']}, ${branchJson['city']}"),
      ],
    );
  }),
] else ...[
  _infoRow("Branch", batch!.branch),
 
  _infoRow("Location", "N/A"),
],

                    
                    _infoRow("Time", "${batch!.startTime} - ${batch!.endTime}"),
                    
                    _infoRow("Style", styleIdToName[batch!.style] ?? batch!.style),
                    
                    _infoRow("Level", levelIdToName[batch!.level] ?? batch!.level),
                    const SizedBox(height: 16),
                   Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    SizedBox(
      width: 100, // Match width used in _infoRow titles
      child: const Text(
        "Days",
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: Colors.grey,
        ),
      ),
    ),
    Expanded(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: batch!.days.map((day) {
          final Map<String, String> dayShortMap = {
            'Mon': 'M',
      'Tue': 'Tu',
      'Wed': 'W',
      'Thu': 'Th',
      'Fri': 'F',
      'Sat': 'Sa',
      'Sun': 'Su',
          };

          final short = dayShortMap[day] ?? day.substring(0, 2);

          return Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Colors.indigo,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              short,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w100,
                fontSize: 13,
              ),
            ),
          );
        }).toList(),
      ),
    ),
  ],
),


                   const SizedBox(height: 16),
                    _infoRow("Total Fee", "₹${batch!.fee}"),
                    
                    _infoRow("Enrolled", "${batch!.enrolledStudents.length} Students"),
                    
                    _infoRow("Capacity", "${batch!.capacity} Students"),
                    const SizedBox(height: 36),
                    Center(
  child: ElevatedButton(
    onPressed: () async {
      final updated = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BatchEditDeleteScreen(batchId: batch!.id),
        ),
      );
      if (updated == true) {
        await fetchBatchDetails();
        batchUpdated = true;
      }
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.indigo,
      foregroundColor: Colors.indigo,
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 14),
      side: const BorderSide(color: Colors.indigo),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50), // 💡 High value for oval shape
      ),
    ),
    child: const Text(
      "Edit Batch",
      style: TextStyle(fontSize: 16, color: Colors.white),
    ),
  ),
),


                  ],
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

      ),
    );
  }

  Widget _infoRow(String title, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100, // Aligns all values neatly
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
      ],
    ),
  );
}


}

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
      branch: json['branch'] ?? '',
      style: json['style'] ?? '',
      level: json['level'] ?? '',
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
