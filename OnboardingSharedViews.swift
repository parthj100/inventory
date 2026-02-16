import SwiftUI

// MARK: - Onboarding Step Title
struct OnboardingStepTitle: View {
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title2.bold())
            Text(subtitle)
                .foregroundColor(.gray)
                .font(.body)
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Floating Label TextField
struct FloatingLabelTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline.bold())
            GlassTextField(placeholder: placeholder, text: $text, icon: icon)
        }
    }
}

// MARK: - Floating Label Picker
struct FloatingLabelPicker: View {
    let label: String
    @Binding var selection: String
    let options: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline.bold())
            Picker(label, selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
    }
}

// MARK: - Floating Label Stepper
struct FloatingLabelStepper: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline.bold())
            HStack {
                Stepper("", value: $value, in: range)
                Text("\(value)")
                    .font(.body)
                    .padding(.horizontal, 12)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
    }
}

// MARK: - Floating Label Location Picker
struct FloatingLabelLocationPicker: View {
    let label: String
    @Binding var selection: UUID?
    let locations: [Location]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline.bold())
            Picker(label, selection: $selection) {
                ForEach(locations) { loc in
                    let detail = loc.detailLine
                    Text(detail.isEmpty ? loc.name : "\(loc.name) • \(detail)").tag(Optional(loc.id))
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
    }
}

// MARK: - Floating Label Image Picker
struct FloatingLabelImagePicker: View {
    let label: String
    @Binding var image: UIImage?
    @Binding var showImagePicker: Bool
    var accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline.bold())
            HStack {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.gray)
                }
                Button("Choose Photo") { showImagePicker = true }
                if image != nil {
                    Button(action: { image = nil }) {
                        Image(systemName: "trash")
                            .symbolRenderingMode(.monochrome)
                            .foregroundStyle(Color.red)
                            .frame(width: 40, height: 40)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 8)
                }
            }
        }
    }
}

// MARK: - Add Location Sheet
struct AddLocationSheet: View {
    @EnvironmentObject var inventoryVM: InventoryViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var name = ""
    @State private var room = ""
    @State private var storageType: StorageType = .box
    @State private var storageLabel = ""
    @State private var image: UIImage? = nil
    @State private var showImagePicker = false
    @State private var selectedPlaceholderID: String = PlaceholderArtwork.locationOptions.first?.id ?? "loc_hanger"
    var onSave: (Location) -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Add Location")
                    .font(.title2.bold())
                GlassTextField(placeholder: "Location Name", text: $name, icon: "mappin.and.ellipse")
                GlassTextField(placeholder: "Room", text: $room, icon: "door.left.hand.open")
                Text("Storage Type")
                    .font(.subheadline.bold())
                Picker("Storage Type", selection: $storageType) {
                    ForEach(StorageType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                GlassTextField(placeholder: "Box / Rack / Label (optional)", text: $storageLabel, icon: "shippingbox")
                HStack(spacing: 12) {
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 64, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray5))
                            .frame(width: 64, height: 64)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.secondary)
                            )
                    }
                    Button(action: { showImagePicker = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "photo.on.rectangle.angled")
                            Text(image == nil ? "Add Photo" : "Change Photo")
                        }
                        .font(.subheadline.bold())
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Built-in Placeholders")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    PlaceholderOptionPicker(category: .location) { option in
                        selectedPlaceholderID = option.id
                        if let data = PlaceholderArtwork.imageData(for: option) {
                            image = UIImage(data: data)
                        }
                    }
                }
                Spacer()
            }
            .padding()
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let finalImageData = image?.jpegData(compressionQuality: 0.8)
                            ?? PlaceholderArtwork.imageData(
                                for: PlaceholderArtwork.option(id: selectedPlaceholderID, category: .location)
                            )
                        let location = Location(name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                                                room: room.trimmingCharacters(in: .whitespacesAndNewlines),
                                                storageType: storageType,
                                                storageLabel: storageLabel.trimmingCharacters(in: .whitespacesAndNewlines),
                                                imageData: finalImageData)
                        inventoryVM.addLocation(location)
                        onSave(location)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $image)
        }
    }
}

