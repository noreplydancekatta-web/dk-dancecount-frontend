import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;

class ReportRegionScreen extends StatefulWidget {
  const ReportRegionScreen({super.key});

  @override
  State<ReportRegionScreen> createState() => _ReportRegionScreenState();
}

class _ReportRegionScreenState extends State<ReportRegionScreen> {
  String viewType = "Branch";
  bool showMonthly = true;
  final int _selectedIndex = 0;
  bool isLoading = true;
  List<Map<String, dynamic>> chartData = [];

  DateTimeRange selectedDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
  setState(() => isLoading = true);
  final uri = Uri.parse(
    "http://147.93.19.17:4000/api/reports/revenue-by-region"
    "?type=${viewType.toLowerCase()}"
    "&startDate=${selectedDateRange.start.toIso8601String()}"
    "&endDate=${selectedDateRange.end.toIso8601String()}"
  );

  try {
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['success'] == true && mounted) {
        setState(() {
          chartData = List<Map<String, dynamic>>.from(json['data']);
        });
      }
    } else {
      print("❌ Error fetching data: ${response.statusCode}");
    }
  } catch (e) {
    print("❌ Exception: $e");
  } finally {
    if (mounted) setState(() => isLoading = false);
  }
}


  void _openCalendarPopup() async {
    // You can integrate your calendar popup here
    // After selection, update selectedDateRange and call fetchData()
  }

  @override
  Widget build(BuildContext context) {
    final data = chartData;
    final highest = data.isNotEmpty ? data.reduce((a, b) => a['value'] > b['value'] ? a : b) : {'label': '-', 'value': 0};
    final lowest = data.isNotEmpty ? data.reduce((a, b) => a['value'] < b['value'] ? a : b) : {'label': '-', 'value': 0};

    return Scaffold(
      appBar: AppBar(
        title: const Text("Revenue by Region"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ToggleButtons(
                    borderRadius: BorderRadius.circular(10),
                    isSelected: [viewType == "City", viewType == "Branch"],
                    onPressed: (index) {
                      setState(() {
                        viewType = index == 0 ? "City" : "Branch";
                      });
                      fetchData();
                    },
                    children: const [
                      Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Text("City")),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Text("Branch")),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 4))
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            TextButton(
                              onPressed: () => setState(() => showMonthly = true),
                              child: Text("Monthly",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: showMonthly ? Colors.indigo : Colors.grey)),
                            ),
                            TextButton(
                              onPressed: () => setState(() => showMonthly = false),
                              child: Text("Yearly",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: !showMonthly ? Colors.indigo : Colors.grey)),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.calendar_today),
                              onPressed: _openCalendarPopup,
                            )
                          ],
                        ),
                        Text(
                          "${selectedDateRange.start.toLocal().toString().split(' ')[0]} - ${selectedDateRange.end.toLocal().toString().split(' ')[0]}",
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 12),
                        AspectRatio(
                          aspectRatio: 1.5,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              barTouchData: BarTouchData(enabled: true),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, _) {
                                      final index = value.toInt();
                                      if (index >= data.length) return const SizedBox.shrink();
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(data[index]['label'], style: const TextStyle(fontSize: 12)),
                                      );
                                    },
                                    reservedSize: 42,
                                  ),
                                ),
                                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              barGroups: data
                                  .asMap()
                                  .map((index, entry) => MapEntry(
                                        index,
                                        BarChartGroupData(
                                          x: index,
                                          barRods: [
                                            BarChartRodData(
                                              toY: (entry['value'] as num).toDouble(),
                                              color: Colors.indigo,
                                              width: 20,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                          ],
                                        ),
                                      ))
                                  .values
                                  .toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildMetricCard("Highest Revenue", highest['label'], "+20%", Colors.green),
                      const SizedBox(width: 16),
                      _buildMetricCard("Lowest Revenue", lowest['label'], "-5%", Colors.red),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String label, String change, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 16)),
            Text(change, style: TextStyle(color: color)),
          ],
        ),
      ),
    );
  }
}