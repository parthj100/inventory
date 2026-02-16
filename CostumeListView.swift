import SwiftUI

struct CostumeListView: View {
    @EnvironmentObject var inventoryVM: InventoryViewModel
    @Binding var statusFilter: InventoryStatusFilter
    @State private var showAdd = false
    @State private var galleryMode = false
    @State private var showEditSheet: Costume? = nil
    @State private var showManageLocations = false
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var selectedLocationID: UUID? = nil
    @State private var sortOption: InventorySortOption = .name
    @State private var selectionMode = false
    @State private var selectedCostumeIDs: Set<UUID> = []
    @State private var showMoveSheet = false
    @State private var moveTargetLocationID: UUID? = nil
    @State private var showMoveResultAlert = false
    @State private var moveResultMessage = ""
    @State private var quickMoveCostume: Costume? = nil
    @State private var quickMoveTargetLocationID: UUID? = nil

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var filteredCostumes: [Costume] {
        var result = inventoryVM.costumes

        // Status filter
        switch statusFilter {
        case .all:
            break
        case .available:
            result = result.filter { $0.status == .available }
        case .partiallyCheckedOut:
            result = result.filter { $0.status == .partiallyCheckedOut }
        case .checkedOut:
            result = result.filter { $0.status == .checkedOut }
        }

        // Category filter
        if selectedCategory != "All" {
            result = result.filter { $0.category == selectedCategory }
        }

        // Location filter
        if let selectedLocationID {
            result = result.filter { $0.location.id == selectedLocationID }
        }

        // Search
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let query = searchText.lowercased()
            result = result.filter { costume in
                costume.name.lowercased().contains(query) ||
                costume.category.lowercased().contains(query) ||
                costume.color.lowercased().contains(query) ||
                costume.size.lowercased().contains(query) ||
                costume.location.name.lowercased().contains(query) ||
                costume.location.room.lowercased().contains(query) ||
                costume.location.storageLabel.lowercased().contains(query)
            }
        }

        // Sort
        switch sortOption {
        case .name:
            result = result.sorted { $0.name < $1.name }
        case .available:
            result = result.sorted { $0.availableQuantity > $1.availableQuantity }
        case .checkedOut:
            result = result.sorted {
                ($0.totalQuantity - $0.availableQuantity) > ($1.totalQuantity - $1.availableQuantity)
            }
        }

