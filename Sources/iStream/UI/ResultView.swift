#if canImport(SwiftUI)
import SwiftUI

public struct ResultView: View {
    let design: PipelineDesign
    @Environment(\.dismiss) private var dismiss

    public init(design: PipelineDesign) {
        self.design = design
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    topicCard
                    flinkCard
                    if !design.skewMitigation.isEmpty { skewCard }
                    if !design.notes.isEmpty { notesCard }
                    mermaidCard
                    markdownCard
                }
                .padding()
            }
            .navigationTitle("Pipeline Design")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    ShareLink(item: design.markdown) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }

    private var topicCard: some View {
        card(title: "Kafka Topic") {
            row("Name", design.topic.name)
            row("Partitions", "\(design.topic.partitions)")
            row("Replication", "\(design.topic.replicationFactor)")
            row("min ISR", "\(design.topic.minInSyncReplicas)")
            row("Retention", "\(design.topic.retentionMs / 86_400_000) days")
            row("Cleanup", design.topic.cleanupPolicy)
            row("Compression", design.topic.compressionType)
        }
    }

    private var flinkCard: some View {
        card(title: "Flink Job") {
            row("Parallelism", "\(design.flink.parallelism)")
            row("State backend", design.flink.stateBackend)
            row("Checkpoint", "\(design.flink.checkpointIntervalMs) ms")
            row("Mode", design.flink.checkpointMode)
            row("Watermark bound", "\(design.flink.watermarkBoundMs) ms")
            row("Allowed lateness", "\(design.flink.allowedLatenessMs) ms")
        }
    }

    private var skewCard: some View {
        card(title: "Skew Mitigation") {
            ForEach(design.skewMitigation, id: \.self) { item in
                bullet(item)
            }
        }
    }

    private var notesCard: some View {
        card(title: "Notes") {
            ForEach(design.notes, id: \.self) { item in
                bullet(item)
            }
        }
    }

    private var mermaidCard: some View {
        card(title: "Topology (Mermaid)") {
            ScrollView(.horizontal) {
                Text(design.mermaid)
                    .font(.system(.footnote, design: .monospaced))
                    .textSelection(.enabled)
            }
            Button {
                Clipboard.copy(design.mermaid)
            } label: {
                Label("Copy Mermaid", systemImage: "doc.on.doc")
            }
            .buttonStyle(.bordered)
        }
    }

    private var markdownCard: some View {
        card(title: "Full Design") {
            Text(design.markdown)
                .font(.system(.footnote, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                Clipboard.copy(design.markdown)
            } label: {
                Label("Copy Markdown", systemImage: "doc.on.doc")
            }
            .buttonStyle(.bordered)
        }
    }

    private func card<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.08))
        )
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
        }
        .font(.subheadline)
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•")
            Text(text).textSelection(.enabled)
        }
        .font(.footnote)
    }
}
#endif
