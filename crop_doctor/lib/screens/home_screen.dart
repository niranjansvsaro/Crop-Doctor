import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers.dart';
import '../services/translate_service.dart';
import '../services/database_service.dart';
import 'camera_screen.dart';
import 'history_screen.dart';
import 'encyclopedia_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadDashboardStats();
  }

  Future<void> _loadDashboardStats() async {
    final stats = await DatabaseService.instance.getWeeklyStats();
    setState(() {
      _stats = stats;
    });
  }

  Widget _buildHomeDashboard(String language) {
    final name = ref.watch(farmerNameProvider);
    final totalScans = _stats['total_scans'] ?? 0;
    final diseasedCount = _stats['diseased_count'] ?? 0;
    final healthScore = _stats['average_health_score'] ?? 100.0;
    final scansByDay = (_stats['scans_by_day'] as List<int>?) ?? [0, 0, 0, 0, 0, 0, 0];

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting & Quote
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${TranslateService.get('greeting', language)},",
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    name.isNotEmpty ? name : "Farmer",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // Profile icon
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF66BB6A), width: 1.5),
                  color: Colors.white.withAlpha(20),
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.person, color: Colors.white, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Weather & Crop Quote Card
          _buildWeatherCard(language),
          const SizedBox(height: 24),

          // Action: Big Glowing Pulse Scan Button
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CameraScreen()),
                    ).then((_) => _loadDashboardStats());
                  },
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF66BB6A).withAlpha(100),
                          blurRadius: 30,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF1B5E20),
                        ),
                        child: const Icon(
                          Icons.camera_alt_outlined,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    ),
                  )
                      .animate(onPlay: (controller) => controller.repeat(reverse: true))
                      .scale(
                        begin: const Offset(1.0, 1.0),
                        end: const Offset(1.1, 1.1),
                        duration: 1200.ms,
                        curve: Curves.easeInOut,
                      )
                      .boxShadow(
                        begin: const BoxShadow(color: Colors.transparent),
                        end: BoxShadow(
                          color: const Color(0xFF66BB6A).withAlpha(140),
                          blurRadius: 40,
                          spreadRadius: 12,
                        ),
                        duration: 1200.ms,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  TranslateService.get('scan_leaf', language),
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF81C784),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Dashboard Metrics Title
          Text(
            TranslateService.get('dashboard', language),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Dashboard Grid
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: TranslateService.get('total_scans', language),
                  value: "$totalScans",
                  icon: Icons.eco_outlined,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: TranslateService.get('diseased', language),
                  value: "$diseasedCount",
                  icon: Icons.bug_report_outlined,
                  color: Colors.orangeAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Farm Health Score Card
          _buildHealthScoreCard(healthScore, language),
          const SizedBox(height: 24),

          // Weekly Chart
          if (totalScans > 0) ...[
            Text(
              "Weekly Scanning Activity",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildWeeklyChart(scansByDay),
          ],
        ],
      ),
    );
  }

  Widget _buildWeatherCard(String language) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Weather Report",
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "32°C",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Humidity: 65%  •  Rain: 10%",
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "\"${TranslateService.get('tagline', language)}\"",
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF81C784),
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Weather status icon
          const Icon(
            Icons.wb_sunny,
            color: Colors.amberAccent,
            size: 64,
          )
              .animate(onPlay: (controller) => controller.repeat())
              .rotate(duration: 10.seconds),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthScoreCard(double score, String language) {
    Color scoreColor = Colors.green;
    if (score < 80 && score >= 50) {
      scoreColor = Colors.orange;
    } else if (score < 50) {
      scoreColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(15),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: scoreColor.withAlpha(40),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.health_and_safety_outlined, color: scoreColor, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  TranslateService.get('farm_health', language),
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                Text(
                  "${score.toStringAsFixed(0)}%",
                  style: TextStyle(
                    color: scoreColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Community alerts
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.redAccent.withAlpha(40),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.redAccent.withAlpha(100)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.redAccent, size: 16),
                SizedBox(width: 4),
                Text("Alert", style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .fade(duration: 800.ms),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(List<int> scans) {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(15),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (scans.reduce((a, b) => a > b ? a : b) + 2).toDouble(),
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                  return Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      days[value.toInt() % 7],
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(7, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: scans[i].toDouble(),
                  color: const Color(0xFF66BB6A),
                  width: 14,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _getActiveTab() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeDashboard(ref.watch(languageProvider));
      case 1:
        return const HistoryScreen();
      case 2:
        return const EncyclopediaScreen();
      case 3:
        return const SettingsScreen();
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    // Listen to changes in the history to rebuild dashboard stats
    ref.listen(historyProvider, (prev, next) {
      _loadDashboardStats();
    });

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // Background Gradient decoration
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2E7D32).withAlpha(40),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -150,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0D47A1).withAlpha(30),
              ),
            ),
          ),

          // Main body content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top App Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Text(
                        TranslateService.get('app_name', language),
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF66BB6A),
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      const Spacer(),
                      // Community alert marquee / alert icon
                      IconButton(
                        icon: const Icon(Icons.notifications_none_outlined, color: Colors.white70),
                        onPressed: () {
                          // Show alert details
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(child: _getActiveTab()),
              ],
            ),
          ),

          // Floating Glassmorphism Bottom Navigation Bar
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(20),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withAlpha(40),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(30),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(0, Icons.home_outlined, Icons.home, TranslateService.get('dashboard', language)),
                      _buildNavItem(1, Icons.history_outlined, Icons.history, TranslateService.get('scan_history', language)),
                      _buildNavItem(2, Icons.menu_book_outlined, Icons.menu_book, TranslateService.get('encyclopedia', language)),
                      _buildNavItem(3, Icons.settings_outlined, Icons.settings, TranslateService.get('settings', language)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData outlineIcon, IconData filledIcon, String label) {
    final isSelected = _currentIndex == index;
    final iconColor = isSelected ? const Color(0xFF66BB6A) : Colors.white60;

    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
        if (index == 0) {
          _loadDashboardStats();
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? filledIcon : outlineIcon,
            color: iconColor,
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: iconColor,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
