import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'profile_screen.dart';
import 'addpage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'batch_list_screen.dart';
import 'home.dart';

class OptionItem {
  final String id;
  final String name;
  OptionItem({required this.id, required this.name});
}

class BatchEditDeleteScreen extends StatefulWidget {
  final String batchId;
  
  const BatchEditDeleteScreen({super.key, required this.batchId});

  @override
  State<BatchEditDeleteScreen> createState() => _BatchDetailScreenState();
}
int enrolledCount = 0; // ADD this near the top of _BatchDetailScreenState

class _BatchDetailScreenState extends State<BatchEditDeleteScreen> {
  int _selectedIndex = -1;
  final _formKey = GlobalKey<FormState>();
  String? startTime, endTime;
  DateTime? fromDate, toDate;
  List<String> selectedDays = [];

  List<OptionItem> branches = [];
  List<OptionItem> styles = [];
  List<OptionItem> levels = [];

  String? selectedBranchId;
  String? selectedStyleId;
  String? selectedLevelId;

  final TextEditingController _batchNameController = TextEditingController();
  final TextEditingController _trainerController = TextEditingController();
  final TextEditingController _feeController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();

  bool get isBatchExpired {
  if (toDate == null) return false;
  final now = DateTime.now();
  return toDate!.isBefore(DateTime(now.year, now.month, now.day));
}


  @override
  void initState() {
    super.initState();
    fetchMetaData().then((_) {
      fetchBatchDetails();
    });
  }

  Future<void> fetchMetaData() async {
    final prefs = await SharedPreferences.getInstance();
    final studioId = prefs.getString('studio_id');

    if (studioId == null) {
      print("❌ Studio ID not found in SharedPreferences");
      return;
    }

  final res = await http.get(
  Uri.parse("http://147.93.19.17:4000/api/meta?studioId=$studioId"),
);


    if (res.statusCode == 200) {
      final data = json.decode(res.body);
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
      print("❌ Failed to fetch meta data: \${res.statusCode}");
    }
  }

Future<void> fetchBatchDetails() async {
    final res = await http.post(
      Uri.parse('http://147.93.19.17:4000/api/batches/getbyid'),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"batchId": widget.batchId}),
    );

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      print("Fetched batch: \$data");

      setState(() {
        _batchNameController.text = data['batchName'] ?? '';
        _trainerController.text = data['trainer'] ?? '';
        _feeController.text = data['fee'] ?? '';
        _capacityController.text = data['capacity'] ?? '';
        startTime = data['startTime'];
        endTime = data['endTime'];
        selectedDays = List<String>.from(data['days'] ?? []);
        fromDate = data['fromDate'] != null ? DateTime.tryParse(data['fromDate'].split('T')[0]) : null;
        toDate = data['toDate'] != null ? DateTime.tryParse(data['toDate'].split('T')[0]) : null;
        enrolledCount = (data['enrolled_students'] as List).length;

        selectedBranchId = data['branch'];
        selectedStyleId = data['style'];
        selectedLevelId = data['level'];
      });
    } else {
      print("❌ Failed to fetch batch details: \${res.statusCode}");
    }
  }

  Future<void> pickTime(bool isStart) async {
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time != null) {
      final formatted = time.format(context);
      setState(() => isStart ? startTime = formatted : endTime = formatted);
    }
  }

  Future<void> pickDate(bool isFrom) async {
  final now = DateTime.now();
  final initialDate = isFrom ? now : (fromDate ?? now);
  final firstDate = isFrom ? now : (fromDate ?? now);

  final date = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: DateTime(2030),
  );

  if (date != null) {
    setState(() => isFrom ? fromDate = date : toDate = date);
  }
}


 Future<void> updateBatch() async {
  final int enteredCapacity = int.tryParse(_capacityController.text.trim()) ?? 0;

  if (enteredCapacity < enrolledCount) {
    showErrorDialog("Capacity cannot be less than enrolled students ($enrolledCount).");

    return;
  }

  final updatedData = {
    "batchId": widget.batchId,
    "batchName": _batchNameController.text.trim(),
    "trainer": _trainerController.text.trim(),
    "fee": _feeController.text.trim(),
    "capacity": _capacityController.text.trim(),
    "startTime": startTime,
    "endTime": endTime,
    "fromDate": fromDate?.toIso8601String(),
    "toDate": toDate?.toIso8601String(),
    "branch": selectedBranchId,
    "style": selectedStyleId,
    "level": selectedLevelId,
    "days": selectedDays,
  };

  final res = await http.post(
    Uri.parse("http://147.93.19.17:4000/api/updatebatch"),
    headers: {"Content-Type": "application/json"},
    body: json.encode(updatedData),
  );

  if (res.statusCode == 200) {
    // First success dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/success.png', height: 100),
            const SizedBox(height: 8),
            const Text("Batch updated successfully!", style: TextStyle(fontSize: 14), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
  onPressed: () {
    Navigator.pop(context);           // ✅ close the success dialog
    _showNotifyStudentsDialog();      // ✅ then show notify students dialog
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.indigo,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  child: const Text("OK, Cool!", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
)

          ],
        ),
      ),
    );
  } else {
    showErrorDialog("Failed to update batch. Please try again.");
  }
}

