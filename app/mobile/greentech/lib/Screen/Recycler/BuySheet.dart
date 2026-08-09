import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:greentech/Model/Listing.dart';
import 'package:greentech/Model/Wallet.dart';
import 'package:greentech/Provider/CitizenProviders.dart';
import 'package:greentech/Service/ApiService.dart';
import 'package:greentech/Widget/UiKit.dart';

enum BuyOutcome { bought, gone, failed }

class BuyResult {
  const BuyResult(this.outcome, {this.message});

  final BuyOutcome outcome;
  final String? message;
}

Future<BuyResult?> showBuySheet(
  BuildContext context, {
  required Listing listing,
}) {
  return showModalBottomSheet<BuyResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: uiInk.withValues(alpha: 0.34),
    builder: (_) => BuySheet(listing: listing),
  );
}

class BuySheet extends ConsumerStatefulWidget {
  const BuySheet({super.key, required this.listing});

  final Listing listing;

  @override
  ConsumerState<BuySheet> createState() => _BuySheetState();
}

class _BuySheetState extends ConsumerState<BuySheet> {
  bool _buying = false;
  bool _asking = false;
  bool _shortOfFunds = false;
  String? _verdict;
  String? _error;
  Listing? _live;

  @override
  void initState() {
    super.initState();
    _verifyStatus();
  }

  Future<void> _verifyStatus() async {
    try {
      final fresh = await ApiService.listing(widget.listing.id);
      if (!mounted) return;
      setState(() => _live = fresh);
    } on ApiException {
      return;
    }
  }

  Future<void> _evaluate() async {
    setState(() {
      _asking = true;
      _verdict = null;
    });

    try {
      final reply = await ApiService.sendChat(
        message: 'Is this a good deal? Should I purchase it?',
        listingId: widget.listing.id,
      );
      if (!mounted) return;
      setState(() {
        _verdict = reply.reply;
        _asking = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _verdict = error.message;
        _asking = false;
      });
    }
  }

  Future<void> _buy() async {
    setState(() {
      _buying = true;
      _error = null;
      _shortOfFunds = false;
    });

    try {
      await ApiService.buyListing(widget.listing.id);
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      Navigator.of(context).pop(const BuyResult(BuyOutcome.bought));
    } on ApiException catch (error) {
      if (!mounted) return;

      if (error.statusCode == 402) {
        await ref.read(walletProvider.notifier).refresh();
        if (!mounted) return;
        setState(() {
          _buying = false;
          _shortOfFunds = true;
          _error = error.message;
        });
        HapticFeedback.vibrate();
        return;
      }

      if (error.statusCode == 409 || error.statusCode == 404) {
        Navigator.of(
          context,
        ).pop(BuyResult(BuyOutcome.gone, message: error.message));
        return;
      }

      setState(() {
        _buying = false;
        _error = error.message;
      });
      HapticFeedback.vibrate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final listing = _live ?? widget.listing;
    final balance = (ref.watch(walletProvider).value ?? Wallet.empty).balance;
    final after = balance - listing.price;
    final affordable = balance >= listing.price;
    final available = listing.status == ListingStatus.open;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
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
                Text(
                  listing.material,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    color: uiInk,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'From ${listing.seller?.fullName ?? 'a seller'}'
                  '${listing.location.isEmpty ? '' : ' · ${listing.location}'}',
                  style: const TextStyle(fontSize: 14, color: uiInkSecondary),
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: uiFill,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'RATE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: uiInkTertiary,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${rupees(listing.pricePerKg)}/kg',
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w700,
                                  color: uiInk,
                                  letterSpacing: -1.2,
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                kilograms(listing.weightKg),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: uiInkSecondary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              const Text(
                                'estimated weight',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: uiInkTertiary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const UiHairline(),
                      const SizedBox(height: 14),
                      _Row(label: 'Lot total', value: rupees(listing.price)),
                      const SizedBox(height: 9),
                      _Row(label: 'Your balance', value: rupees(balance)),
                      const SizedBox(height: 9),
                      _Row(
                        label: affordable ? 'Balance after' : 'Short by',
                        value: rupees(affordable ? after : after.abs()),
                        accent: affordable ? uiGreen : uiDanger,
                        bold: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _WorthItBlock(
                  asking: _asking,
                  verdict: _verdict,
                  onAsk: _evaluate,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 4),
                  if (_shortOfFunds)
                    _ShortfallNote(message: _error!)
                  else
                    UiErrorNote(_error),
                ],
                const SizedBox(height: 18),
                UiPrimaryButton(
                  label: _buying
                      ? 'Buying'
                      : !available
                      ? 'No longer available'
                      : affordable
                      ? 'Buy for ${rupees(listing.price)}'
                      : 'Not enough balance',
                  busy: _buying,
                  onTap: available && affordable && !_buying ? _buy : null,
                ),
                const SizedBox(height: 10),
                Pressable(
                  onTap: _buying ? null : () => Navigator.of(context).pop(),
                  scale: 0.98,
                  child: Container(
                    height: 50,
                    alignment: Alignment.center,
                    child: const Text(
                      'Not now',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        color: uiInkSecondary,
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Text(
                    'Buying is instant and cannot be undone.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: uiInkTertiary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShortfallNote extends StatelessWidget {
  const _ShortfallNote({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: uiAmberSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: uiAmberLine),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedWallet01,
              color: uiAmber,
              size: 17,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: uiInk,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'The lot is still open. Top up and try again.',
                  style: TextStyle(fontSize: 12.5, color: uiInkSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.accent,
    this.bold = false,
  });

  final String label;
  final String value;
  final Color? accent;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
            color: uiInkSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 16 : 14.5,
            fontWeight: FontWeight.w700,
            color: accent ?? uiInk,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

class _WorthItBlock extends StatelessWidget {
  const _WorthItBlock({
    required this.asking,
    required this.verdict,
    required this.onAsk,
  });

  final bool asking;
  final String? verdict;
  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context) {
    if (verdict == null && !asking) {
      return Pressable(
        onTap: onAsk,
        scale: 0.98,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: uiHairlineStrong),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A73D4), uiGreen],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedSparkles,
                  color: Colors.white,
                  size: 15,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Text(
                  'Is this worth it?',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: uiInk,
                    letterSpacing: -0.25,
                  ),
                ),
              ),
              const HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                color: uiInkTertiary,
                size: 17,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: uiFill,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A73D4), uiGreen],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedSparkles,
                  color: Colors.white,
                  size: 13,
                ),
              ),
              const SizedBox(width: 9),
              const Text(
                'Market check',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: uiInkSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (asking)
            const Row(
              children: [
                SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: uiInkSecondary,
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  'Comparing against catalogue rates…',
                  style: TextStyle(fontSize: 13.5, color: uiInkSecondary),
                ),
              ],
            )
          else
            Text(
              verdict!,
              style: const TextStyle(
                fontSize: 14,
                height: 1.55,
                color: uiInk,
                letterSpacing: -0.1,
              ),
            ),
        ],
      ),
    );
  }
}
