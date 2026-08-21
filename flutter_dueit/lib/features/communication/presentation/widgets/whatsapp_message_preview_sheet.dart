import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dueit/core/theme/app_colors.dart';
import 'package:dueit/core/theme/app_typography.dart';
import 'package:dueit/core/utils/currency_formatter.dart';
import 'package:dueit/features/communication/data/services/whatsapp_service.dart';
import 'package:dueit/features/communication/domain/services/payment_message_generator.dart';
import 'package:dueit/features/communication/domain/services/phone_number_normalizer.dart';
import 'package:dueit/features/customers/domain/entities/customer_entity.dart';
import 'package:dueit/features/dues/domain/entities/due_entity.dart';
import 'package:dueit/shared/widgets/status_badge.dart';

enum MessageTemplateType {
  reminder,
  paymentReceived,
}

/// A comprehensive bottom sheet for previewing, editing, and dispatching
/// payment reminders and receipts via WhatsApp or Clipboard.
class WhatsAppMessagePreviewSheet extends ConsumerStatefulWidget {
  final CustomerEntity customer;
  final DueEntity due;
  final String? businessName;
  final double? lastPaidAmount;
  final MessageTemplateType initialTemplate;

  const WhatsAppMessagePreviewSheet({
    super.key,
    required this.customer,
    required this.due,
    this.businessName,
    this.lastPaidAmount,
    this.initialTemplate = MessageTemplateType.reminder,
  });

  static Future<void> show({
    required BuildContext context,
    required CustomerEntity customer,
    required DueEntity due,
    String? businessName,
    double? lastPaidAmount,
    MessageTemplateType initialTemplate = MessageTemplateType.reminder,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => WhatsAppMessagePreviewSheet(
        customer: customer,
        due: due,
        businessName: businessName,
        lastPaidAmount: lastPaidAmount,
        initialTemplate: initialTemplate,
      ),
    );
  }

  @override
  ConsumerState<WhatsAppMessagePreviewSheet> createState() =>
      _WhatsAppMessagePreviewSheetState();
}

