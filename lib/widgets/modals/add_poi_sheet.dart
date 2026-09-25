import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../models/tracker_models.dart';
import '../../providers/tracker_providers.dart';
import '../../utils/ui_helpers.dart';

class AddPoiSheet extends ConsumerStatefulWidget {
  final LatLng point;

  const AddPoiSheet({super.key, required this.point});

  @override
  ConsumerState<AddPoiSheet> createState() => _AddPoiSheetState();
}

class _AddPoiSheetState extends ConsumerState<AddPoiSheet> {
  final _titleController = TextEditingController();
  PoiCategory _selectedCategory = PoiCategory.rendezvous;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: PremiumGlass(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_location_alt_rounded, color: Color(0xFF00E5FF), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SHARED TACTICAL POI',
                          style: GoogleFonts.shareTechMono(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: const Color(0xFF00E5FF),
                          ),
                        ),
                        Text(
                          '${widget.point.latitude.toStringAsFixed(5)}, ${widget.point.longitude.toStringAsFixed(5)}',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Text(
                'KATEGORI TITIK',
                style: GoogleFonts.shareTechMono(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _categoryChip(PoiCategory.rendezvous, 'Rendezvous', Icons.flag_rounded, const Color(0xFF00E5FF)),
                  _categoryChip(PoiCategory.fuel, 'SPBU', Icons.local_gas_station_rounded, const Color(0xFFFFD600)),
                  _categoryChip(PoiCategory.hazard, 'Bahaya / Rintangan', Icons.warning_amber_rounded, const Color(0xFFFF1744)),
                  _categoryChip(PoiCategory.rest, 'Rest Area', Icons.hotel_rounded, const Color(0xFF00E676)),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'NAMA / DESKRIPSI TITIK',
                style: GoogleFonts.shareTechMono(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                autofocus: true,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Misal: Titik Kumpul SPBU KM 57...',
                  hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E232D) : const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.pin_drop_rounded, size: 20),
                  label: Text(
                    'PASANG PIN KE GRUP',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800, letterSpacing: 0.5),
                  ),
                  onPressed: () {
                    final title = _titleController.text.trim();
                    if (title.isEmpty) return;

                    HapticFeedback.mediumImpact();
                    final id = 'poi_${DateTime.now().millisecondsSinceEpoch}';
                    final poi = SharedPoi(
                      id: id,
                      title: title,
                      latitude: widget.point.latitude,
                      longitude: widget.point.longitude,
                      category: _selectedCategory,
                      createdBy: 'Me',
                      createdAt: DateTime.now(),
                    );

                    ref.read(roomProvider.notifier).createPoi(poi);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryChip(PoiCategory category, String label, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedCategory == category;
    return ChoiceChip(
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.black : color),
      label: Text(label),
      selected: isSelected,
      selectedColor: color,
      side: BorderSide(color: isSelected ? color : (isDark ? Colors.white12 : Colors.black12)),
      labelStyle: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.black : (isDark ? Colors.white70 : Colors.black87),
      ),
      onSelected: (val) {
        if (val) setState(() => _selectedCategory = category);
      },
    );
  }
}
