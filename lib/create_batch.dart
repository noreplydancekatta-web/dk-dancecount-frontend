import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'addpage.dart';
import 'home.dart';
import 'profile_screen.dart';

class OptionItem {
  final String id;
  final String name;
  OptionItem({required this.id, required this.name});
}

class CreateBatch extends StatefulWidget {
  const CreateBatch({super.key});

  @override
  State<CreateBatch> createState() => _CreateBatchState();
}

class _CreateBatchState extends State<CreateBatch> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController trainerController = TextEditingController();
  final TextEditingController feeController = TextEditingController();
  final TextEditingController capacityController = TextEditingController();

  String? startTime, endTime;
  String? startDate, endDate;
  List<String> selectedDays = [];

  List<OptionItem> branches = [];
  List<OptionItem> styles = [];
  List<OptionItem> levels = [];

  String? selectedBranchid;
  String? selectedStyleid;
  String? selectedLevelid;

  @override
  void initState() {
    super.initState();
    fetchMetaData();
  }

  @override
  void dispose() {
    nameController.dispose();
    trainerController.dispose();
    feeController.dispose();
    capacityController.dispose();
    super.dispose();
  }

  Future<void> fetchMetaData() async {
    final prefs = await SharedPreferences.getInstance();
    final studioId = prefs.getString('studio_id');

    if (studioId == null) {
      _showFailureDialog("Studio ID not found");
      return;
    }

    final uri =
        Uri.parse("http://147.93.19.17:4000/api/meta?studioId=$studioId");

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        branches = (data['branches'] as List)
            .map((e) => OptionItem(id: e['_id'], name: e['name']))
            .toList();
        styles = (data['styles'] as List)
            .map((e) => OptionItem(id: e['_id'], name: e['name']))
            .toList();
        levels = (data['levels'] as List)
            .map((e) => OptionItem(id: e['_id'], name: e['name']))
            .toList();
      });
    } else {
      _showFailureDialog("Failed to load metadata");
    }
  }

  Widget _inlineRow(String label, Widget field) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, color: Colors.grey)),
          ),
          const SizedBox(width: 10),
          Expanded(child: field),
        ],
      ),
    );
  }

  Future<void> pickTime(bool isStart) async {
    final time =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time != null) {
      final formatted = time.format(context);
      setState(() {
        isStart ? startTime = formatted : endTime = formatted;
      });
    }
  }

  Future<void> pickDate(bool isStart) async {
  final today = DateTime.now();

  // if selecting endDate but no startDate yet → block it
  if (!isStart && startDate == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please select From Date first")),
    );
    return;
  }

  final firstDate = isStart
      ? today
      : DateTime.parse(startDate!); // endDate can't be before startDate

  final date = await showDatePicker(
    context: context,
    initialDate: firstDate,
    firstDate: firstDate,
    lastDate: DateTime(2100),
  );

  if (date != null) {
    final formatted =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    setState(() {
      isStart ? startDate = formatted : endDate = formatted;
    });
  }
}

  Widget buildDayButton(String day) {
    final isSelected = selectedDays.contains(day);
    return GestureDetector(
      onTap: () {
        setState(() {
          isSelected ? selectedDays.remove(day) : selectedDays.add(day);
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.pinkAccent.shade200 : Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          day,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() ||
        startTime == null ||
        endTime == null ||
        selectedBranchid == null ||
        selectedStyleid == null ||
        selectedLevelid == null ||
        selectedDays.isEmpty) {
      _showFailureDialog("Please fill all required fields");
      return;
    }

    _formKey.currentState!.save();

    final prefs = await SharedPreferences.getInstance();
    final studioId = prefs.getString('studio_id');

    if (studioId == null) {
      _showFailureDialog("Studio ID not found");
      return;
    }

    final batchData = {
      "batchName": nameController.text,
      "trainer": trainerController.text,
      "branch": selectedBranchid,
      "style": selectedStyleid,
      "level": selectedLevelid,
      "studioId": studioId,
      "fee": feeController.text,
      "capacity": capacityController.text,
      "startTime": startTime,
      "endTime": endTime,
      "fromDate": startDate,
      "toDate": endDate,
      "days": selectedDays,
    };

    print("🚀 Sending batch data: ${json.encode(batchData)}");

    try {
      final response = await http.post(
        Uri.parse("http://147.93.19.17:4000/api/batches"),
        headers: {"Content-Type": "application/json"},
        body: json.encode(batchData),
      );

      print("🎯 Response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        _showSuccessDialog();
      } else {
        final errorData = json.decode(response.body);
        _showFailureDialog(errorData['message'] ?? "Failed to create batch");
      }
    } catch (e) {
      print("❌ Network error: $e");
      _showFailureDialog("Network error: ${e.toString()}");
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/success.png', height: 80),
            const SizedBox(height: 12),
            const Text("Success!",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 8),
            const Text("Batch created successfully"),
            const SizedBox(height: 16),
           ElevatedButton(
  onPressed: () {
    _resetForm(); // reset form safely
    Navigator.of(context, rootNavigator: true).pop(); // close dialog
    Navigator.pop(context, true); // go back to previous screen
  },
  child: const Text("OK"),
),


          ],
        ),
      ),
    );
  }

  void _showFailureDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/fail.png', height: 80),
            const SizedBox(height: 12),
            const Text("Error",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 8),
            Text(message),
            const SizedBox(height: 16),
           ElevatedButton(
  onPressed: () {
    Navigator.of(context, rootNavigator: true).pop(); // close only dialog
  },
  child: const Text("Try again"),
),

          ],
        ),
      ),
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      selectedDays = [];
      startTime = null;
      endTime = null;
      startDate = null;
      endDate = null;
      selectedBranchid = null;
      selectedStyleid = null;
      selectedLevelid = null;
      nameController.clear();
      trainerController.clear();
      feeController.clear();
      capacityController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Create Batch",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        leading: const BackButton(),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _inlineRow(
                "Name",
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Name is required' : null,
                ),
              ),
              const SizedBox(height: 12),
             _inlineRow(
  "Trainer",
  TextFormField(
    controller: trainerController,
    decoration: const InputDecoration(),
    autovalidateMode: AutovalidateMode.onUserInteraction, // <-- this triggers validation while typing
    validator: (v) {
      if (v == null || v.isEmpty) {
        return 'Trainer name is required';
      }
      if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(v)) {
        return 'Only alphabets allowed';
      }
      return null;
    },
  ),
),


              const SizedBox(height: 12),
            Row(
  children: [
    Expanded(
      child: Row(
        children: [
          const Text("From: ",
              style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
          Text(startDate ?? ''),
        ],
      ),
    ),
    IconButton(
      onPressed: () => pickDate(true),
      icon: const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
    ),
    Expanded(
      child: Row(
        children: [
          const Text("To: ",
              style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
          Text(
            endDate ?? '',
            style: TextStyle(
              color: startDate == null ? Colors.grey : Colors.black, // grey if disabled
            ),
          ),
        ],
      ),
    ),
    IconButton(
      onPressed: startDate == null
          ? null // disable button if no fromDate
          : () => pickDate(false),
      icon: Icon(
        Icons.calendar_today,
        size: 20,
        color: startDate == null ? Colors.grey.shade400 : Colors.grey, // greyed out
      ),
    ),
  ],
),


              const SizedBox(height: 12),
              _inlineRow(
                "Start Time",
                InkWell(
                  onTap: () => pickTime(true),
                  child: Row(
                    children: [
                      Text(startTime ?? '',
                          style: const TextStyle(fontSize: 15)),
                      const SizedBox(width: 6),
                      const Icon(Icons.access_time,
                          size: 18, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _inlineRow(
                "End Time",
                InkWell(
                  onTap: () => pickTime(false),
                  child: Row(
                    children: [
                      Text(endTime ?? '',
                          style: const TextStyle(fontSize: 15)),
                      const SizedBox(width: 6),
                      const Icon(Icons.access_time,
                          size: 18, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _inlineRow(
                "Branch",
                DropdownButtonFormField<String>(
                  value: selectedBranchid,
                  items: branches
                      .map((b) =>
                          DropdownMenuItem(value: b.id, child: Text(b.name)))
                      .toList(),
                  onChanged: (val) => setState(() => selectedBranchid = val),
                ),
              ),
              const SizedBox(height: 12),
              _inlineRow(
                "Style",
                DropdownButtonFormField<String>(
                  value: selectedStyleid,
                  items: styles
                      .map((s) =>
                          DropdownMenuItem(value: s.id, child: Text(s.name)))
                      .toList(),
                  onChanged: (val) => setState(() => selectedStyleid = val),
                ),
              ),
              const SizedBox(height: 12),
              _inlineRow(
                "Level",
                DropdownButtonFormField<String>(
                  value: selectedLevelid,
                  items: levels
                      .map((l) =>
                          DropdownMenuItem(value: l.id, child: Text(l.name)))
                      .toList(),
                  onChanged: (val) => setState(() => selectedLevelid = val),
                ),
              ),
              const SizedBox(height: 16),
              const Text("Days",
                  style: TextStyle(
                      fontWeight: FontWeight.w500, color: Colors.grey)),
              const SizedBox(height: 8),
              Wrap(
                children: ["Mon", "Tues", "Wed", "Thurs", "Fri", "Sat", "Sun"]
                    .map(buildDayButton)
                    .toList(),
              ),
              const SizedBox(height: 12),
              _inlineRow(
                "Fee",
                TextFormField(
                  controller: feeController,
                  decoration: const InputDecoration(),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Fee is required' : null,
                ),
              ),
              const SizedBox(height: 12),
              _inlineRow(
                "Capacity",
                TextFormField(
                  controller: capacityController,
                  decoration: const InputDecoration(),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value == null || value.isEmpty
                          ? 'Capacity is required'
                          : null,
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 67, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text("Save",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.indigo.shade200,
        onTap: (index) {
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddScreen()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
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
