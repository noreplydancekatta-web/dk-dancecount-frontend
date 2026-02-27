import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarPopup extends StatefulWidget {
  final Function(DateTime, DateTime) onApply;
  const CalendarPopup({super.key, required this.onApply});

  @override
  State<CalendarPopup> createState() => _CalendarPopupState();
}

class _CalendarPopupState extends State<CalendarPopup> {
  DateTime focusedDay = DateTime.now();
  DateTime? startDate;
  DateTime? endDate;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TableCalendar(
              focusedDay: focusedDay,
              firstDay: DateTime(2022),
              lastDay: DateTime(2026),
              calendarFormat: CalendarFormat.month,
              selectedDayPredicate: (day) {
                if (startDate == null || endDate == null) return false;
                return day.isAfter(startDate!.subtract(const Duration(days: 1))) &&
                    day.isBefore(endDate!.add(const Duration(days: 1)));
              },
              onDaySelected: (selectedDay, _) {
                setState(() {
                  if (startDate == null || (startDate != null && endDate != null)) {
                    startDate = selectedDay;
                    endDate = null;
                  } else {
                    if (selectedDay.isBefore(startDate!)) {
                      endDate = startDate;
                      startDate = selectedDay;
                    } else {
                      endDate = selectedDay;
                    }
                  }
                });
              },
              onPageChanged: (focused) => focusedDay = focused,
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(color: Colors.pink.shade300, shape: BoxShape.circle),
                selectedDecoration: BoxDecoration(color: Colors.pink, shape: BoxShape.circle),
                rangeHighlightColor: Colors.pink.shade100,
                defaultTextStyle: const TextStyle(color: Colors.black),
                weekendTextStyle: const TextStyle(color: Colors.black),
              ),
              headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                if (startDate != null && endDate != null) {
                  widget.onApply(startDate!, endDate!);
                  Navigator.pop(context);
                }
              },
              child: const Text("Apply"),
            )
          ],
        ),
      ),
    );
  }
}
