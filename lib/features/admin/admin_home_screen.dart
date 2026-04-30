import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/neumorphic_text_field.dart';
import '../../core/widgets/neumorphic_button.dart';
import '../../core/widgets/neumorphic_container.dart';

import '../billing/billing_screen.dart';
import './widgets/garment_form_card.dart';
import '../../core/services/measurement_service.dart';

class AdminHomeScreen extends StatefulWidget {
  final String username;

  const AdminHomeScreen({super.key, required this.username});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final MeasurementService _measurementService = MeasurementService();

  bool _isSearching = false;
  bool _isSubmitting = false;
  bool _showMeasurements = false;
  Map<String, dynamic>? _customerData;
  String? _errorMessage;

  final Map<String, bool> _clothes = {
    'Shirt': false,
    'Kurta': false,
    'Short Kurta': false,
    'Sherwani': false,
    'Coat': false,
    'Jacket': false,
    'Jodhpuri': false,
    'Pant': false,
    'Pathani': false,
    'Salwaar': false,
    'Dhoti': false,
  };

  Map<String, Map<String, dynamic>> _measurements = {};
  late Map<String, GarmentFormConfig> _garmentConfigs;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    _measurements = {
      for (var k in _clothes.keys) k: <String, dynamic>{}
    };

    _garmentConfigs = {
      'Shirt': const GarmentFormConfig(
        inputs: ['Length', 'Sleeves', 'Shoulder', 'Chest', 'Stomach', 'Seat', 'Collar'],
        optionalInputs: ['frontChest', 'frontStomach', 'frontSeat'],
        dropdowns: {
          'collar': ['Shirt Collar', 'Bend Collar'],
          'pocket': ['Yes', 'No'],
          'Sleeve Type': ['Cuph', 'Round'],
        },
        hasCuphLogic: true,
      ),
      'Pant': const GarmentFormConfig(
        inputs: ['Length', 'Bottom', 'Knee', 'Thighs', 'Waist', 'Seat', 'Chain'],
        dropdowns: {
          'Crease': ['Front', 'Side'],
          'Pleats': ['Yes', 'No'],
          'Belt': ['Cut Belt', 'Long Belt'],
          'Belt Style': ['Only Belt', 'Belt & Rubber'],
          'Bottom Style': ['Machine', 'Turpai'],
        },
        defaultDropdowns: {'Pleats': 'No'},
      ),
      'Kurta': const GarmentFormConfig(
        inputs: ['Length', 'Sleeves', 'Shoulder', 'Chest', 'Stomach', 'Seat', 'Bottom', 'Collar'],
        optionalInputs: ['frontChest', 'frontStomach', 'frontSeat'],
        dropdowns: {
          'collar': ['Shirt Collar', 'Bend Collar'],
          'Sleeve Type': ['Cuph', 'Round'],
        },
        hasCuphLogic: true,
      ),
      'Salwaar': const GarmentFormConfig(
        inputs: ['Length', 'Waist'],
        dropdowns: {
          'Belt Style': ['Only Belt', 'Belt & Rubber', 'Naada', 'Naada & Rubber'],
        },
      ),
      'Dhoti': const GarmentFormConfig(inputs: ['Length', 'Waist']),
      'Coat': const GarmentFormConfig(
        inputs: ['Length', 'Sleeves', 'Shoulder', 'Chest', 'Stomach', 'Seat', 'Collar'],
        optionalInputs: ['frontChest', 'frontStomach', 'frontSeat'],
      ),
      'Jodhpuri': const GarmentFormConfig(
        inputs: ['Length', 'Sleeves', 'Shoulder', 'Chest', 'Stomach', 'Seat', 'Collar'],
        optionalInputs: ['frontChest', 'frontStomach', 'frontSeat'],
      ),
      'Short Kurta': const GarmentFormConfig(
        inputs: ['Length', 'Sleeves', 'Shoulder', 'Chest', 'Stomach', 'Seat', 'Bottom', 'Collar'],
        optionalInputs: ['frontChest', 'frontStomach', 'frontSeat'],
        dropdowns: {
          'collar': ['Shirt Collar', 'Bend Collar'],
          'Sleeve Type': ['Cuph', 'Round'],
        },
        hasCuphLogic: true,
      ),
      'Jacket': const GarmentFormConfig(
        inputs: ['Length', 'Shoulder', 'Chest', 'Stomach', 'Seat', 'Bottom', 'Collar'],
      ),
      'Pathani': const GarmentFormConfig(
        inputs: ['Length', 'Sleeves', 'Shoulder', 'Chest', 'Stomach', 'Seat', 'Bottom', 'Collar'],
        optionalInputs: ['frontChest', 'frontStomach', 'frontSeat'],
        dropdowns: {
          'collar': ['Shirt Collar', 'Bend Collar'],
          'Sleeve Type': ['Cuph', 'Round'],
          'Shoulder Loops': ['Yes', 'No'],
          'Pocket Cover': ['Yes', 'No'],
        },
        hasCuphLogic: true,
      ),
      'Sherwani': const GarmentFormConfig(
        inputs: ['Length', 'Sleeves', 'Shoulder', 'Chest', 'Stomach', 'Seat', 'Bottom', 'Collar'],
        optionalInputs: ['frontChest', 'frontStomach', 'frontSeat'],
      ),
    };
  }

  void _searchCustomer() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _showMeasurements = false;
      _customerData = null;
      _errorMessage = null;
      for (var key in _clothes.keys) {
        _clothes[key] = false;
      }
      _initializeData();
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('customerId', isEqualTo: query)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data();
        final uid = doc.id; // Document ID IS the Firebase Auth UID

        // Fetch existing measurements to auto-fill
        final existingMeasurements = await _measurementService.getMeasurements(uid);

        setState(() {
          _customerData = {...data, 'uid': uid};

          // Auto-fill: pre-populate form data and check boxes for existing garments
          for (var entry in existingMeasurements.entries) {
            final garment = entry.key;
            if (_clothes.containsKey(garment)) {
              _clothes[garment] = true;
              // Copy all fields except timestamp and base64 images into the form state
              final formData = Map<String, dynamic>.from(entry.value);
              formData.remove('timestamp');
              _measurements[garment] = formData;
            }
          }
        });
      } else {
        setState(() {
          _errorMessage = 'No customer found with ID: $query';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Error fetching customer.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _copyExactFields(String source, String target) {
    if (_measurements[source] == null || _measurements[source]!.isEmpty) return;

    final fieldsToClone = [
      'Length', 'Sleeves', 'Shoulder', 'Chest', 'Stomach', 'Seat', 'Collar', 'Bottom',
      'frontChest', 'frontStomach', 'frontSeat',
    ];

    setState(() {
      for (var field in fieldsToClone) {
        if (_measurements[source]!.containsKey(field)) {
          _measurements[target]![field] = _measurements[source]![field];
        }
      }
    });
  }

  Future<void> _submitAll() async {
    if (_customerData == null) return;

    setState(() => _isSubmitting = true);

    try {
      final uid = _customerData!['uid'];

      Map<String, Map<String, dynamic>> finalPayload = {};
      for (var entry in _measurements.entries) {
        if (_clothes[entry.key] == true) {
          finalPayload[entry.key] = entry.value;
        }
      }

      await _measurementService.saveMeasurements(uid, finalPayload);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BillingScreen(
          customerId: _customerData!['customerId'].toString(),
          customerName: _customerData!['username']?.toString() ?? '',
          customerUid: _customerData!['uid']?.toString() ?? '',
        )),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
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
            Text('Customer Measurement', style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text('Enter Customer ID to verify user details and assign garments.', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 32),

            NeumorphicTextField(
              hintText: '5-Digit Customer ID',
              controller: _searchController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _searchCustomer(),
            ),
            const SizedBox(height: 16),
            Center(child: NeumorphicButton(label: 'Verify Customer', onTap: _searchCustomer, isLoading: _isSearching)),
            const SizedBox(height: 24),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_errorMessage!, textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.w500)),
              ),

            if (_customerData != null) ...[
              const Divider(height: 48),
              NeumorphicContainer(
                borderRadius: 16,
                padding: const EdgeInsets.all(20),
                isPressed: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.verified_user, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text('Customer Verified', style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ]),
                    const SizedBox(height: 16),
                    Text('Username: ${_customerData!['username']}', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text('Email: ${_customerData!['email']}', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary)),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              Text('Select Garments to Stitch:', style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 16),

              NeumorphicContainer(
                borderRadius: 16,
                padding: const EdgeInsets.symmetric(vertical: 8),
                isPressed: true,
                child: ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: _clothes.length,
                  itemBuilder: (context, index) {
                    String key = _clothes.keys.elementAt(index);
                    return CheckboxListTile(
                      title: Text(key, style: GoogleFonts.poppins(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                      activeColor: AppColors.primary,
                      checkColor: AppColors.textOnPrimary,
                      value: _clothes[key],
                      onChanged: (bool? value) {
                        if (value != null) {
                          setState(() => _clothes[key] = value);
                        }
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),
              Center(
                child: NeumorphicButton(
                  label: 'Get Measurement',
                  onTap: () => setState(() => _showMeasurements = true),
                ),
              ),

              if (_showMeasurements) ...[
                const SizedBox(height: 32),
                Text('Garment Setup', style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 16),

                ..._clothes.entries.where((e) => e.value).map((entry) {
                  final garmentName = entry.key;
                  final config = _garmentConfigs[garmentName]!;

                  final hasCopyShirt = ['Kurta', 'Coat', 'Jodhpuri', 'Short Kurta', 'Pathani', 'Sherwani'].contains(garmentName);
                  final hasCopyKurta = ['Pathani', 'Sherwani'].contains(garmentName);

                  return GarmentFormCard(
                    garmentName: garmentName,
                    config: config,
                    data: _measurements[garmentName]!,
                    onDataChanged: () => setState(() {}),
                    onCopyAsShirt: hasCopyShirt ? () => _copyExactFields('Shirt', garmentName) : null,
                    onCopyAsKurta: hasCopyKurta ? () => _copyExactFields('Kurta', garmentName) : null,
                  );
                }),

                const SizedBox(height: 48),

                Center(
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 8,
                        shadowColor: AppColors.primary.withValues(alpha: 0.4),
                      ),
                      onPressed: _isSubmitting ? null : _submitAll,
                      child: _isSubmitting
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              'Save Measurements',
                              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.5),
                            ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 48),
            ],
          ],
        ),
      ),
    );
  }
}
