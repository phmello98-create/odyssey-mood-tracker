import 'package:flutter/material.dart';

class HorizontalCalendarTimeline extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final Function(DateTime) onDateSelected;
  final double leftMargin;
  final Color monthColor;
  final Color dayColor;
  final Color activeDayColor;
  final Color activeBackgroundDayColor;
  final Color dotsColor;
  final String locale;

  const HorizontalCalendarTimeline({
    Key? key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.onDateSelected,
    this.leftMargin = 20.0,
    this.monthColor = Colors.blueGrey,
    this.dayColor = Colors.teal,
    this.activeDayColor = Colors.white,
    this.activeBackgroundDayColor = Colors.redAccent,
    this.dotsColor = const Color(0xFF333A47),
    this.locale = 'en',
  }) : super(key: key);

  @override
  _HorizontalCalendarTimelineState createState() => _HorizontalCalendarTimelineState();
}

class _HorizontalCalendarTimelineState extends State<HorizontalCalendarTimeline> {
  late DateTime _selectedDate;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _scrollController = ScrollController(
      initialScrollOffset: _calculateInitialScrollOffset(),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  double _calculateInitialScrollOffset() {
    // Calculate initial scroll position to center the initial date
    final daysFromStart = _selectedDate.difference(widget.firstDate).inDays;
    return daysFromStart * 80.0 - 200.0; // 80 is approximate width of a date item, 200 centers it
  }

  @override
  Widget build(BuildContext context) {
    final daysCount = widget.lastDate.difference(widget.firstDate).inDays + 1;
    
    return Container(
      height: 100,
      padding: EdgeInsets.only(left: widget.leftMargin),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: daysCount,
        itemBuilder: (context, index) {
          final date = DateTime(
            widget.firstDate.year,
            widget.firstDate.month,
            widget.firstDate.day + index,
          );
          
          final isSelected = _isSameDay(_selectedDate, date);
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
              });
              widget.onDateSelected(date);
            },
            child: Container(
              width: 80,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getMonthName(date),
                    style: TextStyle(
                      color: isSelected ? widget.activeDayColor : widget.monthColor,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected ? widget.activeBackgroundDayColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        date.day.toString(),
                        style: TextStyle(
                          color: isSelected ? widget.activeDayColor : widget.dayColor,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Small indicator dot - you can customize this based on your needs
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.dotsColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getMonthName(DateTime date) {
    switch (date.month) {
      case 1: return 'Jan';
      case 2: return 'Feb';
      case 3: return 'Mar';
      case 4: return 'Apr';
      case 5: return 'May';
      case 6: return 'Jun';
      case 7: return 'Jul';
      case 8: return 'Aug';
      case 9: return 'Sep';
      case 10: return 'Oct';
      case 11: return 'Nov';
      case 12: return 'Dec';
      default: return '';
    }
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}