import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/utils/money.dart';
import '../models/business.dart';
import '../models/customer.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';

/// Structured A4 invoice PDF per `10_PDF_INVOICE_SPEC.md`.
class InvoicePdfTemplate {
  InvoicePdfTemplate._();

  static const PdfColor _accent = PdfColor.fromInt(0xFF1B4F8A);
  static const PdfColor _text = PdfColor.fromInt(0xFF1A2330);
  static const PdfColor _muted = PdfColor.fromInt(0xFF5C6B7A);
  static const PdfColor _border = PdfColor.fromInt(0xFFE2E8F0);
  static const PdfColor _headerBg = PdfColor.fromInt(0xFFF4F6F8);
  static const PdfColor _black = PdfColors.black;

  static PdfPageFormat get pageFormat => PdfPageFormat.a4.copyWith(
        marginTop: 20 * PdfPageFormat.mm,
        marginBottom: 20 * PdfPageFormat.mm,
        marginLeft: 18 * PdfPageFormat.mm,
        marginRight: 18 * PdfPageFormat.mm,
      );

  static String fileName(String invoiceNumber) {
    final cleaned = invoiceNumber.trim().replaceAll(RegExp(r'\s+'), '_');
    return 'Invoice_$cleaned.pdf';
  }

  /// Spec payment status labels (final unpaid maps to Outstanding).
  static String paymentStatusLabel(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.paid:
        return 'Paid';
      case InvoiceStatus.partial:
        return 'Partially Paid';
      case InvoiceStatus.overdue:
        return 'Overdue';
      case InvoiceStatus.final_:
        return 'Outstanding';
      case InvoiceStatus.draft:
        return 'Draft';
      case InvoiceStatus.cancelled:
        return 'Cancelled';
    }
  }

  static PdfColor paymentStatusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.paid:
        return const PdfColor.fromInt(0xFF2E7D4F);
      case InvoiceStatus.partial:
        return const PdfColor.fromInt(0xFFE08A1E);
      case InvoiceStatus.overdue:
        return const PdfColor.fromInt(0xFFC62828);
      case InvoiceStatus.final_:
        return _accent;
      case InvoiceStatus.draft:
        return const PdfColor.fromInt(0xFF9AA3AD);
      case InvoiceStatus.cancelled:
        return const PdfColor.fromInt(0xFFC62828);
    }
  }

  static String paymentTerms(Invoice invoice) {
    final due = invoice.dueDate;
    if (due == null) return 'Payment due on receipt';
    final issueDay = DateTime(
      invoice.issueDate.year,
      invoice.issueDate.month,
      invoice.issueDate.day,
    );
    final dueDay = DateTime(due.year, due.month, due.day);
    final days = dueDay.difference(issueDay).inDays;
    if (days <= 0) return 'Payment due on receipt';
    if (days == 1) return 'Payment due within 1 day';
    return 'Payment due within $days days';
  }

  static Future<pw.ThemeData> _theme() async {
    try {
      final base = await PdfGoogleFonts.nunitoRegular();
      final bold = await PdfGoogleFonts.nunitoBold();
      return pw.ThemeData.withFont(base: base, bold: bold);
    } catch (_) {
      // Offline / no font cache: fall back to built-in Helvetica.
      return pw.ThemeData.base();
    }
  }

  static Future<pw.Document> build({
    required Business business,
    required Customer customer,
    required Invoice invoice,
    DateTime? generatedAt,
  }) async {
    final when = generatedAt ?? DateTime.now();
    final dateFormat = DateFormat('d MMM yyyy');
    final statusLabel = paymentStatusLabel(invoice.status);
    final statusColor = paymentStatusColor(invoice.status);
    final sortedItems = [...invoice.items]
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    final theme = await _theme();

    final doc = pw.Document(
      title: invoice.invoiceNumber,
      author: 'Business Buddy',
      subject: 'Invoice',
      creator: 'Business Buddy',
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        theme: theme,
        header: (context) => _header(business: business, invoice: invoice),
        footer: (context) => _footer(
          business: business,
          generatedAt: when,
          pageNumber: context.pageNumber,
          pageCount: context.pagesCount,
          dateFormat: dateFormat,
        ),
        build: (context) => [
          pw.SizedBox(height: 12),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _section(
                  title: 'From',
                  children: [
                    _line(business.businessName, bold: true),
                    if (business.ownerName.trim().isNotEmpty)
                      _line(business.ownerName),
                    if (business.address.trim().isNotEmpty)
                      _line(business.address),
                    if (business.phone.trim().isNotEmpty)
                      _line(business.phone),
                    if (business.email.trim().isNotEmpty)
                      _line(business.email),
                    if (business.registrationNumber.trim().isNotEmpty)
                      _line('Reg: ${business.registrationNumber}'),
                    if (business.vatNumber.trim().isNotEmpty)
                      _line('VAT: ${business.vatNumber}'),
                  ],
                ),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: _section(
                  title: 'Bill to',
                  children: [
                    _line(customer.name, bold: true),
                    if (customer.company.trim().isNotEmpty)
                      _line(customer.company),
                    if (customer.phone.trim().isNotEmpty) _line(customer.phone),
                    if (customer.email.trim().isNotEmpty) _line(customer.email),
                    if (customer.address.trim().isNotEmpty)
                      _line(customer.address),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          _detailsBlock(
            invoice: invoice,
            statusLabel: statusLabel,
            statusColor: statusColor,
            dateFormat: dateFormat,
            currency: business.currency,
          ),
          pw.SizedBox(height: 18),
          _itemsTable(sortedItems),
          pw.SizedBox(height: 16),
          _totalsBlock(invoice),
          pw.SizedBox(height: 16),
          _paymentBlock(
            invoice: invoice,
            statusLabel: statusLabel,
            statusColor: statusColor,
          ),
          if (invoice.notes.trim().isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _section(
              title: 'Notes',
              children: [_line(invoice.notes.trim())],
            ),
          ],
        ],
      ),
    );

    return doc;
  }

  static pw.Widget _header({
    required Business business,
    required Invoice invoice,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    business.businessName,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: _accent,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'INVOICE',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: _text,
                    ),
                  ),
                ],
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  invoice.invoiceNumber,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: _text,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Container(height: 2, color: _accent),
      ],
    );
  }

  static pw.Widget _footer({
    required Business business,
    required DateTime generatedAt,
    required int pageNumber,
    required int pageCount,
    required DateFormat dateFormat,
  }) {
    final contact = [
      if (business.phone.trim().isNotEmpty) business.phone.trim(),
      if (business.email.trim().isNotEmpty) business.email.trim(),
    ].join(' | ');

    return pw.Column(
      children: [
        pw.Container(height: 1, color: _border),
        pw.SizedBox(height: 6),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Generated by Business Buddy',
                    style: pw.TextStyle(fontSize: 8, color: _muted),
                  ),
                  pw.Text(
                    'Generated ${dateFormat.format(generatedAt)}',
                    style: pw.TextStyle(fontSize: 8, color: _muted),
                  ),
                  if (contact.isNotEmpty)
                    pw.Text(
                      contact,
                      style: pw.TextStyle(fontSize: 8, color: _muted),
                    ),
                ],
              ),
            ),
            pw.Text(
              'Page $pageNumber of $pageCount',
              style: pw.TextStyle(fontSize: 8, color: _muted),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _section({
    required String title,
    required List<pw.Widget> children,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: _accent,
          ),
        ),
        pw.SizedBox(height: 4),
        ...children,
      ],
    );
  }

  static pw.Widget _line(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: _text,
        ),
      ),
    );
  }

  static pw.Widget _detailsBlock({
    required Invoice invoice,
    required String statusLabel,
    required PdfColor statusColor,
    required DateFormat dateFormat,
    required String currency,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _headerBg,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _detailRow('Invoice number', invoice.invoiceNumber),
                _detailRow('Issue date', dateFormat.format(invoice.issueDate)),
                _detailRow(
                  'Due date',
                  invoice.dueDate == null
                      ? '-'
                      : dateFormat.format(invoice.dueDate!),
                ),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _detailRow(
                  'Payment status',
                  statusLabel,
                  valueColor: statusColor,
                ),
                _detailRow('Currency', currency),
                _detailRow('Payment terms', paymentTerms(invoice)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _detailRow(
    String label,
    String value, {
    PdfColor? valueColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label: ',
              style: pw.TextStyle(fontSize: 9, color: _muted),
            ),
            pw.TextSpan(
              text: value,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: valueColor ?? _text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _itemsTable(List<InvoiceItem> items) {
    final rows = <pw.TableRow>[
      _tableHeaderRow(),
      for (var i = 0; i < items.length; i++)
        _tableItemRow(index: i + 1, item: items[i]),
    ];

    return pw.Table(
      border: pw.TableBorder(
        horizontalInside: const pw.BorderSide(color: _border, width: 0.5),
        bottom: const pw.BorderSide(color: _border, width: 0.5),
        top: const pw.BorderSide(color: _border, width: 0.5),
      ),
      columnWidths: const {
        0: pw.FixedColumnWidth(28),
        1: pw.FlexColumnWidth(4),
        2: pw.FlexColumnWidth(1.2),
        3: pw.FlexColumnWidth(1.6),
        4: pw.FlexColumnWidth(1.6),
      },
      children: rows,
    );
  }

  static pw.TableRow _tableHeaderRow() {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: _headerBg),
      children: [
        _cell('#', header: true),
        _cell('Description', header: true),
        _cell('Qty', header: true, align: pw.TextAlign.right),
        _cell('Unit price', header: true, align: pw.TextAlign.right),
        _cell('Line total', header: true, align: pw.TextAlign.right),
      ],
    );
  }

  static pw.TableRow _tableItemRow({
    required int index,
    required InvoiceItem item,
  }) {
    return pw.TableRow(
      children: [
        _cell('$index'),
        _cell(item.description),
        _cell('${item.quantity}', align: pw.TextAlign.right),
        _cell(
          Money.formatZar(item.unitPriceCents),
          align: pw.TextAlign.right,
        ),
        _cell(
          Money.formatZar(item.lineTotalCents),
          align: pw.TextAlign.right,
        ),
      ],
    );
  }

  static pw.Widget _cell(
    String text, {
    bool header = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: header ? 9 : 9.5,
          fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: header ? _accent : _black,
        ),
      ),
    );
  }

  static pw.Widget _totalsBlock(Invoice invoice) {
    final afterDiscount = invoice.subtotalCents - invoice.discountCents;
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
        width: 240,
        child: pw.Column(
          children: [
            _totalRow('Subtotal', Money.formatZar(invoice.subtotalCents)),
            if (invoice.discountCents > 0) ...[
              _totalRow('Discount', Money.formatZar(invoice.discountCents)),
              _totalRow(
                'Subtotal after discount',
                Money.formatZar(afterDiscount),
              ),
            ],
            _totalRow(
              'VAT (${invoice.taxPercent}%)',
              Money.formatZar(invoice.taxAmountCents),
            ),
            pw.SizedBox(height: 4),
            pw.Container(height: 1, color: _border),
            pw.SizedBox(height: 4),
            _totalRow(
              'Grand total',
              Money.formatZar(invoice.grandTotalCents),
              emphasize: true,
            ),
            _totalRow(
              'Outstanding balance',
              Money.formatZar(invoice.balanceRemainingCents),
              emphasize: true,
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _totalRow(
    String label,
    String value, {
    bool emphasize = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: emphasize ? 11 : 10,
                fontWeight:
                    emphasize ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: _black,
              ),
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: emphasize ? 12 : 10,
              fontWeight: emphasize ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: _black,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _paymentBlock({
    required Invoice invoice,
    required String statusLabel,
    required PdfColor statusColor,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _border),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'PAYMENT',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: _accent,
            ),
          ),
          pw.SizedBox(height: 6),
          _totalRow('Amount paid', Money.formatZar(invoice.amountPaidCents)),
          _totalRow(
            'Outstanding balance',
            Money.formatZar(invoice.balanceRemainingCents),
            emphasize: true,
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Status: $statusLabel',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }
}
