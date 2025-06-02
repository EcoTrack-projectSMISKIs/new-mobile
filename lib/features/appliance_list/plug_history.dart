import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class PlugHistoryPage extends StatefulWidget {
  final String plugId;

  const PlugHistoryPage({Key? key, required this.plugId}) : super(key: key);

  @override
  State<PlugHistoryPage> createState() => _PlugHistoryPageState();
}

enum TimeRange {
  yesterday('yesterday', 'Yesterday', Icons.today_rounded),
  week('week', 'This Week', Icons.date_range_rounded),
  month('month', 'This Month', Icons.calendar_month_rounded),
  year('year', 'This Year', Icons.calendar_today_rounded);

  const TimeRange(this.value, this.label, this.icon);
  final String value;
  final String label;
  final IconData icon;
}

class _PlugHistoryPageState extends State<PlugHistoryPage> {
  List<ChartData> chartData = [];
  bool isLoading = true;
  String? errorMessage;
  TimeRange selectedRange = TimeRange.yesterday;

  @override
  void initState() {
    super.initState();
    fetchChartData();
  }

Future<void> fetchChartData() async {
  try {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse(
          '${dotenv.env['BASE_URL']}/api/plugs/${widget.plugId}/chart?range=${selectedRange.value}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      print('=== API Response for ${selectedRange.value} ===');
      print('Full response: ${json.encode(data)}');

      List<ChartData> tempData = [];

      if (data['chart'] != null && data['chart'] is List) {
        final chartArray = data['chart'] as List;
        print('Chart data length: ${chartArray.length}');

        for (int i = 0; i < chartArray.length; i++) {
          var item = chartArray[i];

          print('Item $i: ${json.encode(item)}');

          // Parse timestamp (renamed to 'date')
          DateTime timestamp;
          try {
            timestamp = DateTime.parse(item['date']);
          } catch (e) {
            print('Error parsing date: ${item['date']}, using current time');
            timestamp = DateTime.now().subtract(Duration(days: chartArray.length - i));
          }

          // Extract current and previous values (renamed keys)
          double currentValue = double.tryParse(item['today'].toString()) ?? 0.0;
          double previousValue = double.tryParse(item['yesterday'].toString()) ?? 0.0;

          print('Extracted values - Current: $currentValue, Previous: $previousValue');

          tempData.add(ChartData(
            timestamp,
            previousValue,
            currentValue,
          ));
        }
      } else {
        print('No chart data in response or invalid format');
      }

      setState(() {
        chartData = tempData;
        isLoading = false;
      });
    } else {
      print('API Error: ${response.statusCode} - ${response.body}');
      setState(() {
        errorMessage = 'Failed to load data: ${response.statusCode}';
        isLoading = false;
      });
    }
  } catch (e) {
    print('Exception in fetchChartData: $e');
    setState(() {
      errorMessage = 'Error: $e';
      isLoading = false;
    });
  }
}

  String _getComparisonLabel() {
    switch (selectedRange) {
      case TimeRange.yesterday:
        return 'Day Before Yesterday';
      case TimeRange.week:
        return 'Last Week';
      case TimeRange.month:
        return 'Last Month';
      case TimeRange.year:
        return 'Last Year';
    }
  }

  String _getCurrentLabel() {
    switch (selectedRange) {
      case TimeRange.yesterday:
        return 'Yesterday';
      case TimeRange.week:
        return 'This Week';
      case TimeRange.month:
        return 'This Month';
      case TimeRange.year:
        return 'This Year';
    }
  }

  DateFormat _getDateFormat() {
    switch (selectedRange) {
      case TimeRange.yesterday:
        return DateFormat.Hm(); // Hour:Minute
      case TimeRange.week:
        return DateFormat.E(); // Day of week
      case TimeRange.month:
        return DateFormat.MMMd(); // Month Day
      case TimeRange.year:
        return DateFormat.MMM(); // Month
    }
  }

  DateTimeIntervalType _getIntervalType() {
    switch (selectedRange) {
      case TimeRange.yesterday:
        return DateTimeIntervalType.hours;
      case TimeRange.week:
        return DateTimeIntervalType.days;
      case TimeRange.month:
        return DateTimeIntervalType.days;
      case TimeRange.year:
        return DateTimeIntervalType.months;
    }
  }

