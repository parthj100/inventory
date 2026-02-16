import SwiftUI

struct CheckInSheet: View {
    let costume: Costume
    let checkOutInfo: CheckOutInfo
    var onCheckIn: (Int) -> Void

    @State private var quantity = 1
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Check In Costume")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 12)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Quantity")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        SleekSectionBody {
                            Stepper(value: $quantity, in: 1...checkOutInfo.quantity) {
                                Text("\(quantity) of \(checkOutInfo.quantity) checked out")
                            }
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
                    Button("Check In") {
                        onCheckIn(quantity)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