// MARK: - StepCostumeSummary
struct StepCostumeSummary: View {
    let name: String
    let size: String
    let color: String
    let category: String
    let totalQuantity: Int
    let location: Location?
    let notes: String
    let image: UIImage?
    var accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let image = image {
                HStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    Spacer()
                }
            }
            Group {
                Text("Name: \(name)")
                Text("Size: \(size)")
                Text("Color: \(color)")
                Text("Category: \(category)")
                Text("Total Quantity: \(totalQuantity)")
                if let location {
                    let detail = location.detailLine
                    Text("Location: \(detail.isEmpty ? location.name : "\(location.name) • \(detail)")")
                } else {
                    Text("Location: N/A")
                }
                if !notes.isEmpty {
                    Text("Notes: \(notes)")
                }
            }
            .font(.body)
        }
    }
}

struct StepCostumeQuantityPicker: View {
    @EnvironmentObject var inventoryVM: InventoryViewModel
    @Binding var selectedCostumes: [UUID: Int]
    var accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(inventoryVM.costumes) { costume in
                HStack {
                    Button(action: {
                        if selectedCostumes[costume.id] != nil {
                            selectedCostumes.removeValue(forKey: costume.id)
                        } else {
                            selectedCostumes[costume.id] = 1
                        }
                    }) {
                        Image(systemName: selectedCostumes[costume.id] != nil ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedCostumes[costume.id] != nil ? accent : .gray)
                    }
                    Text(costume.name)
                        .foregroundColor(.primary)
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
                .padding(.vertical, 2)
            }
        }
    }
}

// MARK: - Review Components
struct ReviewCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            content
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct ReviewRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 110, alignment: .leading)
            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
            Spacer()
        }
    }
}

// MARK: - Liquid Glass Levels
enum GlassLevel {
    case primary
    case secondary
    case none
}

struct GlassSurface: View {
    let level: GlassLevel
    let tint: Color
    let cornerRadius: CGFloat

    var body: some View {
        switch level {
        case .none:
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.clear)
        case .primary:
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .glassEffect(.regular.tint(tint).interactive(), in: .rect(cornerRadius: cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.28), lineWidth: 1)
                )
        case .secondary:
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .glassEffect(.regular.tint(tint), in: .rect(cornerRadius: cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
        }
    }
}

// MARK: - Liquid Glass Row Background
struct GlassRowBackground: View {
    var tint: Color = Color.white.opacity(0.2)
    var cornerRadius: CGFloat = 14

    var body: some View {
        GlassSurface(level: .secondary, tint: tint, cornerRadius: cornerRadius)
    }
}

// MARK: - Liquid Glass Text Field
struct GlassTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 8) {
            if let icon {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
            }
            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.sentences)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .glassEffect(.regular, in: .rect(cornerRadius: 18.0))
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.001))
                .shadow(color: Color.black.opacity(0.16), radius: 16, x: 0, y: 10)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.25), lineWidth: 1)
        )
    }
}

// MARK: - Glass Icon Button
struct GlassIconButton: View {
    let systemName: String
    var iconColor: Color = .primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .glassEffect(.regular.interactive(), in: .circle)
                    .tint(.clear)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    )
                Image(systemName: systemName)
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(iconColor)
            }
            .frame(width: 40, height: 40)
        }
        .buttonStyle(.plain)
        .tint(.clear)
    }
}

struct FloatingLabelDatePicker: View {
    let label: String
    @Binding var date: Date
    var accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline.bold())
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.gray)
                DatePicker(
                    "",
                    selection: $date,
                    displayedComponents: .date
                )
                .labelsHidden()
                .datePickerStyle(.compact)
                .frame(maxWidth: .infinity)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
    }
}

// MARK: - Floating Label Time Picker
struct FloatingLabelTimePicker: View {
    let label: String
    @Binding var time: Date
    var accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline.bold())
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.gray)
                DatePicker(
                    "",
                    selection: $time,
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
                .datePickerStyle(.compact)
                .frame(maxWidth: .infinity)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
    }
}
