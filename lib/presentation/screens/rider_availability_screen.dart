import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/availability/rider_availability_cubit.dart';
import '../../bloc/availability/rider_availability_state.dart';
import '../../models/availability_schedule.dart';
import '../../repository/rider_repository.dart';

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
      appBar: AppBar(title: const Text('Availability & Schedule')),
      body: BlocConsumer<RiderAvailabilityCubit, RiderAvailabilityState>(
        listener: (context, state) {
          if (state is RiderAvailabilityLoaded) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: Colors.red,
                ),
              );
            }
            if (state.successMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.successMessage!),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        },
        builder: (context, state) {
          return switch (state) {
            RiderAvailabilityLoading() =>
              const Center(child: CircularProgressIndicator()),
            RiderAvailabilityError(:final message) =>
              Center(child: Text(message)),
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

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // ── Toggles ──
        _ToggleTile(
          title: 'Go Online',
          subtitle: state.isOnline ? 'You are online' : 'You are offline',
          value: state.isOnline,
          onChanged: cubit.toggleOnline,
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
        const Divider(height: 32),
        _ToggleTile(
          title: 'Accept scheduled rides',
          subtitle: state.acceptsScheduledRides
              ? 'Customers can book you in advance'
              : 'Only immediate rides',
          value: state.acceptsScheduledRides,
          onChanged: cubit.toggleAcceptsScheduled,
        ),

        // ── Timezone ──
        if (state.acceptsScheduledRides) ...[
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Schedule Timezone'),
            subtitle: Text(state.scheduleTimeZone),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickTimeZone(context, cubit, state.scheduleTimeZone),
          ),
        ],

        // ── Weekly schedule ──
        if (state.acceptsScheduledRides) ...[
          const Divider(height: 32),
          const Text(
            'Weekly Schedule',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...weekdayKeys.map(
            (day) => _DayScheduleCard(
              day: day,
              slots: state.schedule[day] ?? [],
              cubit: cubit,
            ),
          ),
        ],

        // ── Save button ──
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: state.isSaving ? null : () => cubit.save(),
            child: state.isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ),
        const SizedBox(height: 24),
      ],
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
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: zones.map((z) {
          return ListTile(
            title: Text(z),
            trailing: z == current ? const Icon(Icons.check) : null,
            onTap: () => Navigator.pop(ctx, z),
          );
        }).toList(),
      ),
    ).then((selected) {
      if (selected != null) cubit.updateScheduleTimeZone(selected);
    });
  }
}

// ─────────────────── Toggle tile ───────────────────

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
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }
}

// ─────────────────── Day schedule card ───────────────────

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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _displayName,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                if (slots.length < 6)
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Add slot',
                    onPressed: () => _showSlotDialog(context),
                  ),
              ],
            ),
            if (slots.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'No slots — day off',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ...List.generate(slots.length, (i) {
              final slot = slots[i];
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text('${slot.start} – ${slot.end}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => _showSlotDialog(context,
                          existingIndex: i, existing: slot),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () => cubit.removeSlot(day, i),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
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
        return AlertDialog(
          title: Text(
              existing != null ? 'Edit Slot' : 'Add Slot — $_displayName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: startCtrl,
                decoration: const InputDecoration(
                  labelText: 'Start (HH:mm)',
                  hintText: '09:00',
                ),
                onTap: () => _pickTime(ctx, startCtrl),
                readOnly: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: endCtrl,
                decoration: const InputDecoration(
                  labelText: 'End (HH:mm)',
                  hintText: '17:00',
                ),
                onTap: () => _pickTime(ctx, endCtrl),
                readOnly: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final slot =
                    TimeSlot(start: startCtrl.text, end: endCtrl.text);
                if (!slot.isValid) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Invalid slot: start must be before end.'),
                      backgroundColor: Colors.red,
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
              child: Text(existing != null ? 'Update' : 'Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickTime(BuildContext context, TextEditingController ctrl) async {
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
