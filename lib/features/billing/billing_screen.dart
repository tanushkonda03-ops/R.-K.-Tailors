import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/neumorphic_container.dart';
import '../../core/widgets/neumorphic_button.dart';
import '../../core/services/billing_service.dart';
import '../../core/services/pdf_service.dart';

class BillingScreen extends StatefulWidget {
  final String customerId;
  final String customerName;
  final String customerUid;

  const BillingScreen({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.customerUid,
  });

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final BillingService _billingService = BillingService();
  final PdfService _pdfService = PdfService();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _otherItemController = TextEditingController();
  final TextEditingController _advanceController = TextEditingController();

  static const List<String> _garmentOptions = [
    'Shirt', 'Kurta', 'Short Kurta', 'Sherwani', 'Coat',
    'Jacket', 'Jodhpuri', 'Pant', 'Pathani', 'Salwaar', 'Dhoti', 'Other',
  ];

  String _selectedItem = 'Shirt';
  int _quantity = 1;
  String? _itemPhoto;
  final List<Map<String, dynamic>> _items = [];

  bool _showTotals = false;
  bool _showGrandTotal = false;
  bool _isGenerating = false;

  double get _total => _items.fold(0.0, (s, item) => s + (item['amount'] as double));
  double get _advance => double.tryParse(_advanceController.text) ?? 0.0;
  double get _grandTotal => _total - _advance;

