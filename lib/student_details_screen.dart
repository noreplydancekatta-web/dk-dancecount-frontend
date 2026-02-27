import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'addpage.dart';
import 'home.dart';
import 'profile_screen.dart';

class StudentDetailScreen extends StatefulWidget {
  final String studentId;

  const StudentDetailScreen({super.key, required this.studentId});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  Map<String, dynamic>? studentData;
  bool showPersonal = true;
  bool showBatches = true;
  int _selectedIndex = -1;
  Set<int> expandedBatches = {};

  @override
  void initState() {
    super.initState();
    fetchStudentDetail();
  }

  Future<void> fetchStudentDetail() async {
    final url =
        'http://147.93.19.17:4000/studentdetails?id=${widget.studentId}';
    final response = await http.get(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      setState(() {
        studentData = json.decode(response.body);
      });
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load student details')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (studentData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final batches = studentData!['enrolled_batches'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        leading: const BackButton(color: Colors.black),
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Avatar
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey[300],
                backgroundImage:
                    (studentData!['imageUrl'] != null &&
                        studentData!['imageUrl'].toString().isNotEmpty)
                    ? NetworkImage(
                        studentData!['imageUrl'].toString().startsWith('http')
                            ? studentData!['imageUrl']
                            : 'http://147.93.19.17:4000${studentData!['imageUrl']}',
                      )
                    : null,

                child: studentData!['imageUrl'] == null
                    ? const Icon(Icons.person, size: 40, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(height: 24),

            /// Section Header: Personal Details
            sectionHeader("Personal Details", showPersonal, () {
              setState(() => showPersonal = !showPersonal);
            }),
            if (showPersonal) ...[
              const SizedBox(height: 14),
              _infoText(
                "Name",
                "${studentData!['firstName'] ?? ''} ${studentData!['lastName'] ?? ''}",
              ),
              const SizedBox(height: 14),

              _infoText("Mobile Number", studentData!['mobile'] ?? '-'),
              const SizedBox(height: 14),

              _infoText(
                "Alternate Mobile Number",
                studentData!['altMobile'] ?? 'Enter number',
              ),
              const SizedBox(height: 14),

              _infoText(
                "Date of Birth",
                (studentData!['dateOfBirth'] != null)
                    ? studentData!['dateOfBirth'].toString().split('T').first
                    : 'DD/MM/YYYY',
              ),

              _infoText(
                "Email address",
                studentData!['email'] ?? 'xxxx@gmail.com',
              ),
              const SizedBox(height: 14),

              _infoText("House/Flat no.", studentData!['address'] ?? '-'),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _infoText("City", studentData!['city'] ?? '-'),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _infoText("State", studentData!['state'] ?? '-'),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _infoText("Pincode", studentData!['pincode'] ?? '-'),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _infoText("Country", studentData!['country'] ?? '-'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],

            const SizedBox(height: 24),

            /// Section Header: Batch Details
            sectionHeader("Batch Details", showBatches, () {
              setState(() => showBatches = !showBatches);
            }),

            if (showBatches)
              ...batches.asMap().entries.map<Widget>((entry) {
                final index = entry.key;
                final batch = entry.value;
                final isExpanded = expandedBatches.contains(index);

                return Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 16),
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
                            Text(
                              batch['batchName'] ?? 'Unnamed Batch',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              isExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              size: 20,
                              color: Colors.indigo,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (isExpanded) ...[
                        _batchRow("Branch", batch['branch'] ?? '-'),
                        const SizedBox(height: 14),
                        _batchRow(
                          "Time",
                          "${batch['startTime'] ?? '-'} - ${batch['endTime'] ?? '-'}",
                        ),
                        const SizedBox(height: 14),
                        _batchRow("Style", batch['style'] ?? '-'),
                        const SizedBox(height: 14),
                        _batchRow("Level", batch['level'] ?? '-'),
                        const SizedBox(height: 14),
                        _daysChips(batch['days']),
                        const SizedBox(height: 14),
                      ],
                      const Divider(),
                    ],
                  ),
                );
              }).toList(),
          ],
        ),
      ),

      /// Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex == -1
            ? 0
            : _selectedIndex, // fallback to 0 to avoid crash
        selectedItemColor: _selectedIndex == -1
            ? Colors.indigo.shade200
            : Colors.indigo, // inactive color when none selected
        unselectedItemColor: Colors.indigo.shade200,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddScreen()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          } else if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
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

  Widget sectionHeader(String title, bool expanded, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            size: 20,
            color: Colors.indigo,
          ),
        ],
      ),
    );
  }

  Widget _infoText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text.rich(
        TextSpan(
          text: '$label\n',
          style: const TextStyle(
            fontSize: 13,
            color: Colors.grey,
            fontWeight: FontWeight.w400,
          ),
          children: [
            TextSpan(
              text: value,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _batchRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              "$label :",
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _daysChips(dynamic daysList) {
    final List<dynamic> days = daysList ?? [];

    // Map full day to short form (1–2 letters)
    final Map<String, String> dayShortMap = {
      'Mon': 'M',
      'Tue': 'Tu',
      'Wed': 'W',
      'Thu': 'Th',
      'Fri': 'F',
      'Sat': 'Sa',
      'Sun': 'Su',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 90,
            child: Text(
              "Days :",
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: days.map<Widget>((day) {
              final short =
                  dayShortMap[day] ??
                  (day.length >= 2
                      ? day[0].toUpperCase() + day[1].toLowerCase()
                      : day.toUpperCase());
              return Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.indigo,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  short,
                  style: const TextStyle(
                    fontWeight: FontWeight.w100,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
