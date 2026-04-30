import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/neumorphic_container.dart';
import '../../core/services/measurement_service.dart';

class UserMeasurementsScreen extends StatefulWidget {
  const UserMeasurementsScreen({super.key});

  @override
  State<UserMeasurementsScreen> createState() => _UserMeasurementsScreenState();
}

class _UserMeasurementsScreenState extends State<UserMeasurementsScreen> {
  final MeasurementService _service = MeasurementService();
  bool _isLoading = true;
  Map<String, Map<String, dynamic>> _measurements = {};

  static const _skipKeys = {'timestamp', 'referenceImagesBase64', 'referenceImageBase64'};

  @override
  void initState() {
    super.initState();
    _loadMeasurements();
  }

  void _loadMeasurements() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final data = await _service.getMeasurements(user.uid);
      if (mounted) {
        setState(() {
          _measurements = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatForClipboard(String garment, Map<String, dynamic> data) {
    final buffer = StringBuffer();
    buffer.writeln('═══ $garment ═══');
    for (var entry in data.entries) {
      if (_skipKeys.contains(entry.key)) continue;
      if (entry.value == null || entry.value.toString().isEmpty) continue;
      buffer.writeln('${entry.key}: ${entry.value}');
    }
    return buffer.toString();
  }

  void _copyToClipboard(String garment, Map<String, dynamic> data) {
    final text = _formatForClipboard(garment, data);
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$garment measurements copied!'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _copyAllToClipboard() {
    final buffer = StringBuffer();
    buffer.writeln('My Measurements');
    buffer.writeln('────────────────');
    for (var entry in _measurements.entries) {
      buffer.writeln(_formatForClipboard(entry.key, entry.value));
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('All measurements copied!'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildMeasurementRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBase64Images(Map<String, dynamic> data) {
    List<String> images = [];

    if (data.containsKey('referenceImagesBase64') && data['referenceImagesBase64'] is List) {
      images = List<String>.from(data['referenceImagesBase64']);
    } else if (data.containsKey('referenceImageBase64') && data['referenceImageBase64'] is String) {
      images = [data['referenceImageBase64']];
    }

    if (images.isEmpty) return [];

    return [
      const SizedBox(height: 12),
      Text('Reference Images', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      const SizedBox(height: 8),
      SizedBox(
        height: 140,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: images.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            try {
              final base64Str = images[index].split(',').last;
              return ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(
                  base64Decode(base64Str),
                  height: 140,
                  width: 140,
                  fit: BoxFit.cover,
                ),
              );
            } catch (_) {
              return Container(
                height: 140,
                width: 140,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(child: Icon(Icons.broken_image, color: AppColors.textSecondary)),
              );
            }
          },
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'My Measurements',
          style: GoogleFonts.playfairDisplay(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_measurements.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.copy_all, color: AppColors.primary),
              tooltip: 'Copy All',
              onPressed: _copyAllToClipboard,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _measurements.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.straighten, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text(
                        'No measurements yet.',
                        style: GoogleFonts.poppins(fontSize: 16, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Visit your tailor to get measured!',
                        style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ..._measurements.entries.map((entry) {
                        final garment = entry.key;
                        final data = entry.value;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: NeumorphicContainer(
                            borderRadius: 16,
                            padding: const EdgeInsets.all(20),
                            isPressed: false,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(children: [
                                      Icon(Icons.straighten, size: 20, color: AppColors.primary),
                                      const SizedBox(width: 8),
                                      Text(
                                        garment,
                                        style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                                      ),
                                    ]),
                                    TextButton.icon(
                                      icon: const Icon(Icons.copy, size: 16, color: AppColors.primary),
                                      label: Text('Copy', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      onPressed: () => _copyToClipboard(garment, data),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),

                                ...data.entries
                                    .where((e) => !_skipKeys.contains(e.key) && e.value != null && e.value.toString().isNotEmpty)
                                    .map((e) => _buildMeasurementRow(e.key, e.value.toString())),

                                ..._buildBase64Images(data),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
    );
  }
}
