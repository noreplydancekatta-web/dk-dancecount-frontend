import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
//import 'package:shared_preferences/shared_preferences.dart';
import 'models/branch.dart'; // or correct relative path
import 'profile_screen.dart';
import 'addpage.dart';
import 'home.dart';
import 'branch_list_screen.dart'; // adjust path if needed





void main() => runApp(MaterialApp(home: BranchForm()));

class BranchForm extends StatefulWidget {
  final Branch? branch;

  const BranchForm({super.key, this.branch});

  @override
  _BranchFormState createState() => _BranchFormState();
  
  
}


class _BranchFormState extends State<BranchForm> {
 

  final _formKey = GlobalKey<FormState>();
  String? selectedCountry, selectedState, selectedCity;
  List<String> countries = [], states = [], cities = [];
  File? _image;
  bool isLoading = false;
  bool isEditMode = false;
  String? editingBranchId;
  int _selectedIndex = -1;

  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final contactNoController = TextEditingController();

  final pincodeController = TextEditingController();
  final areaController = TextEditingController();
  final mapLinkController = TextEditingController();

@override
void initState() {
  super.initState();
  fetchCountries().then((_) {
    if (widget.branch != null) {
      isEditMode = true;
      editingBranchId = widget.branch!.id;
      nameController.text = widget.branch!.name;
      addressController.text = widget.branch!.address;
      contactNoController.text = widget.branch!.contactNo;
      pincodeController.text = widget.branch!.pincode;
      areaController.text = widget.branch!.area;
      mapLinkController.text = widget.branch!.mapLink;

      selectedCountry = widget.branch!.country;
      selectedState = widget.branch!.state;
      selectedCity = widget.branch!.city;

      fetchStates(selectedCountry!, keepState: true).then((_) {
        fetchCities(selectedState!, keepCity: true).then((_) {
          // explicitly set again
          setState(() {
            if (cities.contains(widget.branch!.city)) {
              selectedCity = widget.branch!.city;
            }
          });
        });
      });
    }
  });
}



  Future<void> fetchCountries() async {
  final response = await http.get(Uri.parse('http://147.93.19.17:4000/api/country/getCountries'));
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    setState(() => countries = List<String>.from(data.map((e) => e['name'])));
  }
}

Future<void> fetchStates(String country, {bool keepState = false}) async {
  final uri = Uri.parse('http://147.93.19.17:4000/api/state/getStates?country=$country');
  final response = await http.get(uri);
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final newStates = List<String>.from(data.map((e) => e['name']));
    setState(() {
      states = newStates;
      if (keepState && selectedState != null && newStates.contains(selectedState)) {
        // keep selectedState
      } else {
        selectedState = null;
      }
      cities = [];
      selectedCity = null;
    });
  }
}

Future<void> fetchCities(String state, {bool keepCity = false}) async {
  final uri = Uri.parse('http://147.93.19.17:4000/api/city/getCities?state=$state');
  final response = await http.get(uri);
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final newCities = List<String>.from(data.map((e) => e['name']));
    setState(() {
      cities = newCities;
      if (keepCity && selectedCity != null && newCities.contains(selectedCity)) {
        // keep selectedCity
      } else {
        selectedCity = null;
      }
    });
  }
}

  Future<void> pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  
  
