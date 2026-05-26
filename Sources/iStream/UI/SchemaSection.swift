#if canImport(SwiftUI)
import SwiftUI

public struct SchemaSection: View {
    @ObservedObject var vm: PipelineFormViewModel

    public init(vm: PipelineFormViewModel) {
        self.vm = vm
    }

    public var body: some View {
        Section {
            TextField("Topic name", text: $vm.topicName)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            ForEach($vm.fields) { $field in
                HStack {
                    TextField("name", text: $field.name)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Picker("", selection: $field.type) {
                        ForEach(FieldType.allCases, id: \.self) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
            }
            .onDelete(perform: vm.removeFields)

            Button {
                vm.addField()
            } label: {
                Label("Add field", systemImage: "plus.circle")
            }
        } header: {
            Text("Schema")
        } footer: {
            Text("Define the event payload. Used to validate that the partition key references a real field.")
        }
    }
}
#endif
