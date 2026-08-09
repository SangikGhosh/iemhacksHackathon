import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:greentech/Model/Detection.dart';
import 'package:greentech/Widget/UiKit.dart';

class ScanResultView extends StatelessWidget {
  const ScanResultView({
    super.key,
    required this.detection,
    this.showRewards = true,
  });

  final Detection detection;
  final bool showRewards;

  @override
  Widget build(BuildContext context) {
    final offer = detection.offer;
    final impact = detection.impact;
    final showOffer = detection.eligible && offer.hasValue;

    var step = 0;
    int delay() => 60 * step++;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FadeSlideIn(
          delayMs: delay(),
          child: _Verdict(detection: detection),
        ),
        if (showOffer) ...[
          const SizedBox(height: 28),
          FadeSlideIn(
            delayMs: delay(),
            child: _OfferHero(offer: offer),
          ),
        ],
        if (showRewards &&
            detection.eligible &&
            detection.totalRewardPoints > 0) ...[
          const SizedBox(height: 24),
          FadeSlideIn(
            delayMs: delay(),
            child: _PointsCard(detection: detection),
          ),
        ],
        const SizedBox(height: 28),
        FadeSlideIn(
          delayMs: delay(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const UiSectionLabel('Environmental impact'),
              _ImpactGrid(detection: detection, impact: impact),
            ],
          ),
        ),
        if (detection.recommendation.primaryBin != WasteBin.unknown) ...[
          const SizedBox(height: 28),
          FadeSlideIn(
            delayMs: delay(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const UiSectionLabel('Where it goes'),
                _BinCard(recommendation: detection.recommendation),
              ],
            ),
          ),
        ],
        if (detection.materials.isNotEmpty) ...[
          const SizedBox(height: 28),
          FadeSlideIn(
            delayMs: delay(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                UiSectionLabel(
                  'Detected materials',
                  trailing:
                      '${detection.materials.length} type'
                      '${detection.materials.length == 1 ? '' : 's'}',
                ),
                _MaterialsList(materials: detection.materials),
              ],
            ),
          ),
        ],
        if (detection.aiSummary.trim().isNotEmpty) ...[
          const SizedBox(height: 28),
          FadeSlideIn(
            delayMs: delay(),
            child: _SummaryCard(detection: detection),
          ),
        ],
        const SizedBox(height: 20),
        FadeSlideIn(
          delayMs: delay(),
          child: _QualityFootnote(detection: detection),
        ),
      ],
    );
  }
}

class _Verdict extends StatelessWidget {
  const _Verdict({required this.detection});

  final Detection detection;

