import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../bloc/availability/rider_availability_cubit.dart';
import '../../bloc/availability/rider_availability_state.dart';
import '../../models/availability_schedule.dart';
import '../../repository/rider_repository.dart';
import '../widgets/glass_card.dart';
import '../widgets/primary_button.dart';

class RiderAvailabilityScreen extends StatelessWidget {
  final String riderId;
  const RiderAvailabilityScreen({super.key, required this.riderId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RiderAvailabilityCubit(
        context.read<RiderRepository>(),
        riderId,
      ),
      child: const _AvailabilityView(),
    );
  }
}

class _AvailabilityView extends StatelessWidget {
  const _AvailabilityView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: BlocConsumer<RiderAvailabilityCubit, RiderAvailabilityState>(
        listener: (context, state) {
          if (state is RiderAvailabilityLoaded) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: const Color(0xFFFF4757),
                ),
              );
            }
            if (state.successMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.successMessage!),
                  backgroundColor: const Color(0xFF00E5C3),
                ),
              );
            }
          }
        },
        builder: (context, state) {
          return switch (state) {
            RiderAvailabilityLoading() => const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E5C3)),
                ),
              ),
            RiderAvailabilityError(:final message) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: GlassCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Color(0xFFFF4757),
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          message,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.1,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            RiderAvailabilityLoaded() => _LoadedBody(state: state),
          };
        },
      ),
    );
  }
}

class _LoadedBody extends StatelessWidget {
  final RiderAvailabilityLoaded state;
  const _LoadedBody({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RiderAvailabilityCubit>();

    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Availability',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: const Duration(milliseconds: 300))
              .slideY(
                begin: -0.2,
                end: 0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              ),
          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                GlassCard(
                  child: Column(
                    children: [
                      _ToggleTile(
                        title: 'Go Online',
                        subtitle:
                            state.isOnline ? 'You are online' : 'You are offline',
                        value: state.isOnline,
                        onChanged: cubit.toggleOnline,
                      ),
                      Container(
                        height: 1,
                        margin: const EdgeInsets.symmetric(vertical: 16),
                        color: Colors.white.withOpacity(0.08),
                      ),
                      _ToggleTile(
                        title: 'Available for rides now',
                        subtitle: !state.isOnline
                            ? 'Go online first'
                            : state.isAvailable
                                ? 'Accepting immediate rides'
                                : 'Not accepting rides right now',
                        value: state.isAvailable,
                        onChanged: state.isOnline ? cubit.toggleAvailable : null,
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(
                      delay: const Duration(milliseconds: 100),
                      duration: const Duration(milliseconds: 300),
                    )
                    .slideY(
                      begin: 0.2,
                      end: 0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    ),
                const SizedBox(height: 16),
                GlassCard(
                  child: _ToggleTile(
                    title: 'Accept scheduled rides',
                    subtitle: state.acceptsScheduledRides
                        ? 'Customers can book you in advance'
                        : 'Only immediate rides',
                    value: state.acceptsScheduledRides,
                    onChanged: cubit.toggleAcceptsScheduled,
                  ),
                )
                    .animate()
                    .fadeIn(
                      delay: const Duration(milliseconds: 150),
                      duration: const Duration(milliseconds: 300),
                    )
                    .slideY(
                      begin: 0.2,
                      end: 0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    ),
                if (state.acceptsScheduledRides) ...[
                  const SizedBox(height: 16),
                  GlassCard(
                    onTap: () => _pickTimeZone(context, cubit, state.scheduleTimeZone),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E5C3).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.schedule,
                            color: Color(0xFF00E5C3),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'SCHEDULE TIMEZONE',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1.2,
                                  color: Color(0xFF8A8A9A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                state.scheduleTimeZone,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.1,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: Color(0xFF8A8A9A),
                          size: 24,
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(
                        delay: const Duration(milliseconds: 200),
                        duration: const Duration(milliseconds: 300),
                      )
                      .slideY(
                        begin: 0.2,
                        end: 0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      ),
                  const SizedBox(height: 24),
                  const Text(
                    'Weekly Schedule',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: Colors.white,
                    ),
                  )
                      .animate()
                      .fadeIn(
                        delay: const Duration(milliseconds: 250),
                        duration: const Duration(milliseconds: 300),
                      )
                      .slideY(
                        begin: 0.2,
                        end: 0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      ),
                  const SizedBox(height: 16),
                  ...weekdayKeys.asMap().entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _DayScheduleCard(
                            day: entry.value,
                            slots: state.schedule[entry.value] ?? [],
                            cubit: cubit,
                          )
                              .animate()
                              .fadeIn(
                                delay: Duration(
                                    milliseconds: 300 + (entry.key * 50)),
                                duration: const Duration(milliseconds: 300),
                              )
                              .slideY(
                                begin: 0.2,
                                end: 0,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              ),
                        ),
                      ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    text: 'Save',
                    loading: state.isSaving,
                    onPressed: state.isSaving ? null : () => cubit.save(),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _pickTimeZone(
    BuildContext context,
    RiderAvailabilityCubit cubit,
    String current,
  ) {
    const zones = [
      'Asia/Kolkata',
      'Asia/Dubai',
      'Asia/Singapore',
      'Asia/Tokyo',
      'Europe/London',
      'Europe/Berlin',
      'America/New_York',
      'America/Chicago',
      'America/Denver',
      'America/Los_Angeles',
      'Australia/Sydney',
      'Pacific/Auckland',
    ];

    showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF12121A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Select Timezone',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: zones.map((z) {
                final isSelected = z == current;
                return ListTile(
                  title: Text(
                    z,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF00E5C3)
                          : Colors.white,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_circle,
                          color: Color(0xFF00E5C3),
                        )
                      : null,
                  onTap: () => Navigator.pop(ctx, z),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    ).then((selected) {
      if (selected != null) cubit.updateScheduleTimeZone(selected);
    });
  }
}

class _ToggleTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _ToggleTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.1,
                  color: Color(0xFF8A8A9A),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF00E5C3),
          activeTrackColor: const Color(0xFF00E5C3).withOpacity(0.3),
          inactiveThumbColor: const Color(0xFF8A8A9A),
          inactiveTrackColor: const Color(0xFF8A8A9A).withOpacity(0.2),
        ),
      ],
    );
  }
}