  void _addItem() {
    final price = double.tryParse(_priceController.text.trim());
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid price.')),
      );
      return;
    }

    String itemName = _selectedItem;
    if (_selectedItem == 'Other') {
      itemName = _otherItemController.text.trim();
      if (itemName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter item name.')),
        );
        return;
      }
    }

    setState(() {
      _items.add({
        'srNo': _items.length + 1,
        'name': itemName,
        'price': price,
        'quantity': _quantity,
        'amount': price * _quantity,
        'photoBase64': _itemPhoto != null ? _encodePhoto(_itemPhoto!) : null,
      });

      // Reset form
      _priceController.clear();
      _otherItemController.clear();
      _selectedItem = 'Shirt';
      _quantity = 1;
      _itemPhoto = null;
      _showTotals = false;
      _showGrandTotal = false;
    });
  }

  String? _encodePhoto(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) {
        final bytes = file.readAsBytesSync();
        return 'data:image/jpeg;base64,${base64Encode(bytes)}';
      }
    } catch (_) {}
    return null;
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      // Re-number
      for (int i = 0; i < _items.length; i++) {
        _items[i]['srNo'] = i + 1;
      }
      _showTotals = false;
      _showGrandTotal = false;
    });
  }

  Future<void> _pickItemPhoto() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                  title: Text('Camera', style: GoogleFonts.poppins(color: AppColors.textPrimary)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 20, maxWidth: 400, maxHeight: 400);
                    if (picked != null) setState(() => _itemPhoto = picked.path);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: AppColors.primary),
                  title: Text('Gallery', style: GoogleFonts.poppins(color: AppColors.textPrimary)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 20, maxWidth: 400, maxHeight: 400);
                    if (picked != null) setState(() => _itemPhoto = picked.path);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _generateBill() async {
    if (_items.isEmpty) return;

    setState(() => _isGenerating = true);

    try {
      final billNo = await _billingService.generateBillNumber();
      final now = DateTime.now();

      final billData = {
        'billNo': billNo,
        'customerId': widget.customerId,
        'customerName': widget.customerName,
        'customerUid': widget.customerUid,
        'date': Timestamp.fromDate(now),
        'items': _items.map((item) {
          final cleaned = Map<String, dynamic>.from(item);
          // Remove null photos to save space
          if (cleaned['photoBase64'] == null) {
            cleaned.remove('photoBase64');
          }
          return cleaned;
        }).toList(),
        'total': _total,
        'advance': _advance,
        'grandTotal': _grandTotal,
        'status': 'active',
      };

      await _billingService.saveBill(billData);

      // Generate & show PDF
      final pdfBytes = await _pdfService.generateBillPdf(billData);

      if (!mounted) return;

      await Printing.layoutPdf(onLayout: (_) => pdfBytes);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bill #$billNo generated successfully!'), backgroundColor: AppColors.primary),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _otherItemController.dispose();
    _advanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Customer Billing', style: GoogleFonts.playfairDisplay(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Customer Info Header
              NeumorphicContainer(
                borderRadius: 12, padding: const EdgeInsets.all(16), isPressed: true,
                child: Row(children: [
                  Icon(Icons.person, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('${widget.customerName}  •  ID: ${widget.customerId}',
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  ),
                ]),
              ),

              const SizedBox(height: 32),
              Text('Add Item', style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 16),

              // Item Dropdown
              _label('Item Name'),
              NeumorphicContainer(
                borderRadius: 12, padding: const EdgeInsets.symmetric(horizontal: 16), isPressed: true,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedItem,
                    isExpanded: true,
                    dropdownColor: AppColors.background,
                    style: GoogleFonts.poppins(color: AppColors.textPrimary),
                    items: _garmentOptions.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                    onChanged: (val) => setState(() => _selectedItem = val!),
                  ),
                ),
              ),

              // Other item text input
              if (_selectedItem == 'Other') ...[
                const SizedBox(height: 12),
                NeumorphicContainer(
                  borderRadius: 12, padding: const EdgeInsets.symmetric(horizontal: 16), isPressed: true,
                  child: TextField(
                    controller: _otherItemController,
                    style: GoogleFonts.poppins(color: AppColors.textPrimary),
                    decoration: InputDecoration(border: InputBorder.none, hintText: 'Enter item name', hintStyle: GoogleFonts.poppins(color: AppColors.textSecondary)),
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Price
              _label('Price per unit (₹)'),
              NeumorphicContainer(
                borderRadius: 12, padding: const EdgeInsets.symmetric(horizontal: 16), isPressed: true,
                child: TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.poppins(color: AppColors.textPrimary),
                  decoration: InputDecoration(border: InputBorder.none, hintText: 'e.g. 500', hintStyle: GoogleFonts.poppins(color: AppColors.textSecondary)),
                ),
              ),

              const SizedBox(height: 12),

              // Quantity with +/-
              _label('Quantity'),
              NeumorphicContainer(
                borderRadius: 12, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), isPressed: true,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: AppColors.primary),
                      onPressed: () { if (_quantity > 1) setState(() => _quantity--); },
                    ),
                    const SizedBox(width: 16),
                    Text('$_quantity', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                      onPressed: () => setState(() => _quantity++),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Photo
              GestureDetector(
                onTap: _pickItemPhoto,
                child: NeumorphicContainer(
                  borderRadius: 12, padding: const EdgeInsets.all(12), isPressed: false,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(_itemPhoto != null ? Icons.image : Icons.add_a_photo, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(_itemPhoto != null ? 'Photo added ✓' : 'Add Item Photo (Optional)',
                      style: GoogleFonts.poppins(color: AppColors.textPrimary, fontWeight: FontWeight.w500, fontSize: 13)),
                  ]),
                ),
              ),

              if (_itemPhoto != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(File(_itemPhoto!), height: 100, width: double.infinity, fit: BoxFit.cover),
                ),
              ],

              const SizedBox(height: 20),
              Center(child: NeumorphicButton(label: 'Add Item', onTap: _addItem)),

              // Item List
              if (_items.isNotEmpty) ...[
                const SizedBox(height: 32),
                Text('Items Added', style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 16),

                ..._items.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: NeumorphicContainer(
                      borderRadius: 12, padding: const EdgeInsets.all(12), isPressed: false,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16, backgroundColor: AppColors.primary,
                            child: Text('${item['srNo']}', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('${item['name']}', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                              Text('₹${item['price']} × ${item['quantity']} = ₹${(item['amount'] as double).toStringAsFixed(0)}',
                                style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                            ]),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                            onPressed: () => _removeItem(idx),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 24),

                // Get Total
                if (!_showTotals)
                  Center(child: NeumorphicButton(label: 'Get Total', onTap: () => setState(() => _showTotals = true))),

                if (_showTotals) ...[
                  NeumorphicContainer(
                    borderRadius: 16, padding: const EdgeInsets.all(20), isPressed: false,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      _summaryRow('Total', '₹${_total.toStringAsFixed(0)}'),
                      const SizedBox(height: 16),
                      _label('Advance Payment (₹)'),
                      NeumorphicContainer(
                        borderRadius: 12, padding: const EdgeInsets.symmetric(horizontal: 16), isPressed: true,
                        child: TextField(
                          controller: _advanceController,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.poppins(color: AppColors.textPrimary),
                          decoration: InputDecoration(border: InputBorder.none, hintText: 'Enter advance amount', hintStyle: GoogleFonts.poppins(color: AppColors.textSecondary)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (!_showGrandTotal)
                        Center(child: NeumorphicButton(label: 'Grand Total', onTap: () => setState(() => _showGrandTotal = true))),

                      if (_showGrandTotal) ...[
                        const Divider(height: 32),
                        _summaryRow('Total', '₹${_total.toStringAsFixed(0)}'),
                        _summaryRow('Advance', '- ₹${_advance.toStringAsFixed(0)}'),
                        const Divider(height: 24),
                        _summaryRow('Grand Total', '₹${_grandTotal.toStringAsFixed(0)}', bold: true),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 8,
                            ),
                            onPressed: _isGenerating ? null : _generateBill,
                            child: _isGenerating
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text('Generate Bill', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                          ),
                        ),
                      ],
                    ]),
                  ),
                ],
                const SizedBox(height: 48),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(text, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: bold ? 18 : 15, fontWeight: bold ? FontWeight.w700 : FontWeight.w600, color: AppColors.primary)),
          Text(value, style: GoogleFonts.poppins(fontSize: bold ? 18 : 15, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