  double _getInterval() {
    switch (selectedRange) {
      case TimeRange.yesterday:
        return 2; // Every 2 hours
      case TimeRange.week:
        return 1; // Every day
      case TimeRange.month:
        return 5; // Every 5 days
      case TimeRange.year:
        return 1; // Every month
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF2D3748),
        title: const Text(
          'Energy Analytics',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 24,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF667EEA),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667EEA).withOpacity(0.3),
                  spreadRadius: 0,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: fetchChartData,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _buildHeaderCard(),
              const SizedBox(height: 24),
              _buildRangeSelector(),
              const SizedBox(height: 20),
              _buildStatsCards(),
              const SizedBox(height: 24),
              Expanded(
                child: _buildChartContainer(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.3),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.electric_bolt_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Energy Consumption',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${selectedRange.label} Analysis',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeSelector() {
    return Container(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: TimeRange.values.length,
        itemBuilder: (context, index) {
          final range = TimeRange.values[index];
          final isSelected = selectedRange == range;
          
          return Container(
            margin: EdgeInsets.only(right: index < TimeRange.values.length - 1 ? 12 : 0),
            child: GestureDetector(
onTap: () {
  if (selectedRange != range) {
    setState(() {
      isLoading = true;
      selectedRange = range;
      chartData = [];
    });
    fetchChartData();
  }
},
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF667EEA) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF667EEA) : const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: const Color(0xFF667EEA).withOpacity(0.3),
                        spreadRadius: 0,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      range.icon,
                      color: isSelected ? Colors.white : const Color(0xFF6B7280),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      range.label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF6B7280),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsCards() {
    if (chartData.isEmpty) return const SizedBox.shrink();

    double currentTotal = chartData.fold(0, (sum, item) => sum + item.todayConsumption);
    double previousTotal = chartData.fold(0, (sum, item) => sum + item.yesterdayConsumption);
    double difference = currentTotal - previousTotal;
    bool isIncrease = difference > 0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            _getCurrentLabel(),
            '${currentTotal.toStringAsFixed(2)} kWh',
            Icons.trending_up_rounded,
            const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            _getComparisonLabel(),
            '${previousTotal.toStringAsFixed(2)} kWh',
            Icons.history_rounded,
            const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Difference',
            '${isIncrease ? '+' : ''}${difference.toStringAsFixed(2)} kWh',
            isIncrease ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            isIncrease ? const Color(0xFFEF4444) : const Color(0xFF10B981),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartContainer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.0),
        child: _buildChart(),
      ),
    );
  }

  Widget _buildChart() {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF667EEA).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Loading chart data...',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: fetchChartData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      );
    }

    if (chartData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.bar_chart_rounded,
                size: 48,
                color: Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No data available',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Energy consumption data for ${selectedRange.label.toLowerCase()} will appear here once available',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF9CA3AF),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SfCartesianChart(
        primaryXAxis: DateTimeAxis(
          title: AxisTitle(
            text: 'Time',
            textStyle: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          dateFormat: _getDateFormat(),
          intervalType: _getIntervalType(),
          interval: _getInterval(),
          labelStyle: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 11,
          ),
          axisLine: const AxisLine(color: Color(0xFFE5E7EB), width: 1),
          majorTickLines: const MajorTickLines(color: Color(0xFFE5E7EB), size: 4),
          majorGridLines: const MajorGridLines(color: Color(0xFFF3F4F6), width: 1),
        ),
        primaryYAxis: NumericAxis(
          title: AxisTitle(
            text: 'Energy Consumption (kWh)',
            textStyle: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          numberFormat: NumberFormat.decimalPattern(),
          labelStyle: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 11,
          ),
          axisLine: const AxisLine(color: Color(0xFFE5E7EB), width: 1),
          majorTickLines: const MajorTickLines(color: Color(0xFFE5E7EB), size: 4),
          majorGridLines: const MajorGridLines(color: Color(0xFFF3F4F6), width: 1),
        ),
        title: ChartTitle(
          text: 'Energy Consumption Comparison - ${selectedRange.label}',
          textStyle: const TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        legend: Legend(
          isVisible: true,
          position: LegendPosition.bottom,
          textStyle: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        tooltipBehavior: TooltipBehavior(enable: true),
        zoomPanBehavior: ZoomPanBehavior(
          enablePinching: true,
          enablePanning: true,
          enableDoubleTapZooming: true,
        ),
        plotAreaBorderColor: Colors.transparent,
        series: <CartesianSeries<ChartData, DateTime>>[
          LineSeries<ChartData, DateTime>(
            dataSource: chartData,
            xValueMapper: (ChartData data, _) => data.timestamp,
            yValueMapper: (ChartData data, _) => data.todayConsumption,
            name: _getCurrentLabel(),
            color: const Color(0xFF667EEA),
            width: 3,
            markerSettings: const MarkerSettings(
              isVisible: true,
              shape: DataMarkerType.circle,
              width: 6,
              height: 6,
              color: Color(0xFF667EEA),
              borderColor: Colors.white,
              borderWidth: 2,
            ),
          ),
          LineSeries<ChartData, DateTime>(
            dataSource: chartData,
            xValueMapper: (ChartData data, _) => data.timestamp,
            yValueMapper: (ChartData data, _) => data.yesterdayConsumption,
            name: _getComparisonLabel(),
            color: const Color(0xFF9CA3AF),
            width: 3,
            dashArray: const <double>[5, 3],
            markerSettings: const MarkerSettings(
              isVisible: true,
              shape: DataMarkerType.circle,
              width: 6,
              height: 6,
              color: Color(0xFF9CA3AF),
              borderColor: Colors.white,
              borderWidth: 2,
            ),
          ),
        ],
      ),
    );
  }
}

// class ChartData {
//   final DateTime timestamp;
//   final double yesterdayConsumption;
//   final double todayConsumption;
// }

class ChartData {
  final DateTime timestamp;
  final double yesterdayConsumption;
  final double todayConsumption;

  ChartData(this.timestamp, this.yesterdayConsumption, this.todayConsumption);
}