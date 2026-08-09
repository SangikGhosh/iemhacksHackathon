import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:greentech/Utils/AppColors.dart';

const kPaper = appBackground;
const kInk = appInk;
const kBrand = Color(0xFF159447);
const kLeaf = Color(0xFF6ED883);
const kForest = Color(0xFF0E2A1B);

class OnboardingService {
  const OnboardingService._();

  static const _seenKey = 'onboarding.seen';

  static bool? _seen;

  static Future<bool> hasSeen() async {
    if (_seen != null) return _seen!;

    final prefs = await SharedPreferences.getInstance();
    _seen = prefs.getBool(_seenKey) ?? false;
    return _seen!;
  }

  static Future<void> markSeen() async {
    _seen = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenKey, true);
  }
}

class _PageData {
  const _PageData({
    required this.label,
    required this.title,
    required this.description,
    required this.visualBuilder,
  });

  final String label;
  final String title;
  final String description;
  final WidgetBuilder visualBuilder;
}

final _pages = <_PageData>[
  _PageData(
    label: 'SEGREGATE',
    title: 'Sort it right,\nevery time.',
    description:
        'Point your camera at any item and let the AI confirm the category — plastic, organic, metal or e-waste — before it ever leaves your home.',
    visualBuilder: (context) => const _ScanVisual(),
  ),
  _PageData(
    label: 'EARN',
    title: 'Turn waste into\nGreen Points.',
    description:
        'Every verified segregation credits your wallet. Redeem points for rewards, or sell sorted scrap straight from the marketplace.',
    visualBuilder: (context) => const _PointsVisual(),
  ),
  _PageData(
    label: 'COLLECT',
    title: 'Pickups that\nfind you.',
    description:
        'Follow collection vehicles live along optimised routes, book a doorstep pickup, and see smart bins report their own fill level.',
    visualBuilder: (context) => const _RouteVisual(),
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();

  int _currentPage = 0;
  bool _finishing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLastPage => _currentPage == _pages.length - 1;

  void _next() {
    if (_isLastPage) {
      _finish();
      return;
    }

    _controller.nextPage(
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeInOutCubic,
    );
  }

  void _back() {
    _controller.previousPage(
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);

    await OnboardingService.markSeen();

    if (!mounted) return;
    context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: kPaper,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: kPaper,
        body: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              clipBehavior: Clip.none,
              physics: const ClampingScrollPhysics(),
              itemCount: _pages.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) => _PageBody(
                page: _pages[index],
                index: index,
                controller: _controller,
              ),
            ),

            Positioned(
              top: topInset + 12,
              left: 22,
              right: 22,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AnimatedOpacity(
                    opacity: _currentPage > 0 ? 1 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: IgnorePointer(
                      ignoring: _currentPage == 0,
                      child: _CircleButton(onTap: _back),
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: _isLastPage ? 0 : 1,
                    duration: const Duration(milliseconds: 220),
                    child: IgnorePointer(
                      ignoring: _isLastPage,
                      child: _SkipButton(onTap: _finish),
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              left: 30,
              right: 24,
              bottom: 44,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: List.generate(_pages.length, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.only(right: 6),
                        width: isActive ? 24 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isActive
                              ? kInk
                              : kInk.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  _PrimaryButton(
                    label: _isLastPage ? 'Get Started' : 'Next',
                    onTap: _next,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageBody extends StatelessWidget {
  const _PageBody({
    required this.page,
    required this.index,
    required this.controller,
  });

  final _PageData page;
  final int index;
  final PageController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Spacer(flex: 3),

          _Parallax(
            controller: controller,
            index: index,
            child: _DesignCanvas(child: Builder(builder: page.visualBuilder)),
          ),

          const Spacer(flex: 2),

          SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 18,
                      height: 2,
                      decoration: BoxDecoration(
                        color: kBrand,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      page.label,
                      style: const TextStyle(
                        color: kBrand,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Text(
                  page.title,
                  maxLines: 3,
                  style: const TextStyle(
                    color: kInk,
                    fontSize: 38,
                    height: 1.08,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1.2,
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  page.description,
                  style: TextStyle(
                    color: kInk.withValues(alpha: 0.62),
                    fontSize: 15,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(flex: 4),
        ],
      ),
    );
  }
}

class _DesignCanvas extends StatelessWidget {
  const _DesignCanvas({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(width: 320, height: 300, child: child),
    );
  }
}

class _Parallax extends StatelessWidget {
  const _Parallax({
    required this.controller,
    required this.index,
    required this.child,
  });

  final PageController controller;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.38,
      child: Flow(
        clipBehavior: Clip.none,
        delegate: _ParallaxFlowDelegate(controller: controller, index: index),
        children: [Center(child: child)],
      ),
    );
  }
}

class _ParallaxFlowDelegate extends FlowDelegate {
  _ParallaxFlowDelegate({required this.controller, required this.index})
    : super(repaint: controller);

  final PageController controller;
  final int index;

  @override
  void paintChildren(FlowPaintingContext context) {
    if (!controller.position.haveDimensions) {
      context.paintChild(0);
      return;
    }

    final offset = index - (controller.page ?? 0);
    final scale = 1 - offset.abs() * 0.05;
    final transform = Matrix4.identity()
      ..translateByDouble(context.size.width * 0.32 * offset, 0, 0, 1)
      ..scaleByDouble(scale, scale, scale, 1);

    context.paintChild(
      0,
      transform: transform,
      opacity: (1 - offset.abs() * 0.9).clamp(0.0, 1.0),
    );
  }

  @override
  bool shouldRepaint(covariant _ParallaxFlowDelegate oldDelegate) =>
      controller != oldDelegate.controller || index != oldDelegate.index;
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: kInk,
          boxShadow: [
            BoxShadow(
              color: kInk.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 15,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _SkipButton extends StatelessWidget {
  const _SkipButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 34,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: kInk,
          borderRadius: BorderRadius.circular(17),
          boxShadow: [
            BoxShadow(
              color: kInk.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Text(
          'SKIP',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
        decoration: BoxDecoration(
          color: kInk,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: kInk.withValues(alpha: 0.24),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
                height: 1,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_rounded,
              size: 16,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingChip extends StatelessWidget {
  const _FloatingChip({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: kInk.withValues(alpha: 0.1),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withValues(alpha: 0.14),
            ),
            child: Icon(icon, size: 15, color: iconColor),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: kInk,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
              height: 1,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 6),
            Text(
              trailing!,
              style: TextStyle(
                color: kInk.withValues(alpha: 0.4),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScanVisual extends StatefulWidget {
  const _ScanVisual();

  @override
  State<_ScanVisual> createState() => _ScanVisualState();
}

class _ScanVisualState extends State<_ScanVisual>
    with TickerProviderStateMixin {
  late final AnimationController _sweep;
  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();

    _sweep = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();

    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _sweep.dispose();
    _entrance.dispose();
    super.dispose();
  }

  Animation<double> _pop(double start) => CurvedAnimation(
    parent: _entrance,
    curve: Interval(start, (start + 0.45).clamp(0.0, 1.0),
        curve: Curves.easeOutBack),
  );

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          left: 12,
          right: 12,
          top: 22,
          bottom: 26,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(34),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF16452C), kForest, Color(0xFF071710)],
              ),
              boxShadow: [
                BoxShadow(
                  color: kForest.withValues(alpha: 0.32),
                  blurRadius: 34,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _GridPainter())),

                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(26),
                    child: CustomPaint(painter: _BracketPainter()),
                  ),
                ),

                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Image.asset(
                      'Assets/image/segregation_icon.png',
                      width: 210,
                      height: 210,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                AnimatedBuilder(
                  animation: _sweep,
                  builder: (context, child) {
                    final t = Curves.easeInOut.transform(
                      _sweep.value < 0.5
                          ? _sweep.value * 2
                          : (1 - _sweep.value) * 2,
                    );
                    return Positioned(
                      left: 26,
                      right: 26,
                      top: 30 + t * 178,
                      child: child!,
                    );
                  },
                  child: Container(
                    height: 26,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          kLeaf.withValues(alpha: 0),
                          kLeaf.withValues(alpha: 0.22),
                        ],
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: kLeaf.withValues(alpha: 0.85),
                          width: 1.6,
                        ),
                      ),
                    ),
                  ),
                ),

                Positioned(
                  left: 20,
                  top: 18,
                  child: Row(
                    children: [
                      _PulseDot(animation: _sweep),
                      const SizedBox(width: 7),
                      Text(
                        'AI SCAN',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        Positioned(
          right: -4,
          top: 4,
          child: ScaleTransition(
            scale: _pop(0.25),
            child: const _FloatingChip(
              icon: Icons.recycling_rounded,
              iconColor: kBrand,
              title: 'Plastic',
              trailing: '98%',
            ),
          ),
        ),

        Positioned(
          left: -6,
          bottom: 2,
          child: ScaleTransition(
            scale: _pop(0.5),
            child: const _FloatingChip(
              icon: Icons.verified_rounded,
              iconColor: Color(0xFF2F9E44),
              title: 'Verified',
              trailing: '+25 pts',
            ),
          ),
        ),
      ],
    );
  }
}

class _PulseDot extends StatelessWidget {
  const _PulseDot({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = (sin(animation.value * 2 * pi) + 1) / 2;
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: kLeaf,
            boxShadow: [
              BoxShadow(
                color: kLeaf.withValues(alpha: 0.25 + t * 0.5),
                blurRadius: 4 + t * 8,
                spreadRadius: t * 2,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.045)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 26) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 26) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kLeaf.withValues(alpha: 0.9)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const arm = 24.0;
    final w = size.width;
    final h = size.height;

    canvas
      ..drawPath(
        Path()
          ..moveTo(0, arm)
          ..lineTo(0, 0)
          ..lineTo(arm, 0),
        paint,
      )
      ..drawPath(
        Path()
          ..moveTo(w - arm, 0)
          ..lineTo(w, 0)
          ..lineTo(w, arm),
        paint,
      )
      ..drawPath(
        Path()
          ..moveTo(w, h - arm)
          ..lineTo(w, h)
          ..lineTo(w - arm, h),
        paint,
      )
      ..drawPath(
        Path()
          ..moveTo(arm, h)
          ..lineTo(0, h)
          ..lineTo(0, h - arm),
        paint,
      );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PointRow {
  const _PointRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.points,
    this.filled = false,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String points;
  final bool filled;
}

const _pointRows = <_PointRow>[
  _PointRow(
    icon: Icons.local_drink_rounded,
    color: Color(0xFF2B8AE0),
    label: 'Plastic bottles',
    points: '+25',
  ),
  _PointRow(
    icon: Icons.eco_rounded,
    color: kBrand,
    label: 'Organic waste',
    points: '+15',
    filled: true,
  ),
  _PointRow(
    icon: Icons.memory_rounded,
    color: Color(0xFFB4531F),
    label: 'E-waste drop',
    points: '+60',
  ),
  _PointRow(
    icon: Icons.hardware_rounded,
    color: Color(0xFF6C6F7A),
    label: 'Scrap metal',
    points: '+40',
  ),
];

class _PointsVisual extends StatefulWidget {
  const _PointsVisual();

  @override
  State<_PointsVisual> createState() => _PointsVisualState();
}

class _PointsVisualState extends State<_PointsVisual>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _count;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..forward();

    _count = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.7, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _count,
          builder: (context, child) {
            final value = (_count.value * 1240).round();
            return Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: kInk.withValues(alpha: 0.08),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(right: 12, bottom: 2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [kLeaf, kBrand],
                      ),
                    ),
                    child: const Icon(
                      Icons.savings_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [kBrand, Color(0xFF3FAE2A)],
                    ).createShader(bounds),
                    child: Text(
                      _format(value),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1.4,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      'pts',
                      style: TextStyle(
                        color: kInk.withValues(alpha: 0.42),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 22),

        ...List.generate(_pointRows.length, (index) {
          final start = 0.2 + index * 0.14;
          final animation = CurvedAnimation(
            parent: _controller,
            curve: Interval(
              start.clamp(0.0, 1.0),
              (start + 0.4).clamp(0.0, 1.0),
              curve: Curves.easeOutCubic,
            ),
          );

          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) => Opacity(
              opacity: animation.value,
              child: Transform.translate(
                offset: Offset(26 * (1 - animation.value), 0),
                child: child,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: _PointChip(row: _pointRows[index]),
            ),
          );
        }),
      ],
    );
  }

  String _format(int value) {
    final text = value.toString();
    if (text.length < 4) return text;
    return '${text.substring(0, text.length - 3)},'
        '${text.substring(text.length - 3)}';
  }
}

class _PointChip extends StatelessWidget {
  const _PointChip({required this.row});

  final _PointRow row;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 10, 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: row.color.withValues(alpha: 0.13),
            ),
            child: Icon(row.icon, size: 16, color: row.color),
          ),
          const SizedBox(width: 11),
          Flexible(
            child: Text(
              row.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: kInk,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
                height: 1,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: row.filled ? kBrand : kBrand.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              row.points,
              style: TextStyle(
                color: row.filled ? Colors.white : kBrand,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );

    final pill = row.filled
        ? Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: kInk.withValues(alpha: 0.07),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: content,
          )
        : CustomPaint(
            painter: _DashedPillPainter(color: kInk.withValues(alpha: 0.22)),
            child: content,
          );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: pill,
    );
  }
}

class _DashedPillPainter extends CustomPainter {
  const _DashedPillPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final source = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(size.height / 2),
        ),
      );

    const dash = 6.0;
    const gap = 5.0;
    final dashed = Path();

    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        dashed.addPath(
          metric.extractPath(distance, min(distance + dash, metric.length)),
          Offset.zero,
        );
        distance += dash + gap;
      }
    }

    canvas.drawPath(dashed, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedPillPainter oldDelegate) =>
      oldDelegate.color != color;
}

