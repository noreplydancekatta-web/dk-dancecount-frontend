import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import './screen/signin_screen.dart';
import 'addpage.dart';
import 'home.dart';
import 'studio_registration_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedIndex = 2;
  Map<String, dynamic>? studioData;
  String? studioId, userEmail, userPhone;
  bool isLoading = true;

  final String apiUrl = 'http://147.93.19.17:4000/api/studios/';

  bool _policiesOpen = false;
  bool _contactOpen = false;

  @override
  void initState() {
    super.initState();
    _loadPrefsAndFetch();
  }

  Future<void> _loadPrefsAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    studioId = prefs.getString('studio_id');
    userEmail = prefs.getString('loggedEmail');
    userPhone = prefs.getString('phone');
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    debugPrint('>>> studio_id: $studioId');
    debugPrint('>>> loggedEmail: $userEmail');
    debugPrint('>>> userPhone: $userPhone');
    debugPrint('>>> isLoggedIn: $isLoggedIn');

    if (studioId == null || studioId!.isEmpty) {
      debugPrint('>>> No valid studio_id found in preferences');
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No studio ID found. Please log in again."),
          ),
        );
      }
      return;
    }

    await _fetchStudioData(studioId!);
  }

  Future<void> _fetchStudioData(String id) async {
    try {
      debugPrint('>>> Fetching studio ID: $id for email: $userEmail');
      final res = await http.get(Uri.parse('$apiUrl$id'));

      debugPrint('>>> API Response - Status: ${res.statusCode}');
      debugPrint('>>> API Response - Body length: ${res.body.length} chars');

      if (res.statusCode == 200) {
        final fetchedData = json.decode(res.body);

        // ────────────────────────────────────────────────────────────────
        // DEBUG PRINTS FOR FETCHED STUDIO DATA
        // ────────────────────────────────────────────────────────────────
        debugPrint('┌──────────────────────────────────────────────────────');
        debugPrint('>>> FULL FETCHED STUDIO DATA:');
        debugPrint('Body (pretty): ${const JsonEncoder.withIndent("  ").convert(fetchedData)}');
        debugPrint('──────────────────── Key fields ──────────────────────');
        debugPrint('  _id / studioId      → ${fetchedData['_id']}');
        debugPrint('  studioName          → ${fetchedData['studioName']}');
        debugPrint('  contactEmail        → ${fetchedData['contactEmail']}');
        debugPrint('  contactNumber       → ${fetchedData['contactNumber']}');
        debugPrint('  status              → ${fetchedData['status']}');
        debugPrint('  registeredAddress   → ${fetchedData['registeredAddress']}');
        debugPrint('  logoUrl             → ${fetchedData['logoUrl']}');
        debugPrint('  studioPhotos count  → ${(fetchedData['studioPhotos'] as List?)?.length ?? 0}');
        debugPrint('  ownerId             → ${fetchedData['ownerId']}');
        debugPrint('  createdAt           → ${fetchedData['createdAt']}');
        debugPrint('  updatedAt           → ${fetchedData['updatedAt']}');
        debugPrint('└──────────────────────────────────────────────────────');

        // Optional: Compare with logged email (for your debugging)
        if (userEmail != null && fetchedData['contactEmail'] != null) {
          final match = fetchedData['contactEmail'].toString().toLowerCase().trim() ==
              userEmail!.toLowerCase().trim();
          debugPrint('>>> Email match check: $match (API: ${fetchedData['contactEmail']} | Logged: $userEmail)');
        }

        setState(() {
          studioData = fetchedData;
          isLoading = false;
        });
      } else {
        debugPrint('>>> Studio fetch failed: ${res.statusCode} - ${res.body}');
        setState(() => isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load studio (HTTP ${res.statusCode})')),
          );
        }
      }
    } catch (e, stack) {
      debugPrint('>>> Error fetching profile: $e');
      debugPrint('Stack trace: $stack');
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  // ──────────────────────────────────────────────────────────────────────
  // The rest of your code remains unchanged (logout, launchUrl, build, etc.)
  // ──────────────────────────────────────────────────────────────────────

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SignInPage()),
      (_) => false,
    );
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  void _launchEmail() async {
    final to = studioData?['contactEmail'] ?? userEmail ?? '';
    final uri = Uri(
      scheme: 'mailto',
      path: to,
      query: 'subject=Help&body=Hi Team,',
    );
    if (!await launchUrl(uri)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open email app')),
      );
    }
  }

  Widget _thinDivider() =>
      const Divider(height: 1, thickness: 1, color: Colors.black12);

  @override
  Widget build(BuildContext context) {
    final showEmail = studioData?['contactEmail'] ?? userEmail ?? '';
    final showPhone = studioData?['contactNumber'] ?? userPhone ?? '';
    final showName = studioData?['studioName'] ?? '';
    final showProfile = studioData?['profilePictureUrl'] != null
        ? "http://147.93.19.17:4000/profile-pictures/${studioData!['profilePictureUrl'].split('/').last}"
        : 'http://via.placeholder.com/150';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(showProfile),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    showName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    showPhone,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    showEmail,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "The Dance Studio",
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 30),

                  // ACCOUNT section
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Account",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.edit),
                    title: const Text("Update Studio Profile"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final updated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UpdateStudioProfileScreen(),
                        ),
                      );

                      if (updated == true) {
                        _loadPrefsAndFetch();
                      }
                    },
                  ),

                  _thinDivider(),
                  const SizedBox(height: 16),

                  // SUPPORT section
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Support",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  // Policies
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.policy),
                    title: const Text("Policies"),
                    trailing: Icon(
                      _policiesOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    ),
                    onTap: () => setState(() => _policiesOpen = !_policiesOpen),
                  ),
                  if (_policiesOpen)
                    Padding(
                      padding: const EdgeInsets.only(left: 0, top: 8, bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () => _launchUrl("https://dancecount.com/privacy-policy/"),
                              icon: const Icon(Icons.privacy_tip, size: 18),
                              label: const Text("Privacy Policy"),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                alignment: Alignment.centerLeft,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () => _launchUrl("https://dancecount.com/terms-conditions/"),
                              icon: const Icon(Icons.description, size: 18),
                              label: const Text("Terms & Conditions"),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                alignment: Alignment.centerLeft,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  _thinDivider(),

                  // Contact Us
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.contact_support),
                    title: const Text("Contact Us"),
                    trailing: Icon(
                      _contactOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    ),
                    onTap: () => setState(() => _contactOpen = !_contactOpen),
                  ),
                  if (_contactOpen)
                    Padding(
                      padding: const EdgeInsets.only(left: 0, right: 16, top: 8, bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'For business and platform-related queries, please contact:',
                            style: TextStyle(fontSize: 14, height: 1.4),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () async {
                              final uri = Uri(
                                scheme: 'mailto',
                                path: 'noreply@dancecount.com',
                                query: 'subject=Help&body=Hi Team,',
                              );
                              if (!await launchUrl(uri)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Could not open email app')),
                                );
                              }
                            },
                            icon: const Icon(Icons.mail_outline, size: 18),
                            label: const Text('noreply@dancecount.com'),
                          ),
                        ],
                      ),
                    ),

                  _thinDivider(),

                  // Log out
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.logout, color: Colors.black),
                    title: const Text(
                      "Log Out",
                      style: TextStyle(color: Colors.black),
                    ),
                    onTap: _logout,
                  ),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.indigo.shade200,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddScreen()),
            );
          } else if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          } else {
            setState(() => _selectedIndex = index);
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