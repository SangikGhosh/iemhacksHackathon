import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:greentech/Model/Detection.dart';
import 'package:greentech/Model/Listing.dart';
import 'package:greentech/Provider/CitizenProviders.dart';
import 'package:greentech/Service/ApiService.dart';
import 'package:greentech/Service/ToastService.dart';
import 'package:greentech/Widget/CitizenWidgets/CitizenKit.dart';
import 'package:greentech/Widget/UiKit.dart';

class ListingsScreen extends ConsumerStatefulWidget {
  const ListingsScreen({super.key});

  @override
  ConsumerState<ListingsScreen> createState() => _ListingsScreenState();
}

class _ListingsScreenState extends ConsumerState<ListingsScreen> {
  void _exit() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  Future<void> _create() async {
    final created = await showModalBottomSheet<Listing>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: uiInk.withValues(alpha: 0.34),
      builder: (_) => const _CreateListingSheet(),
    );

    if (created == null || !mounted) return;
    ToastService.show('Listed for recyclers.', ToastType.success, context);
    await ref.read(myListingsProvider.notifier).refresh();
  }

  Future<void> _withdraw(Listing listing) async {
    final confirmed = await showUiConfirmSheet(
      context,
      title: 'Withdraw listing?',
      message: 'It will no longer be visible to recyclers.',
      confirmLabel: 'Withdraw',
      cancelLabel: 'Keep it',
      destructive: true,
    );

    if (confirmed != true || !mounted) return;

    try {
      await ApiService.cancelListing(listing.id);
      if (!mounted) return;
      ToastService.show('Listing withdrawn.', ToastType.info, context);
      await ref.read(myListingsProvider.notifier).refresh();
    } on ApiException catch (error) {
      if (!mounted) return;
      ToastService.show(error.message, ToastType.error, context);
      await ref.read(myListingsProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(myListingsProvider);
    final listings = async.value ?? const <Listing>[];

    final open = listings.where((l) => l.status == ListingStatus.open).length;
    final sold = listings.where((l) => l.status == ListingStatus.sold);
    final earned = sold.fold<double>(0, (sum, l) => sum + l.price);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CitizenAppBar(
        title: 'Sell waste',
        subtitle: listings.isEmpty
            ? 'List segregated waste for recyclers'
            : '$open open · ${sold.length} sold',
        onBack: _exit,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(
              child: Pressable(
                onTap: _create,
                scale: 0.92,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: uiInk,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  alignment: Alignment.center,
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedAdd01,
                    color: Colors.white,
                    size: 21,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: async.isLoading && listings.isEmpty
          ? const Center(child: CircularProgressIndicator(color: uiInk))
          : async.hasError && listings.isEmpty
          ? ErrorRetry(
              message: '${async.error}',
              onRetry: () => ref.read(myListingsProvider.notifier).refresh(),
            )
          : RefreshIndicator(
              color: uiInk,
              onRefresh: () => ref.read(myListingsProvider.notifier).refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 36),
                children: [
                  if (listings.isNotEmpty) ...[
                    Row(
                      children: [
                        Expanded(
                          child: MetricTile(
                            icon: HugeIcons.strokeRoundedTag01,
                            value: '$open',
                            label: 'Open',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MetricTile(
                            icon: HugeIcons.strokeRoundedCheckmarkBadge01,
                            value: '${sold.length}',
                            label: 'Sold',
                            accent: uiGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MetricTile(
                            icon: HugeIcons.strokeRoundedCoins01,
                            value: rupees(earned),
                            label: 'Earned',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (listings.isEmpty)
                    EmptyState(
                      icon: HugeIcons.strokeRoundedShoppingBag01,
                      title: 'Nothing listed yet',
                      message:
                          'Turn a scan into a listing and let recyclers bid for your segregated waste.',
                      actionLabel: 'Create a listing',
                      onAction: _create,
                    )
                  else
                    for (final listing in listings)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ListingCard(
                          listing: listing,
                          onWithdraw: listing.canWithdraw
                              ? () => _withdraw(listing)
                              : null,
                        ),
                      ),
                ],
              ),
            ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({required this.listing, this.onWithdraw});

  final Listing listing;
  final VoidCallback? onWithdraw;

  Color get _tone => switch (listing.status) {
    ListingStatus.open => const Color(0xFF1A73D4),
    ListingStatus.sold => uiGreen,
    ListingStatus.cancelled => uiInkSecondary,
    ListingStatus.unknown => uiInkSecondary,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: uiHairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _tone.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  listing.status.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _tone,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                relativeTime(listing.createdAt),
                style: const TextStyle(fontSize: 12.5, color: uiInkTertiary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.material,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: uiInk,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${kilograms(listing.weightKg)} · ${rupees(listing.pricePerKg)}/kg'
                      '${listing.location.isEmpty ? '' : ' · ${listing.location}'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: uiInkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                rupees(listing.price),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: uiInk,
                  letterSpacing: -0.6,
                ),
              ),
            ],
          ),
          if (listing.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              listing.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: uiInkSecondary,
              ),
            ),
          ],
          if (listing.buyer != null) ...[
            const SizedBox(height: 14),
            const UiHairline(),
            const SizedBox(height: 12),
            Row(
              children: [
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedUser,
                  color: uiInkTertiary,
                  size: 15,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Bought by ${listing.buyer!.fullName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: uiInkSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (onWithdraw != null) ...[
            const SizedBox(height: 14),
            Pressable(
              onTap: onWithdraw,
              scale: 0.98,
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: uiFill,
                  borderRadius: BorderRadius.circular(21),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Withdraw listing',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: uiInkSecondary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CreateListingSheet extends ConsumerStatefulWidget {
  const _CreateListingSheet();

  @override
  ConsumerState<_CreateListingSheet> createState() =>
      _CreateListingSheetState();
}

class _CreateListingSheetState extends ConsumerState<_CreateListingSheet> {
  final _priceController = TextEditingController();
  final _materialController = TextEditingController();
  final _weightController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  DetectionHistoryItem? _scan;
  bool _manual = false;
  bool _submitting = false;
  bool _showErrors = false;
  String? _error;

  @override
  void dispose() {
    _priceController.dispose();
    _materialController.dispose();
    _weightController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  double? get _price => double.tryParse(_priceController.text.trim());

  bool get _valid {
    final price = _price;
    if (price == null || price < 1) return false;
    if (_manual) {
      final weight = double.tryParse(_weightController.text.trim());
      return _materialController.text.trim().isNotEmpty &&
          weight != null &&
          weight > 0;
    }
    return _scan != null;
  }

  Future<void> _submit() async {
    if (!_valid) {
      setState(() => _showErrors = true);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final listing = await ApiService.createListing(
        price: _price!,
        detectionId: _manual ? null : _scan?.id,
        material: _manual ? _materialController.text.trim() : null,
        weightKg: _manual
            ? double.tryParse(_weightController.text.trim())
            : null,
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
      );

      if (!mounted) return;
      HapticFeedback.heavyImpact();
      Navigator.of(context).pop(listing);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(detectionHistoryProvider).value;
    final scans = (history?.items ?? const <DetectionHistoryItem>[])
        .where((item) => item.eligible)
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.55,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: uiHairlineStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                  children: [
                    const Text(
                      'New listing',
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w700,
                        color: uiInk,
                        letterSpacing: -0.9,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Attach a scan so material and weight fill themselves in.',
                      style: TextStyle(
                        fontSize: 14.5,
                        height: 1.45,
                        color: uiInkSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _Toggle(
                            label: 'From a scan',
                            selected: !_manual,
                            onTap: () => setState(() => _manual = false),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _Toggle(
                            label: 'Enter manually',
                            selected: _manual,
                            onTap: () => setState(() => _manual = true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    if (!_manual) ...[
                      const UiSectionLabel('Choose a scan'),
                      if (scans.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: uiFill,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'No scans available. Scan some waste first, or enter the details manually.',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: uiInkSecondary,
                            ),
                          ),
                        )
                      else
                        for (final scan in scans.take(6))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Pressable(
                              onTap: () => setState(() => _scan = scan),
                              scale: 0.99,
                              child: AnimatedContainer(
                                duration: uiQuick,
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: scan.id == _scan?.id
                                      ? uiInk
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: scan.id == _scan?.id
                                        ? uiInk
                                        : uiHairlineStrong,
                                    width: scan.id == _scan?.id ? 1.6 : 1.2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            scan.materialSummary,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: scan.id == _scan?.id
                                                  ? Colors.white
                                                  : uiInk,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            kilograms(scan.estimatedWeightKg),
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              color: scan.id == _scan?.id
                                                  ? Colors.white.withValues(
                                                      alpha: 0.6,
                                                    )
                                                  : uiInkTertiary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      rupees(scan.estimatedOffer),
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: scan.id == _scan?.id
                                            ? Colors.white
                                            : uiInk,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      if (_showErrors && _scan == null)
                        const Padding(
                          padding: EdgeInsets.only(left: 4, top: 2),
                          child: Text(
                            'Pick a scan or switch to manual entry.',
                            style: TextStyle(fontSize: 13, color: uiDanger),
                          ),
                        ),
                    ] else ...[
                      UiTextField(
                        label: 'Material',
                        controller: _materialController,
                        hint: 'Cardboard',
                        textInputAction: TextInputAction.next,
                        errorText:
                            _showErrors &&
                                _materialController.text.trim().isEmpty
                            ? 'What are you selling?'
                            : null,
                        onSubmitted: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                      UiTextField(
                        label: 'Weight (kg)',
                        controller: _weightController,
                        hint: '5.0',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                        errorText:
                            _showErrors &&
                                (double.tryParse(
                                          _weightController.text.trim(),
                                        ) ??
                                        0) <=
                                    0
                            ? 'Enter a weight above zero.'
                            : null,
                        onSubmitted: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                    ],
                    const SizedBox(height: 16),
                    UiTextField(
                      label: 'Asking price (INR)',
                      controller: _priceController,
                      hint: '60',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      errorText: _showErrors && (_price ?? 0) < 1
                          ? 'Price must be at least 1.'
                          : null,
                      onSubmitted: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    UiTextField(
                      label: 'Description (optional)',
                      controller: _descriptionController,
                      hint: 'Clean PET bottles, rinsed',
                      textInputAction: TextInputAction.next,
                      inputFormatters: [LengthLimitingTextInputFormatter(400)],
                    ),
                    const SizedBox(height: 16),
                    UiTextField(
                      label: 'Location (optional)',
                      controller: _locationController,
                      hint: 'Howrah Maidan',
                      textInputAction: TextInputAction.done,
                      inputFormatters: [LengthLimitingTextInputFormatter(160)],
                    ),
                    UiErrorNote(_error),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  6,
                  20,
                  12 + MediaQuery.of(context).padding.bottom,
                ),
                child: UiPrimaryButton(
                  label: _submitting ? 'Listing' : 'List it',
                  busy: _submitting,
                  onTap: _valid && !_submitting ? _submit : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.97,
      child: AnimatedContainer(
        duration: uiQuick,
        height: 46,
        decoration: BoxDecoration(
          color: selected ? uiInk : uiFill,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : uiInkSecondary,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}