class _DayScheduleCard extends StatelessWidget {
  final String day;
  final List<TimeSlot> slots;
  final RiderAvailabilityCubit cubit;

  const _DayScheduleCard({
    required this.day,
    required this.slots,
    required this.cubit,
  });

  String get _displayName => '${day[0].toUpperCase()}${day.substring(1)}';

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _displayName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: Colors.white,
                ),
              ),
              if (slots.length < 6)
                GestureDetector(
                  onTap: () => _showSlotDialog(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5C3).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Color(0xFF00E5C3),
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
          if (slots.isEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'No slots — day off',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.1,
                color: Color(0xFF8A8A9A),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            ...List.generate(slots.length, (i) {
              final slot = slots[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5C3).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF00E5C3).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          '${slot.start} – ${slot.end}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: Color(0xFF00E5C3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showSlotDialog(context,
                          existingIndex: i, existing: slot),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => cubit.removeSlot(day, i),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4757).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFFF4757).withOpacity(0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Color(0xFFFF4757),
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  void _showSlotDialog(
    BuildContext context, {
    int? existingIndex,
    TimeSlot? existing,
  }) {
    final startCtrl = TextEditingController(text: existing?.start ?? '09:00');
    final endCtrl = TextEditingController(text: existing?.end ?? '17:00');

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: const Color(0xFF12121A),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  existing != null ? 'Edit Slot' : 'Add Slot — $_displayName',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: startCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Start (HH:mm)',
                    labelStyle: const TextStyle(color: Color(0xFF8A8A9A)),
                    hintText: '09:00',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    filled: true,
                    fillColor: const Color(0xFF0A0A0F),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFF00E5C3),
                        width: 2,
                      ),
                    ),
                  ),
                  onTap: () => _pickTime(ctx, startCtrl),
                  readOnly: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: endCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'End (HH:mm)',
                    labelStyle: const TextStyle(color: Color(0xFF8A8A9A)),
                    hintText: '17:00',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    filled: true,
                    fillColor: const Color(0xFF0A0A0F),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFF00E5C3),
                        width: 2,
                      ),
                    ),
                  ),
                  onTap: () => _pickTime(ctx, endCtrl),
                  readOnly: true,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          final slot = TimeSlot(
                              start: startCtrl.text, end: endCtrl.text);
                          if (!slot.isValid) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Invalid slot: start must be before end.'),
                                backgroundColor: Color(0xFFFF4757),
                              ),
                            );
                            return;
                          }
                          if (existingIndex != null) {
                            cubit.updateSlot(day, existingIndex, slot);
                          } else {
                            cubit.addSlot(day, slot);
                          }
                          Navigator.pop(ctx);
                        },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E5C3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              existing != null ? 'Update' : 'Add',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0A0A0F),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickTime(
      BuildContext context, TextEditingController ctrl) async {
    final parts = ctrl.text.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 9,
      minute: int.tryParse(parts[1]) ?? 0,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) {
      ctrl.text =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }
  }
}
