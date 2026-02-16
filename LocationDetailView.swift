import SwiftUI

struct LocationDetailView: View {
    @EnvironmentObject var inventoryVM: InventoryViewModel
    @Environment(\.dismiss) private var dismiss
    let location: Location
    @State private var searchText = ""
    @State private var showDeleteConfirm = false
    @State private var showReassignDeleteSheet = false
    @State private var reassignTargetID: UUID? = nil
    @State private var showDeleteBlockedAlert = false
    @State private var deleteBlockedMessage = ""

    var locationCostumes: [Costume] {
        var costumes = inventoryVM.costumes
            .filter { $0.location.id == location.id }
            .sorted { $0.name < $1.name }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !query.isEmpty {
            costumes = costumes.filter { costume in
                costume.name.lowercased().contains(query) ||
                costume.category.lowercased().contains(query) ||
                costume.size.lowercased().contains(query) ||
                costume.color.lowercased().contains(query)
            }
        }
        return costumes
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(.systemGray6), Color.white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        if let data = location.imageData, let image = data.cachedUIImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 70, height: 70)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        } else {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(.systemGray5))
                                .frame(width: 70, height: 70)
                                .overlay(
                                    Image(systemName: "mappin.and.ellipse")
                                        .foregroundColor(.secondary)
                                )
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(location.name)
                                .font(.title2.bold())
                            if !location.detailLine.isEmpty {
                                Text(location.detailLine)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                    }
                    .padding(.top, 8)

                    GlassTextField(placeholder: "Search costumes in this location", text: $searchText, icon: "magnifyingglass")

                    let totalPieces = locationCostumes.reduce(0) { $0 + $1.totalQuantity }
                    let availablePieces = locationCostumes.reduce(0) { $0 + $1.availableQuantity }
                    HStack {
                        Text("\(locationCostumes.count) items")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(availablePieces)/\(totalPieces) available")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if locationCostumes.isEmpty {
                        Text("No costumes assigned to this location.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    } else {
                        SleekSectionBody {
                            VStack(spacing: 10) {
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
                                ForEach(locationCostumes) { costume in
                                    NavigationLink(destination: CostumeDetailView(costume: costume)) {
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
                                        .padding(.vertical, 4)
                                    }
                                    .buttonStyle(.plain)
                                    if costume.id != locationCostumes.last?.id {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Location")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    beginDeleteFlow()
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .sheet(isPresented: $showReassignDeleteSheet) {
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
                            reassignTargetID = nil
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Reassign & Delete") {
                            guard let targetID = reassignTargetID else { return }
                            _ = inventoryVM.reassignCostumes(from: location.id, to: targetID)
                            _ = inventoryVM.deleteLocation(location)
                            showReassignDeleteSheet = false
                            dismiss()
                        }
                        .disabled(reassignTargetID == nil)
                    }
                }
            }
        }
        .alert("Delete Location?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                if inventoryVM.deleteLocation(location) {
                    dismiss()
                } else {
                    deleteBlockedMessage = "This location still has assigned costumes. Reassign them before deleting."
                    showDeleteBlockedAlert = true
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Delete \"\(location.name)\"?")
        }
        .alert("Can’t Delete Location", isPresented: $showDeleteBlockedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(deleteBlockedMessage)
        }
    }

    private func beginDeleteFlow() {
        if inventoryVM.isLocationInUse(location.id) {
            let alternatives = inventoryVM.locations.filter { $0.id != location.id }
            guard !alternatives.isEmpty else {
                deleteBlockedMessage = "Move or delete costumes first. You can’t delete the only location while it still has costumes."
                showDeleteBlockedAlert = true
                return
            }
            reassignTargetID = alternatives.first?.id
            showReassignDeleteSheet = true
            return
        }
        showDeleteConfirm = true
    }
}
