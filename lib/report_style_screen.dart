import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'calendar_popup.dart';
import 'profile_screen.dart';
import 'addpage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ReportStyleScreen extends StatefulWidget {
  const ReportStyleScreen({super.key});

  @override
  State<ReportStyleScreen> createState() => _ReportStyleScreenState();
}

class _ReportStyleScreenState extends State<ReportStyleScreen> {
  int _selectedIndex = 0;
  bool isMonthly = true;
  DateTimeRange selectedDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  bool _isLoading = true;
  List<Map<String, dynamic>> revenueData = [];

  @override
  void initState() {
    super.initState();
    _fetchRevenueData();
  }

  Future<void> _fetchRevenueData() async {
    setState(() => _isLoading = true);
    try {
      final start = selectedDateRange.start.toIso8601String();
      final end = selectedDateRange.end.toIso8601String();
      final url =
          'http://147.93.19.17:4000/api/reports/revenue-by-style?startDate=$start&endDate=$end';

      print("\u{1F680} Starting API call...");
      print("\u{1F4E1} Fetching from: $url");

      final response = await http.get(Uri.parse(url));
      print("\u{1F4E5} Response status: ${response.statusCode}");
      print("\u{1F4E5} Response body: ${response.body}");

      final result = json.decode(response.body);
      final data = List<Map<String, dynamic>>.from(result['data'] ?? []);

      print("\u{2705} Parsed data: $data");

      if (!mounted) return;
      setState(() {
        revenueData = data;
        _isLoading = false;
      });
    } catch (e) {
      print("\u{274C} Error fetching revenue data: $e");
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _openCalendarPopup() {
    showDialog(
      context: context,
      builder: (_) => CalendarPopup(
        onApply: (start, end) {
          setState(() {
            selectedDateRange = DateTimeRange(start: start, end: end);
          });
          _fetchRevenueData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxY = revenueData.isEmpty
        ? 1000
        : revenueData.map((e) => e['value'] as num).reduce((a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Revenue by Style'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(blurRadius: 6, color: Colors.black12),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            ToggleButtons(
                              isSelected: [isMonthly, !isMonthly],
                              onPressed: (index) {
                                setState(() => isMonthly = index == 0);
                              },
                              borderRadius: BorderRadius.circular(8),
                              selectedColor: Colors.red,
                              fillColor: Colors.transparent,
                              borderColor: Colors.transparent,
                              selectedBorderColor: Colors.transparent,
                              textStyle: const TextStyle(fontWeight: FontWeight.bold),
                              children: const [
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Text("Monthly"),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Text("Yearly"),
                                ),
                              ],
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.calendar_today, size: 18),
                              onPressed: _openCalendarPopup,
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4, left: 4),
                            child: Text(
                              "${DateFormat('dd/MM/yyyy').format(selectedDateRange.start)} - ${DateFormat('dd/MM/yyyy').format(selectedDateRange.end)}",
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        AspectRatio(
                          aspectRatio: 1.5,
                          child: BarChart(
                            BarChartData(
                              maxY: maxY + 500,
                              borderData: FlBorderData(show: false),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    getTitlesWidget: (value, _) => Text(
                                      '${value ~/ 1000}k',
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                    interval: 1000,
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, _) {
                                      int index = value.toInt();
                                      if (index >= revenueData.length) return const SizedBox();
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          revenueData[index]['label'],
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              gridData: FlGridData(show: false),
                              barGroups: revenueData.asMap().entries.map((entry) {
                                int index = entry.key;
                                double value = (entry.value['value'] as num).toDouble();
                                return BarChartGroupData(
                                  x: index,
                                  barRods: [
                                    BarChartRodData(
                                      toY: value,
                                      width: 18,
                                      color: Colors.indigo,
                                      borderRadius: BorderRadius.circular(6),
                                    )
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.indigo,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AddScreen()));
          } else if (index == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
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
