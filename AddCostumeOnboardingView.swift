import SwiftUI

// MARK: - ButtonGridPicker (Reusable)
struct ButtonGridPicker<T: Hashable & CustomStringConvertible>: View {
    let options: [T]
    @Binding var selection: T
    let columns: Int

    var body: some View {
        let gridItems = Array(repeating: GridItem(.flexible(), spacing: 16), count: columns)
        LazyVGrid(columns: gridItems, spacing: 16) {
            ForEach(options, id: \.self) { option in
                Button(action: { selection = option }) {
                    Text(option.description)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(selection == option ? Color.blue.opacity(0.12) : Color(.systemGray6))
                        .foregroundColor(selection == option ? .blue : .primary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selection == option ? Color.blue : Color(.systemGray4), lineWidth: 2)
                        )
                        .cornerRadius(12)
                }
            }
        }
        .padding(.horizontal, 12)
    }
}

extension Location: CustomStringConvertible {
    public var description: String { name }
}

struct AddCostumeOnboardingView: View {
    @EnvironmentObject var inventoryVM: InventoryViewModel
    @Environment(\.presentationMode) var presentationMode

    enum Step: Int, CaseIterable {
        case basics, attributes, details, confirm
    }

    @State private var step: Step = .basics
    @State private var name = ""
    @State private var size = "M"
    @State private var color = "Black"
    @State private var category = "Dance"
    @State private var totalQuantity = 1
    @State private var selectedLocationIndex = 0
    @State private var images: [UIImage] = []
    @State private var selectedPlaceholderID: String = PlaceholderArtwork.costumeOptions.first?.id ?? "cos_shirt"
    @State private var showImagePicker = false
    @State private var showAddLocation = false
    @State private var pendingLocationID: UUID? = nil

    let sizeOptions = ["XS", "S", "M", "L", "XL", "Custom"]
    let colorOptions = ["Red", "Blue", "Green", "Black", "White", "Other"]
    let categoryOptions = ["Dance", "Drama", "Prop", "Accessory"]
    let quantityOptions = Array(1...16)
    let accent = Color.blue

    var locationOptions: [Location] { inventoryVM.locations }
    var selectedLocation: Location? {
        locationOptions.indices.contains(selectedLocationIndex) ? locationOptions[selectedLocationIndex] : nil
    }

    private func storagePlacementLabel(for location: Location) -> String {
        let label = location.storageLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        switch location.storageType {
        case .box:
            return label.isEmpty ? "Box" : "Box \(label)"
        case .hanging:
            return label.isEmpty ? "Hanging" : "Hanging \(label)"
        case .shelf:
            return label.isEmpty ? "Shelf" : "Shelf \(label)"
        case .rack:
            return label.isEmpty ? "Rack" : "Rack \(label)"
        case .other:
            return label.isEmpty ? "Storage" : label
        }
    }

    private func locationSelectionLabel(_ location: Location) -> String {
        let room = location.room.trimmingCharacters(in: .whitespacesAndNewlines)
        let placement = storagePlacementLabel(for: location)
        return room.isEmpty ? placement : "\(room) • \(placement)"
    }

