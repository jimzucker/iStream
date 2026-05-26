import 'package:flutter/material.dart';

import '../engine/design_engine.dart';
import '../models/field.dart';
import '../models/pipeline_input.dart';
import '../models/skew_level.dart';
import 'result_screen.dart';
import 'sections/key_distro_section.dart';
import 'sections/schema_section.dart';
import 'sections/targets_section.dart';

class PipelineFormScreen extends StatefulWidget {
  const PipelineFormScreen({super.key});

  @override
  State<PipelineFormScreen> createState() => _PipelineFormScreenState();
}

class _PipelineFormScreenState extends State<PipelineFormScreen> {
  String _topicName = 'events';
  List<Field> _fields = [
    Field(name: 'user_id', type: FieldType.stringType),
    Field(name: 'event_time', type: FieldType.timestampType),
    Field(name: 'amount', type: FieldType.decimalType),
  ];
  String _partitionKey = 'user_id';
  int _cardinality = 1000000;
  SkewLevel _skew = SkewLevel.mild;
  int _throughputEventsPerSec = 50000;
  double _peakMultiplier = 3.0;
  int _avgEventSizeBytes = 512;
  int _latencySLOms = 1000;

  void _addField() {
    setState(() {
      _fields = [
        ..._fields,
        Field(
          name: 'field_${_fields.length + 1}',
          type: FieldType.stringType,
        ),
      ];
    });
  }

  void _removeField(int index) {
    setState(() {
      final removedName = _fields[index].name;
      _fields = [..._fields]..removeAt(index);
      if (removedName == _partitionKey) {
        _partitionKey = _fields.isNotEmpty ? _fields.first.name : '';
      }
    });
  }

  void _updateField(int index, Field updated) {
    setState(() {
      final oldName = _fields[index].name;
      _fields = [..._fields];
      _fields[index] = updated;
      if (oldName == _partitionKey && updated.name != oldName) {
        _partitionKey = updated.name;
      }
    });
  }

  PipelineInput _buildInput() {
    return PipelineInput(
      topicName: _topicName.isEmpty ? 'events' : _topicName,
      fields: _fields,
      partitionKey: _partitionKey,
      cardinality: _cardinality,
      skew: _skew,
      throughputEventsPerSec: _throughputEventsPerSec,
      peakMultiplier: _peakMultiplier,
      avgEventSizeBytes: _avgEventSizeBytes,
      latencySLOms: _latencySLOms,
    );
  }

  void _generate() {
    final design = DesignEngine.design(_buildInput());
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ResultScreen(design: design)),
    );
  }

  bool get _canGenerate => _fields.isNotEmpty && _partitionKey.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('iStream')),
      body: ListView(
        children: [
          SchemaSection(
            topicName: _topicName,
            onTopicNameChanged: (v) => setState(() => _topicName = v),
            fields: _fields,
            onFieldChanged: _updateField,
            onFieldRemoved: _removeField,
            onFieldAdded: _addField,
          ),
          KeyDistroSection(
            fields: _fields,
            partitionKey: _partitionKey,
            onPartitionKeyChanged: (v) => setState(() => _partitionKey = v),
            cardinality: _cardinality,
            onCardinalityChanged: (v) => setState(() => _cardinality = v),
            skew: _skew,
            onSkewChanged: (v) => setState(() => _skew = v),
          ),
          TargetsSection(
            throughputEventsPerSec: _throughputEventsPerSec,
            onThroughputChanged: (v) =>
                setState(() => _throughputEventsPerSec = v),
            peakMultiplier: _peakMultiplier,
            onPeakChanged: (v) => setState(() => _peakMultiplier = v),
            avgEventSizeBytes: _avgEventSizeBytes,
            onAvgEventSizeChanged: (v) =>
                setState(() => _avgEventSizeBytes = v),
            latencySLOms: _latencySLOms,
            onLatencySLOChanged: (v) => setState(() => _latencySLOms = v),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: _canGenerate ? _generate : null,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Generate Pipeline Design'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
