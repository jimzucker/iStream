import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/pipeline_design.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.design});

  final PipelineDesign design;

  void _copy(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard'), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pipeline Design')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Card(
            title: 'Kafka Topic',
            children: [
              _row('Name', design.topic.name),
              _row('Partitions', '${design.topic.partitions}'),
              _row('Replication', '${design.topic.replicationFactor}'),
              _row('min ISR', '${design.topic.minInSyncReplicas}'),
              _row('Retention', '${design.topic.retentionMs ~/ 86400000} days'),
              _row('Cleanup', design.topic.cleanupPolicy),
              _row('Compression', design.topic.compressionType),
            ],
          ),
          _Card(
            title: 'Flink Job',
            children: [
              _row('Parallelism', '${design.flink.parallelism}'),
              _row('State backend', design.flink.stateBackend),
              _row('Checkpoint', '${design.flink.checkpointIntervalMs} ms'),
              _row('Mode', design.flink.checkpointMode),
              _row('Watermark bound', '${design.flink.watermarkBoundMs} ms'),
              _row('Allowed lateness', '${design.flink.allowedLatenessMs} ms'),
            ],
          ),
          if (design.skewMitigation.isNotEmpty)
            _Card(
              title: 'Skew Mitigation',
              children: [for (final s in design.skewMitigation) _bullet(s)],
            ),
          if (design.notes.isNotEmpty)
            _Card(
              title: 'Notes',
              children: [for (final n in design.notes) _bullet(n)],
            ),
          _Card(
            title: 'Topology (Mermaid)',
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SelectableText(
                  design.mermaid,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _copy(context, design.mermaid, 'Mermaid'),
                icon: const Icon(Icons.copy),
                label: const Text('Copy Mermaid'),
              ),
            ],
          ),
          _Card(
            title: 'Full Design',
            children: [
              SelectableText(
                design.markdown,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _copy(context, design.markdown, 'Markdown'),
                icon: const Icon(Icons.copy),
                label: const Text('Copy Markdown'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            flex: 3,
            child: SelectableText(
              value,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(child: SelectableText(text)),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}
