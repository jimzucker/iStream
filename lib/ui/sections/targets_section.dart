import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '_section_card.dart';

class TargetsSection extends StatelessWidget {
  const TargetsSection({
    super.key,
    required this.throughputEventsPerSec,
    required this.onThroughputChanged,
    required this.peakMultiplier,
    required this.onPeakChanged,
    required this.avgEventSizeBytes,
    required this.onAvgEventSizeChanged,
    required this.latencySLOms,
    required this.onLatencySLOChanged,
  });

  final int throughputEventsPerSec;
  final ValueChanged<int> onThroughputChanged;
  final double peakMultiplier;
  final ValueChanged<double> onPeakChanged;
  final int avgEventSizeBytes;
  final ValueChanged<int> onAvgEventSizeChanged;
  final int latencySLOms;
  final ValueChanged<int> onLatencySLOChanged;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Throughput & Latency Targets',
      footer:
          'Peak multiplier scales base throughput for traffic spikes. Latency SLO bounds checkpointing and watermark intervals.',
      children: [
        _IntField(
          label: 'Throughput (events/sec)',
          value: throughputEventsPerSec,
          onChanged: onThroughputChanged,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('Peak multiplier'),
            const Spacer(),
            Text('×${peakMultiplier.toStringAsFixed(1)}'),
          ],
        ),
        Slider(
          value: peakMultiplier,
          min: 1.0,
          max: 10.0,
          divisions: 18,
          label: '×${peakMultiplier.toStringAsFixed(1)}',
          onChanged: onPeakChanged,
        ),
        _IntField(
          label: 'Avg event size (bytes)',
          value: avgEventSizeBytes,
          onChanged: onAvgEventSizeChanged,
        ),
        const SizedBox(height: 12),
        _IntField(
          label: 'Latency SLO (ms)',
          value: latencySLOms,
          onChanged: onLatencySLOChanged,
        ),
      ],
    );
  }
}

class _IntField extends StatelessWidget {
  const _IntField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value.toString(),
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (v) => onChanged(int.tryParse(v) ?? 0),
    );
  }
}
