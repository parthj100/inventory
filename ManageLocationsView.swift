import SwiftUI

struct ManageLocationsView: View {
    @EnvironmentObject var inventoryVM: InventoryViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText = ""
    @State private var showAddLocation = false
    @State private var pendingLocationID: UUID? = nil
    @State private var showResetAlert = false
    @State private var locationToDelete: Location? = nil
    @State private var showDeleteConfirm = false
    @State private var showReassignDeleteSheet = false
    @State private var reassignTargetID: UUID? = nil
    @State private var showDeleteBlockedAlert = false
    @State private var deleteBlockedMessage = ""
    @State private var showLoadDemoAlert = false

    var filteredLocations: [Location] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if query.isEmpty {
            return inventoryVM.locations.sorted { $0.name < $1.name }
        }
        return inventoryVM.locations.filter { location in
            if location.name.lowercased().contains(query) { return true }
            if location.room.lowercased().contains(query) { return true }
            if location.storageLabel.lowercased().contains(query) { return true }
            let costumes = inventoryVM.costumes.filter { $0.location.id == location.id }
            return costumes.contains { $0.name.lowercased().contains(query) }
        }
        .sorted { $0.name < $1.name }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(.systemGray6), Color.white],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    contentSection
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { presentationMode.wrappedValue.dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showLoadDemoAlert = true
                        } label: {
                            Label("Load Demo Data", systemImage: "sparkles")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showAddLocation, onDismiss: {
                pendingLocationID = nil
            }) {
                AddLocationSheet { location in
                    pendingLocationID = location.id
                }
                .environmentObject(inventoryVM)
            }
            .sheet(isPresented: $showReassignDeleteSheet, onDismiss: {
                locationToDelete = nil
                reassignTargetID = nil
            }) {
                if let location = locationToDelete {
                    NavigationStack {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Reassign Before Delete")
                                .font(.title2.bold())
                            Text("Move all costumes from \"\(location.name)\" to another location, then delete it.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Picker("Move Costumes To", selection: $reassignTargetID) {
                                ForEach(inventoryVM.locations.filter { $0.id != location.id }) { candidate in
                                    Text(candidate.name).tag(Optional(candidate.id))
                                }
                            }
                            .pickerStyle(.menu)

                            Spacer()
                        }
                        .padding(20)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") {
                                    showReassignDeleteSheet = false
                                }
                            }
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Reassign & Delete") {
                                    guard let targetID = reassignTargetID else { return }
                                    _ = inventoryVM.reassignCostumes(from: location.id, to: targetID)
                                    _ = inventoryVM.deleteLocation(location)
                                    showReassignDeleteSheet = false
                                }
                                .disabled(reassignTargetID == nil)
                            }
                        }
                    }
                }
            }
            .confirmationDialog(
                "Reset All Data?",
                isPresented: $showResetAlert,
                titleVisibility: .visible
            ) {
                Button("Reset", role: .destructive) {
                    inventoryVM.resetAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will delete all costumes, events, checkouts, and locations. This cannot be undone.")
            }
            .alert(isPresented: $showLoadDemoAlert) {
                Alert(
                    title: Text("Load Demo Data?"),
                    message: Text("This will replace current data with sample costumes, locations, events, and activity logs."),
                    primaryButton: .destructive(Text("Load Demo")) {
                        inventoryVM.loadDemoData()
                    },
                    secondaryButton: .cancel()
                )
            }
            .alert("Delete Location?", isPresented: $showDeleteConfirm, presenting: locationToDelete) { location in
                Button("Delete", role: .destructive) {
                    _ = inventoryVM.deleteLocation(location)
                    locationToDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    locationToDelete = nil
                }
            } message: { location in
                Text("Delete \"\(location.name)\"?")
            }
            .alert("Can’t Delete Location", isPresented: $showDeleteBlockedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(deleteBlockedMessage)
            }
        }
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Locations")
                .font(.largeTitle)
                .fontWeight(.bold)

            HStack(spacing: 10) {
                Button(action: { showAddLocation = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                        Text("Add")
                    }
                    .font(.subheadline.bold())
                    .padding(.horizontal, 12)
                    .frame(height: 32)
                    .background(Color.blue.opacity(0.12))
                    .foregroundColor(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                Button(action: { showResetAlert = true }) {
                    Text("Reset Data")
                        .font(.subheadline.bold())
                        .padding(.horizontal, 12)
                        .frame(height: 32)
                        .background(Color.red.opacity(0.12))
                        .foregroundColor(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                Spacer()
            }

            GlassTextField(placeholder: "Search locations or costumes", text: $searchText, icon: "magnifyingglass")

            if filteredLocations.isEmpty {
                Text("No locations found.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            } else {
                ForEach(filteredLocations) { location in
                    locationRow(location)
                }
            }
        }
    }

    @ViewBuilder
    private func locationRow(_ location: Location) -> some View {
        let costumes = inventoryVM.costumes
            .filter { $0.location.id == location.id }
            .sorted { $0.name < $1.name }
        let totalPieces = costumes.reduce(0) { $0 + $1.totalQuantity }
        let availablePieces = costumes.reduce(0) { $0 + $1.availableQuantity }

        NavigationLink(destination: LocationDetailView(location: location)) {
            SleekSectionBody {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        if let data = location.imageData, let image = data.cachedUIImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 44, height: 44)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.systemGray5))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Image(systemName: "mappin.and.ellipse")
                                        .foregroundColor(.secondary)
                                )
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(location.name)
                                .font(.headline)
                            if !location.detailLine.isEmpty {
                                Text(location.detailLine)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(costumes.count) items")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(availablePieces)/\(totalPieces) available")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.trailing, 44)
                    }

                    if costumes.isEmpty {
                        Text("No costumes assigned to this location.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        VStack(spacing: 6) {
                            HStack {
                                Text("Costume")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("Qty")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Divider()
                            ForEach(costumes) { costume in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(costume.name)
                                            .font(.subheadline)
                                        Text(costume.status.rawValue)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text("\(costume.availableQuantity)/\(costume.totalQuantity)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                if costume.id != costumes.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            Menu {
                Button(role: .destructive) {
                    beginDeleteFlow(for: location)
                } label: {
                    Label("Delete Location", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .padding(8)
                    .background(Color.white.opacity(0.7), in: Circle())
            }
            .padding(10)
            .offset(x: 2, y: -2)
        }
        .contextMenu {
            Button(role: .destructive) {
                beginDeleteFlow(for: location)
            } label: {
                Label("Delete Location", systemImage: "trash")
            }
        }
    }

    private func beginDeleteFlow(for location: Location) {
        let hasAssignedCostumes = inventoryVM.isLocationInUse(location.id)
        if hasAssignedCostumes {
            let alternatives = inventoryVM.locations.filter { $0.id != location.id }
            guard !alternatives.isEmpty else {
                deleteBlockedMessage = "Move or delete costumes first. You can’t delete the only location while it still has costumes."
                showDeleteBlockedAlert = true
                return
            }
            locationToDelete = location
            reassignTargetID = alternatives.first?.id
            showReassignDeleteSheet = true
            return
        }

        locationToDelete = location
        showDeleteConfirm = true
    }
}
