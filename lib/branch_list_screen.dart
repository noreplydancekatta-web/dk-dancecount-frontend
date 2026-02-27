import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'create_branch.dart';
import 'branch_details_screen.dart';
import 'models/branch.dart';
import 'profile_screen.dart';
import 'addpage.dart';
import 'home.dart';

class BranchListScreen extends StatefulWidget {
  const BranchListScreen({super.key});

  @override
  _BranchListScreenState createState() => _BranchListScreenState();
}

class _BranchListScreenState extends State<BranchListScreen> {
  int _selectedIndex = -1;
  List<Branch> allBranches = [];
  List<Branch> filteredBranches = [];
  List<Map<String, dynamic>> cities = [{"city": "All", "count": 0}];
  String selectedCity = "All";
  bool isLoading = true;
  String? studioId;

  final TextEditingController searchController = TextEditingController();

@override
void dispose() {
  searchController.dispose();
  super.dispose();
}


  @override
  void initState() {
    super.initState();
    loadStudioIdAndFetch();
  }

  Future<void> loadStudioIdAndFetch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    studioId = prefs.getString('studio_id');

    if (studioId == null) {
      print("❌ studio_id not found in SharedPreferences");
      setState(() => isLoading = false);
      return;
    }

    await fetchBranchesAndCities();
  }

  Future<void> fetchBranchesAndCities() async {
  try {
    final uri = Uri.parse('http://147.93.19.17:4000/api/branches/list?studioId=$studioId');

    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      final loaded = data.map((e) => Branch.fromJson(e)).toList();
      setState(() {
        allBranches = loaded;
        filteredBranches = List.from(loaded);

        final cityMap = <String, int>{};
        for (var b in loaded) {
          final city = b.city.trim().toLowerCase();
          cityMap[city] = (cityMap[city] ?? 0) + 1;
        }

        cities = [
          {"city": "All", "count": allBranches.length},
          ...cityMap.entries.map((e) => {"city": e.key, "count": e.value})
        ];
      });
    } else {
      print('❌ Failed to load branches: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Error fetching branches: $e');
  } finally {
    if (mounted) setState(() => isLoading = false);
  }
}


  void filterBranches(String city) {
    setState(() {
      selectedCity = city;
      if (city == "All") {
        filteredBranches = List.from(allBranches);
      } else {
        filteredBranches = allBranches
            .where((b) => b.city.trim().toLowerCase() == city.trim().toLowerCase())
            .toList();
      }
    });
  }
  void filterBranchesBySearch(String query) {
  query = query.trim().toLowerCase();

  setState(() {
    if (query.isEmpty) {
      filterBranches(selectedCity);
    } else {
      filteredBranches = allBranches.where((b) {
        final name = b.name.toLowerCase();
        final city = b.city.toLowerCase();
        final area = b.area.toLowerCase();
        return name.contains(query) || city.contains(query) || area.contains(query);
      }).toList();
    }
  });
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Branch",
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 20)),
        centerTitle: false,
      ),
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                              controller: searchController,
                              decoration: const InputDecoration(
                                hintText: 'Search branch',
                                border: InputBorder.none,
                                icon: Icon(Icons.search, color: Colors.grey),
                              ),
                              onChanged: (query) {
                                filterBranchesBySearch(query);
                              },
                            ),

                  ),
                ),
SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: Padding(
    padding: const EdgeInsets.only(left: 16.0),
    child: Row(
      children: cities.map((city) {
        final isSelected = selectedCity == city['city'];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: OutlinedButton(
            onPressed: () => filterBranches(city['city']),
            style: OutlinedButton.styleFrom(
              backgroundColor: isSelected ? Colors.indigo : null,
              foregroundColor: isSelected ? Colors.white : Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: const BorderSide(color: Colors.grey),
            ),
            child: Text(
              "${city['city'][0].toUpperCase()}${city['city'].substring(1)} (${city['count']})",
              style: const TextStyle(fontSize: 14),
            ),
          ),
        );
      }).toList(),
    ),
  ),
),


                const SizedBox(height: 8),
                Expanded(
                  child: filteredBranches.isEmpty
                      ? const Center(child: Text("No branches found"))
                      : ListView.builder(
                          itemCount: filteredBranches.length,
                          itemBuilder: (context, index) {
                            final branch = filteredBranches[index];
                            return InkWell(
                              onTap: () async {
  final updated = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => BranchDetailScreen(branch: branch),
    ),
  );
  if (updated == true) {
    await fetchBranchesAndCities();
  }
},

                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12.0, horizontal: 16.0),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 100,
                                          height: 100,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            image: DecorationImage(
                                          image: branch.imageUrl.isNotEmpty
                                              ? NetworkImage('http://147.93.19.17:4000${branch.imageUrl}')
                                              : const AssetImage('assets/placeholder.jpg') as ImageProvider,

                                          fit: BoxFit.cover,
                                        ),

                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(branch.name,
                                                style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600)),
                                            const SizedBox(height: 4),
                                            Text(
                                              branch.area.isNotEmpty
                                                  ? "${branch.area}, ${branch.city}"
                                                  : branch.city,
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                  const Divider(height: 1),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      
       floatingActionButton: Padding(
 padding: const EdgeInsets.only(bottom: 16.0, right: 16.0),
  child: FloatingActionButton(
    onPressed: () {
       Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => BranchForm()),
                  );
    },
    backgroundColor: Colors.pinkAccent.shade200, // Light pink
    shape: const CircleBorder(),
     child: const Icon(
      Icons.add,
      color: Colors.white,
      size: 34, // 🔼 Increase icon size (default is ~24)
    ),
  ),
),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