        return result
    }

    var categoryOptions: [String] {
        let categories = Set(inventoryVM.costumes.map { $0.category }.filter { !$0.isEmpty })
        return ["All"] + categories.sorted()
    }

    var locationOptions: [Location] {
        inventoryVM.locations
    }

    var hasActiveFilters: Bool {
        selectedCategory != "All" || selectedLocationID != nil || sortOption != .name
    }

    var selectedCount: Int {
        selectedCostumeIDs.count
    }

    func statusLabel(_ filter: InventoryStatusFilter) -> String {
        switch filter {
        case .all: return "All"
        case .available: return "Avail"
        case .partiallyCheckedOut: return "Partial"
        case .checkedOut: return "Out"
        }
    }

    private func toggleSelection(_ costumeID: UUID) {
        if selectedCostumeIDs.contains(costumeID) {
            selectedCostumeIDs.remove(costumeID)
        } else {
            selectedCostumeIDs.insert(costumeID)
        }
    }

    private func enterSelectionMode(with costumeID: UUID? = nil) {
        selectionMode = true
        if let costumeID {
            selectedCostumeIDs.insert(costumeID)
        }
    }

    private func exitSelectionMode() {
        selectionMode = false
        selectedCostumeIDs.removeAll()
    }

    private func selectAllVisible() {
        selectedCostumeIDs = Set(filteredCostumes.map(\.id))
    }

    private func performMoveSelected() {
        guard let targetLocationID = moveTargetLocationID else { return }
        let validCostumeIDs = selectedCostumeIDs.intersection(Set(inventoryVM.costumes.map(\.id)))
        let movedCount = inventoryVM.moveCostumes(validCostumeIDs, to: targetLocationID)
        if movedCount > 0 {
            moveResultMessage = "Moved \(movedCount) costume\(movedCount == 1 ? "" : "s")."
        } else {
            moveResultMessage = "No costumes were moved. They may already be in that location."
        }
        showMoveResultAlert = true
        showMoveSheet = false
        exitSelectionMode()
    }

    private func startQuickMove(for costume: Costume) {
        let alternatives = inventoryVM.locations.filter { $0.id != costume.location.id }
        if alternatives.isEmpty {
            moveResultMessage = "Add another location first to move this costume."
            showMoveResultAlert = true
            return
        }
        quickMoveTargetLocationID = alternatives.first?.id
        quickMoveCostume = costume
    }

    private func performQuickMove(_ costume: Costume) {
        guard let targetLocationID = quickMoveTargetLocationID else { return }
        let movedCount = inventoryVM.moveCostumes([costume.id], to: targetLocationID)
        moveResultMessage = movedCount > 0
            ? "Moved \"\(costume.name)\"."
            : "No move was made."
        showMoveResultAlert = true
        quickMoveCostume = nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedSectionBackground(accent: .blue)
                VStack(spacing: 0) {
                    GlassCard(tint: Color.white.opacity(0.24)) {
                        VStack(spacing: 10) {
                            // Title and Add Button row
                            HStack {
                                Text("Inventory")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                Spacer()
                                Button(action: { showManageLocations = true }) {
                                    Image(systemName: "mappin.and.ellipse")
                                        .font(.system(size: 16, weight: .semibold))
                                        .frame(width: 40, height: 40)
                                        .background(Color.blue.opacity(0.12))
                                        .foregroundColor(.blue)
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                                Button(action: { showAdd = true }) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 18, weight: .semibold))
                                        .frame(width: 40, height: 40)
                                        .foregroundColor(.white)
                                        .background(GlassSurface(level: .primary, tint: .blue, cornerRadius: 20))
                                }
                            }

                            // Search
                            GlassTextField(placeholder: "Search costumes", text: $searchText, icon: "magnifyingglass")

                            // Status + Filters in one bar
                            HStack(spacing: 10) {
                                Picker("Status", selection: $statusFilter) {
                                    ForEach(InventoryStatusFilter.allCases) { filter in
                                        Text(statusLabel(filter)).tag(filter)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                Menu {
                                    Menu("Category") {
                                        ForEach(categoryOptions, id: \.self) { option in
                                            Button(option) { selectedCategory = option }
                                        }
                                    }
                                    Menu("Location") {
                                        Button("All") { selectedLocationID = nil }
                                        ForEach(locationOptions) { location in
                                            let detail = location.detailLine
                                            Button(detail.isEmpty ? location.name : "\(location.name) • \(detail)") {
                                                selectedLocationID = location.id
                                            }
                                        }
                                    }
                                    Menu("Sort") {
                                        ForEach(InventorySortOption.allCases) { option in
                                            Button(option.rawValue) { sortOption = option }
                                        }
                                    }
                                    Section("Quick Actions") {
                                        Button(selectionMode ? "Done Selecting" : "Select Multiple") {
                                            if selectionMode {
                                                exitSelectionMode()
                                            } else {
                                                selectionMode = true
                                            }
                                        }
                                        if selectionMode {
                                            Button("Select All Results") {
                                                selectAllVisible()
                                            }
                                            Button("Move Selected (\(selectedCount))") {
                                                if moveTargetLocationID == nil {
                                                    moveTargetLocationID = inventoryVM.locations.first?.id
                                                }
                                                showMoveSheet = true
                                            }
                                            .disabled(selectedCount == 0 || inventoryVM.locations.isEmpty)
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "line.3.horizontal.decrease.circle")
                                        Text("Filters")
                                        if hasActiveFilters {
                                            Circle()
                                                .fill(Color.blue)
                                                .frame(width: 6, height: 6)
                                        }
                                    }
                                    .font(.caption.bold())
                                    .padding(.horizontal, 10)
                                    .frame(height: 32)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(Color.white.opacity(0.6))
                                    )
                                }
                            }

                            // List/Gallery Toggle
                            Picker("View", selection: $galleryMode) {
                                Text("List").tag(false)
                                Text("Gallery").tag(true)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        .padding()
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                    if galleryMode {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(filteredCostumes) { costume in
                                    if selectionMode {
                                        Button(action: { toggleSelection(costume.id) }) {
                                            CostumeGalleryCard(
                                                costume: costume,
                                                isSelecting: true,
                                                isSelected: selectedCostumeIDs.contains(costume.id)
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    } else {
                                        NavigationLink(destination: CostumeDetailView(costume: costume)) {
                                            CostumeGalleryCard(costume: costume)
                                        }
                                        .buttonStyle(.plain)
                                        .overlay(alignment: .topTrailing) {
                                            Menu {
                                                Button {
                                                    startQuickMove(for: costume)
                                                } label: {
                                                    Label("Move Costume", systemImage: "arrow.right.arrow.left")
                                                }
                                            } label: {
                                                Image(systemName: "ellipsis.circle")
                                                    .font(.title3)
                                                    .foregroundColor(.secondary)
                                                    .padding(6)
                                                    .background(Color.white.opacity(0.75), in: Circle())
                                            }
                                            .padding(8)
                                        }
                                        .simultaneousGesture(
                                            LongPressGesture(minimumDuration: 0.35).onEnded { _ in
                                                enterSelectionMode(with: costume.id)
                                            }
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 24)
                        }
                        .background(Color.clear)
                        .transition(.opacity)
                    } else {
                        ScrollView {
                            VStack(spacing: 14) {
                                ForEach(filteredCostumes) { costume in
                                    if selectionMode {
                                        Button(action: { toggleSelection(costume.id) }) {
                                            CostumeBentoCard(
                                                costume: costume,
                                                isSelecting: true,
                                                isSelected: selectedCostumeIDs.contains(costume.id)
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    } else {
                                        NavigationLink(destination: CostumeDetailView(costume: costume)) {
                                            CostumeBentoCard(costume: costume)
                                        }
                                        .buttonStyle(.plain)
                                        .overlay(alignment: .topTrailing) {
                                            Menu {
                                                Button {
                                                    startQuickMove(for: costume)
                                                } label: {
                                                    Label("Move Costume", systemImage: "arrow.right.arrow.left")
                                                }
                                            } label: {
                                                Image(systemName: "ellipsis.circle")
                                                    .font(.title3)
                                                    .foregroundColor(.secondary)
                                                    .padding(6)
                                                    .background(Color.white.opacity(0.75), in: Circle())
                                            }
                                            .padding(8)
                                        }
                                        .simultaneousGesture(
                                            LongPressGesture(minimumDuration: 0.35).onEnded { _ in
                                                enterSelectionMode(with: costume.id)
                                            }
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 16)
                        }
                        .background(Color.clear)
                        .transition(.opacity)
                    }
                    if filteredCostumes.isEmpty {
                        VStack(spacing: 8) {
                            Text("No costumes found")
                                .font(.headline)
                            Text("Try adjusting filters or search.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 220, alignment: .center)
                        .padding(.top, 12)
                    }
                }
                .sheet(isPresented: $showAdd) {
                    AddCostumeOnboardingView()
                }
                .sheet(item: $showEditSheet) { costume in
                    CostumeEditView(editCostume: costume)
                }
                .sheet(isPresented: $showManageLocations) {
                    ManageLocationsView()
                        .environmentObject(inventoryVM)
                }
                .sheet(isPresented: $showMoveSheet, onDismiss: {
                    moveTargetLocationID = nil
                }) {
                    MoveCostumeDestinationSheet(
                        title: "Move Selected Costumes",
                        subtitle: "\(selectedCount) selected",
                        sourceLine: nil,
                        locations: locationOptions,
                        selectedLocationID: $moveTargetLocationID,
                        onCancel: { showMoveSheet = false },
                        onConfirm: { performMoveSelected() }
                    )
                }
                .alert("Move Selected", isPresented: $showMoveResultAlert) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(moveResultMessage)
                }
                .sheet(item: $quickMoveCostume, onDismiss: {
                    quickMoveTargetLocationID = nil
                }) { costume in
                    let destinationOptions = locationOptions.filter { $0.id != costume.location.id }
                    MoveCostumeDestinationSheet(
                        title: "Move Costume",
                        subtitle: costume.name,
                        sourceLine: "Current: \(costume.location.name)",
                        locations: destinationOptions,
                        selectedLocationID: $quickMoveTargetLocationID,
                        onCancel: { quickMoveCostume = nil },
                        onConfirm: { performQuickMove(costume) }
                    )
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .bottom) {
                if selectionMode {
                    HStack(spacing: 12) {
                        Button("Cancel") {
                            exitSelectionMode()
                        }
                        .font(.subheadline.bold())

                        Spacer()

                        Text("\(selectedCount) selected")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Spacer()

                        Button(action: {
                            if moveTargetLocationID == nil {
                                moveTargetLocationID = inventoryVM.locations.first?.id
                            }
                            showMoveSheet = true
                        }) {
                            Label("Move", systemImage: "arrow.right.arrow.left")
                                .font(.subheadline.bold())
                        }
                        .disabled(selectedCount == 0 || inventoryVM.locations.isEmpty)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 6)
                }
            }
        }
    }
}

struct MoveCostumeDestinationSheet: View {
    let title: String
    let subtitle: String
    let sourceLine: String?
    let locations: [Location]
    @Binding var selectedLocationID: UUID?
    let onCancel: () -> Void
    let onConfirm: () -> Void

    private var canConfirm: Bool {
        selectedLocationID != nil && !locations.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedSectionBackground(accent: .blue)

                VStack(spacing: 12) {
                    HStack {
                        Button("Cancel", action: onCancel)
                            .font(.headline)
                            .foregroundStyle(.blue)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(Color.blue.opacity(0.45), lineWidth: 1.2)
                            )
                        Spacer()
                        Button("Move", action: onConfirm)
                            .font(.headline)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .foregroundColor(canConfirm ? .white : .secondary)
                            .background(GlassSurface(level: .primary, tint: canConfirm ? .blue : .gray, cornerRadius: 20))
                            .disabled(!canConfirm)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)

                    SleekSectionBody {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(title)
                                .font(.title2.bold())
                            Text(subtitle)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            if let sourceLine, !sourceLine.isEmpty {
                                Text(sourceLine)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal)

                    if locations.isEmpty {
                        SleekSectionBody {
                            Text("No destination locations available.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(locations) { location in
                                    Button {
                                        selectedLocationID = location.id
                                    } label: {
                                        MoveDestinationRow(
                                            location: location,
                                            isSelected: selectedLocationID == location.id
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 4)
                            .padding(.bottom, 20)
                        }
                    }
                }
                .toolbar(.hidden, for: .navigationBar)
            }
        }
    }
}

struct MoveDestinationRow: View {
    let location: Location
    let isSelected: Bool

    var body: some View {
        SleekSectionBody {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 48, height: 48)
                    .overlay {
                        if let data = location.imageData, let image = data.cachedUIImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 48, height: 48)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.blue)
                        }
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text(location.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    let detail = location.detailLine
                    Text(detail.isEmpty ? "No location detail" : detail)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? .blue : .secondary.opacity(0.7))
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isSelected ? Color.blue.opacity(0.85) : Color.clear, lineWidth: 2)
        )
    }
}

struct FilterPill: View {
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 6) {
            Text(label + ":")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.6))
        )
    }
}

// MARK: - Gallery Card View (unchanged)
struct CostumeGalleryCard: View {
    let costume: Costume
    var isSelecting: Bool = false
    var isSelected: Bool = false

    var body: some View {
        SleekSectionBody {
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.12))
                        .frame(height: 100)
                    if let data = costume.imageDatas.first, let uiImage = data.cachedUIImage {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 100)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        Image(systemName: "tshirt.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 50)
                            .foregroundColor(.blue)
                    }
                }
                Text(costume.name)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundColor(.primary)
                let locDetail = costume.location.detailLine
                Text(locDetail.isEmpty ? costume.location.name : "\(costume.location.name) • \(locDetail)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Size: \(costume.size)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Qty: \(costume.availableQuantity)/\(costume.totalQuantity)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .bold()
                Text(costume.status.rawValue)
                    .font(.caption2)
                    .foregroundColor(
                        costume.status == .available ? .green :
                        costume.status == .partiallyCheckedOut ? .orange : .red
                    )
                    .bold()
            }
        }
        .frame(height: 300, alignment: .top)
        .overlay(alignment: .topTrailing) {
            if isSelecting {
                SelectionBadge(isSelected: isSelected)
                    .padding(8)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isSelecting && isSelected ? Color.blue.opacity(0.8) : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Bento Card for List View

struct CostumeBentoCard: View {
    let costume: Costume
    var isSelecting: Bool = false
    var isSelected: Bool = false

    private var statusColor: Color {
        switch costume.status {
        case .available:
            return .green
        case .partiallyCheckedOut:
            return .orange
        case .checkedOut:
            return .red
        }
    }

    var body: some View {
        SleekSectionBody {
            HStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 60, height: 60)
                    .overlay {
                        if let data = costume.imageDatas.first, let uiImage = data.cachedUIImage {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            Image(systemName: "tshirt.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 32, height: 32)
                                .foregroundColor(.blue)
                        }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(costume.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    let locDetail = costume.location.detailLine
                    Text(locDetail.isEmpty ? costume.location.name : "\(costume.location.name) • \(locDetail)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .truncationMode(.tail)
                    Text("Qty: \(costume.availableQuantity)/\(costume.totalQuantity)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(costume.status.rawValue)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(statusColor)
                    .lineLimit(2)
                    .multilineTextAlignment(.trailing)
            }
        }
        .frame(height: 136, alignment: .top)
        .overlay(alignment: .topTrailing) {
            if isSelecting {
                SelectionBadge(isSelected: isSelected)
                    .padding(8)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isSelecting && isSelected ? Color.blue.opacity(0.8) : Color.clear, lineWidth: 2)
        )
    }
}

struct SelectionBadge: View {
    let isSelected: Bool

    var body: some View {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            .font(.title3)
            .foregroundColor(isSelected ? .blue : .secondary.opacity(0.8))
            .padding(2)
            .background(Color.white.opacity(0.9), in: Circle())
    }
}
