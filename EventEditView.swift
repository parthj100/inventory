import SwiftUI

struct EventEditView: View {
    @EnvironmentObject var inventoryVM: InventoryViewModel
    @Environment(\.presentationMode) var presentationMode

    var editEvent: Event?

    @State private var name = ""
    @State private var date = Date()
    @State private var organizer = ""
    @State private var isAllDay = false
    @State private var isCompleted = false
    @State private var selectedCostumes: [UUID: Int] = [:]
    @State private var notes = ""
    @State private var selectedEventIconID: String = PlaceholderArtwork.eventOptions.first?.id ?? "evt_calendar"
    @State private var eventImage: UIImage? = nil
    @State private var showImagePicker = false

    var assignedCostumeList: [AssignedCostume] {
        inventoryVM.costumes
            .filter { selectedCostumes[$0.id] != nil }
            .map { AssignedCostume(costumeID: $0.id, costumeName: $0.name, quantity: selectedCostumes[$0.id] ?? 1) }
    }

    var body: some View {
        NavigationStack {
            let costumes = inventoryVM.costumes // Precompute for performance

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(editEvent == nil ? "Add Event" : "Edit Event")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 12)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Event Info")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        SleekSectionBody {
                            VStack(alignment: .leading, spacing: 12) {
                                GlassTextField(placeholder: "Name", text: $name, icon: "calendar")
                                DatePicker("Date", selection: $date, displayedComponents: .date)
                                Toggle("All Day", isOn: $isAllDay)
                                Toggle("Completed", isOn: $isCompleted)
                                GlassTextField(placeholder: "Organizer", text: $organizer, icon: "person")
                                GlassTextField(placeholder: "Notes", text: $notes, icon: "square.and.pencil")
                                HStack(spacing: 10) {
                                    Group {
                                        if let eventImage {
                                            Image(uiImage: eventImage)
                                                .resizable()
                                                .scaledToFill()
                                        } else {
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color(.systemGray5))
                                                .overlay(
                                                    Image(systemName: "photo")
                                                        .foregroundColor(.secondary)
                                                )
                                        }
                                    }
                                    .frame(width: 56, height: 56)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))

                                    Button(action: { showImagePicker = true }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "photo.on.rectangle.angled")
                                            Text(eventImage == nil ? "Add Image" : "Change Image")
                                        }
                                        .font(.subheadline.bold())
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 12)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(12)
                                    }

                                    if eventImage != nil {
                                        Button("Remove") { eventImage = nil }
                                            .font(.caption.bold())
                                            .foregroundColor(.red)
                                    }
                                }
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Event Placeholder")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    PlaceholderOptionPicker(category: .event, selectedID: selectedEventIconID) { option in
                                        selectedEventIconID = option.id
                                        eventImage = nil
                                    }
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Costumes")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        SleekSectionBody {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(costumes) { costume in
                                    HStack {
                                        Button(action: {
                                            if selectedCostumes[costume.id] != nil {
                                                selectedCostumes.removeValue(forKey: costume.id)
                                            } else {
                                                selectedCostumes[costume.id] = 1
                                            }
                                        }) {
                                            Image(systemName: selectedCostumes[costume.id] != nil ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(selectedCostumes[costume.id] != nil ? .blue : .gray)
                                        }
                                        Text(costume.name)
                                        Spacer()
                                        if let qty = selectedCostumes[costume.id] {
                                            Stepper("", value: Binding(
                                                get: { qty },
                                                set: { newValue in
                                                    selectedCostumes[costume.id] = min(max(1, newValue), costume.totalQuantity)
                                                }
                                            ), in: 1...costume.totalQuantity)
                                            Text("\(qty)/\(costume.totalQuantity)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
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
                    Button("Save") {
                        let event = Event(
                            id: editEvent?.id ?? UUID(),
                            name: name,
                            date: date,
                            isAllDay: isAllDay,
                            isCompleted: isCompleted,
                            organizer: organizer,
                            assignedCostumes: assignedCostumeList,
                            notes: notes.isEmpty ? nil : notes,
                            iconID: selectedEventIconID,
                            imageData: eventImage?.jpegData(compressionQuality: 0.85)
                        )
                        if editEvent == nil {
                            inventoryVM.addEvent(event)
                        } else {
                            inventoryVM.updateEvent(event)
                        }
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(name.isEmpty || organizer.isEmpty)
                }
            }
            .onAppear {
                if let event = editEvent {
                    name = event.name
                    date = event.date
                    organizer = event.organizer
                    isAllDay = event.isAllDay
                    isCompleted = event.isCompleted
                    notes = event.notes ?? ""
                    selectedEventIconID = event.iconID ?? selectedEventIconID
                    eventImage = event.imageData.flatMap(UIImage.init(data:))
                    selectedCostumes = Dictionary(
                        uniqueKeysWithValues: event.assignedCostumes.map { ($0.costumeID, $0.quantity) }
                    )
                }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $eventImage)
        }
    }
}
