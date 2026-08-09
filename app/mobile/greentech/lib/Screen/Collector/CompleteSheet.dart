import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:greentech/Model/Pickup.dart';
import 'package:greentech/Service/ApiService.dart';
import 'package:greentech/Widget/UiKit.dart';

Future<bool?> showCompleteSheet(
  BuildContext context, {
  required Pickup pickup,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: uiInk.withValues(alpha: 0.34),
    builder: (_) => CompleteSheet(pickup: pickup),
  );
}

class CompleteSheet extends StatefulWidget {
  const CompleteSheet({super.key, required this.pickup});

  final Pickup pickup;

  @override
  State<CompleteSheet> createState() => _CompleteSheetState();
}

class _CompleteSheetState extends State<CompleteSheet> {
  final _weight = TextEditingController();
  final _amount = TextEditingController();
  final _notes = TextEditingController();

  bool _busy = false;
  bool _showErrors = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _weight.addListener(() => setState(() {}));
    final estimate = widget.pickup.money.finalWeightKg;
    if (estimate != null && estimate > 0) {
      _weight.text = estimate.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _weight.dispose();
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  double? get _weightValue => double.tryParse(_weight.text.trim());

  double? get _amountValue => double.tryParse(_amount.text.trim());

  int get _projectedPoints {
    final weight = _weightValue ?? 0;
    final rate = widget.pickup.mode == PickupMode.dropOff ? 8 : 5;
    return (weight * rate).round() + 20;
  }

  bool get _valid =>
      (_weightValue ?? -1) >= 0 && (_amountValue ?? -1) >= 0 && !_busy;

  Future<void> _complete() async {
    if (!_valid) {
      setState(() => _showErrors = true);
      return;
    }

    final confirmed = await showUiConfirmSheet(
      context,
      title: 'Complete this pickup?',
      message:
          'You are recording ${kilograms(_weightValue!)} at ${rupees(_amountValue!)}. '
          'This credits $_projectedPoints points to the citizen and cannot be undone.',
      confirmLabel: 'Yes, complete it',
      cancelLabel: 'Check again',
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ApiService.completePickup(
        widget.pickup.id,
        finalWeightKg: _weightValue!,
        finalAmount: _amountValue!,
        collectorNotes: _notes.text.trim(),
      );
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error.message;
      });
    }
  }

  Future<void> _release() async {
    final reason = await showReleaseSheet(context);
    if (reason == null || !mounted) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ApiService.releasePickup(widget.pickup.id, reason: reason);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pickup = widget.pickup;
    final estimate = pickup.money.finalWeightKg;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: uiHairlineStrong,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Weigh and settle',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                      color: uiInk,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pickup.location.address.isEmpty
                        ? pickup.materials
                        : pickup.location.address,
                    style: const TextStyle(fontSize: 14, color: uiInkSecondary),
                  ),
                  const SizedBox(height: 22),
                  if (estimate != null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: uiFill,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const HugeIcon(
                            icon: HugeIcons.strokeRoundedInformationCircle,
                            color: uiInkTertiary,
                            size: 16,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Photo estimate was ${kilograms(estimate)} at '
                              '${rupees(pickup.money.estimatedOffer)}. The scale wins.',
                              style: const TextStyle(
                                fontSize: 12.5,
                                height: 1.4,
                                color: uiInkSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 18),
                  UiTextField(
                    label: 'Weighed amount (kg)',
                    controller: _weight,
                    hint: '3.200',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    errorText: _showErrors && (_weightValue ?? -1) < 0
                        ? 'Enter the weight from the scale.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  UiTextField(
                    label: 'Amount paid (INR)',
                    controller: _amount,
                    hint: '128.00',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    errorText: _showErrors && (_amountValue ?? -1) < 0
                        ? 'Enter what you paid the citizen.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  UiTextField(
                    label: 'Notes (optional)',
                    controller: _notes,
                    hint: 'Clean PET, well segregated',
                    textInputAction: TextInputAction.done,
                    inputFormatters: [LengthLimitingTextInputFormatter(300)],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: uiGreenSoft,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: uiGreenLine),
                    ),
                    child: Row(
                      children: [
                        const HugeIcon(
                          icon: HugeIcons.strokeRoundedStar,
                          color: uiGreen,
                          size: 18,
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Text(
                            'Citizen earns $_projectedPoints points '
                            '(${pickup.mode == PickupMode.dropOff ? 8 : 5}/kg + 20 bonus)',
                            style: const TextStyle(
                              fontSize: 13.5,
                              height: 1.4,
                              color: uiInk,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  UiErrorNote(_error),
                  const SizedBox(height: 18),
                  UiPrimaryButton(
                    label: _busy ? 'Saving' : 'Complete pickup',
                    busy: _busy,
                    onTap: _valid ? _complete : null,
                  ),
                  const SizedBox(height: 10),
                  Pressable(
                    onTap: _busy ? null : _release,
                    scale: 0.98,
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: uiAmberSoft,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Cannot make it — release job',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: uiAmber,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<String?> showReleaseSheet(BuildContext context) {
  final controller = TextEditingController();

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: uiInk.withValues(alpha: 0.34),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Release this job?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: uiInk,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'It goes back into the open pool for another collector, and the citizen can cancel again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: uiInkSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                UiTextField(
                  label: 'Reason (optional)',
                  controller: controller,
                  hint: 'Vehicle breakdown',
                  textInputAction: TextInputAction.done,
                  inputFormatters: [LengthLimitingTextInputFormatter(200)],
                ),
                const SizedBox(height: 18),
                Pressable(
                  onTap: () =>
                      Navigator.of(sheetContext).pop(controller.text.trim()),
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      color: uiAmber,
                      borderRadius: BorderRadius.circular(27),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Release job',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Pressable(
                  onTap: () => Navigator.of(sheetContext).pop(),
                  scale: 0.98,
                  child: Container(
                    height: 50,
                    alignment: Alignment.center,
                    child: const Text(
                      'Keep it',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        color: uiInkSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
