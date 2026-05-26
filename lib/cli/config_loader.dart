import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

import '../models/field.dart';
import '../models/pipeline_input.dart';
import '../models/skew_level.dart';

class ConfigError implements Exception {
  ConfigError(this.message);
  final String message;
  @override
  String toString() => message;
}

Future<String> readInput(String source) async {
  if (source == '-') {
    return stdin.transform(utf8.decoder).join();
  }
  final file = File(source);
  if (!file.existsSync()) {
    throw FileSystemException('Config file not found', source);
  }
  return file.readAsString();
}

PipelineInput parseConfig(String raw) {
  final dynamic doc = loadYaml(raw);
  if (doc is! Map) {
    throw ConfigError('Config must be a YAML/JSON object at the root.');
  }
  final m = Map<dynamic, dynamic>.from(doc);

  final fields = _parseFields(m['fields']);
  final partitionKey = _requireString(m, 'partition_key');
  if (!fields.any((f) => f.name == partitionKey)) {
    throw ConfigError(
      "partition_key '$partitionKey' does not match any field in schema.",
    );
  }

  return PipelineInput(
    topicName: _requireString(m, 'topic_name'),
    fields: fields,
    partitionKey: partitionKey,
    cardinality: _requireInt(m, 'cardinality'),
    skew: _parseSkew(m['skew']),
    throughputEventsPerSec: _requireInt(m, 'throughput_eps'),
    peakMultiplier: _requireDouble(m, 'peak_multiplier'),
    avgEventSizeBytes: _requireInt(m, 'avg_event_size_bytes'),
    latencySLOms: _requireInt(m, 'latency_slo_ms'),
  );
}

List<Field> _parseFields(dynamic raw) {
  if (raw is! List || raw.isEmpty) {
    throw ConfigError("'fields' must be a non-empty list of {name, type}.");
  }
  return raw.map<Field>((entry) {
    if (entry is! Map) {
      throw ConfigError("Each field must be a map with 'name' and 'type'.");
    }
    final name = entry['name'];
    final type = entry['type'];
    if (name is! String || type is! String) {
      throw ConfigError("Field 'name' and 'type' must be strings.");
    }
    final fieldType = FieldType.values.firstWhere(
      (t) => t.label == type,
      orElse: () => throw ConfigError(
        "Unknown field type '$type'. Valid: ${FieldType.values.map((t) => t.label).join(', ')}",
      ),
    );
    return Field(name: name, type: fieldType);
  }).toList();
}

SkewLevel _parseSkew(dynamic raw) {
  if (raw is! String) {
    throw ConfigError("'skew' must be one of: none, mild, heavy.");
  }
  final normalized = raw.toLowerCase();
  return SkewLevel.values.firstWhere(
    (s) => s.name.toLowerCase() == normalized,
    orElse: () =>
        throw ConfigError("Unknown skew '$raw'. Valid: none, mild, heavy."),
  );
}

String _requireString(Map<dynamic, dynamic> m, String key) {
  final v = m[key];
  if (v is! String || v.isEmpty) {
    throw ConfigError("'$key' is required and must be a non-empty string.");
  }
  return v;
}

int _requireInt(Map<dynamic, dynamic> m, String key) {
  final v = m[key];
  if (v is int) return v;
  if (v is String) {
    final parsed = int.tryParse(v);
    if (parsed != null) return parsed;
  }
  throw ConfigError("'$key' is required and must be an integer.");
}

double _requireDouble(Map<dynamic, dynamic> m, String key) {
  final v = m[key];
  if (v is num) return v.toDouble();
  if (v is String) {
    final parsed = double.tryParse(v);
    if (parsed != null) return parsed;
  }
  throw ConfigError("'$key' is required and must be a number.");
}
