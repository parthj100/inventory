import SwiftUI

struct CheckOutSheet: View {
    let costume: Costume
    var onCheckOut: (String, Int, Date) -> Void

    @State private var checkedOutBy = ""
    @State private var quantity = 1
    @State private var dueDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Check Out Costume")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 12)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Quantity")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        SleekSectionBody {
                            Stepper(value: $quantity, in: 1...costume.availableQuantity) {
                                Text("\(quantity) of \(costume.availableQuantity) available")
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Checked Out By")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        SleekSectionBody {
                            GlassTextField(placeholder: "Name", text: $checkedOutBy, icon: "person")
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Return Date")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        SleekSectionBody {
                            DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background(
                LinearGradient(
                    colors: [Color(.systemGray6), Color.white],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Check Out") {
                        onCheckOut(checkedOutBy, quantity, dueDate)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(checkedOutBy.isEmpty)
                }
            }
        }
    }
}
