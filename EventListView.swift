import SwiftUI

struct EventListView: View {
    @EnvironmentObject var inventoryVM: InventoryViewModel
    @State private var showAddEvent = false
    @State private var showCompleted = false

    var filteredEvents: [Event] {
        let sorted = inventoryVM.events.sorted { $0.date < $1.date }
        if showCompleted {
            return sorted.filter { inventoryVM.eventStatus(for: $0) == .done }
        } else {
            return sorted.filter { inventoryVM.eventStatus(for: $0) != .done }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedSectionBackground(accent: .red)

                VStack(spacing: 0) {
                    GlassCard(tint: Color.white.opacity(0.24)) {
                        VStack(spacing: 10) {
                            // Title and New Event Button row
                            HStack {
                                Text("Events")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                Spacer()
                                Button(action: { showAddEvent = true }) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 18, weight: .semibold))
                                        .frame(width: 40, height: 40)
                                        .foregroundColor(.white)
                                        .background(GlassSurface(level: .primary, tint: .red, cornerRadius: 20))
                                }
                            }

                            Picker("Events", selection: $showCompleted) {
                                Text("Upcoming").tag(false)
                                Text("Completed").tag(true)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        .padding()
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                    // List of events
                    ScrollView {
                        VStack(spacing: 20) {
                            ForEach(filteredEvents) { event in
                                NavigationLink(destination: EventDetailView(event: event)) {
                                    EventCardView(event: event)
                                        .padding(.horizontal)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            Spacer(minLength: 20)
                        }
                        .padding(.top, 20)
                    }
                }
                .toolbar(.hidden, for: .navigationBar)
                .sheet(isPresented: $showAddEvent) {
                    AddEventOnboardingView()
                }
            }
        }
    }
}

struct EventCardView: View {
    @EnvironmentObject var inventoryVM: InventoryViewModel
    let event: Event

    var eventStatusColor: Color {
        switch inventoryVM.eventStatus(for: event) {
        case .upcoming:
            return .blue
        case .ongoing:
            return .orange
        case .done:
            return .secondary
        }
    }

    var eventIconOption: PlaceholderOption {
        PlaceholderArtwork.option(id: event.iconID, category: .event)
    }

    var body: some View {
        let status = inventoryVM.eventStatus(for: event)
        SleekSectionBody {
            HStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(eventIconOption.background))
                    .frame(width: 60, height: 60)
                    .overlay {
                        if let data = event.imageData, let uiImage = data.cachedUIImage {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            Image(systemName: eventIconOption.symbol)
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(Color(eventIconOption.foreground))
                        }
                    }

                VStack(alignment: .leading, spacing: 8) {
                    Text(event.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(event.date, format: .dateTime.month(.abbreviated).day().year())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(event.isAllDay ? "Time: All Day" : "Time: \(event.date.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
                Text(status.rawValue)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(eventStatusColor)
            }
        }
    }
}
