import 'package:flutter/material.dart';

import '../../models/field.dart';
import '_section_card.dart';

class SchemaSection extends StatelessWidget {
  const SchemaSection({
    super.key,
    required this.topicName,
    required this.onTopicNameChanged,
    required this.fields,
    required this.onFieldChanged,
    required this.onFieldRemoved,
    required this.onFieldAdded,
  });

  final String topicName;
  final ValueChanged<String> onTopicNameChanged;
  final List<Field> fields;
  final void Function(int index, Field field) onFieldChanged;
  final ValueChanged<int> onFieldRemoved;
  final VoidCallback onFieldAdded;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Schema',
      footer:
          'Define the event payload. The partition key must reference a real field.',
      children: [
        TextFormField(
          initialValue: topicName,
          decoration: const InputDecoration(labelText: 'Topic name'),
          onChanged: onTopicNameChanged,
          autocorrect: false,
        ),
        const SizedBox(height: 12),
        for (int i = 0; i < fields.length; i++) ...[
          _FieldRow(
            field: fields[i],
            onChanged: (f) => onFieldChanged(i, f),
            onRemove: () => onFieldRemoved(i),
          ),
        ],
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onFieldAdded,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Add field'),
          ),
        ),
      ],
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.field,
    required this.onChanged,
    required this.onRemove,
  });

  final Field field;
  final ValueChanged<Field> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              initialValue: field.name,
              decoration: const InputDecoration(labelText: 'name'),
              autocorrect: false,
              onChanged: (v) =>
                  onChanged(Field(name: v, type: field.type)),
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<FieldType>(
            value: field.type,
            onChanged: (t) {
              if (t != null) onChanged(Field(name: field.name, type: t));
            },
            items: [
              for (final t in FieldType.values)
                DropdownMenuItem(value: t, child: Text(t.label)),
            ],
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.remove_circle_outline),
            tooltip: 'Remove',
          ),
        ],
      ),
    );
  }
}

