import SwiftUI

struct CostumeEditView: View {
    @EnvironmentObject var inventoryVM: InventoryViewModel
    @Environment(\.presentationMode) var presentationMode

    var editCostume: Costume

    @State private var name: String
    @State private var size: String
    @State private var color: String
    @State private var category: String
    @State private var totalQuantity: Int
    @State private var selectedLocationID: UUID
    @State private var notes: String
    @State private var images: [UIImage] = []
    @State private var showImagePicker = false
    @State private var selectedPlaceholderID: String = PlaceholderArtwork.costumeOptions.first?.id ?? "cos_shirt"
    @State private var showAddLocation = false
    @State private var pendingLocationID: UUID? = nil

    let sizeOptions = ["XS", "S", "M", "L", "XL", "Custom"]
    let colorOptions = ["Red", "Blue", "Green", "Black", "White", "Other"]
    let categoryOptions = ["Dance", "Drama", "Prop", "Accessory"]

    init(editCostume: Costume) {
        self.editCostume = editCostume
        _name = State(initialValue: editCostume.name)
        _size = State(initialValue: editCostume.size)
        _color = State(initialValue: editCostume.color)
        _category = State(initialValue: editCostume.category)
        _totalQuantity = State(initialValue: editCostume.totalQuantity)
        _selectedLocationID = State(initialValue: editCostume.location.id)
        _notes = State(initialValue: editCostume.notes ?? "")
        // Pre-fill images from imageDatas
        _images = State(initialValue: editCostume.imageDatas.compactMap { $0.cachedUIImage })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                let checkedOutCount = editCostume.checkOuts.map { $0.quantity }.reduce(0, +)
                let minTotal = max(1, checkedOutCount)
                let maxTotal = max(100, minTotal)

                VStack(alignment: .leading, spacing: 18) {
                    Text("Edit Costume")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 12)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Photos")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        SleekSectionBody {
                            VStack(alignment: .leading, spacing: 12) {
                                if !images.isEmpty {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach(0..<images.count, id: \.self) { idx in
                                                ZStack(alignment: .topTrailing) {
                                                    Image(uiImage: images[idx])
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(width: 64, height: 64)
                                                        .padding(3)
                                                        .background(Color.white.opacity(0.6))
                                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                                    Button(action: { images.remove(at: idx) }) {
                                                        Image(systemName: "xmark.circle.fill")
                                                            .foregroundColor(.red)
                                                            .background(Color.white.clipShape(Circle()))
                                                    }
                                                    .padding(4)
                                                }
                                                .padding(.trailing, 4)
                                            }
                                        }
                                    }
                                }
                                Button(action: { showImagePicker = true }) {
                                    HStack {
                                        Image(systemName: "photo.on.rectangle.angled")
                                        Text(images.isEmpty ? "Choose Photos" : "Manage Photos")
                                    }
                                    .font(.subheadline.bold())
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 14)
                                    .background(Color.blue.opacity(0.12))
                                    .cornerRadius(12)
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
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Costume Info")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        SleekSectionBody {
                            VStack(alignment: .leading, spacing: 12) {
                                GlassTextField(placeholder: "Name", text: $name, icon: "tag")
                                Picker("Size", selection: $size) {
                                    ForEach(sizeOptions, id: \.self) { option in
                                        Text(option).tag(option)
                                    }
                                }
                                Picker("Color", selection: $color) {
                                    ForEach(colorOptions, id: \.self) { option in
                                        Text(option).tag(option)
                                    }
                                }
                                Picker("Category", selection: $category) {
                                    ForEach(categoryOptions, id: \.self) { option in
                                        Text(option).tag(option)
                                    }
                                }
                                Stepper("Total Quantity: \(totalQuantity)", value: $totalQuantity, in: minTotal...maxTotal)
                                Text("Available: \(editCostume.availableQuantity) / \(totalQuantity)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                if totalQuantity < checkedOutCount {
                                    Text("Total quantity cannot be below checked-out count (\(checkedOutCount)).")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                                Picker("Location", selection: $selectedLocationID) {
                                    ForEach(inventoryVM.locations) { loc in
                                        let detail = loc.detailLine
                                        Text(detail.isEmpty ? loc.name : "\(loc.name) • \(detail)").tag(loc.id)
                                    }
                                }
                                Button(action: { showAddLocation = true }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "plus")
                                        Text("Add Location")
                                    }
                                    .font(.subheadline.bold())
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Color.blue.opacity(0.12))
                                    .foregroundColor(.blue)
                                    .cornerRadius(10)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                GlassTextField(placeholder: "Notes", text: $notes, icon: "square.and.pencil")
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePickerGallery(images: $images)
            }
            .sheet(isPresented: $showAddLocation, onDismiss: {
                if let id = pendingLocationID {
                    selectedLocationID = id
                }
                pendingLocationID = nil
            }) {
                AddLocationSheet { location in
                    pendingLocationID = location.id
                }
                .environmentObject(inventoryVM)
            }
            .background(
                LinearGradient(
                    colors: [Color(.systemGray6), Color.white],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let location = inventoryVM.locations.first(where: { $0.id == selectedLocationID }) else { return }
                        let updatedCostume = Costume(
                            id: editCostume.id,
                            name: name,
                            size: size,
                            color: color,
                            category: category,
                            totalQuantity: totalQuantity,
                            location: location,
                            status: editCostume.status,
                            notes: notes.isEmpty ? nil : notes,
                            checkOuts: editCostume.checkOuts,
                            imageDatas: images.isEmpty
                                ? (editCostume.imageDatas.isEmpty
                                    ? [PlaceholderArtwork.imageData(
                                        for: PlaceholderArtwork.option(id: selectedPlaceholderID, category: .costume)
                                      ) ?? Data()]
                                    : editCostume.imageDatas)
                                : images.map { $0.jpegData(compressionQuality: 0.8) ?? Data() } // preserve current check-outs!
                        )
                        inventoryVM.updateCostume(updatedCostume)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(name.isEmpty || size.isEmpty || color.isEmpty || category.isEmpty)
                }
            }
        }
    }
}
