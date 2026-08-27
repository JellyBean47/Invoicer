import 'dart:typed_data';

import 'package:printing/printing.dart';

import '../core/utils/app_exception.dart';
import '../core/utils/money.dart';
import '../models/business.dart';
import '../models/customer.dart';
import '../models/invoice.dart';
import '../pdf/invoice_pdf_template.dart';
import '../repositories/business_repository.dart';
import '../repositories/customer_repository.dart';
import '../repositories/invoice_repository.dart';
import 'analytics_service.dart';

/// Generates and shares invoice PDFs from structured data (not UI screenshots).
class InvoicePdfService {
  InvoicePdfService({
    InvoiceRepository? invoiceRepository,
    BusinessRepository? businessRepository,
    CustomerRepository? customerRepository,
    AnalyticsService? analyticsService,
  })  : _invoiceRepository = invoiceRepository,
        _businessRepository = businessRepository,
        _customerRepository = customerRepository,
        _analyticsService = analyticsService;

  final InvoiceRepository? _invoiceRepository;
  final BusinessRepository? _businessRepository;
  final CustomerRepository? _customerRepository;
  final AnalyticsService? _analyticsService;

  /// Validates per PDF spec before generation.
  static void validate({
    required Business? business,
    required Customer? customer,
    required Invoice invoice,
  }) {
    if (business == null || business.businessName.trim().isEmpty) {
      throw const AppException(
        'Business information is missing. Complete business setup first.',
      );
    }
    if (customer == null) {
      throw const AppException('Customer not found for this invoice.');
    }
    if (!invoice.status.isFinalized) {
      throw const AppException(
        'Only finalized invoices can be shared as a PDF.',
      );
    }
    if (invoice.invoiceNumber.trim().isEmpty) {
      throw const AppException('Invoice number is missing.');
    }
    if (invoice.items.isEmpty) {
      throw const AppException('Invoice has no line items.');
    }
    _validateTotals(invoice);
  }

  static void _validateTotals(Invoice invoice) {
    try {
      final breakdown = Money.calculate(
        lineTotalsCents:
            invoice.items.map((item) => item.lineTotalCents).toList(),
        discountCents: invoice.discountCents,
        taxPercent: invoice.taxPercent,
      );
      final expectedBalance =
          invoice.grandTotalCents - invoice.amountPaidCents;
      final matches = breakdown.subtotalCents == invoice.subtotalCents &&
          breakdown.taxAmountCents == invoice.taxAmountCents &&
          breakdown.totalCents == invoice.grandTotalCents &&
          invoice.balanceRemainingCents == expectedBalance;
      if (!matches) {
        throw const AppException(
          'Invoice totals are invalid. Duplicate for correction if needed.',
        );
      }
      for (final item in invoice.items) {
        final expected = Money.lineTotal(
          quantity: item.quantity,
          unitPriceCents: item.unitPriceCents,
        );
        if (expected != item.lineTotalCents) {
          throw const AppException(
            'Invoice line totals are invalid. Duplicate for correction if needed.',
          );
        }
      }
    } on AppException {
      rethrow;
    } on ArgumentError catch (error) {
      throw AppException(
        error.message?.toString() ?? 'Invoice totals are invalid.',
      );
    }
  }

  Future<Uint8List> generateBytes({
    required Business business,
    required Customer customer,
    required Invoice invoice,
    DateTime? generatedAt,
  }) async {
    validate(business: business, customer: customer, invoice: invoice);
    final document = await InvoicePdfTemplate.build(
      business: business,
      customer: customer,
      invoice: invoice,
      generatedAt: generatedAt,
    );
    return document.save();
  }

  /// Loads invoice + relations, validates, returns PDF bytes.
  Future<Uint8List> generateForInvoiceId(String invoiceId) async {
    final loaded = await _load(invoiceId);
    return generateBytes(
      business: loaded.business,
      customer: loaded.customer,
      invoice: loaded.invoice,
    );
  }

  Future<void> shareInvoicePdf({
    required Business business,
    required Customer customer,
    required Invoice invoice,
  }) async {
    final bytes = await generateBytes(
      business: business,
      customer: customer,
      invoice: invoice,
    );
    final name = InvoicePdfTemplate.fileName(invoice.invoiceNumber);
    await Printing.sharePdf(bytes: bytes, filename: name);
    await _analyticsService?.logPdfShared();
  }

  Future<void> shareInvoicePdfById(String invoiceId) async {
    final loaded = await _load(invoiceId);
    await shareInvoicePdf(
      business: loaded.business,
      customer: loaded.customer,
      invoice: loaded.invoice,
    );
  }

  Future<({Business business, Customer customer, Invoice invoice})> _load(
    String invoiceId,
  ) async {
    final invoices = _invoiceRepository;
    final businesses = _businessRepository;
    final customers = _customerRepository;
    if (invoices == null || businesses == null || customers == null) {
      throw const AppException('PDF service is not fully configured.');
    }

    final invoice = await invoices.getById(invoiceId);
    if (invoice == null) {
      throw const AppException('Invoice not found.');
    }
    final business = await businesses.getById(invoice.businessId);
    final customer = await customers.getById(invoice.customerId);
    validate(business: business, customer: customer, invoice: invoice);
    return (business: business!, customer: customer!, invoice: invoice);
  }
}
