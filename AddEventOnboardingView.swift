import SwiftUI

struct AddEventOnboardingView: View {
    @EnvironmentObject var inventoryVM: InventoryViewModel
    @Environment(\.presentationMode) var presentationMode

    // Pass this when editing
    var editEvent: Event? = nil

    enum Step: Int, CaseIterable {
        case basics, schedule, costumes, confirm
    }

    @State private var step: Step = .basics
    @State private var name = ""
    @State private var date = Date()
    @State private var time = Date()
    @State private var isAllDay = false
    @State private var isCompleted = false
    @State private var organizer = ""
    @State private var selectedCostumes: [UUID: Int] = [:]
    @State private var notes = ""
    @State private var categoryIndex = 0
    @State private var selectedEventIconID: String = PlaceholderArtwork.eventOptions.first?.id ?? "evt_calendar"
    @State private var eventImage: UIImage? = nil
    @State private var showImagePicker = false

    let accent = Color.pink
    var costumeOptions: [Costume] { inventoryVM.costumes }
    var categorizedCostumes: [(category: String, items: [Costume])] {
        let grouped = Dictionary(grouping: costumeOptions, by: { $0.category.isEmpty ? "Uncategorized" : $0.category })
        return grouped.keys.sorted().map { key in
            (category: key, items: (grouped[key] ?? []).sorted { $0.name < $1.name })
        }
    }
    var currentCategoryGroup: (category: String, items: [Costume])? {
        guard !categorizedCostumes.isEmpty else { return nil }
        let safeIndex = min(max(categoryIndex, 0), categorizedCostumes.count - 1)
        return categorizedCostumes[safeIndex]
    }
    var assignedCostumeList: [AssignedCostume] {
        costumeOptions
            .filter { selectedCostumes[$0.id] != nil }
            .map { AssignedCostume(costumeID: $0.id, costumeName: $0.name, quantity: selectedCostumes[$0.id] ?? 1) }
    }

    var body: some View {
        GeometryReader { geo in
            let cardWidth: CGFloat = max(320, min(420, geo.size.width - 32))
            let cardHeight: CGFloat = max(420, min(540, geo.size.height - 140))
            ZStack {
                Color.white.ignoresSafeArea()
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Label(editEvent == nil ? "Create New Event" : "Edit Event", systemImage: "calendar")
                            .font(.title2.bold())
                            .foregroundColor(accent)
                        Spacer()
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.top, 28)
                    .padding(.horizontal, 28)

                    // Progress bar and step
                    VStack(alignment: .leading, spacing: 8) {
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color(.systemGray5))
                                .frame(height: 6)
                            Capsule()
                                .fill(accent)
                                .frame(
                                    width: (cardWidth - 56) *
                                        CGFloat(step.rawValue + 1) / CGFloat(Step.allCases.count),
                                    height: 6
                                )
                                .animation(.easeInOut, value: step)
                        }
                        HStack {
                            Spacer()
                            Text("Step \(step.rawValue + 1) of \(Step.allCases.count)")
                                .font(.caption)
                                .foregroundColor(accent)
                        }
                    }
                    .padding(.top, 12)
                    .padding(.horizontal, 28)