    var body: some View {
        GeometryReader { geo in
            let cardWidth: CGFloat = max(320, min(420, geo.size.width - 32))
            let cardHeight: CGFloat = max(420, min(540, geo.size.height - 140))
            ZStack {
                Color.white.ignoresSafeArea()
                VStack {
                    Spacer(minLength: 0)
                    VStack(spacing: 0) {
                    // Header
                    HStack {
                        Label("Add Costume", systemImage: "tshirt")
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
                    Group {
                        switch step {
                        case .basics:
                            VStack(alignment: .leading, spacing: 24) {
                                OnboardingStepTitle(
                                    title: "Costume Basics",
                                    subtitle: "Name and category"
                                )
                                FloatingLabelTextField(
                                    label: "Costume Name",
                                    placeholder: "e.g. Pirate Outfit",
                                    text: $name,
                                    icon: "tag"
                                )
                                ButtonGridPicker(
                                    options: categoryOptions,
                                    selection: $category,
                                    columns: 2
                                )
                                .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .padding(.top, 24)

                        case .attributes:
                            VStack(alignment: .leading, spacing: 24) {
                                OnboardingStepTitle(
                                    title: "Attributes",
                                    subtitle: "Size, color, and quantity"
                                )
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Size")
                                        .font(.subheadline.bold())
                                    HStack {
                                        Text(size)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                    }
                                    Slider(
                                        value: Binding<Double>(
                                            get: { Double(sizeOptions.firstIndex(of: size) ?? 0) },
                                            set: { size = sizeOptions[Int($0.rounded())] }
                                        ),
                                        in: 0...Double(max(0, sizeOptions.count - 1)),
                                        step: 1
                                    )
                                }
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Color")
                                        .font(.subheadline.bold())
                                    HStack {
                                        Text(color)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                    }
                                    Slider(
                                        value: Binding<Double>(
                                            get: { Double(colorOptions.firstIndex(of: color) ?? 0) },
                                            set: { color = colorOptions[Int($0.rounded())] }
                                        ),
                                        in: 0...Double(max(0, colorOptions.count - 1)),
                                        step: 1
                                    )
                                }
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Quantity")
                                        .font(.subheadline.bold())
                                    HStack {
                                        Text("\(totalQuantity)")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                    }
                                    Slider(
                                        value: Binding<Double>(
                                            get: { Double(totalQuantity) },
                                            set: { totalQuantity = Int($0.rounded()) }
                                        ),
                                        in: 1...Double(quantityOptions.last ?? 1),
                                        step: 1
                                    )
                                }
                            }
                            .padding(.top, 24)

                        case .details:
                            VStack(alignment: .leading, spacing: 24) {
                                OnboardingStepTitle(
                                    title: "Details",
                                    subtitle: "Location and photos"
                                )
                                let gridItems = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
                                LazyVGrid(columns: gridItems, spacing: 16) {
                                    ForEach(Array(locationOptions.enumerated()), id: \.element.id) { idx, location in
                                        Button(action: { selectedLocationIndex = idx }) {
                                            VStack(spacing: 6) {
                                                Text(locationSelectionLabel(location))
                                                    .fontWeight(.medium)
                                                    .multilineTextAlignment(.center)
                                                    .lineLimit(2)
                                            }
                                            .frame(maxWidth: .infinity, minHeight: 56)
                                            .background(selectedLocationIndex == idx ? Color.blue.opacity(0.12) : Color(.systemGray6))
                                            .foregroundColor(selectedLocationIndex == idx ? .blue : .primary)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(selectedLocationIndex == idx ? Color.blue : Color(.systemGray4), lineWidth: 2)
                                            )
                                            .cornerRadius(12)
                                        }
                                    }
                                    Button(action: { showAddLocation = true }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "plus")
                                            Text("Add Location")
                                        }
                                        .fontWeight(.medium)
                                        .frame(maxWidth: .infinity, minHeight: 44)
                                        .background(Color.blue.opacity(0.12))
                                        .foregroundColor(.blue)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.blue.opacity(0.6), lineWidth: 2)
                                        )
                                        .cornerRadius(12)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Photos")
                                        .font(.subheadline.bold())
                                    Button(action: { showImagePicker = true }) {
                                        HStack {
                                            Image(systemName: "photo.on.rectangle.angled")
                                            Text(images.isEmpty ? "Choose Photos" : "Manage Photos")
                                        }
                                        .font(.headline)
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 14)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(12)
                                    }
                                    if images.isEmpty {
                                        Text("Add up to 10 photos.")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    } else {
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 10) {
                                                ForEach(0..<images.count, id: \.self) { idx in
                                                    Image(uiImage: images[idx])
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(width: 56, height: 56)
                                                        .padding(3)
                                                        .background(Color.white.opacity(0.6))
                                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                                }
                                            }
                                        }
                                        HStack(spacing: 12) {
                                            Button("Remove All") { images.removeAll() }
                                                .font(.subheadline.bold())
                                                .foregroundColor(.red)
                                        }
                                    }
                                    Text("Built-in Placeholders")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    PlaceholderOptionPicker(category: .costume) { option in
                                        selectedPlaceholderID = option.id
                                        if let data = PlaceholderArtwork.imageData(for: option),
                                           let placeholderImage = UIImage(data: data) {
                                            images = [placeholderImage]
                                        }
                                    }
                                }
                            }
                            .sheet(isPresented: $showImagePicker) {
                                ImagePickerGallery(images: $images)
                            }

                        case .confirm:
                            VStack(alignment: .leading, spacing: 24) {
                                OnboardingStepTitle(
                                    title: "Review Costume",
                                    subtitle: "Review and confirm all costume details"
                                )
                                VStack(spacing: 14) {
                                    if !images.isEmpty {
                                        TabView {
                                            ForEach(0..<images.count, id: \.self) { idx in
                                                Image(uiImage: images[idx])
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 120, height: 120)
                                                    .padding(4)
                                                    .background(Color.white.opacity(0.6))
                                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                                    .shadow(radius: 4)
                                            }
                                        }
                                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                                        .frame(height: 140)
                                    }
                                    ReviewCard {
                                        ReviewRow(label: "Name", value: name)
                                        ReviewRow(label: "Size", value: size)
                                        ReviewRow(label: "Color", value: color)
                                        ReviewRow(label: "Category", value: category)
                                        ReviewRow(label: "Total Quantity", value: "\(totalQuantity)")
                                        ReviewRow(label: "Location", value: selectedLocation.map { loc in
                                            let detail = loc.detailLine
                                            return detail.isEmpty ? loc.name : "\(loc.name) • \(detail)"
                                        } ?? "N/A")
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                            .padding(.top, 24)
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
                            Button(action: { addCostume() }) {
                                HStack {
                                    Text("Add Costume")
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
                .frame(maxWidth: .infinity, minHeight: cardHeight)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .sheet(isPresented: $showImagePicker) {
                ImagePickerGallery(images: $images)
            }
        }
        .onAppear {
            if selectedLocationIndex == 0 && !locationOptions.isEmpty {
                selectedLocationIndex = 0
            }
        }
        .sheet(isPresented: $showAddLocation, onDismiss: {
            if let id = pendingLocationID,
               let idx = locationOptions.firstIndex(where: { $0.id == id }) {
                selectedLocationIndex = idx
            }
            pendingLocationID = nil
        }) {
            AddLocationSheet { location in
                pendingLocationID = location.id
            }
            .environmentObject(inventoryVM)
        }
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
        case .basics: return !name.isEmpty && !category.isEmpty
        case .attributes: return !size.isEmpty && !color.isEmpty && totalQuantity > 0
        case .details: return selectedLocation != nil
        case .confirm: return true
        }
    }
    private func addCostume() {
        guard let location = selectedLocation else { return }
        let costume = Costume(
            id: UUID(),
            name: name,
            size: size,
            color: color,
            category: category,
            totalQuantity: totalQuantity,
            location: location,
            status: .available,
            notes: nil,
            imageDatas: (images.isEmpty
                         ? [PlaceholderArtwork.imageData(
                            for: PlaceholderArtwork.option(id: selectedPlaceholderID, category: .costume)
                         ) ?? Data()]
                         : images.map { $0.jpegData(compressionQuality: 0.8) ?? Data() })
        )
        inventoryVM.addCostume(costume)
        presentationMode.wrappedValue.dismiss()
    }
}