void _showNotifyStudentsDialog() async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Notify Students?"),
      content: const Text("Do you want to notify all enrolled students about the batch update?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("No"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text("Yes, Notify"),
        ),
      ],
    ),
  );

  if (confirm == true) {
    await notifyStudents();
  }

  // ✅ After notify, pop this edit page and tell previous screen we updated
  Navigator.pop(context, true);
}



Future<void> notifyStudents() async {
  final res = await http.post(
    Uri.parse("http://147.93.19.17:5003/notify-batch-created"),
    headers: {"Content-Type": "application/json"},
    body: json.encode({"batchId": widget.batchId}),
  );

  if (res.statusCode == 200) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Notification sent to students!")),
    );
  } else {
    showErrorDialog("Failed to send notifications to students.");
  }
}
  


  Future<void> deleteBatch() async {
  

  // ✅ Confirm delete
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Confirm Delete"),
      content: const Text("Are you sure you want to delete this batch? This action cannot be undone."),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          //style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
          child: const Text("Delete"),
        ),
      ],
    ),
  );

  if (confirm != true) return;

  // ✅ Proceed to delete
  final res = await http.post(
    Uri.parse("http://147.93.19.17:4000/api/deletebatch"),
    headers: {"Content-Type": "application/json"},
    body: json.encode({"batchId": widget.batchId}),
  );

  if (enrolledCount > 0) {
    // 🛑 Show error dialog
    showErrorDialog("This batch has $enrolledCount enrolled student(s). Please remove them before deleting.");

    return; // Stop further execution
  }

   if (res.statusCode == 200) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/success.png', height: 100),
          const SizedBox(height: 8),
          const Text("Batch deleted successfully!", style: TextStyle(fontSize: 14), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const BatchListScreen()), 
                (route) => false, // remove all previous routes so user can't go back
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("OK, Cool!", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          )
        ],
      ),
    ),
  );
} else {
  showErrorDialog("Failed to delete batch. (${res.statusCode})");
}




}

void showSuccessDialog(String message) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/success.png', height: 100), // ✅ use your success image
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(fontSize: 14), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("OK, Cool!", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          )
        ],
      ),
    ),
  );
}

