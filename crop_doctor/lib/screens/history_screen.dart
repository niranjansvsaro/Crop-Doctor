import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers.dart';
import '../models/scan_result.dart';
import '../services/translate_service.dart';
import '../widgets/scan_card.dart';
import 'result_screen.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'all'; // all, severe, healthy, crop
  String? _selectedCrop;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    ref.read(historyProvider.notifier).searchScans(value.trim());
  }

  List<ScanResult> _applyFilters(List<ScanResult> list) {
    List<ScanResult> filtered = list;

    // 1. Severity Filter
    if (_selectedFilter == 'severe') {
      filtered = filtered.where((scan) => scan.severity >= 4).toList();
    } else if (_selectedFilter == 'healthy') {
      filtered = filtered.where((scan) => 
        scan.diseaseNameEn.toLowerCase().contains('healthy') || 
        scan.severity == 1
      ).toList();
    }

    // 2. Crop Filter
    if (_selectedCrop != null) {
      filtered = filtered.where((scan) => scan.cropType.toLowerCase() == _selectedCrop!.toLowerCase()).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final rawHistory = ref.watch(historyProvider);
    final historyList = _applyFilters(rawHistory);
    final language = ref.watch(languageProvider);

    // Extract unique crops for filter chips
    final crops = rawHistory.map((s) => s.cropType).toSet().toList();

    return Column(
      children: [
        // Search & Filters Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              // Search Input
              TextField(
                controller: _searchController,
                onChanged: _onSearch,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: TranslateService.get('search_placeholder', language),
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withAlpha(15),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.white.withAlpha(20)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Color(0xFF66BB6A)),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Filter Chips Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // All filter
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(TranslateService.get('filter_all', language)),
                        selected: _selectedFilter == 'all' && _selectedCrop == null,
                        selectedColor: const Color(0xFF66BB6A),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedFilter = 'all';
                              _selectedCrop = null;
                            });
                          }
                        },
                      ),
                    ),
                    // Severe filter
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(TranslateService.get('filter_severe', language)),
                        selected: _selectedFilter == 'severe',
                        selectedColor: const Color(0xFFEF5350),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedFilter = 'severe';
                              _selectedCrop = null;
                            });
                          }
                        },
                      ),
                    ),
                    // Healthy filter
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(TranslateService.get('filter_healthy', language)),
                        selected: _selectedFilter == 'healthy',
                        selectedColor: const Color(0xFF66BB6A),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedFilter = 'healthy';
                              _selectedCrop = null;
                            });
                          }
                        },
                      ),
                    ),
                    // Crop filters
                    ...crops.map((crop) {
                      final isSelected = _selectedCrop == crop;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(crop),
                          selected: isSelected,
                          selectedColor: const Color(0xFF66BB6A),
                          onSelected: (selected) {
                            setState(() {
                              _selectedCrop = selected ? crop : null;
                              _selectedFilter = 'all'; // reset main filter when crop is toggled
                            });
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Scans History List
        Expanded(
          child: historyList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.history_toggle_off, size: 64, color: Colors.white24),
                      const SizedBox(height: 16),
                      Text(
                        "No scan reports found",
                        style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 120),
                  itemCount: historyList.length,
                  itemBuilder: (context, index) {
                    final scan = historyList[index];
                    return ScanCard(
                      scan: scan,
                      language: language,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ResultScreen(scan: scan),
                          ),
                        );
                      },
                      onDelete: () {
                        // Confirm deletion dialog
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: const Color(0xFF222222),
                            title: const Text("Delete Report", style: TextStyle(color: Colors.white)),
                            content: const Text("Are you sure you want to delete this scan report permanently?", style: TextStyle(color: Colors.white70)),
                            actions: [
                              TextButton(
                                child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
                                onPressed: () => Navigator.pop(context),
                              ),
                              TextButton(
                                child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
                                onPressed: () {
                                  ref.read(historyProvider.notifier).deleteScan(scan.id);
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, duration: 400.ms);
                  },
                ),
        ),
      ],
    );
  }
}
