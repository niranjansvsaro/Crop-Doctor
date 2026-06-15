import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/disease.dart';
import '../widgets/disease_card.dart';
import '../widgets/severity_badge.dart';

class EncyclopediaScreen extends ConsumerStatefulWidget {
  const EncyclopediaScreen({super.key});

  @override
  ConsumerState<EncyclopediaScreen> createState() => _EncyclopediaScreenState();
}

class _EncyclopediaScreenState extends ConsumerState<EncyclopediaScreen> {
  List<Disease> _allDiseases = [];
  List<Disease> _filteredDiseases = [];
  bool _isLoading = true;
  String _selectedCrop = 'All';
  final _searchController = TextEditingController();

  final List<String> _cropCategories = [
    'All',
    'Rice',
    'Wheat',
    'Tomato',
    'Cotton',
    'Maize',
    'Sugarcane',
  ];

  @override
  void initState() {
    super.initState();
    _loadEncyclopediaData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEncyclopediaData() async {
    try {
      final String jsonString = await DefaultAssetBundle.of(context)
          .loadString('assets/diseases/diseases.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      
      final diseases = jsonList.map((j) => Disease.fromJson(j)).toList();
      setState(() {
        _allDiseases = diseases;
        _filteredDiseases = diseases;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Failed to load encyclopedia data: $e");
      setState(() => _isLoading = false);
    }
  }

  void _filterAndSearch() {
    final query = _searchController.text.toLowerCase();
    List<Disease> temp = _allDiseases;

    // Filter by crop type
    if (_selectedCrop != 'All') {
      temp = temp.where((d) => d.cropType.toLowerCase() == _selectedCrop.toLowerCase()).toList();
    }

    // Search query
    if (query.isNotEmpty) {
      temp = temp.where((d) =>
        d.name.toLowerCase().contains(query) ||
        d.scientificName.toLowerCase().contains(query) ||
        d.symptoms.toLowerCase().contains(query)
      ).toList();
    }

    setState(() {
      _filteredDiseases = temp;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search & Category Tabs
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              // Search input
              TextField(
                controller: _searchController,
                onChanged: (_) => _filterAndSearch(),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Search encyclopedia...",
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

              // Horizontal scrollable crop categories
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _cropCategories.map((crop) {
                    final isSelected = _selectedCrop == crop;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(crop),
                        selected: isSelected,
                        selectedColor: const Color(0xFF66BB6A),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedCrop = crop;
                            });
                            _filterAndSearch();
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // List builder
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF66BB6A)))
              : _filteredDiseases.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.library_books_outlined, size: 64, color: Colors.white24),
                          SizedBox(height: 16),
                          Text("No diseases found in catalog", style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 120),
                      itemCount: _filteredDiseases.length,
                      itemBuilder: (context, index) {
                        final disease = _filteredDiseases[index];
                        return DiseaseCard(
                          disease: disease,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DiseaseDetailScreen(disease: disease),
                              ),
                            );
                          },
                        ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08, duration: 350.ms);
                      },
                    ),
        ),
      ],
    );
  }
}

// Inline detailed view screen
class DiseaseDetailScreen extends StatelessWidget {
  final Disease disease;

  const DiseaseDetailScreen({super.key, required this.disease});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          disease.name,
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Crop type and scientific name header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green[800]?.withAlpha(80),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    disease.cropType,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  disease.scientificName,
                  style: const TextStyle(color: Colors.white60, fontStyle: FontStyle.italic, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Severity Badge
            SeverityBadge(severity: disease.severity),
            const SizedBox(height: 24),

            // Symptoms Header & Body
            Text(
              "Symptoms",
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withAlpha(20)),
              ),
              child: Text(
                disease.symptoms,
                style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
              ),
            ),
            const SizedBox(height: 24),

            // Treatments Header & Body
            Text(
              "Treatment Steps",
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...disease.treatment.map((step) => Card(
                  color: Colors.white.withAlpha(15),
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.white.withAlpha(20)),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child: Icon(Icons.healing_outlined, color: Colors.white, size: 20),
                    ),
                    title: Text(
                      step,
                      style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
                    ),
                  ),
                )),
            const SizedBox(height: 24),

            // Prevention Header & Body
            Text(
              "Prevention Tips",
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withAlpha(20)),
              ),
              child: Text(
                disease.prevention,
                style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
