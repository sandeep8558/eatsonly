import 'dart:io';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';

class PrintService {
  Future<bool> printKOT({
    required String printerIp,
    required String tableName,
    required String orderId,
    required List<dynamic> items,
    String? stationName,
  }) async {
    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile);
      List<int> bytes = [];

      // Header
      bytes += generator.text('KITCHEN ORDER',
          styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
      bytes += generator.text('Station: ${stationName ?? "Main"}', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.hr();

      // Order Info
      bytes += generator.row([
        PosColumn(text: 'Table: $tableName', width: 6, styles: const PosStyles(bold: true)),
        PosColumn(text: DateFormat('HH:mm').format(DateTime.now()), width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.text('Order: #${orderId.substring(0, 8)}');
      bytes += generator.hr();

      // Items
      for (var item in items) {
        bytes += generator.text('${item['quantity']} x ${item['menu_item']['name']}',
            styles: const PosStyles(bold: true));
        
        if (item['notes'] != null && item['notes'].toString().isNotEmpty) {
          bytes += generator.text('  NOTE: ${item['notes']}', styles: const PosStyles(bold: true));
        }


        if (item['children'] != null) {
          for (var child in item['children']) {
             bytes += generator.text('  - ${child['menu_item']['name']}', styles: const PosStyles(fontType: PosFontType.fontB));
          }
        }
      }

      bytes += generator.hr();
      bytes += generator.feed(2);
      bytes += generator.cut();

      // Send to printer via Socket (Network)
      final socket = await Socket.connect(printerIp, 9100, timeout: const Duration(seconds: 5));
      socket.add(bytes);
      await socket.flush();
      await socket.close();

      return true;
    } catch (e) {
      print('Printing Error: $e');
      return false;
    }
  }

  Future<bool> printBill({
    required String printerIp,
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
  }) async {
    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile);
      List<int> bytes = [];

      // Header
      bytes += generator.text(restaurantName,
          styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
      bytes += generator.text('INVOICE', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text(DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now()), styles: const PosStyles(align: PosAlign.center));
      bytes += generator.hr();

      // Table Info
      bytes += generator.text('Table: $tableName', styles: const PosStyles(bold: true));
      bytes += generator.text('Order: #${orderId.substring(0, 8)}');
      bytes += generator.hr();

      // Item Headers
      bytes += generator.row([
        PosColumn(text: 'Item', width: 8),
        PosColumn(text: 'Qty', width: 2, styles: const PosStyles(align: PosAlign.center)),
        PosColumn(text: 'Price', width: 2, styles: const PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.hr();

      // Items
      for (var item in items) {
        bytes += generator.row([
          PosColumn(text: item['menu_item']['name'], width: 8),
          PosColumn(text: '${item['quantity']}', width: 2, styles: const PosStyles(align: PosAlign.center)),
          PosColumn(text: '${item['price']}', width: 2, styles: const PosStyles(align: PosAlign.right)),
        ]);
      }

      bytes += generator.hr();

      // Totals
      bytes += generator.row([
        PosColumn(text: 'Subtotal', width: 8),
        PosColumn(text: 'Rs.${subtotal.toStringAsFixed(2)}', width: 4, styles: const PosStyles(align: PosAlign.right)),
      ]);
      
      bytes += generator.row([
        PosColumn(text: 'Service Charge', width: 8),
        PosColumn(text: 'Rs.${serviceCharge.toStringAsFixed(2)}', width: 4, styles: const PosStyles(align: PosAlign.right)),
      ]);
      
      bytes += generator.row([
        PosColumn(text: 'Packing Charge', width: 8),
        PosColumn(text: 'Rs.${packingCharge.toStringAsFixed(2)}', width: 4, styles: const PosStyles(align: PosAlign.right)),
      ]);
      
      bytes += generator.row([
        PosColumn(text: 'Delivery Charge', width: 8),
        PosColumn(text: 'Rs.${deliveryCharge.toStringAsFixed(2)}', width: 4, styles: const PosStyles(align: PosAlign.right)),
      ]);
      
      if (taxBreakup != null && taxBreakup.isNotEmpty) {
        for (var entry in taxBreakup.entries) {
          final bool isInclusive = entry.value['isInclusive'];
          final double amount = entry.value['amount'];
          bytes += generator.row([
            PosColumn(text: '${entry.key}${isInclusive ? ' (incl)' : ''}', width: 8),
            PosColumn(text: 'Rs.${amount.toStringAsFixed(2)}', width: 4, styles: const PosStyles(align: PosAlign.right)),
          ]);
        }
      } else {
        bytes += generator.row([
          PosColumn(text: 'Tax', width: 8),
          PosColumn(text: 'Rs.${tax.toStringAsFixed(2)}', width: 4, styles: const PosStyles(align: PosAlign.right)),
        ]);
      }
      
      if (tipAmount > 0) {
        bytes += generator.row([
          PosColumn(text: 'Tip', width: 8),
          PosColumn(text: 'Rs.${tipAmount.toStringAsFixed(2)}', width: 4, styles: const PosStyles(align: PosAlign.right)),
        ]);
      }
      bytes += generator.hr();
      bytes += generator.row([
        PosColumn(text: 'GRAND TOTAL', width: 8, styles: const PosStyles(bold: true)),
        PosColumn(text: 'Rs.${(total + tipAmount).toStringAsFixed(2)}', width: 4, styles: const PosStyles(bold: true, align: PosAlign.right)),
      ]);

      bytes += generator.hr();
      bytes += generator.text('Thank you!', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.feed(3);

      bytes += generator.cut();

      final socket = await Socket.connect(printerIp, 9100, timeout: const Duration(seconds: 5));
      socket.add(bytes);
      await socket.flush();
      await socket.close();

      return true;
    } catch (e) {
      print('Printing Error: $e');
      return false;
    }
  }
}