  @override
  Widget build(BuildContext context) {
    final positive = detection.eligible;
    final tint = positive ? uiGreenSoft : uiAmberSoft;
    final line = positive ? uiGreenLine : uiAmberLine;
    final accent = positive ? uiGreen : uiAmber;

    final message = detection.message.trim().isEmpty
        ? (positive
              ? 'We identified everything in this photo.'
              : 'We could not read this photo well enough.')
        : detection.message.trim();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.14),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: HugeIcon(
              icon: positive
                  ? HugeIcons.strokeRoundedCheckmarkBadge01
                  : HugeIcons.strokeRoundedAlert02,
              color: accent,
              size: 21,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  positive
                      ? '${detection.totalObjects} item'
                            '${detection.totalObjects == 1 ? '' : 's'} detected'
                      : detection.status.headline,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: uiInk,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.45,
                    color: uiInkSecondary,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferHero extends StatelessWidget {
  const _OfferHero({required this.offer});

  final DetectionOffer offer;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          offer.awaitingCollector ? 'INDICATIVE VALUE' : 'ESTIMATED OFFER',
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: uiInkTertiary,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          rupees(offer.estimatedOffer),
          style: const TextStyle(
            fontSize: 52,
            fontWeight: FontWeight.w700,
            color: uiInk,
            letterSpacing: -2.2,
            height: 1.0,
          ),
        ),
        if (offer.hasRange) ...[
          const SizedBox(height: 24),
          _RangeBar(offer: offer),
        ],
        if (offer.awaitingCollector) ...[
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: uiFill,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedInformationCircle,
                  color: uiInkSecondary,
                  size: 15,
                ),
                SizedBox(width: 7),
                Text(
                  'A collector confirms the final price',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: uiInkSecondary,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _RangeBar extends StatelessWidget {
  const _RangeBar({required this.offer});

  final DetectionOffer offer;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            const knob = 14.0;
            final travel = constraints.maxWidth - knob;

            return SizedBox(
              height: knob,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 5,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      gradient: LinearGradient(
                        colors: [
                          uiFillStrong,
                          uiGreen.withValues(alpha: 0.35),
                          uiFillStrong,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: travel * offer.position,
                    child: Container(
                      width: knob,
                      height: knob,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: uiGreen, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: uiInk.withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              rupees(offer.minimumOffer),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: uiInkSecondary,
              ),
            ),
            Text(
              rupees(offer.maximumOffer),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: uiInkSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PointsCard extends StatelessWidget {
  const _PointsCard({required this.detection});

  final Detection detection;

  @override
  Widget build(BuildContext context) {
    final credited = detection.pointsAwarded;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: uiInk,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: const HugeIcon(
              icon: HugeIcons.strokeRoundedStar,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '+${detection.totalRewardPoints} points',
                  style: const TextStyle(
                    fontSize: 17.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  credited
                      ? 'Balance is now ${detection.userPointsBalance}'
                      : 'Pending — not credited yet',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.white.withValues(alpha: 0.62),
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
          if (credited)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Credited',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ImpactGrid extends StatelessWidget {
  const _ImpactGrid({required this.detection, required this.impact});

  final Detection detection;
  final DetectionImpact impact;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      _StatTile(
        icon: HugeIcons.strokeRoundedDashboardSquare01,
        value: '${detection.totalObjects}',
        label: 'Items found',
      ),
      _StatTile(
        icon: HugeIcons.strokeRoundedWeightScale01,
        value: kilograms(impact.estimatedWeightKg),
        label: 'Estimated weight',
      ),
      _StatTile(
        icon: HugeIcons.strokeRoundedLeaf01,
        value: kilograms(impact.carbonSavedKg),
        label: 'CO₂ saved',
        accent: uiGreen,
      ),
      _StatTile(
        icon: HugeIcons.strokeRoundedRecycle01,
        value: '${impact.recyclablePercent}%',
        label: 'Recyclable',
      ),
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: tiles[0]),
            const SizedBox(width: 12),
            Expanded(child: tiles[1]),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: tiles[2]),
            const SizedBox(width: 12),
            Expanded(child: tiles[3]),
          ],
        ),
        if (impact.landfillReducedKg > 0 &&
            (impact.landfillReducedKg - impact.estimatedWeightKg).abs() >
                0.005) ...[
          const SizedBox(height: 12),
          _StatTile(
            icon: HugeIcons.strokeRoundedDelete02,
            value: kilograms(impact.landfillReducedKg),
            label: 'Kept out of landfill',
            wide: true,
          ),
        ],
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    this.accent,
    this.wide = false,
  });

  final dynamic icon;
  final String value;
  final String label;
  final Color? accent;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final tone = accent ?? uiInk;

    if (wide) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: uiFill,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            HugeIcon(icon: icon, color: tone, size: 21),
            const SizedBox(width: 13),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: uiInkSecondary,
                letterSpacing: -0.1,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: tone,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: uiFill,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HugeIcon(icon: icon, color: tone, size: 21),
          const SizedBox(height: 18),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: tone,
              letterSpacing: -0.9,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: uiInkSecondary,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _BinCard extends StatelessWidget {
  const _BinCard({required this.recommendation});

  final DetectionRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final primary = recommendation.primaryBin;
    final secondary = recommendation.secondaryBin;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: uiHairline),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: [
          _BinRow(bin: primary, tag: 'Primary'),
          if (secondary != WasteBin.unknown && secondary != primary) ...[
            const UiHairline(indent: 50),
            _BinRow(bin: secondary, tag: 'Also'),
          ],
        ],
      ),
    );
  }
}

class _BinRow extends StatelessWidget {
  const _BinRow({required this.bin, required this.tag});

  final WasteBin bin;
  final String tag;

  @override
  Widget build(BuildContext context) {
    final color = binColor(bin);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bin.label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: uiInk,
                    letterSpacing: -0.3,
                  ),
                ),
                if (bin.blurb.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    bin.blurb,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: uiInkSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            tag,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: uiInkTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MaterialsList extends StatelessWidget {
  const _MaterialsList({required this.materials});

  final List<DetectionMaterial> materials;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: uiHairline),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: [
          for (var index = 0; index < materials.length; index++) ...[
            if (index > 0) const UiHairline(),
            _MaterialRow(material: materials[index]),
          ],
        ],
      ),
    );
  }
}

class _MaterialRow extends StatelessWidget {
  const _MaterialRow({required this.material});

  final DetectionMaterial material;

  @override
  Widget build(BuildContext context) {
    final color = binColor(material.bin);

    final meta = [
      if (material.category.isNotEmpty) material.category,
      if (material.stream.isNotEmpty) material.stream,
      if (material.estimatedWeightKg > 0) kilograms(material.estimatedWeightKg),
    ].join('  ·  ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        material.material,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: uiInk,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: uiFill,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '×${material.count}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: uiInkSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    meta,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: uiInkTertiary,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                material.estimatedValue > 0
                    ? rupees(material.estimatedValue)
                    : '—',
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  color: uiInk,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                material.recyclable ? 'Recyclable' : 'Not recyclable',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: material.recyclable ? uiGreen : uiInkTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.detection});

  final Detection detection;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: uiFill,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedSparkles,
                color: uiInk,
                size: 18,
              ),
              const SizedBox(width: 9),
              const Text(
                'Summary',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: uiInk,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            detection.aiSummary.trim(),
            style: const TextStyle(
              fontSize: 15,
              height: 1.55,
              color: uiInkSecondary,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _QualityFootnote extends StatelessWidget {
  const _QualityFootnote({required this.detection});

  final Detection detection;

  @override
  Widget build(BuildContext context) {
    final quality = detection.quality;

    final parts = [
      if (quality.detectionQuality != 'NONE')
        '${quality.detectionQuality.toLowerCase()} confidence',
      if (quality.averageConfidence > 0)
        '${quality.confidencePercent}% average',
      if (detection.processingTimeMs > 0) '${detection.processingTimeMs} ms',
    ];

    if (parts.isEmpty) return const SizedBox.shrink();

    return Text(
      parts.join('  ·  '),
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 12.5,
        color: uiInkTertiary,
        letterSpacing: 0.1,
      ),
    );
  }
}
