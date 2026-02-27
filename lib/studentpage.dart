import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'student_details_screen.dart';
import 'addpage.dart';
import 'profile_screen.dart';
import 'home.dart';

class Student {
  final String id;
  final String fullName;
  final String imageUrl;
  final String status;

  Student({
    required this.id,
    required this.fullName,
    required this.imageUrl,
    required this.status,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    final fallbackImage = 'https://via.placeholder.com/150';
    return Student(
      id: json['_id'] ?? '',
      fullName: json['fullName'] ?? 'Unnamed',
      imageUrl:
          (json['imageUrl'] != null && json['imageUrl'].toString().isNotEmpty)
          ? json['imageUrl']
          : fallbackImage,
      status: json['status'] ?? 'inactive',
    );
  }
}

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  int _selectedIndex = -1;
  List<Student> allStudents = [];
  List<Student> filteredStudents = [];
  String selectedFilter = '';
  int totalCount = 0;
  int activeCount = 0;
  int inactiveCount = 0;

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    final prefs = await SharedPreferences.getInstance();
    final studioId = prefs.getString('studio_id') ?? '';

    final response = await http.get(
      Uri.parse('http://147.93.19.17:4000/api/students?studioId=$studioId'),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      final studentList = data.map((e) => Student.fromJson(e)).toList();

      setState(() {
        allStudents = studentList;
        totalCount = allStudents.length;
        activeCount = allStudents.where((s) => s.status == 'active').length;
        inactiveCount = allStudents.where((s) => s.status == 'inactive').length;
        selectedFilter = 'All ($totalCount)';
        applyFilter();
      });
    } else {
      print('Failed to load students: ${response.statusCode}');
    }
  }

  void applyFilter() {
    setState(() {
      if (selectedFilter.startsWith('All')) {
        filteredStudents = allStudents;
      } else if (selectedFilter.startsWith('Active')) {
        filteredStudents = allStudents
            .where((s) => s.status == 'active')
            .toList();
      } else {
        filteredStudents = allStudents
            .where((s) => s.status == 'inactive')
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filters = [
      'All ($totalCount)',
      'Active ($activeCount)',
      'Inactive ($inactiveCount)',
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Students", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: filters.map((status) {
              final isSelected = selectedFilter == status;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: OutlinedButton(
                  onPressed: () {
                    selectedFilter = status;
                    applyFilter();
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isSelected ? Colors.indigo : null,
                    foregroundColor: isSelected ? Colors.white : Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(status),
                ),
              );
            }).toList(),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  filteredStudents = allStudents
                      .where(
                        (s) => s.fullName.toLowerCase().contains(
                          value.toLowerCase(),
                        ),
                      )
                      .toList();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search student',
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                fillColor: Colors.grey[200],
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: filteredStudents.isEmpty
                ? const Center(child: Text("No students found."))
                : ListView.separated(
                    itemCount: filteredStudents.length,
                    separatorBuilder: (context, index) => const Divider(
                      color: Colors.grey,
                      thickness: 0.8,
                      indent: 72, // so it aligns nicely with avatar
                      endIndent: 16,
                    ),
                    itemBuilder: (context, index) {
                      final student = filteredStudents[index];
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.grey[200],
                          // backgroundImage: student.imageUrl.isNotEmpty
                          //     ? (student.imageUrl.startsWith('http')
                          //         ? NetworkImage(student.imageUrl)
                          //         : MemoryImage(base64Decode(
                          //             student.imageUrl.contains(',')
                          //                 ? student.imageUrl.split(',').last
                          //                 : student.imageUrl)))
                          //     : null,
                          backgroundImage: NetworkImage(
                            student.imageUrl.startsWith('http')
                                ? student.imageUrl
                                : 'http://147.93.19.17:4000${student.imageUrl}',
                          ),

                          child: student.imageUrl.isEmpty
                              ? const Icon(Icons.person, color: Colors.grey)
                              : null,
                        ),
                        title: Text(student.fullName),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  StudentDetailScreen(studentId: student.id),
                            ),
                          );
                          fetchStudents(); // ⬅️ Refresh data when coming back
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      

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
}
