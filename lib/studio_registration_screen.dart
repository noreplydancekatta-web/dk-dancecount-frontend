import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
class UpdateStudioProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? studioData;

  const UpdateStudioProfileScreen({super.key, this.studioData});

  @override
  State<UpdateStudioProfileScreen> createState() =>
      _UpdateStudioProfileScreenState();
}
class CapitalizeWordsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text
        .split(' ')
        .map((word) =>
            word.isNotEmpty
                ? word[0].toUpperCase() + word.substring(1).toLowerCase()
                : '')
        .join(' ');

    return newValue.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
class _UpdateStudioProfileScreenState
    extends State<UpdateStudioProfileScreen> {
  String? existingLogoUrl;
  List<String> existingStudioPhotos = [];
  String? existingAadharFrontUrl;
  String? existingAadharBackUrl;

  final _formKey = GlobalKey<FormState>();

  final studioNameController = TextEditingController();
  final registeredAddressController = TextEditingController();
  final emailController = TextEditingController();
  final contactNumberController = TextEditingController();
  final gstNumberController = TextEditingController();
  final panController = TextEditingController();
  final aadharController = TextEditingController();
  final bankAccountController = TextEditingController();
  final reEnterBankAccountController = TextEditingController();
  final ifscController = TextEditingController();
  final introController = TextEditingController();
  final websiteController = TextEditingController();
  final facebookController = TextEditingController();
  final youtubeController = TextEditingController();
  final instagramController = TextEditingController();

  File? logoFile;
  List<File?> studioPhotos = List.generate(6, (index) => null);

  File? aadharFront;
  File? aadharBack;

  String? studioId;

 
@override
void initState() {
  super.initState();
  _loadStudioData();
}

Future<void> _loadStudioData() async {
  final prefs = await SharedPreferences.getInstance();
  studioId = prefs.getString('studio_id');

  // Use passed studioData if available, otherwise fetch from API
  final data = widget.studioData;

  if (data != null) {
    setState(() {
      studioNameController.text = data['studioName'] ?? '';
      registeredAddressController.text = data['registeredAddress'] ?? '';
      emailController.text = data['contactEmail'] ?? '';
      contactNumberController.text = data['contactNumber'] ?? '';
      gstNumberController.text = data['gstNumber'] ?? '';
      panController.text = data['panNumber'] ?? '';
      aadharController.text = data['aadharNumber'] ?? '';
      bankAccountController.text = data['bankAccountNumber'] ?? '';
      reEnterBankAccountController.text = data['bankAccountNumber'] ?? '';
      ifscController.text = data['bankIfscCode'] ?? '';
      introController.text = data['studioIntroduction'] ?? '';
      websiteController.text = data['studioWebsite'] ?? '';
      facebookController.text = data['studioFacebook'] ?? '';
      youtubeController.text = data['studioYoutube'] ?? '';
      instagramController.text = data['studioInstagram'] ?? '';
      existingLogoUrl = data['logoUrl'];
      existingStudioPhotos =
          (data['studioPhotos'] as List?)?.cast<String>() ?? [];
      existingAadharFrontUrl = data['aadharFrontUrl'];
      existingAadharBackUrl = data['aadharBackUrl'];
    });
  } else if (studioId != null) {
    // Fallback: fetch from API if studioData wasn't passed
    final response = await http.get(
      Uri.parse('http://147.93.19.17:4000/api/studios/$studioId'),
    );
    if (response.statusCode == 200) {
      final fetched = jsonDecode(response.body);
      setState(() {
        studioNameController.text = fetched['studioName'] ?? '';
        registeredAddressController.text = fetched['registeredAddress'] ?? '';
        emailController.text = fetched['contactEmail'] ?? '';
        contactNumberController.text = fetched['contactNumber'] ?? '';
        gstNumberController.text = fetched['gstNumber'] ?? '';
        panController.text = fetched['panNumber'] ?? '';
        aadharController.text = fetched['aadharNumber'] ?? '';
        bankAccountController.text = fetched['bankAccountNumber'] ?? '';
        reEnterBankAccountController.text = fetched['bankAccountNumber'] ?? '';
        ifscController.text = fetched['bankIfscCode'] ?? '';
        introController.text = fetched['studioIntroduction'] ?? '';
        websiteController.text = fetched['studioWebsite'] ?? '';
        facebookController.text = fetched['studioFacebook'] ?? '';
        youtubeController.text = fetched['studioYoutube'] ?? '';
        instagramController.text = fetched['studioInstagram'] ?? '';
        existingLogoUrl = fetched['logoUrl'];
        existingStudioPhotos =
            (fetched['studioPhotos'] as List?)?.cast<String>() ?? [];
        existingAadharFrontUrl = fetched['aadharFrontUrl'];
        existingAadharBackUrl = fetched['aadharBackUrl'];
      });
    } else {
      _showSnackbar("Failed to load studio data");
    }
  } else {
    _showSnackbar("No studio ID found. Please log in again.");
  }
}
  Future<void> _pickImage(Function(File) onPicked) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) onPicked(File(picked.path));
  }

  Future<void> _showSuccessDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/success.png', height: 100),
            const SizedBox(height: 8),
            const Text("Studio profile updated successfully!",
                style: TextStyle(fontSize: 14), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // close dialog only
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("OK, Cool!",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        title:
            const Text("Operation Failed", style: TextStyle(color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/fail.png', height: 80),
            const SizedBox(height: 12),
            Text(message,
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child:
                  const Text("OK", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<String?> _uploadFile(File file, String type) async {
    try {
      final uri = Uri.parse('http://147.93.19.17:4000/api/studios/upload-$type');
      var request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      var response = await request.send();

      if (response.statusCode == 200) {
        final resStr = await response.stream.bytesToString();
        final data = jsonDecode(resStr);
        return data['url'];
      } else {
        _showSnackbar('Failed to upload $type');
        return null;
      }
    } catch (e) {
      _showSnackbar('Error uploading $type: $e');
      return null;
    }
  }

  Future<void> _updateStudioProfile() async {
    if (_formKey.currentState!.validate()) {
      if (studioId == null) {
        _showSnackbar('Studio ID missing.');
        return;
      }

      if (bankAccountController.text !=
          reEnterBankAccountController.text) {
        _showSnackbar('Bank account numbers do not match.');
        return;
      }

      try {
        // --- 1. Upload files ---
        String? logoUrl;
        if (logoFile != null) {
          logoUrl = await _uploadFile(logoFile!, "logo");
        }

        List<String> studioPhotoUrls = [];
        for (var photo in studioPhotos) {
          if (photo != null) {
            final url = await _uploadFile(photo, "studios");
            if (url != null) studioPhotoUrls.add(url);
          }
        }

        String? aadharFrontUrl, aadharBackUrl;
        if (aadharFront != null) {
          aadharFrontUrl = await _uploadFile(aadharFront!, "aadhar");
        }
        if (aadharBack != null) {
          aadharBackUrl = await _uploadFile(aadharBack!, "aadhar");
        }

        // --- 2. Collect form data + uploaded URLs ---
        final updatedData = {
  'studioName': studioNameController.text,
  'registeredAddress': registeredAddressController.text,
  'contactEmail': emailController.text,
  'contactNumber': contactNumberController.text,
  'gstNumber': gstNumberController.text,
  'panNumber': panController.text,
  'aadharNumber': aadharController.text,
  'bankAccountNumber': bankAccountController.text,
  'bankIfscCode': ifscController.text,
  'studioIntroduction': introController.text,
  'studioWebsite': websiteController.text,
  'studioFacebook': facebookController.text,
  'studioYoutube': youtubeController.text,
  'studioInstagram': instagramController.text,
  'logoUrl': logoUrl ?? existingLogoUrl,
  'studioPhotos': studioPhotoUrls.isNotEmpty
      ? studioPhotoUrls
      : existingStudioPhotos,
  'aadharFrontUrl': aadharFrontUrl ?? existingAadharFrontUrl,
  'aadharBackUrl': aadharBackUrl ?? existingAadharBackUrl,
};


        // --- 3. Send PUT request ---
        final response = await http.put(
          Uri.parse('http://147.93.19.17:4000/api/studios/$studioId'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(updatedData),
        );

        if (response.statusCode == 200) {
          await _showSuccessDialog();
          if (mounted) Navigator.pop(context, true);
        } else {
          _showErrorDialog('Update failed: ${response.body}');
        }
      } catch (e) {
        _showErrorDialog("Unexpected error: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // pad existing URLs to always length 6
    List<String?> paddedExistingUrls =
        List<String?>.from(existingStudioPhotos);
    while (paddedExistingUrls.length < 6) {
      paddedExistingUrls.add(null);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Update Studio Profile',
            style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _field('Studio Name*', studioNameController, inputFormatters: [CapitalizeWordsFormatter()],),
              _field('Registered Address*', registeredAddressController, inputFormatters: [CapitalizeWordsFormatter()],),
              _field('Official Contact Email ID*', emailController),
              _field('Official Contact Number*', contactNumberController),
              _field('GST Registration Number (Optional)', gstNumberController),
              const SizedBox(height: 16),
              const Text('KYC Details of Studio Owner',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              _field('PAN Number of Owner*', panController),
              _field('Aadhar Number of Owner*', aadharController),
              Row(
                children: [
                  Expanded(
                    child: _uploadButton(
                      'Upload Aadhar Front',
                      file: aadharFront,
                      url: aadharFront == null ? existingAadharFrontUrl : null,
                      onPicked: (file) => setState(() {
                        aadharFront = file;
                        existingAadharFrontUrl = null;
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _uploadButton(
                      'Upload Aadhar Back',
                      file: aadharBack,
                      url: aadharBack == null ? existingAadharBackUrl : null,
                      onPicked: (file) => setState(() {
                        aadharBack = file;
                        existingAadharBackUrl = null;
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Bank Details of Studio',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              _field('Bank Account Number*', bankAccountController),
              _field('Re-enter Bank Account Number*',
                  reEnterBankAccountController),
              _field('Enter Bank IFSC Code*', ifscController),
              const SizedBox(height: 16),
              const Divider(),
              const Text('Upload Logo*',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              _uploadButton(
                'Upload Logo',
                file: logoFile,
                url: logoFile == null ? existingLogoUrl : null,
                onPicked: (file) => setState(() {
                  logoFile = file;
                  existingLogoUrl = null;
                }),
              ),
              const SizedBox(height: 16),
              const Text('Upload Studio Photos',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              GridView.builder(
                itemCount: 6,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8),
                itemBuilder: (context, index) {
                  return _uploadButton(
                    'Upload',
                    file: studioPhotos[index],
                    url: studioPhotos[index] == null
                        ? paddedExistingUrls[index]
                        : null,
                    onPicked: (file) => setState(() {
                      studioPhotos[index] = file;
                      paddedExistingUrls[index] = null;
                    }),
                  );
                },
              ),
              const SizedBox(height: 16),
              _field('Studio Introduction*', introController, maxLines: 4, inputFormatters: [CapitalizeWordsFormatter()],),
              _field('Studio Website', websiteController),
              _field('Studio Facebook Page', facebookController),
              _field('Studio YouTube Page', youtubeController),
              _field('Studio Instagram Page', instagramController),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _updateStudioProfile,
                  child: const Text('Update Profile',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller,
      {int maxLines = 1,List<TextInputFormatter>? inputFormatters,}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        inputFormatters: inputFormatters,
        validator: (v) => (v == null || v.trim().isEmpty) &&
                label.contains('*')
            ? 'Required'
            : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black87),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
    );
  }

Widget _uploadButton(String label,
    {File? file, String? url, required Function(File) onPicked}) {
  return GestureDetector(
    onTap: () => _pickImage(onPicked),
    child: Container(
      height: 90,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black26),
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey[100],
      ),
      child: (file != null || url != null)
          ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: file != null
                  ? Image.file(file, fit: BoxFit.cover)
                  : Image.network(
                      url!.startsWith('http')
                          ? url
                          : 'http://147.93.19.17:4000$url',
                      fit: BoxFit.cover,
                    ),
            )
          : Center(
              child: Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.black87)),
            ),
    ),
  );
}
}  