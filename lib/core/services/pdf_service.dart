
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:cloud_firestore/cloud_firestore.dart';

class PdfService {
  /// Generate a PDF matching the R.K. Tailors bill blueprint.
  Future<Uint8List> generateBillPdf(Map<String, dynamic> bill) async {
    final pdf = pw.Document();

    final billNo = bill['billNo'] ?? '';
    final customerName = bill['customerName'] ?? '';
    final customerId = bill['customerId'] ?? '';
    final items = List<Map<String, dynamic>>.from(bill['items'] ?? []);
    final total = (bill['total'] ?? 0).toDouble();
    final advance = (bill['advance'] ?? 0).toDouble();
    final grandTotal = (bill['grandTotal'] ?? 0).toDouble();

    // Format date
    String dateStr = '';
    if (bill['date'] is Timestamp) {
      final dt = (bill['date'] as Timestamp).toDate();
      dateStr = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } else {
      final now = DateTime.now();
      dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    }

    final redColor = PdfColor.fromHex('#B71C1C');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: redColor, width: 2),
            ),
            padding: const pw.EdgeInsets.all(16),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Header
                pw.Center(
                  child: pw.Text(
                    'R. K. Tailors',
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: redColor,
                    ),
                  ),
                ),
                pw.SizedBox(height: 4),

                // Phone & Owner
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('+91 9022291965', style: pw.TextStyle(fontSize: 11, color: redColor)),
                    pw.Text('Kumar R. Konda', style: pw.TextStyle(fontSize: 11, color: redColor)),
                  ],
                ),
                pw.Divider(color: redColor, thickness: 1.5),

                // Name & Bill No
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Name: $customerName', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: redColor)),
                    pw.Text('Bill No. $billNo', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: redColor)),
                  ],
                ),
                pw.SizedBox(height: 4),

                // Cust Id & Date
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Cust. I'd: $customerId", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: redColor)),
                    pw.Text('Date: $dateStr', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: redColor)),
                  ],
                ),
                pw.Divider(color: redColor, thickness: 1.5),

                // Column Headers
                pw.Row(
                  children: [
                    pw.SizedBox(width: 40, child: pw.Text('Sr. No.', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: redColor))),
                    pw.Expanded(child: pw.Text('Item Name', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: redColor))),
                    pw.SizedBox(width: 40, child: pw.Text('Qnt.', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: redColor), textAlign: pw.TextAlign.right)),
                    pw.SizedBox(width: 60, child: pw.Text('Amt.', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: redColor), textAlign: pw.TextAlign.right)),
                  ],
                ),
                pw.SizedBox(height: 8),

                // Items
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: items.map((item) {
                      return pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 2),
                        child: pw.Row(
                          children: [
                            pw.SizedBox(width: 40, child: pw.Text('${item['srNo']}', style: const pw.TextStyle(fontSize: 11))),
                            pw.Expanded(child: pw.Text('${item['name']}', style: const pw.TextStyle(fontSize: 11))),
                            pw.SizedBox(width: 40, child: pw.Text('${item['quantity']}', style: const pw.TextStyle(fontSize: 11), textAlign: pw.TextAlign.right)),
                            pw.SizedBox(width: 60, child: pw.Text('${item['amount']}', style: const pw.TextStyle(fontSize: 11), textAlign: pw.TextAlign.right)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Totals
                _dashedLine(redColor),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: redColor)),
                    pw.Text('Rs. ${total.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: redColor)),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Advance', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: redColor)),
                    pw.Text('Rs. ${advance.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: redColor)),
                  ],
                ),
                _dashedLine(redColor),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Grand Total', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: redColor)),
                    pw.Text('Rs. ${grandTotal.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: redColor)),
                  ],
                ),
                pw.SizedBox(height: 16),

                // Disclaimer
                pw.Divider(color: redColor, thickness: 1.5),
                pw.SizedBox(height: 4),
                pw.Center(
                  child: pw.Text(
                    'We are not responsible for any delivery after 2 months',
                    style: pw.TextStyle(fontSize: 10, color: redColor),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _dashedLine(PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: List.generate(
          40,
          (_) => pw.Expanded(
            child: pw.Container(
              height: 1.5,
              margin: const pw.EdgeInsets.symmetric(horizontal: 1),
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
