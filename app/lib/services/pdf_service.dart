import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfService {
  Future<void> generateBillPdf({
    required String restaurantName,
    required String tableName,
    required String orderId,
    required double subtotal,
    required double tax,
    required double total,
    double tipAmount = 0,
    double deliveryCharge = 0,
    double packingCharge = 0,
    double serviceCharge = 0,
    required List<dynamic> items,
    Map<String, Map<String, dynamic>>? taxBreakup,
    String? address,
    String? phone,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(10),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(restaurantName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                    if (address != null) pw.Text(address, style: const pw.TextStyle(fontSize: 10)),
                    if (phone != null) pw.Text('Phone: $phone', style: const pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 5),
                    pw.Text('INVOICE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    pw.Text(DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now()), style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ),
              pw.Divider(thickness: 1),
              pw.Text('Table: $tableName', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              pw.Text('Order: #${orderId.substring(0, 8)}', style: const pw.TextStyle(fontSize: 10)),
              pw.Divider(thickness: 1),
              
              pw.Row(
                children: [
                  pw.Expanded(flex: 6, child: pw.Text('Item', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                  pw.Expanded(flex: 2, child: pw.Text('Qty', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                  pw.Expanded(flex: 4, child: pw.Text('Price', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                ],
              ),
              pw.Divider(thickness: 0.5),
              
              ...items.map((item) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Row(
                  children: [
                    pw.Expanded(flex: 6, child: pw.Text(item['menu_item']['name'], style: const pw.TextStyle(fontSize: 10))),
                    pw.Expanded(flex: 2, child: pw.Text('${item['quantity']}', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 10))),
                    pw.Expanded(flex: 4, child: pw.Text('Rs.${(item['price'] * item['quantity']).toStringAsFixed(2)}', textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 10))),
                  ],
                ),
              )),
              
              pw.Divider(thickness: 1),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Rs.${subtotal.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Service Charge', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Rs.${serviceCharge.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Packing Charge', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Rs.${packingCharge.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Delivery Charge', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Rs.${deliveryCharge.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              if (taxBreakup != null && taxBreakup.isNotEmpty)
                ...taxBreakup.entries.map((entry) {
                  final bool isInclusive = entry.value['isInclusive'];
                  final double amount = entry.value['amount'];
                  return pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('${entry.key}${isInclusive ? ' (incl)' : ''}', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Rs.${amount.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  );
                })
              else
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Tax', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Rs.${tax.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              if (tipAmount > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Tip', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Rs.${tipAmount.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('GRAND TOTAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                  pw.Text('Rs.${(total + tipAmount).toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                ],
              ),
              pw.Divider(thickness: 1),
              pw.Center(
                child: pw.Text('Thank you!', style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 10)),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  Future<void> generateKotPdf({
    required String tableName,
    required String orderId,
    required List<Map<String, dynamic>> stationGroups, // List of {name: '', items: []}
  }) async {
    final pdf = pw.Document();

    for (var group in stationGroups) {
      final stationName = group['name'] as String;
      final items = group['items'] as List<dynamic>;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.roll80,
          margin: const pw.EdgeInsets.all(10),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text('KITCHEN ORDER', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                      pw.Text('Station: $stationName', style: const pw.TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                pw.Divider(thickness: 1),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Table: $tableName', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    pw.Text(DateFormat('HH:mm').format(DateTime.now()), style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.Text('Order: #${orderId.substring(0, 8)}', style: const pw.TextStyle(fontSize: 10)),
                pw.Divider(thickness: 1),
                
                ...items.map((item) => pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 4),
                      child: pw.Text('${item['quantity']} x ${item['menu_item']['name']}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    ),
                    if (item['notes'] != null && item['notes'].toString().isNotEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 10, bottom: 4),
                        child: pw.Text('  NOTE: ${item['notes']}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ),
                    if (item['children'] != null)
                      ...((item['children'] as List).map((child) => pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 10),
                        child: pw.Text('- ${child['menu_item']['name']}', style: const pw.TextStyle(fontSize: 10)),
                      ))),
                    pw.Divider(thickness: 0.2),
                  ],
                )),
                
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text('--- End of Station KOT ---', style: const pw.TextStyle(fontSize: 8)),
                ),
              ],
            );
          },
        ),
      );
    }

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  Future<void> generateQrPdf({
    required String restaurantName,
    required String tableName,
    required String url,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(restaurantName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 32)),
                pw.SizedBox(height: 20),
                pw.Text('Table $tableName', style: const pw.TextStyle(fontSize: 24)),
                pw.SizedBox(height: 40),
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black, width: 2),
                  ),
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: url,
                    width: 300,
                    height: 300,
                  ),
                ),
                pw.SizedBox(height: 40),
                pw.Text('Scan to view Digital Menu & Order', style: const pw.TextStyle(fontSize: 18)),
                pw.SizedBox(height: 10),
                pw.Text(url, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              ],
            ),
          );
        },
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'table_${tableName}_qr.pdf');
  }

  Future<void> generateAccountingReportPdf({
    required String restaurantName,
    required String reportType, // 'sales', 'purchases', 'wastage'
    required String periodTitle,
    required List<dynamic> records,
  }) async {
    final pdf = pw.Document();

    // 1. Resolve columns & headers
    List<String> headers = [];
    String reportTitle = '';
    if (reportType == 'sales') {
      reportTitle = 'SALES & TAX REVENUE REPORT';
      headers = ['ID', 'Date & Time', 'Customer', 'Subtotal', 'CGST', 'SGST', 'Total', 'Pay Mode'];
    } else if (reportType == 'purchases') {
      reportTitle = 'PROCUREMENT & BILLS EXPORTS';
      headers = ['PO Number', 'Order Date', 'Supplier Name', 'Status', 'Total Amount'];
    } else {
      reportTitle = 'WASTAGE & INVENTORY LOSS REPORT';
      headers = ['Item Name', 'Log Date', 'Qty', 'Unit Cost', 'Financial Loss', 'Reason'];
    }

    // 2. Format row values
    List<List<String>> rowData = [];
    double grandTotal = 0.0;
    double cgstTotal = 0.0;
    double sgstTotal = 0.0;
    double subtotalTotal = 0.0;

    for (var r in records) {
      if (reportType == 'sales') {
        final id = r['id'].toString().substring(0, 8);
        final date = r['date'].toString();
        final cust = r['customer_name'].toString();
        final sub = (r['subtotal'] as num).toDouble();
        final cgst = (r['cgst'] as num).toDouble();
        final sgst = (r['sgst'] as num).toDouble();
        final tot = (r['total'] as num).toDouble();
        final pay = r['payment_method'].toString();

        subtotalTotal += sub;
        cgstTotal += cgst;
        sgstTotal += sgst;
        grandTotal += tot;

        rowData.add([
          id,
          date,
          cust,
          'Rs.${sub.toStringAsFixed(1)}',
          'Rs.${cgst.toStringAsFixed(1)}',
          'Rs.${sgst.toStringAsFixed(1)}',
          'Rs.${tot.toStringAsFixed(1)}',
          pay
        ]);
      } else if (reportType == 'purchases') {
        final po = r['po_number'].toString();
        final date = r['order_date'].toString();
        final supplier = r['supplier_name'].toString();
        final status = r['status'].toString();
        final tot = (r['total_amount'] as num).toDouble();

        grandTotal += tot;

        rowData.add([
          po,
          date,
          supplier,
          status,
          'Rs.${tot.toStringAsFixed(2)}'
        ]);
      } else {
        final item = r['item_name'].toString();
        final date = r['date'].toString();
        final qty = (r['quantity'] as num).toDouble();
        final unit = r['unit'].toString();
        final cost = (r['cost_per_unit'] as num).toDouble();
        final loss = (r['financial_loss'] as num).toDouble();
        final reason = r['reason'].toString();

        grandTotal += loss;

        rowData.add([
          item,
          date,
          '${qty.toStringAsFixed(1)} $unit',
          'Rs.${cost.toStringAsFixed(1)}',
          'Rs.${loss.toStringAsFixed(1)}',
          reason
        ]);
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(restaurantName.toUpperCase(), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.amber)),
                      pw.SizedBox(height: 4),
                      pw.Text('CHARTERED ACCOUNTANT COMPLIANCE LEDGER', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(reportTitle, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 4),
                      pw.Text('Period: $periodTitle', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    ],
                  )
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Divider(thickness: 1, color: PdfColors.amber),
              pw.SizedBox(height: 16),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 24),
            child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
          );
        },
        build: (pw.Context context) {
          return [
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: rowData,
              border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.amber),
              rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: reportType == 'sales'
                  ? {
                      3: pw.Alignment.centerRight,
                      4: pw.Alignment.centerRight,
                      5: pw.Alignment.centerRight,
                      6: pw.Alignment.centerRight,
                    }
                  : reportType == 'purchases'
                      ? {4: pw.Alignment.centerRight}
                      : {2: pw.Alignment.centerRight, 3: pw.Alignment.centerRight, 4: pw.Alignment.centerRight},
            ),
            pw.SizedBox(height: 24),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.amber50,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColors.amber100),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      if (reportType == 'sales') ...[
                        pw.Text('Subtotal Net Total: Rs.${subtotalTotal.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 9)),
                        pw.SizedBox(height: 4),
                        pw.Text('Total CGST (2.5%): Rs.${cgstTotal.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 9)),
                        pw.SizedBox(height: 4),
                        pw.Text('Total SGST (2.5%): Rs.${sgstTotal.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 9)),
                        pw.SizedBox(height: 8),
                      ],
                      pw.Text(
                        'GRAND LEDGER TOTAL: Rs.${grandTotal.toStringAsFixed(2)}',
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.amber900),
                      ),
                    ],
                  ),
                )
              ],
            )
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${reportType}_ledger_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }
}
