import SwiftUI

struct EventDetailView: View {
    @EnvironmentObject var inventoryVM: InventoryViewModel
    @Environment(\.presentationMode) var presentationMode
    @State var event: Event
    @State private var showEditOnboarding = false
    @State private var showDeleteAlert = false

    // Helper to get the latest costume from inventory
    func latestCostume(for assigned: AssignedCostume) -> Costume? {
        inventoryVM.costumes.first(where: { $0.id == assigned.costumeID })
    }

    var eventPlaceholderImage: UIImage? {
        if let data = event.imageData, let image = data.cachedUIImage {
            return image
        }
        let option = PlaceholderArtwork.option(id: event.iconID, category: .event)
        guard let data = PlaceholderArtwork.imageData(for: option, size: CGSize(width: 900, height: 900)) else { return nil }
        return UIImage(data: data)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Group {
                    if let eventPlaceholderImage {
                        Image(uiImage: eventPlaceholderImage)
                            .resizable()
                            .scaledToFill()
                            .aspectRatio(1, contentMode: .fit)
                    } else {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color(.systemGray5))
                            .aspectRatio(1, contentMode: .fit)
                            .overlay {
                                Image(systemName: "calendar")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 70, height: 70)
                                    .foregroundColor(.pink)
                            }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding(.horizontal)

                // Card-like info panel
                VStack(alignment: .leading, spacing: 20) {
                    // Organizer/department + Edit/Delete
                    HStack {
                        HStack(spacing: 10) {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 32, height: 32)
                                .foregroundColor(.gray)
                            Text(event.organizer)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        GlassIconButton(systemName: "pencil", iconColor: .red) {
                            showEditOnboarding = true
                        }
                        .accessibilityLabel("Edit Event")
                        Button(action: { showDeleteAlert = true }) {
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
                        .accessibilityLabel("Delete Event")
                        .alert(isPresented: $showDeleteAlert) {
                            Alert(
                                title: Text("Delete Event?"),
                                message: Text("Are you sure you want to delete this event? This action cannot be undone."),
                                primaryButton: .destructive(Text("Delete")) {
                                    inventoryVM.deleteEvent(event)
                                    presentationMode.wrappedValue.dismiss()
                                },
                                secondaryButton: .cancel()
                            )
                        }
                    }

                    // Name, status badge, date/time/location
                    VStack(alignment: .leading, spacing: 6) {
                        Text(event.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        HStack {
                            let status = inventoryVM.eventStatus(for: event)
                            Text(status.rawValue)
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(.systemGray5))
                                )
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("ID: \(event.id.uuidString.prefix(8))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        HStack {
                            let status = inventoryVM.eventStatus(for: event)
                            if event.isCompleted {
                                Button("Mark Active") {
                                    var updated = event
                                    updated.isCompleted = false
                                    inventoryVM.updateEvent(updated)
                                    event = updated
                                }
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .glassEffect(.regular.tint(Color.white.opacity(0.3)).interactive(), in: .capsule)
                            } else if status != .done {
                                Button("Mark Completed") {
                                    var updated = event
                                    updated.isCompleted = true
                                    inventoryVM.updateEvent(updated)
                                    event = updated
                                }
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .glassEffect(.regular.tint(Color.white.opacity(0.3)).interactive(), in: .capsule)
                            }
                            Spacer()
                        }
                        HStack(spacing: 16) {
                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                Text(event.date, format: .dateTime.month(.abbreviated).day().year())
                            }
                            HStack(spacing: 6) {
                                Image(systemName: "clock")
                                Text(event.isAllDay ? "All Day" : event.date.formatted(date: .omitted, time: .shortened))
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        HStack {
                            Image(systemName: "mappin.and.ellipse")
                            Text(event.assignedCostumes.first.flatMap { assigned in
                                guard let loc = latestCostume(for: assigned)?.location else { return nil }
                                let detail = loc.detailLine
                                return detail.isEmpty ? loc.name : "\(loc.name) • \(detail)"
                            } ?? "—")
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(color: Color(.systemGray4).opacity(0.2), radius: 8, x: 0, y: 4)

                // Description
                if let notes = event.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        Text(notes)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                }

                // Assigned Costumes (with images)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Assigned Costumes")
                        .font(.headline)
                    if event.assignedCostumes.isEmpty {
                        Text("No costumes assigned.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(event.assignedCostumes) { assigned in
                            let costume = latestCostume(for: assigned)
                            HStack(spacing: 12) {
                                if let costume,
                                   let data = costume.imageDatas.first,
                                   let uiImage = data.cachedUIImage {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 36, height: 36)
                                        .padding(2)
                                        .background(Color.white.opacity(0.55))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                VStack(alignment: .leading) {
                                    Text(costume?.name ?? assigned.costumeName)
                                        .fontWeight(.medium)
                                    Text("Qty: \(assigned.quantity)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(event.name)
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(inventoryVM.$events) { updated in
            if let latest = updated.first(where: { $0.id == event.id }) {
                event = latest
            }
        }
        .sheet(isPresented: $showEditOnboarding) {
            AddEventOnboardingView(editEvent: event)
                .environmentObject(inventoryVM)
        }
    }
}