void showErrorDialog(String message) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.all(24),
      title: const Text("Operation Failed", style: TextStyle(color: Colors.red)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/fail.png', height: 80), // ✅ use your error image
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(fontSize: 14), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("OK", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ),
  );
}

  Widget buildDayChip(String day) {
    final selected = selectedDays.contains(day);
    return GestureDetector(
      onTap: () => setState(() => selected ? selectedDays.remove(day) : selectedDays.add(day)),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.pinkAccent.shade200 : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(day, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: selected ? Colors.white : Colors.black)),
      ),
    );
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Batch", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        leading: const BackButton(),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AbsorbPointer(
    absorbing: isBatchExpired,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _inlineRow("Name", TextFormField(controller: _batchNameController)),


              const SizedBox(height: 12),
              _inlineRow(
  "Trainer",
  TextFormField(
    controller: _trainerController,
    decoration: const InputDecoration(),
    autovalidateMode: AutovalidateMode.onUserInteraction,
    validator: (v) {
      if (v == null || v.trim().isEmpty) {
        return 'Trainer name is required';
      }
      if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(v.trim())) {
        return 'Only alphabets allowed';
      }
      return null;
    },
  ),
),

              const SizedBox(height: 12),
                Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Expanded(
      child: Row(
        children: [
          const Text("From: ", style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
          Text(fromDate != null ? fromDate!.toLocal().toString().split(' ')[0] : ''),
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
          const Text("To: ", style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
          Text(toDate != null ? toDate!.toLocal().toString().split(' ')[0] : ''),
        ],
      ),
    ),
    IconButton(
      onPressed: fromDate == null ? null : () => pickDate(false),
      icon: Icon(Icons.calendar_today, size: 20, color: fromDate == null ? Colors.grey.shade400 : Colors.grey),
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
                              Text(startTime ?? '', style: const TextStyle(fontSize: 15)),
                              const SizedBox(width: 6),
                              const Icon(Icons.access_time, size: 18, color: Colors.grey),
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
                      Text(endTime ?? '', style: const TextStyle(fontSize: 15)),
                      const SizedBox(width: 6),
                      const Icon(Icons.access_time, size: 18, color: Colors.grey),
                    ],
                  ),
                ),
              ),


              const SizedBox(height: 12),
             _inlineRow(
  "Branch",
  DropdownButtonFormField(
    value: selectedBranchId,
    items: branches.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name))).toList(),
    onChanged: (val) => setState(() => selectedBranchId = val),
  ),
),
              const SizedBox(height: 12),
             _inlineRow(
  "Style",
  DropdownButtonFormField(
    value: selectedStyleId,
    items: styles.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name))).toList(),
    onChanged: (val) => setState(() => selectedStyleId = val),
  ),
),
              const SizedBox(height: 12),
              _inlineRow(
  "Level",
  DropdownButtonFormField(
    value: selectedLevelId,
    items: levels.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name))).toList(),
    onChanged: (val) => setState(() => selectedLevelId = val),
  ),
),
              const SizedBox(height: 16),
const Text("Days", style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
const SizedBox(height: 8),
Wrap(
  children: ["Mon", "Tues", "Wed", "Thurs", "Fri", "Sat", "Sun"]
      .map(buildDayChip)
      .toList(),
),


              const SizedBox(height: 16),
              _inlineRow("Fee", TextFormField(controller: _feeController, keyboardType: TextInputType.number)),

              const SizedBox(height: 12),
              _inlineRow("Capacity", TextFormField(controller: _capacityController, keyboardType: TextInputType.number)),

              const SizedBox(height: 20),
              Row(
  children: [
    if (isBatchExpired) ...[
      Expanded(
        child: ElevatedButton(
          onPressed: () {
            // You can implement actual archive logic here
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Batch archived!")),
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          child: const Text("Archive"),
        ),
      ),
    ] else ...[
      Expanded(
        child: ElevatedButton(
          onPressed: deleteBatch,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.indigo,
            side: const BorderSide(color: Colors.indigo),
            elevation: 0,
          ),
          child: const Text("Delete batch"),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: ElevatedButton(
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Confirm Update"),
                content: const Text("Are you sure you want to update this batch?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text("Yes, Update"),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              await updateBatch();
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor:  Colors.indigo, foregroundColor: Colors.white),
          child: const Text("Update"),
        ),
      ),
    ]
  ],
)


            ],
          ),
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
 