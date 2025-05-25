import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ecotrack_mobile/widgets/navbar.dart';

class EnergyDashboard extends StatefulWidget {
  const EnergyDashboard({Key? key}) : super(key: key);

  @override
  State<EnergyDashboard> createState() => _EnergyDashboardState();
}

class _EnergyDashboardState extends State<EnergyDashboard> {
  // Dummy data for appliance energy consumption
  final List<ApplianceData> appliancesData = [
    ApplianceData('AC', 2982, Colors.green[600]!),
    ApplianceData('Ref', 1850, Colors.green[500]!),
    ApplianceData('Oven', 1350, Colors.green[400]!),
    ApplianceData('Fan', 650, Colors.lightGreen[300]!),
    ApplianceData('Other', 900, Colors.grey[400]!),
  ];

  @override
  Widget build(BuildContext context) {
    // Calculate total energy for percentage calculation
    final totalWatts = appliancesData.fold(0, (sum, item) => sum + item.watts);

    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Main content area with white background
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Bar graph section
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: ApplianceBarChart(
                              appliancesData: appliancesData,
                              totalWatts: totalWatts),
                        ),
                      ),

                      // Energy stats banner
                      Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: Color(0xFF109717),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withOpacity(0.5), // Shadow color
                              blurRadius: 5, // Softness of the shadow
                              offset: const Offset(0, 4),
                            ),
                          ], // X and Y offset
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.power, color: Colors.white),
                                        SizedBox(width: 8),
                                        Text(
                                          'Today',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Text(
                                      '69 kWh',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 60,
                              color: Colors.white.withOpacity(0.5),
                            ),
                            Expanded(
                              child: Container(
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.bolt, color: Colors.white),
                                        SizedBox(width: 8),
                                        Text(
                                          'This Week',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Text(
                                      '691 kWh',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // AI Energy Saving Tip
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AI Energy Saving Tip',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                    color: Colors.black87, fontSize: 16),
                                children: [
                                  TextSpan(
                                    text:
                                        'Based on your top appliance consumer, ',
                                  ),
                                  TextSpan(
                                    text: 'AC',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(
                                    text: ', which is used for ',
                                  ),
                                  TextSpan(
                                    text: '69 hours daily',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(
                                    text: ', you must save your energy',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      bottomNavigationBar: SafeArea(
        bottom: false,
            child: CustomBottomNavBar(selectedIndex: 0),
        ));
  }
}

class ApplianceData {
  final String name;
  final int watts;
  final Color color;

  ApplianceData(this.name, this.watts, this.color);
}

class ApplianceBarChart extends StatelessWidget {
  final List<ApplianceData> appliancesData;
  final int totalWatts;

  const ApplianceBarChart({
    Key? key,
    required this.appliancesData,
    required this.totalWatts,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(
                  0xFFF2EAFF), // Pale purple background for bar graph only
              borderRadius: BorderRadius.circular(16),
            ),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceEvenly,
                maxY: appliancesData
                        .map((e) => e.watts.toDouble())
                        .reduce((a, b) => a > b ? a : b) *
                    1.2,
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value < 0 || value >= appliancesData.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            appliancesData[value.toInt()].name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                      reservedSize: 28,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(
                            '${value.toInt()} W',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 500,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[300],
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                  drawVerticalLine: false,
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(
                  appliancesData.length,
                  (index) => BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: appliancesData[index].watts.toDouble(),
                        color: appliancesData[index].color,
                        width: 20,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Total Consumption: ',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
              ),
            ),
            Text(
              '${totalWatts} W',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