Future<void> editBranch() async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Confirm Update'),
      content: Text('Are you sure you want to update this branch?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text('Yes, Update')),
      ],
    ),
  );

  if (confirmed != true) return;

  if (_formKey.currentState!.validate() && editingBranchId != null) {
    setState(() => isLoading = true);

    try {
      final uri = Uri.parse('http://147.93.19.17:4000/api/branch/updateBranch');
      final request = http.MultipartRequest('POST', uri);

      // text fields
      request.fields['_id'] = editingBranchId!;
      request.fields['name'] = nameController.text;
      request.fields['address'] = addressController.text;
      request.fields['contactNo'] = contactNoController.text;
      request.fields['pincode'] = pincodeController.text;
      request.fields['area'] = areaController.text;
      request.fields['mapLink'] = mapLinkController.text;
      request.fields['country'] = selectedCountry ?? '';
      request.fields['state'] = selectedState ?? '';
      request.fields['city'] = selectedCity ?? '';

      // file if present
      if (_image != null) {
        request.files.add(await http.MultipartFile.fromPath('image', _image!.path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      setState(() => isLoading = false);

      // Debug: print server response (helpful while testing)
      print('EDIT BRANCH RESPONSE: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);

        // Try to find the returned image URL in common places
        String newImageUrl = widget.branch?.imageUrl ?? '';

        if (res is Map) {
          if (res['imageUrl'] != null && res['imageUrl'] is String) {
            newImageUrl = res['imageUrl'];
          } else if (res['data'] is Map && res['data']['imageUrl'] is String) {
            newImageUrl = res['data']['imageUrl'];
          } else if (res['branch'] is Map && res['branch']['imageUrl'] is String) {
            newImageUrl = res['branch']['imageUrl'];
          } else if (res['filename'] is String) {
            newImageUrl = res['filename'];
          } else if (res['file'] is Map && res['file']['filename'] is String) {
            newImageUrl = res['file']['filename'];
          }
        }

        // Fallback: if backend didn't return the image path, keep old value
        final updatedBranch = Branch(
          id: editingBranchId!,
          name: nameController.text,
          address: addressController.text,
          contactNo: contactNoController.text,
          pincode: pincodeController.text,
          area: areaController.text,
          mapLink: mapLinkController.text,
          country: selectedCountry ?? '',
          state: selectedState ?? '',
          city: selectedCity ?? '',
          imageUrl: newImageUrl, // important: pass server-provided path
          studioId: widget.branch?.studioId ?? '',
        );

        // show success and pop with updated branch
        showSuccessDialog("Branch updated successfully!", onClose: () {
          Navigator.pop(context, updatedBranch);
        });
      } else {
        final error = jsonDecode(response.body);
        showErrorDialog(error['message'] ?? 'Failed to update branch');
      }
    } catch (e) {
      setState(() => isLoading = false);
      showErrorDialog("Error: $e");
    }
  }
}




 Future<void> deleteBranch() async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Confirm Delete'),
      content: Text('Are you sure you want to delete this branch?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text('Yes, Delete')),
      ],
    ),
  );

  if (confirmed != true || editingBranchId == null) return;

  try {
    final response = await http.post(
      Uri.parse('http://147.93.19.17:4000/api/branch/deleteBranch'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'_id': editingBranchId, 'name': nameController.text}),
    );

    final responseBody = jsonDecode(response.body);

    if (response.statusCode == 200) {
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
              const Text("Branch deleted successfully!", style: TextStyle(fontSize: 14), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // close success dialog
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const BranchListScreen()),
                    (route) => false,
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
      // Show error from backend if exists
      showErrorDialog(responseBody['message'] ?? 'Failed to delete branch');
    }
  } catch (e) {
    showErrorDialog('Error: $e');
  }
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



  void clearForm() {
    setState(() {
      nameController.clear();
      addressController.clear();
      contactNoController.clear();

      pincodeController.clear();
      areaController.clear();
      mapLinkController.clear();
      selectedCountry = null;
      selectedState = null;
      selectedCity = null;
      _image = null;
      states = [];
      cities = [];
      editingBranchId = null;
      isEditMode = false;
    });
  }

  void showSuccessDialog(String message, {VoidCallback? onClose}) {
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
          Text(message, style: const TextStyle(fontSize: 14), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // close the dialog
              if (onClose != null) onClose(); // callback
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
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(title: Text('Branch Form')),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Branch name*'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 25),

              // Address
              TextFormField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Full Address*'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 25),

              // Contact Number
              TextFormField(
                controller: contactNoController,
                decoration: const InputDecoration(labelText: 'Contact Number*'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (!RegExp(r'^\d{10}$').hasMatch(v)) return 'Enter valid 10-digit mobile number';
                  return null;
                },
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 25),

              // Upload Image Label + Preview
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'Upload photo*',
                  style: TextStyle(
                    fontSize: 13, // same as InputDecoration default
                    color: Colors.grey[700], // same as labelText color
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),

              const SizedBox(height: 6),

Center(
  child: GestureDetector(
    onTap: pickImage,
    child: Container(
      width: 200,
      height: 150,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: _image != null
    ? ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(_image!, fit: BoxFit.cover),
      )
    : (widget.branch?.imageUrl != null && widget.branch!.imageUrl.isNotEmpty)
        ? ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              widget.branch!.imageUrl.startsWith('/uploads/')
                ? 'http://147.93.19.17:4000${widget.branch!.imageUrl}'
                : 'http://147.93.19.17:4000/uploads/${widget.branch!.imageUrl}',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image)),
            ),
          )
        : const Center(child: Icon(Icons.add_a_photo, color: Colors.grey)),

    ),
  ),
),

              const SizedBox(height: 30),

              // Row 1: City & State
            // Row 1: Country & State
