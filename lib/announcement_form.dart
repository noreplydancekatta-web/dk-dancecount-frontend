import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'announcement.dart';
import 'home.dart';
import 'addpage.dart';
import 'profile_screen.dart';

class AnnouncementForm extends StatefulWidget {
  final String batchName;

  const AnnouncementForm({super.key, required this.batchName});

  @override
  State<AnnouncementForm> createState() => _AnnouncementFormState();
}

class _AnnouncementFormState extends State<AnnouncementForm> {
  final subjectController = TextEditingController();
  final messageController = TextEditingController();
  bool isLoading = false;
  int _selectedIndex = -1;

  Future<void> sendAnnouncement() async {
    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final loggedEmail = prefs.getString('loggedEmail');

    final title = subjectController.text.trim();
    final message = messageController.text.trim();
    final batch = widget.batchName;

    if (loggedEmail == null ||
        loggedEmail.isEmpty ||
        title.isEmpty ||
        message.isEmpty ||
        batch.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email, title, message, and batch name are required'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => isLoading = false);
      return;
    }

    final emailURL = Uri.parse('http://147.93.19.17:5003/send-announcement');
    final dbURL = Uri.parse('http://147.93.19.17:4000/announcements');

    try {
      final emailRes = await http.post(
        emailURL,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': loggedEmail,
          'title': title,
          'message': message,
          'batchName': batch,
        }),
      );

      if (emailRes.statusCode != 200) {
        final err = jsonDecode(emailRes.body)['message'] ?? 'Email failed';
        throw Exception(err);
      }

      final dbRes = await http.post(
        dbURL,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'message': message,
          'email': loggedEmail,
          'batchName': batch,
        }),
      );

      if (dbRes.statusCode != 201) {
        final err = jsonDecode(dbRes.body)['message'] ?? 'DB Save Failed';
        throw Exception(err);
      }

      _showSuccessDialog();
    } catch (err) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed: $err'), backgroundColor: Colors.red),
      );
    }

    setState(() => isLoading = false);
  }

  void _showSuccessDialog() => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/success.png', height: 100),
              const SizedBox(height: 12),
              const Text(
                'Announcement Sent!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const AnnouncementScreen()),
                  );
                },
                child: const Text('OK', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );

  InputDecoration _input(String label, String hint) => InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Announcement', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Send Announcement',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('To batch: ${widget.batchName}',
                style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 24),
            TextField(
              controller: subjectController,
              decoration: _input('Subject', 'e.g. Schedule Update'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: messageController,
              maxLines: 5,
              decoration: _input('Message', 'Write your announcement...'),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: sendAnnouncement,
                      child: const Text('Send Announcement',
                          style: TextStyle(fontSize: 16, color: Colors.white)),
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

    );
  }
}