class _WhatsAppMessagePreviewSheetState
    extends ConsumerState<WhatsAppMessagePreviewSheet> {
  late TextEditingController _messageController;
  late MessageTemplateType _selectedTemplate;
  bool _isLaunching = false;
  String? _errorMessage;
  bool _whatsAppUnavailable = false;

  @override
  void initState() {
    super.initState();
    _selectedTemplate = widget.initialTemplate;
    _messageController = TextEditingController(text: _generateInitialMessage());
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  String _generateInitialMessage() {
    if (_selectedTemplate == MessageTemplateType.paymentReceived) {
      final paid = widget.lastPaidAmount ?? widget.due.paidAmount;
      return PaymentMessageGenerator.generatePaymentReceivedMessage(
        customerName: widget.customer.name,
        paidAmount: paid > 0 ? paid : widget.due.amount,
        remainingAmount: widget.due.remainingAmount,
        isFullyPaid: widget.due.status == DueStatus.paid ||
            widget.due.remainingAmount <= 0,
        businessName: widget.businessName,
      );
    } else {
      return PaymentMessageGenerator.generateDueReminderMessage(
        customerName: widget.customer.name,
        amount: widget.due.amount,
        dueDate: widget.due.dueDate,
        remainingAmount: widget.due.remainingAmount,
        status: widget.due.status,
        businessName: widget.businessName,
      );
    }
  }

  void _onTemplateChanged(MessageTemplateType template) {
    setState(() {
      _selectedTemplate = template;
      _messageController.text = _generateInitialMessage();
      _errorMessage = null;
    });
  }

  Future<void> _handleOpenWhatsApp() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      setState(() => _errorMessage = 'Message cannot be empty.');
      return;
    }

    final rawPhone = widget.customer.phone;
    final normalized = PhoneNumberNormalizer.normalize(rawPhone);
    if (normalized == null) {
      setState(
          () => _errorMessage = "Please check this customer's phone number.");
      return;
    }

    setState(() {
      _isLaunching = true;
      _errorMessage = null;
      _whatsAppUnavailable = false;
    });

    final service = ref.read(whatsAppServiceProvider);
    final launched = await service.launchWhatsApp(
      rawPhone: rawPhone,
      message: message,
    );

    if (!mounted) return;

    setState(() => _isLaunching = false);

    if (launched) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _whatsAppUnavailable = true;
        _errorMessage = "WhatsApp isn't available on this device.";
      });
    }
  }

  Future<void> _handleCopyMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      setState(() => _errorMessage = 'Message cannot be empty.');
      return;
    }

    final service = ref.read(whatsAppServiceProvider);
    await service.copyMessageToClipboard(message);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message copied'),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPhoneValid = PhoneNumberNormalizer.isValid(widget.customer.phone);
    final formattedPhone =
        PhoneNumberNormalizer.formatDisplay(widget.customer.phone);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar: Title & Close Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.chat_rounded,
                        color: Color(0xFF1E7E34),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WhatsApp Message',
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Review before opening WhatsApp',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Customer & Due Card Summary
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceVariant),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      widget.customer.calculatedInitials,
                      style: const TextStyle(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.customer.name,
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formattedPhone.isNotEmpty
                              ? formattedPhone
                              : 'No phone number added',
                          style: AppTypography.bodySmall.copyWith(
                            color: isPhoneValid
                                ? AppColors.onSurfaceVariant
                                : AppColors.error,
                            fontWeight: isPhoneValid
                                ? FontWeight.normal
                                : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyFormatter.format(widget.due.remainingAmount),
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      StatusBadge(status: widget.due.status),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Template Switcher (Reminder vs Receipt)
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Reminder')),
                    selected: _selectedTemplate == MessageTemplateType.reminder,
                    selectedColor:
                        AppColors.primaryContainer.withValues(alpha: 0.3),
                    labelStyle: TextStyle(
                      color: _selectedTemplate == MessageTemplateType.reminder
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    onSelected: (_) =>
                        _onTemplateChanged(MessageTemplateType.reminder),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Payment Receipt')),
                    selected: _selectedTemplate ==
                        MessageTemplateType.paymentReceived,
                    selectedColor:
                        AppColors.primaryContainer.withValues(alpha: 0.3),
                    labelStyle: TextStyle(
                      color: _selectedTemplate ==
                              MessageTemplateType.paymentReceived
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    onSelected: (_) =>
                        _onTemplateChanged(MessageTemplateType.paymentReceived),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Error Banner (Invalid phone or WhatsApp missing)
            if (_errorMessage != null || !isPhoneValid) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.errorContainer),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage ??
                            "Please check this customer's phone number.",
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Message Editor
            Text(
              'Message Preview (Editable)',
              style: AppTypography.labelSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _messageController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.surfaceVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.surfaceVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                filled: true,
                fillColor: AppColors.surfaceContainerLowest,
              ),
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 18),

            // Action Buttons
            if (_whatsAppUnavailable) ...[
              // Fallback buttons when WhatsApp is not available
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        minimumSize: const Size(0, 48),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _handleCopyMessage,
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Copy Message'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        minimumSize: const Size(0, 48),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Standard buttons
              Row(
                children: [
                  // Copy Button
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      onPressed: _handleCopyMessage,
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Copy'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        minimumSize: const Size(0, 48),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Open WhatsApp Button
                  Expanded(
                    flex: 3,
                    child: FilledButton.icon(
                      onPressed: (_isLaunching || !isPhoneValid)
                          ? null
                          : _handleOpenWhatsApp,
                      icon: _isLaunching
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, size: 18),
                      label: const Text('Open WhatsApp'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1E7E34),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        minimumSize: const Size(0, 48),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
