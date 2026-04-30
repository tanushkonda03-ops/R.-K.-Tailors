import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/neumorphic_text_field.dart';
import '../../core/widgets/neumorphic_button.dart';
import '../../core/widgets/neumorphic_container.dart';
import '../../core/services/billing_service.dart';
import '../../core/services/pdf_service.dart';

class AdminBillStatusScreen extends StatefulWidget {
  const AdminBillStatusScreen({super.key});

  @override
  State<AdminBillStatusScreen> createState() => _AdminBillStatusScreenState();
}

class _AdminBillStatusScreenState extends State<AdminBillStatusScreen> {
  final TextEditingController _billNoController = TextEditingController();
  final BillingService _billingService = BillingService();
  final PdfService _pdfService = PdfService();

  bool _isLoading = false;
  bool _isEditing = false;
  String? _error;
  Map<String, dynamic>? _billData;

  // Editing controllers
  final TextEditingController _editAdvanceController = TextEditingController();
  List<Map<String, dynamic>> _editItems = [];

  void _fetchBill() async {
    final query = _billNoController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _billData = null;
      _isEditing = false;
    });

    try {
      final data = await _billingService.getBillByNumber(query);
      if (data != null) {
        setState(() => _billData = data);
      } else {
        setState(() => _error = 'No bill found with number: $query');
      }
    } catch (e) {
      setState(() => _error = 'Error fetching bill.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startEditing() {
    _editItems = List<Map<String, dynamic>>.from(
      (_billData!['items'] as List).map((e) => Map<String, dynamic>.from(e)),
    );
    _editAdvanceController.text = (_billData!['advance'] ?? 0).toString();
    setState(() => _isEditing = true);
  }

  void _saveEdits() async {
    setState(() => _isLoading = true);

    try {
      final billNo = _billData!['billNo'];
      double total = _editItems.fold(
        0.0,
        (s, item) => s + (item['amount'] as num).toDouble(),
      );
      double advance = double.tryParse(_editAdvanceController.text) ?? 0;

      await _billingService.updateBill(billNo, {
        'items': _editItems,
        'total': total,
        'advance': advance,
        'grandTotal': total - advance,
      });

      // Re-fetch to show updated data
      final updated = await _billingService.getBillByNumber(billNo);
      setState(() {
        _billData = updated;
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bill updated!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _markDelivered() async {
    final billNo = _billData!['billNo'];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        title: Text(
          'Mark as Delivered?',
          style: GoogleFonts.playfairDisplay(color: AppColors.textPrimary),
        ),
        content: Text(
          'Bill #$billNo will be permanently deleted.',
          style: GoogleFonts.poppins(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Deliver',
              style: GoogleFonts.poppins(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      await _billingService.deleteBill(billNo);
      setState(() {
        _billData = null;
        _billNoController.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bill #$billNo delivered & removed.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _printBill() async {
    if (_billData == null) return;
    final pdfBytes = await _pdfService.generateBillPdf(_billData!);
    await Printing.layoutPdf(onLayout: (_) => pdfBytes);
  }

  String _formatDate(dynamic dateVal) {
    if (dateVal is Timestamp) {
      final dt = dateVal.toDate();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    }
    return '-';
  }

  @override
  void dispose() {
    _billNoController.dispose();
    _editAdvanceController.dispose();
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
              'Bill Status',
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Search and manage customer bills.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),

            NeumorphicTextField(
              hintText: 'Bill Number (e.g. 0001)',
              controller: _billNoController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _fetchBill(),
            ),
            const SizedBox(height: 16),
            Center(
              child: NeumorphicButton(
                label: 'Find Bill',
                onTap: _fetchBill,
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

            if (_billData != null) ...[
              const Divider(height: 48),

              NeumorphicContainer(
                borderRadius: 16,
                padding: const EdgeInsets.all(20),
                isPressed: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Bill #${_billData!['billNo']}',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          _formatDate(_billData!['date']),
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Customer: ${_billData!['customerName']}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      "Cust. ID: ${_billData!['customerId']}",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Divider(height: 24),

                    // Items Table Header
                    Row(
                      children: [
                        SizedBox(
                          width: 30,
                          child: Text(
                            '#',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Item',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 35,
                          child: Text(
                            'Qty',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        SizedBox(
                          width: 70,
                          child: Text(
                            'Amt',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Items
                    if (_isEditing)
                      ..._editItems.asMap().entries.map((e) {
                        final idx = e.key;
                        final item = e.value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 30,
                                child: Text(
                                  '${idx + 1}',
                                  style: GoogleFonts.poppins(fontSize: 13),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '${item['name']}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 50,
                                child: TextField(
                                  controller: TextEditingController(
                                    text: '${item['quantity']}',
                                  ),
                                  keyboardType: TextInputType.number,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                  ),
                                  textAlign: TextAlign.right,
                                  decoration: const InputDecoration(
                                    border: UnderlineInputBorder(),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                  ),
                                  onChanged: (val) {
                                    final qty = int.tryParse(val) ?? 1;
                                    _editItems[idx]['quantity'] = qty;
                                    _editItems[idx]['amount'] =
                                        (item['price'] as num).toDouble() * qty;
                                  },
                                ),
                              ),
                              SizedBox(
                                width: 60,
                                child: Text(
                                  '₹${((item['amount'] as num).toDouble()).toStringAsFixed(0)}',
                                  style: GoogleFonts.poppins(fontSize: 13),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _editItems.removeAt(idx);
                                    for (
                                      int i = 0;
                                      i < _editItems.length;
                                      i++
                                    ) {
                                      _editItems[i]['srNo'] = i + 1;
                                    }
                                  });
                                },
                                child: const Padding(
                                  padding: EdgeInsets.only(left: 4),
                                  child: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      })
                    else
                      ...(_billData!['items'] as List).map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 30,
                                child: Text(
                                  '${item['srNo']}',
                                  style: GoogleFonts.poppins(fontSize: 13),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '${item['name']}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 35,
                                child: Text(
                                  '${item['quantity']}',
                                  style: GoogleFonts.poppins(fontSize: 13),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              SizedBox(
                                width: 70,
                                child: Text(
                                  '₹${((item['amount'] as num).toDouble()).toStringAsFixed(0)}',
                                  style: GoogleFonts.poppins(fontSize: 13),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                    const Divider(height: 24),

                    // Totals
                    _totalRow(
                      'Total',
                      '₹${(_billData!['total'] as num).toDouble().toStringAsFixed(0)}',
                    ),

                    if (_isEditing) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Advance (₹)',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      TextField(
                        controller: _editAdvanceController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 4),
                        ),
                      ),
                    ] else
                      _totalRow(
                        'Advance',
                        '₹${(_billData!['advance'] as num).toDouble().toStringAsFixed(0)}',
                      ),

                    const Divider(height: 16),
                    _totalRow(
                      'Grand Total',
                      '₹${(_billData!['grandTotal'] as num).toDouble().toStringAsFixed(0)}',
                      bold: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(
                        _isEditing ? Icons.save : Icons.edit,
                        size: 18,
                      ),
                      label: Text(
                        _isEditing ? 'Save' : 'Edit',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isEditing ? _saveEdits : _startEditing,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.print, size: 18),
                      label: Text(
                        'Print',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _printBill,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline, size: 20),
                  label: Text(
                    'Mark as Delivered',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _markDelivered,
                ),
              ),
              const SizedBox(height: 48),
            ],
          ],
        ),
      ),
    );
  }

  Widget _totalRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: bold ? 16 : 14,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: bold ? 16 : 14,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
