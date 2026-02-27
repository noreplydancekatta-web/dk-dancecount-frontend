import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'addpage.dart';
import 'home.dart';
import 'profile_screen.dart';
import 'branch_list_screen.dart';

void main() => runApp(MaterialApp(home: BranchForm()));

class BranchForm extends StatefulWidget {
  const BranchForm({super.key});

  @override
  _BranchFormState createState() => _BranchFormState();
}

class _BranchFormState extends State<BranchForm> {
  final _formKey = GlobalKey<FormState>();
  String? selectedCountry, selectedState, selectedCity;
  List<String> countries = [], states = [], cities = [];
  File? _image;
  bool isLoading = false;

  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final contactNoController = TextEditingController();
  final pincodeController = TextEditingController();
  final areaController = TextEditingController();
  final mapLinkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchCountries();
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
        // keep selectedState as is
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
    if (pickedFile != null) setState(() => _image = File(pickedFile.path));
  }

 void submitForm() async {
  if (_formKey.currentState!.validate() && _image != null) {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? studioId = prefs.getString('studio_id');
    if (studioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Studio ID missing. Please login again."))
      );
      return;
    }

    try {
      var uri = Uri.parse('http://147.93.19.17:4000/api/branch/createBranch');
      var request = http.MultipartRequest('POST', uri);

      // Add text fields
      request.fields['name'] = nameController.text;
      request.fields['address'] = addressController.text;
      request.fields['contactNo'] = contactNoController.text;
      request.fields['pincode'] = pincodeController.text;
      request.fields['area'] = areaController.text;
      request.fields['mapLink'] = mapLinkController.text;
      request.fields['country'] = selectedCountry ?? '';
      request.fields['state'] = selectedState ?? '';
      request.fields['city'] = selectedCity ?? '';
      request.fields['studioId'] = studioId;

      // Add the image file
      request.files.add(await http.MultipartFile.fromPath('image', _image!.path));

      setState(() => isLoading = true); // optional loading indicator

      var response = await request.send();

      setState(() => isLoading = false);

      if (response.statusCode == 200) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            contentPadding: EdgeInsets.all(24),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/success.png', height: 100),
                SizedBox(height: 8),
                Text('Branch added successfully!', style: TextStyle(fontSize: 14)),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop(); // close dialog
                    clearForm(); // reset form
                    // Navigate to Branch List page
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => BranchListScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text("OK, Cool!", style: TextStyle(color: Colors.white)),
                )
              ],
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.statusCode}'))
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      print('Error uploading branch: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again.'))
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please fill all required fields and upload an image.'))
    );
  }
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text('Add Branch')),
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
                const SizedBox(height: 16),

                // Address
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Full Address*'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Contact
                TextFormField(
                  controller: contactNoController,
                  decoration: const InputDecoration(labelText: 'Contact Number*'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (!RegExp(r'^\d{10}$').hasMatch(v)) return 'Enter valid 10-digit number';
                    return null;
                  },
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 25),

                // Upload image preview
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('Upload photo', style: TextStyle(fontSize: 16, color: Colors.grey[850])),
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
                          ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(_image!, fit: BoxFit.cover))
                          : Center(child: Icon(Icons.add_a_photo, color: Colors.grey)),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Row: City & State
               // Row: Country & State
Row(
  children: [
    Expanded(
      child: DropdownButtonFormField<String>(
        value: selectedCountry,
        items: countries
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
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
    const SizedBox(width: 16),
    Expanded(
      child: DropdownButtonFormField<String>(
        value: selectedState,
        items: states
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        decoration: const InputDecoration(
          labelText: 'State*',
          border: OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: selectedCountry == null
            ? null
            : (val) {
                setState(() {
                  selectedState = val;
                  selectedCity = null;
                  cities = [];
                });
                fetchCities(val!);
              },
        validator: (v) =>
            selectedCountry == null
                ? null
                : (v == null ? 'Please select a state' : null),
      ),
    ),
  ],
),
const SizedBox(height: 16),

// Row: City & Pincode
Row(
  children: [
    Expanded(
      child: DropdownButtonFormField<String>(
        value: selectedCity,
        items: cities
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        decoration: const InputDecoration(
          labelText: 'City*',
          border: OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: selectedState == null ? null : (val) => setState(() => selectedCity = val),
        validator: (v) =>
            selectedState == null
                ? null
                : (v == null ? 'Please select a city' : null),
      ),
    ),
    const SizedBox(width: 16),
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

                const SizedBox(height: 16),

                // Area
                TextFormField(
                  controller: areaController,
                  decoration: const InputDecoration(labelText: 'Area*'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Google Map link
                TextFormField(
                  controller: mapLinkController,
                  decoration: const InputDecoration(labelText: 'Google Map Link'),
                ),
                const SizedBox(height: 25),

                // Submit button
                const SizedBox(height: 20),
                              Center(
                                child: ElevatedButton(
                                  onPressed: submitForm,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.indigo,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 67, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                  ),
                                  child: const Text("Save", style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),

              ],
            ),
          ),
        ),
      ),
       bottomNavigationBar: BottomNavigationBar(
  currentIndex: 1, // 'Add' tab is selected because you're on CreateBatch
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
