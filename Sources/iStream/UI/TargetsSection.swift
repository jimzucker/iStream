#if canImport(SwiftUI)
import SwiftUI

public struct TargetsSection: View {
    @ObservedObject var vm: PipelineFormViewModel

    public init(vm: PipelineFormViewModel) {
        self.vm = vm
    }

    public var body: some View {
        Section {
            HStack {
                Text("Throughput (events/sec)")
                Spacer()
                TextField("50000", value: $vm.throughputEventsPerSec, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 140)
            }

            VStack(alignment: .leading) {
                HStack {
                    Text("Peak multiplier")
                    Spacer()
                    Text("×\(vm.peakMultiplier, specifier: "%.1f")")
                        .foregroundStyle(.secondary)
                }
                Slider(value: $vm.peakMultiplier, in: 1.0...10.0, step: 0.5)
            }

            HStack {
                Text("Avg event size (bytes)")
                Spacer()
                TextField("512", value: $vm.avgEventSizeBytes, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 140)
            }

            HStack {
                Text("Latency SLO (ms)")
                Spacer()
                TextField("1000", value: $vm.latencySLOms, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 140)
            }
        } header: {
            Text("Throughput & Latency Targets")
        } footer: {
            Text("Peak multiplier scales base throughput for traffic spikes. Latency SLO bounds checkpointing and watermark intervals.")
        }
    }
}
#endif
