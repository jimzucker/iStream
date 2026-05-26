#if canImport(SwiftUI)
import SwiftUI

public struct iStreamRootView: View {
    @StateObject private var vm = PipelineFormViewModel()
    @State private var design: PipelineDesign?

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                SchemaSection(vm: vm)
                KeyDistroSection(vm: vm)
                TargetsSection(vm: vm)

                Section {
                    Button {
                        design = DesignEngine.design(vm.build())
                    } label: {
                        Text("Generate Pipeline Design")
                            .frame(maxWidth: .infinity)
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(vm.fields.isEmpty || vm.partitionKey.isEmpty)
                }
            }
            .navigationTitle("iStream")
            .sheet(item: $design) { d in
                ResultView(design: d)
            }
        }
    }
}

#Preview {
    iStreamRootView()
}
#endif