Row(
  children: [
    Expanded(
      child: DropdownButtonFormField<String>(
        value: selectedCountry,
        isExpanded: true,
        items: countries.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        decoration: const InputDecoration(
          labelText: 'Country*',
          border: OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: (val) {
          setState(() {
            selectedCountry = val;
            selectedState = null;
            selectedCity = null;
            states = [];
            cities = [];
          });
          fetchStates(val!);
        },
        validator: (v) => v == null ? 'Please select a country' : null,
      ),
    ),
    const SizedBox(width: 10),
    Expanded(
      child: DropdownButtonFormField<String>(
        value: states.contains(selectedState) ? selectedState : null,
        isExpanded: true,
        items: states.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        decoration: const InputDecoration(
          labelText: 'State*',
          border: OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: selectedCountry == null
            ? null
            : (val) {
                if (val != selectedState) {
                  setState(() {
                    selectedState = val;
                    selectedCity = null;
                    cities = [];
                  });
                  fetchCities(val!);
                }
              },
        validator: (v) =>
            selectedCountry == null ? null : (v == null ? 'Please select a state' : null),
      ),
    ),
  ],
),

const SizedBox(height: 25),

// Row 2: City & Pincode
Row(
  children: [
    Expanded(
      child: DropdownButtonFormField<String>(
        value: cities.contains(selectedCity) ? selectedCity : null,
        isExpanded: true,
        items: cities.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        decoration: const InputDecoration(
          labelText: 'City*',
          border: OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: selectedState == null ? null : (val) => setState(() => selectedCity = val),
        validator: (v) =>
            selectedState == null ? null : (v == null ? 'Please select a city' : null),
      ),
    ),
    const SizedBox(width: 10),
    Expanded(
      child: TextFormField(
        controller: pincodeController,
        decoration: const InputDecoration(
          labelText: 'Pincode*',
          border: OutlineInputBorder(),
          isDense: true,
        ),
        keyboardType: TextInputType.number,
        validator: (v) {
          if (v == null || v.isEmpty) return 'Required';
          if (!RegExp(r'^\d{6}$').hasMatch(v)) return 'Enter valid 6-digit pincode';
          return null;
        },
      ),
    ),
  ],
),

              const SizedBox(height: 25),

              // Area
              TextFormField(
                controller: areaController,
                decoration: const InputDecoration(labelText: 'Area*'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 25),

              // Google Maps Link
              TextFormField(
                controller: mapLinkController,
                decoration: const InputDecoration(labelText: 'Google Map Link'),
                
              ),
              const SizedBox(height: 25),

              // Action Buttons
              Row(
  children: [
    Expanded(
      child: ElevatedButton(
        onPressed: isEditMode ? deleteBranch : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.indigo,
          side: const BorderSide(color: Colors.indigo),
          elevation: 0,
        ),
        child: const Text("Delete"),
      ),
    ),
    const SizedBox(width: 10),
    Expanded(
      child: ElevatedButton(
        onPressed: isEditMode ? editBranch : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
        ),
        child: const Text("Update"),
      ),
    ),
  ],
),

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