const _routeCanvas = Size(300, 232);

const _stops = <double>[0.16, 0.46, 0.76];

Path _buildRoutePath(Size size) {
  final w = size.width;
  final h = size.height;

  return Path()
    ..moveTo(w * 0.12, h * 0.86)
    ..cubicTo(w * 0.05, h * 0.58, w * 0.34, h * 0.62, w * 0.36, h * 0.42)
    ..cubicTo(w * 0.38, h * 0.22, w * 0.62, h * 0.3, w * 0.7, h * 0.46)
    ..cubicTo(w * 0.78, h * 0.62, w * 0.94, h * 0.42, w * 0.88, h * 0.14);
}

class _RouteVisual extends StatefulWidget {
  const _RouteVisual();

  @override
  State<_RouteVisual> createState() => _RouteVisualState();
}

class _RouteVisualState extends State<_RouteVisual>
    with TickerProviderStateMixin {
  late final AnimationController _drive;
  late final AnimationController _pulse;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();

    _drive = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..forward();

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _progress = Tween<double>(begin: 0, end: 0.82).animate(
      CurvedAnimation(parent: _drive, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _drive.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          width: _routeCanvas.width,
          height: _routeCanvas.height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(34),
            border: Border.all(color: kInk.withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(
                color: kInk.withValues(alpha: 0.07),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: AnimatedBuilder(
            animation: _progress,
            builder: (context, child) {
              final path = _buildRoutePath(_routeCanvas);
              final metric = path.computeMetrics().first;
              final position =
                  metric
                      .getTangentForOffset(metric.length * _progress.value)
                      ?.position ??
                  Offset.zero;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _RoutePainter(progress: _progress.value),
                    ),
                  ),

                  Positioned(
                    left: position.dx - 23,
                    top: position.dy - 23,
                    child: _TruckMarker(pulse: _pulse),
                  ),
                ],
              );
            },
          ),
        ),

        Positioned(
          top: 12,
          right: -8,
          child: _FloatingChip(
            icon: Icons.route_rounded,
            iconColor: kBrand,
            title: '4 stops',
            trailing: 'optimised',
          ),
        ),

        Positioned(
          bottom: 16,
          left: -10,
          child: _FloatingChip(
            icon: Icons.access_time_rounded,
            iconColor: Color(0xFF2B8AE0),
            title: 'Arriving',
            trailing: '12 min',
          ),
        ),
      ],
    );
  }
}

