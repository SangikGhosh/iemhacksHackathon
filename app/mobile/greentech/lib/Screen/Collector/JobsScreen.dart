import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:greentech/Model/Pickup.dart';
import 'package:greentech/Provider/CitizenProviders.dart';
import 'package:greentech/Service/ApiService.dart';
import 'package:greentech/Service/ToastService.dart';
import 'package:greentech/Utils/avatar_helper.dart';
import 'package:greentech/Provider/SessionProvider.dart';
import 'package:greentech/Widget/CitizenWidgets/CitizenKit.dart';
import 'package:greentech/Widget/UiKit.dart';

class JobsScreen extends ConsumerStatefulWidget {
  const JobsScreen({super.key});

  @override
  ConsumerState<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends ConsumerState<JobsScreen> {
  String? _accepting;

  Future<void> _accept(Pickup job) async {
    final confirmed = await showUiConfirmSheet(
      context,
      title: 'Accept this job?',
      message:
          'The citizen can no longer cancel once you accept. Only take what you can actually collect — releasing it later sends them back to waiting.',
      confirmLabel: 'Accept job',
      cancelLabel: 'Not now',
    );

    if (confirmed != true || !mounted) return;

    setState(() => _accepting = job.id);

    try {
      final accepted = await ApiService.acceptPickup(job.id);
      if (!mounted) return;

      HapticFeedback.heavyImpact();
      ref.read(availableJobsProvider.notifier).remove(job.id);
      ref.read(pickupsProvider.notifier).adopt(accepted);
      ToastService.show(
        'Job accepted. Added to your route.',
        ToastType.success,
        context,
      );

      await Future.wait([
        ref.read(pickupsProvider.notifier).refresh(),
        ref.read(routeProvider.notifier).refresh(),
      ]);
    } on ApiException catch (error) {
      if (!mounted) return;

      if (error.statusCode == 409) {
        ToastService.show('Someone got there first.', ToastType.info, context);
        ref.read(availableJobsProvider.notifier).remove(job.id);
      } else {
        ToastService.show(error.message, ToastType.error, context);
      }
      await ref.read(availableJobsProvider.notifier).refresh();
    } finally {
      if (mounted) setState(() => _accepting = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(availableJobsProvider);
    final jobs = async.value ?? const <Pickup>[];
    final user = ref.watch(sessionProvider).value;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CitizenAppBar(
        title: 'Open jobs',
        subtitle: jobs.isEmpty
            ? 'Nothing waiting right now'
            : '${jobs.length} pickup${jobs.length == 1 ? '' : 's'} up for grabs',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(
              child: Pressable(
                onTap: () => context.push('/profile'),
                scale: 0.92,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: uiHairline, width: 1.5),
                  ),
                  padding: const EdgeInsets.all(1.5),
                  child: CircleAvatar(
                    backgroundColor: uiFill,
                    backgroundImage: NetworkImage(
                      AvatarHelper.getAvatarForName(user?.fullName ?? 'Green'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: async.isLoading && jobs.isEmpty
          ? const Center(child: CircularProgressIndicator(color: uiInk))
          : async.hasError && jobs.isEmpty
          ? ErrorRetry(
              message: '${async.error}',
              onRetry: () => ref.read(availableJobsProvider.notifier).refresh(),
            )
          : RefreshIndicator(
              color: uiInk,
              onRefresh: () =>
                  ref.read(availableJobsProvider.notifier).refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 36),
                children: [
                  if (jobs.isEmpty)
                    const EmptyState(
                      icon: HugeIcons.strokeRoundedDeliveryBox01,
                      title: 'No open jobs',
                      message:
                          'When citizens request a pickup in your area it appears here. Pull down to check again.',
                    )
                  else
                    for (final job in jobs)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: JobCard(
                          job: job,
                          busy: _accepting == job.id,
                          onAccept: _accepting == null
                              ? () => _accept(job)
                              : null,
                        ),
                      ),
                ],
              ),
            ),
    );
  }
}

class JobCard extends StatelessWidget {
  const JobCard({
    super.key,
    required this.job,
    required this.busy,
    this.onAccept,
  });

  final Pickup job;
  final bool busy;
  final VoidCallback? onAccept;

  @override
  Widget build(BuildContext context) {
    final weight = job.money.finalWeightKg;

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
                  color: uiFill,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HugeIcon(
                      icon: job.mode == PickupMode.dropOff
                          ? HugeIcons.strokeRoundedLocation01
                          : HugeIcons.strokeRoundedTruck,
                      color: uiInkSecondary,
                      size: 13,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      job.mode.label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: uiInkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                relativeTime(job.createdAt),
                style: const TextStyle(fontSize: 12.5, color: uiInkTertiary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            job.materials.isEmpty ? '${job.totalObjects} items' : job.materials,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: uiInk,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedLocation01,
                color: uiInkTertiary,
                size: 14,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  job.location.address.isEmpty
                      ? 'No address given'
                      : job.location.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13.5, color: uiInkSecondary),
                ),
              ),
            ],
          ),
          if ((job.location.landmark ?? '').isNotEmpty) ...[
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Text(
                job.location.landmark!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12.5, color: uiInkTertiary),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _Stat(
                label: 'Est. weight',
                value: weight == null ? '—' : kilograms(weight),
              ),
              const SizedBox(width: 22),
              _Stat(
                label: 'Citizen quoted',
                value: rupees(job.money.estimatedOffer),
              ),
              const SizedBox(width: 22),
              _Stat(label: 'Items', value: '${job.totalObjects}'),
            ],
          ),
          const SizedBox(height: 16),
          Pressable(
            onTap: onAccept,
            dimWhenDisabled: false,
            scale: 0.98,
            child: AnimatedContainer(
              duration: uiQuick,
              height: 48,
              decoration: BoxDecoration(
                color: onAccept == null && !busy ? uiFillStrong : uiInk,
                borderRadius: BorderRadius.circular(24),
              ),
              alignment: Alignment.center,
              child: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Accept job',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: onAccept == null ? uiInkTertiary : Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            color: uiInk,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11.5, color: uiInkTertiary),
        ),
      ],
    );
  }
}
