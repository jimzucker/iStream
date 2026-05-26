#if canImport(SwiftUI)
import SwiftUI

public struct KeyDistroSection: View {
    @ObservedObject var vm: PipelineFormViewModel

    public init(vm: PipelineFormViewModel) {
        self.vm = vm
    }

    public var body: some View {
        Section {
            Picker("Partition key", selection: $vm.partitionKey) {
                ForEach(vm.fields) { f in
                    Text(f.name).tag(f.name)
                }
            }

            HStack {
                Text("Cardinality")
                Spacer()
                TextField("e.g. 1000000", value: $vm.cardinality, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 160)
            }

            Picker("Skew", selection: $vm.skew) {
                ForEach(SkewLevel.allCases) { s in
                    Text(s.rawValue).tag(s)
                }
            }
            .pickerStyle(.segmented)

            Text(vm.skew.description)
                .font(.footnote)
                .foregroundStyle(.secondary)
        } header: {
            Text("Key & Distribution")
        } footer: {
            Text("Cardinality = approx number of distinct key values. Skew = how concentrated the volume is on hot keys.")
        }
    }
}
#endif
