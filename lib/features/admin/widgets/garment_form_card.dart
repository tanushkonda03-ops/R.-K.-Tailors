import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/neumorphic_container.dart';

class GarmentFormConfig {
  final List<String> inputs;
  final List<String> optionalInputs;
  final Map<String, List<String>> dropdowns;
  final Map<String, String> defaultDropdowns;
  final bool hasCuphLogic;
  final bool hasNoteAndImage;

  const GarmentFormConfig({
    this.inputs = const [],
    this.optionalInputs = const [],
    this.dropdowns = const {},
    this.defaultDropdowns = const {},
    this.hasCuphLogic = false,
    this.hasNoteAndImage = true,
  });
}

class GarmentFormCard extends StatefulWidget {
  final String garmentName;
  final GarmentFormConfig config;
  final Map<String, dynamic> data;
  final VoidCallback onDataChanged;
  final VoidCallback? onCopyAsShirt;
  final VoidCallback? onCopyAsKurta;

  const GarmentFormCard({
    super.key,
    required this.garmentName,
    required this.config,
    required this.data,
    required this.onDataChanged,
    this.onCopyAsShirt,
    this.onCopyAsKurta,
  });

  @override
  State<GarmentFormCard> createState() => _GarmentFormCardState();
}

class _GarmentFormCardState extends State<GarmentFormCard> {
  final ImagePicker _picker = ImagePicker();
  static const int _maxImages = 4;

  List<String> get _images {
    final imgs = widget.data['referenceImages'];
    if (imgs is List) {
      return List<String>.from(imgs);
    }
    return [];
  }

  void _updateField(String key, dynamic value) {
    widget.data[key] = value;
    widget.onDataChanged();
  }

  void _addImage(String path) {
    final current = _images;
    if (current.length >= _maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum $_maxImages images allowed per garment.'),
        ),
      );
      return;
    }
    current.add(path);
    _updateField('referenceImages', current);
  }

  void _removeImage(int index) {
    final current = _images;
    if (index >= 0 && index < current.length) {
      current.removeAt(index);
      _updateField('referenceImages', current);
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    'Scan Reference (Camera)',
                    style: GoogleFonts.poppins(color: AppColors.textPrimary),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final picked = await _picker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 25,
                      maxWidth: 600,
                      maxHeight: 600,
                    );
                    if (picked != null) _addImage(picked.path);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    'Upload from Gallery',
                    style: GoogleFonts.poppins(color: AppColors.textPrimary),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final picked = await _picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 25,
                      maxWidth: 600,
                      maxHeight: 600,
                    );
                    if (picked != null) _addImage(picked.path);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(String key, String label, {bool optional = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NeumorphicContainer(
        borderRadius: 12,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        isPressed: true,
        child: TextField(
          controller:
              TextEditingController(text: widget.data[key]?.toString() ?? '')
                ..selection = TextSelection.collapsed(
                  offset: (widget.data[key]?.toString() ?? '').length,
                ),
          onChanged: (val) => _updateField(key, val),
          style: GoogleFonts.poppins(color: AppColors.textPrimary),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: '$label ${optional ? "(Optional)" : ""}',
            hintStyle: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String key, String label, List<String> options) {
    final value =
        widget.data[key]?.toString() ??
        widget.config.defaultDropdowns[key] ??
        options.first;
    final safeValue = options.contains(value) ? value : options.first;

    if (widget.data[key] == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateField(key, safeValue);
      });
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          NeumorphicContainer(
            borderRadius: 12,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            isPressed: true,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: safeValue,
                isExpanded: true,
                dropdownColor: AppColors.background,
                style: GoogleFonts.poppins(color: AppColors.textPrimary),
                items: options
                    .map(
                      (opt) => DropdownMenuItem(value: opt, child: Text(opt)),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) _updateField(key, val);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery() {
    final images = _images;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: NeumorphicContainer(
            borderRadius: 12,
            padding: const EdgeInsets.all(16),
            isPressed: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  images.isNotEmpty
                      ? Icons.add_photo_alternate
                      : Icons.add_a_photo,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  images.isEmpty
                      ? 'Add Reference Image'
                      : 'Add More (${images.length}/$_maxImages)',
                  style: GoogleFonts.poppins(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (images.isNotEmpty) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final imgPath = images[index];
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildImageWidget(imgPath),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImageWidget(String path) {
    // Local file path
    final file = File(path);
    return Image.file(
      file,
      height: 130,
      width: 130,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        height: 130,
        width: 130,
        color: AppColors.background,
        child: const Center(
          child: Icon(Icons.broken_image, color: AppColors.textSecondary),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: NeumorphicContainer(
        borderRadius: 16,
        padding: const EdgeInsets.all(24),
        isPressed: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  widget.garmentName,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.onCopyAsShirt != null)
                      TextButton.icon(
                        icon: const Icon(
                          Icons.copy,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        label: Text(
                          'Copy as Shirt',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: widget.onCopyAsShirt,
                      ),
                    if (widget.onCopyAsShirt != null &&
                        widget.onCopyAsKurta != null)
                      const SizedBox(width: 8),
                    if (widget.onCopyAsKurta != null)
                      TextButton.icon(
                        icon: const Icon(
                          Icons.content_copy,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        label: Text(
                          'Copy as Kurta',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: widget.onCopyAsKurta,
                      ),
                  ],
                ),
              ],
            ),
            const Divider(height: 32),

            // Base Inputs
            ...widget.config.inputs.map((key) => _buildTextField(key, key)),

            // Optional Inputs
            if (widget.config.optionalInputs.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Optional Measurements',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...widget.config.optionalInputs.map(
                (key) => _buildTextField(key, key, optional: true),
              ),
            ],

            // Dropdowns
            if (widget.config.dropdowns.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...widget.config.dropdowns.entries.map(
                (e) => _buildDropdown(e.key, e.key, e.value),
              ),
            ],

            // Cuph Logic
            if (widget.config.hasCuphLogic) ...[
              Builder(
                builder: (ctx) {
                  final sleeveType = widget.data['Sleeve Type']?.toString();
                  if (sleeveType == 'Round') {
                    return _buildTextField('Cuph Loosing', 'Cuph Loosing');
                  } else {
                    return _buildDropdown('Cuph', 'Cuph Size', [
                      '9 x 2½',
                      '10 x 2½',
                      '9 x 3',
                      '10 x 3',
                    ]);
                  }
                },
              ),
            ],

            // Note and Images
            if (widget.config.hasNoteAndImage) ...[
              const SizedBox(height: 8),
              _buildTextField('Note', 'Additional Note', optional: true),
              const SizedBox(height: 16),
              _buildImageGallery(),
            ],
          ],
        ),
      ),
    );
  }
}