                    // Step content with fade animation
                    ScrollView(showsIndicators: false) {
                        Group {
                            switch step {
                            case .basics:
                                VStack(alignment: .leading, spacing: 24) {
                                    OnboardingStepTitle(
                                        title: "Event Basics",
                                        subtitle: "Name and organizer"
                                    )
                                FloatingLabelTextField(
                                    label: "Event Name",
                                    placeholder: "e.g. Summer Theater Production",
                                    text: $name,
                                    icon: "calendar"
                                )
                                FloatingLabelTextField(
                                    label: "Organizer Name",
                                    placeholder: "e.g. John Doe",
                                    text: $organizer,
                                    icon: "person"
                                )
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Event Image")
                                        .font(.subheadline.bold())
                                    HStack(spacing: 12) {
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
                                }
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Built-in Placeholders")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    PlaceholderOptionPicker(category: .event, selectedID: selectedEventIconID) { option in
                                        selectedEventIconID = option.id
                                        eventImage = nil
                                    }
                                }
                                }
                                .padding(.top, 24)

                            case .schedule:
                                VStack(alignment: .leading, spacing: 24) {
                                    OnboardingStepTitle(
                                        title: "Schedule",
                                        subtitle: "Date and time"
                                    )
                                    FloatingLabelDatePicker(
                                        label: "Event Date",
                                        date: $date,
                                        accent: accent
                                    )
                                    Toggle("All Day", isOn: $isAllDay)
                                        .toggleStyle(SwitchToggleStyle(tint: accent))
                                    if !isAllDay {
                                        FloatingLabelTimePicker(
                                            label: "Event Time",
                                            time: $time,
                                            accent: accent
                                        )
                                    }
                                }
                                .padding(.top, 24)

                            case .costumes:
                                VStack(alignment: .leading, spacing: 24) {
                                    OnboardingStepTitle(
                                        title: "Assign Costumes",
                                        subtitle: "Pick by category and set quantities"
                                    )
                                    if let group = currentCategoryGroup {
                                        HStack {
                                            Button(action: {
                                                categoryIndex = max(0, categoryIndex - 1)
                                            }) {
                                                HStack(spacing: 6) {
                                                    Image(systemName: "chevron.left")
                                                    Text("Prev")
                                                }
                                                .font(.subheadline.bold())
                                            }
                                            .disabled(categoryIndex == 0)
                                            Spacer()
                                            VStack(spacing: 2) {
                                                Text(group.category)
                                                    .font(.headline)
                                                Text("Category \(categoryIndex + 1) of \(categorizedCostumes.count)")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            Spacer()
                                            Button(action: {
                                                categoryIndex = min(categorizedCostumes.count - 1, categoryIndex + 1)
                                            }) {
                                                HStack(spacing: 6) {
                                                    Text("Next")
                                                    Image(systemName: "chevron.right")
                                                }
                                                .font(.subheadline.bold())
                                            }
                                            .disabled(categoryIndex >= categorizedCostumes.count - 1)
                                        }
                                        .padding(.horizontal, 4)

                                        VStack(spacing: 12) {
                                            ForEach(group.items) { costume in
                                                let available = max(0, costume.availableQuantity)
                                                let qtyBinding = Binding<Int>(
                                                    get: { selectedCostumes[costume.id] ?? 0 },
                                                    set: { newValue in
                                                        if newValue <= 0 {
                                                            selectedCostumes.removeValue(forKey: costume.id)
                                                        } else {
                                                            selectedCostumes[costume.id] = min(newValue, available)
                                                        }
                                                    }
                                                )

                                                HStack(spacing: 12) {
                                                    if let data = costume.imageDatas.first, let uiImage = data.cachedUIImage {
                                                        Image(uiImage: uiImage)
                                                            .resizable()
                                                            .scaledToFit()
                                                            .frame(width: 44, height: 44)
                                                            .padding(4)
                                                            .background(Color.white.opacity(0.55))
                                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                                    } else {
                                                        Image(systemName: "tshirt.fill")
                                                            .resizable()
                                                            .scaledToFit()
                                                            .frame(width: 28, height: 28)
                                                            .foregroundColor(accent)
                                                            .frame(width: 44, height: 44)
                                                            .background(Color.white.opacity(0.5))
                                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                                    }
                                                    VStack(alignment: .leading, spacing: 4) {
                                                        Text(costume.name)
                                                            .fontWeight(.semibold)
                                                        Text("Available: \(costume.availableQuantity)/\(costume.totalQuantity)")
                                                            .font(.caption)
                                                            .foregroundColor(.secondary)
                                                    }
                                                    Spacer()
                                                    VStack(alignment: .trailing, spacing: 4) {
                                                        Text("Qty \(qtyBinding.wrappedValue)")
                                                            .font(.caption)
                                                            .foregroundColor(.secondary)
                                                        Stepper(
                                                            "",
                                                            value: qtyBinding,
                                                            in: 0...max(0, available)
                                                        )
                                                        .labelsHidden()
                                                        .disabled(available == 0)
                                                    }
                                                }
                                                .padding(12)
                                                .background(qtyBinding.wrappedValue > 0 ? accent.opacity(0.08) : Color(.systemGray6))
                                                .cornerRadius(12)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(qtyBinding.wrappedValue > 0 ? accent : Color(.systemGray4), lineWidth: 1.5)
                                                )
                                                .onTapGesture {
                                                    if available > 0 && qtyBinding.wrappedValue == 0 {
                                                        qtyBinding.wrappedValue = 1
                                                    }
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 12)
                                    } else {
                                        Text("No costumes available.")
                                            .foregroundColor(.secondary)
                                    }

                                    GlassTextField(
                                        placeholder: "Notes (optional)",
                                        text: $notes,
                                        icon: "square.and.pencil"
                                    )
                                }
                                .padding(.top, 24)

                            case .confirm:
                                VStack(alignment: .leading, spacing: 24) {
                                    OnboardingStepTitle(
                                        title: "Review Event",
                                        subtitle: "Review and confirm all event details"
                                    )
                                    VStack(spacing: 14) {
                                        ReviewCard {
                                            ReviewRow(label: "Name", value: name)
                                            ReviewRow(label: "Date", value: date.formatted(date: .long, time: .omitted))
                                            ReviewRow(label: "Time", value: isAllDay ? "All Day" : time.formatted(date: .omitted, time: .shortened))
                                            ReviewRow(label: "Organizer", value: organizer)
                                        }
                                        ReviewCard {
                                            ReviewRow(label: "Costumes", value: assignedCostumeList.isEmpty ? "None" : "")
                                            if assignedCostumeList.isEmpty {
                                                Text("No costumes assigned.")
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                            } else {
                                                ForEach(assignedCostumeList) { assigned in
                                                    HStack(spacing: 10) {
                                                        if let costume = inventoryVM.latestCostume(for: assigned.costumeID),
                                                           let data = costume.imageDatas.first,
                                                           let uiImage = data.cachedUIImage {
                                                            Image(uiImage: uiImage)
                                                                .resizable()
                                                                .scaledToFit()
                                                                .frame(width: 32, height: 32)
                                                                .padding(2)
                                                                .background(Color.white.opacity(0.55))
                                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                        } else {
                                                            Image(systemName: "tshirt.fill")
                                                                .foregroundColor(.pink)
                                                        }
                                                        Text(inventoryVM.latestCostume(for: assigned.costumeID)?.name ?? assigned.costumeName)
                                                            .font(.subheadline)
                                                        Spacer()
                                                        Text("x\(assigned.quantity)")
                                                            .font(.subheadline)
                                                            .foregroundColor(.secondary)
                                                    }
                                                    .padding(.vertical, 4)
                                                }
                                            }
                                        }
                                        if !notes.isEmpty {
                                            ReviewCard {
                                                ReviewRow(label: "Notes", value: notes)
                                            }
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                                .padding(.top, 24)
                            }
                        }
                    }
                    .transition(.opacity)
                    .animation(.easeInOut, value: step)
                    .padding(.vertical, 18)
                    .padding(.horizontal, 28)
                    .frame(maxWidth: .infinity, minHeight: cardHeight, alignment: .top)
                    .padding(.bottom, 32)

                    // Buttons (just below content)
                    HStack(spacing: 16) {
                        if step == .basics {
                            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                                Text("Cancel")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color(.systemGray6))
                                    .foregroundColor(.black)
                                    .cornerRadius(12)
                            }
                        } else {
                            Button(action: { previousStep() }) {
                                HStack {
                                    Image(systemName: "arrow.left")
                                    Text("Back")
                                }
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray6))
                                .foregroundColor(.black)
                                .cornerRadius(12)
                            }
                        }
                        if step != .confirm {
                            Button(action: { nextStep() }) {
                                HStack {
                                    Text("Next")
                                    Image(systemName: "arrow.right")
                                }
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(accent)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(!canGoNext)
                        } else {
                            Button(action: { addEvent() }) {
                                HStack {
                                    Text("Add Event")
                                    Image(systemName: "checkmark")
                                }
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(accent)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(!canGoNext)
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 32)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.top, 8)
            }
        }
        .onAppear {
            if let event = editEvent {
                name = event.name
                date = event.date
                time = event.date
                isAllDay = event.isAllDay
                isCompleted = event.isCompleted
                organizer = event.organizer
                notes = event.notes ?? ""
                selectedCostumes = Dictionary(
                    uniqueKeysWithValues: event.assignedCostumes.map { ($0.costumeID, $0.quantity) }
                )
                selectedEventIconID = event.iconID ?? selectedEventIconID
                eventImage = event.imageData.flatMap(UIImage.init(data:))
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $eventImage)
        }
    }

    private func nextStep() {
        if let next = Step(rawValue: step.rawValue + 1) {
            step = next
        }
    }
    private func previousStep() {
        if let prev = Step(rawValue: step.rawValue - 1) {
            step = prev
        }
    }
    private var canGoNext: Bool {
        switch step {
        case .basics: return !name.isEmpty && !organizer.isEmpty
        case .schedule: return true
        case .costumes: return true
        case .confirm: return true
        }
    }
    private func addEvent() {
        let eventDateTime: Date
        if isAllDay {
            eventDateTime = Calendar.current.startOfDay(for: date)
        } else {
            eventDateTime = Calendar.current.date(
                bySettingHour: Calendar.current.component(.hour, from: time),
                minute: Calendar.current.component(.minute, from: time),
                second: 0,
                of: date
            ) ?? date
        }

        let event = Event(
            id: editEvent?.id ?? UUID(),
            name: name,
            date: eventDateTime,
            isAllDay: isAllDay,
            isCompleted: editEvent?.isCompleted ?? isCompleted,
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
}