class _TruckMarker extends StatelessWidget {
  const _TruckMarker({required this.pulse});

  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) {
        final t = pulse.value;
        return SizedBox(
          width: 46,
          height: 46,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 46 * (0.7 + t * 0.5),
                height: 46 * (0.7 + t * 0.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kBrand.withValues(alpha: (1 - t) * 0.22),
                ),
              ),
              child!,
            ],
          ),
        );
      },
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: kForest,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: kForest.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.local_shipping_rounded,
          size: 17,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = kInk.withValues(alpha: 0.035)
      ..strokeWidth = 1;

    for (double x = 22; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 18; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final blob = Paint()..color = kLeaf.withValues(alpha: 0.1);
    canvas
      ..drawCircle(Offset(size.width * 0.82, size.height * 0.78), 46, blob)
      ..drawCircle(Offset(size.width * 0.16, size.height * 0.2), 34, blob);

    final path = _buildRoutePath(size);
    final metric = path.computeMetrics().first;

    final base = Paint()
      ..color = kInk.withValues(alpha: 0.14)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const dash = 7.0;
    const gap = 7.0;
    final dashed = Path();
    var distance = 0.0;
    while (distance < metric.length) {
      dashed.addPath(
        metric.extractPath(distance, min(distance + dash, metric.length)),
        Offset.zero,
      );
      distance += dash + gap;
    }
    canvas.drawPath(dashed, base);

    final travelled = metric.extractPath(0, metric.length * progress);
    canvas
      ..drawPath(
        travelled,
        Paint()
          ..color = kBrand.withValues(alpha: 0.25)
          ..strokeWidth = 11
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      )
      ..drawPath(
        travelled,
        Paint()
          ..shader = const LinearGradient(
            colors: [kLeaf, kBrand],
          ).createShader(Offset.zero & size)
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );

    final origin = metric.getTangentForOffset(0)?.position ?? Offset.zero;
    canvas
      ..drawCircle(origin, 8, Paint()..color = kBrand.withValues(alpha: 0.16))
      ..drawCircle(origin, 4, Paint()..color = kBrand);

    for (final stop in _stops) {
      final point =
          metric.getTangentForOffset(metric.length * stop)?.position ??
          Offset.zero;
      final reached = progress >= stop;

      canvas
        ..drawCircle(
          point,
          9,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.fill,
        )
        ..drawCircle(
          point,
          9,
          Paint()
            ..color = reached ? kBrand : kInk.withValues(alpha: 0.2)
            ..strokeWidth = 2.5
            ..style = PaintingStyle.stroke,
        );

      if (reached) {
        canvas.drawCircle(point, 3.4, Paint()..color = kBrand);
      }
    }

    final finish =
        metric.getTangentForOffset(metric.length)?.position ?? Offset.zero;
    final flag = Paint()..color = kForest;
    canvas
      ..drawCircle(finish, 11, Paint()..color = kForest.withValues(alpha: 0.12))
      ..drawCircle(finish, 6, flag);
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
