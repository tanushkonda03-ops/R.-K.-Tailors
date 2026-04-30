import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/neumorphic_text_field.dart';
import '../../core/widgets/neumorphic_button.dart';
import '../../core/widgets/neumorphic_container.dart';
import '../../core/services/measurement_service.dart';

class AdminViewMeasurementsScreen extends StatefulWidget {
  const AdminViewMeasurementsScreen({super.key});

  @override
  State<AdminViewMeasurementsScreen> createState() =>
      _AdminViewMeasurementsScreenState();
}

class _AdminViewMeasurementsScreenState
    extends State<AdminViewMeasurementsScreen> {
  final TextEditingController _idController = TextEditingController();
  final MeasurementService _measurementService = MeasurementService();

  bool _isLoading = false;
  String? _error;
  String? _customerUid;
  String? _customerName;
  List<String> _availableGarments = [];
  String? _selectedGarment;
  Map<String, dynamic>? _garmentData;

  // Keys to skip when displaying measurements
  static const _skipKeys = {
    'timestamp',
    'referenceImagesBase64',
    'referenceImageBase64',
  };

  void _fetchCustomer() async {
    final query = _idController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _customerUid = null;
      _customerName = null;
      _availableGarments = [];
      _selectedGarment = null;
      _garmentData = null;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('customerId', isEqualTo: query)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() => _error = 'No customer found with ID: $query');
        return;
      }

      final userData = snapshot.docs.first.data();
      final uid = userData['uid'];
      final name = userData['username'] ?? 'Customer';

      // Fetch all measurements for this customer
      final measurements = await _measurementService.getMeasurements(uid);

      setState(() {
        _customerUid = uid;
        _customerName = name;
        _availableGarments = measurements.keys.toList()..sort();
      });

      if (_availableGarments.isEmpty) {
        setState(() => _error = 'No measurements found for $name.');
      }
    } catch (e) {
      setState(() => _error = 'Error fetching data.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _loadGarment() async {
    if (_customerUid == null || _selectedGarment == null) return;

    setState(() {
      _isLoading = true;
      _garmentData = null;
    });

    try {
      final data = await _measurementService.getGarmentMeasurement(
        _customerUid!,
        _selectedGarment!,
      );
      setState(() => _garmentData = data);
    } catch (e) {
      setState(() => _error = 'Error loading garment.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildMeasurementRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBase64Images(Map<String, dynamic> data) {
    List<String> images = [];

    // Support both old single-image and new multi-image format
    if (data.containsKey('referenceImagesBase64') &&
        data['referenceImagesBase64'] is List) {
      images = List<String>.from(data['referenceImagesBase64']);
    } else if (data.containsKey('referenceImageBase64') &&
        data['referenceImageBase64'] is String) {
      images = [data['referenceImageBase64']];
    }

    if (images.isEmpty) return [];

    return [
      const SizedBox(height: 16),
      Text(
        'Reference Images',
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 200,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: images.length,
          separatorBuilder: (context, index) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            try {
              final base64Str = images[index].split(',').last;
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  base64Decode(base64Str),
                  height: 200,
                  width: 200,
                  fit: BoxFit.cover,
                ),
              );
            } catch (_) {
              return Container(
                height: 200,
                width: 200,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(
                    Icons.broken_image,
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            }
          },
        ),
      ),
    ];
  }

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'View Measurements',
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Quick reference while stitching garments.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),

            NeumorphicTextField(
              hintText: '5-Digit Customer ID',
              controller: _idController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _fetchCustomer(),
            ),
            const SizedBox(height: 16),
            Center(
              child: NeumorphicButton(
                label: 'Find Customer',
                onTap: _fetchCustomer,
                isLoading: _isLoading,
              ),
            ),
            const SizedBox(height: 24),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            if (_availableGarments.isNotEmpty) ...[
              const Divider(height: 48),
              Text(
                'Customer: $_customerName',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Select Garment',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              NeumorphicContainer(
                borderRadius: 12,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                isPressed: true,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedGarment,
                    hint: Text(
                      'Choose garment',
                      style: GoogleFonts.poppins(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    isExpanded: true,
                    dropdownColor: AppColors.background,
                    style: GoogleFonts.poppins(color: AppColors.textPrimary),
                    items: _availableGarments
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedGarment = val),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: NeumorphicButton(
                  label: 'Get Measurement',
                  onTap: _loadGarment,
                  isLoading: _isLoading,
                ),
              ),
            ],

            if (_garmentData != null) ...[
              const SizedBox(height: 32),
              NeumorphicContainer(
                borderRadius: 16,
                padding: const EdgeInsets.all(24),
                isPressed: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.straighten, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          _selectedGarment ?? '',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),

                    ..._garmentData!.entries
                        .where(
                          (e) =>
                              !_skipKeys.contains(e.key) &&
                              e.value != null &&
                              e.value.toString().isNotEmpty,
                        )
                        .map(
                          (e) =>
                              _buildMeasurementRow(e.key, e.value.toString()),
                        ),

                    ..._buildBase64Images(_garmentData!),
                  ],
                ),
              ),
              const SizedBox(height: 48),
            ],
          ],
        ),
      ),
    );
  }
}
