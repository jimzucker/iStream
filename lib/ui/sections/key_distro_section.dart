import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/field.dart';
import '../../models/skew_level.dart';
import '_section_card.dart';

class KeyDistroSection extends StatelessWidget {
  const KeyDistroSection({
    super.key,
    required this.fields,
    required this.partitionKey,
    required this.onPartitionKeyChanged,
    required this.cardinality,
    required this.onCardinalityChanged,
    required this.skew,
    required this.onSkewChanged,
  });

  final List<Field> fields;
  final String partitionKey;
  final ValueChanged<String> onPartitionKeyChanged;
  final int cardinality;
  final ValueChanged<int> onCardinalityChanged;
  final SkewLevel skew;
  final ValueChanged<SkewLevel> onSkewChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dropdownValue =
        fields.any((f) => f.name == partitionKey) ? partitionKey : null;

    return SectionCard(
      title: 'Key & Distribution',
      footer:
          'Cardinality = approx number of distinct key values. Skew = how concentrated the volume is on hot keys.',
      children: [
        DropdownButtonFormField<String>(
          value: dropdownValue,
          decoration: const InputDecoration(labelText: 'Partition key'),
          items: [
            for (final f in fields)
              DropdownMenuItem(value: f.name, child: Text(f.name)),
          ],
          onChanged: (v) {
            if (v != null) onPartitionKeyChanged(v);
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: cardinality.toString(),
          decoration: const InputDecoration(labelText: 'Cardinality'),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (v) => onCardinalityChanged(int.tryParse(v) ?? 0),
        ),
        const SizedBox(height: 12),
        SegmentedButton<SkewLevel>(
          segments: [
            for (final s in SkewLevel.values)
              ButtonSegment(value: s, label: Text(s.label)),
          ],
          selected: {skew},
          onSelectionChanged: (s) => onSkewChanged(s.first),
        ),
        const SizedBox(height: 4),
        Text(skew.description, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
