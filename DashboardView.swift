import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var inventoryVM: InventoryViewModel
    @Binding var selectedTab: ContentView.Tab
    @Binding var inventoryStatusFilter: InventoryStatusFilter
    @State private var showAddCostume = false
    @State private var showAddEvent = false
    @State private var showQuickCheckOut = false
    @State private var quickCheckOutCostume: Costume? = nil
    @State private var aiQuery = ""
    private let aiPrompt = "How many Festival Kurta costumes are available?"

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedSectionBackground(accent: .green)

                ScrollView {
                // Break up complex expressions for compiler performance
                let startOfToday = Calendar.current.startOfDay(for: Date())
                let futureEvents = inventoryVM.events.filter { event in
                    event.date >= startOfToday && inventoryVM.eventStatus(for: event) != .done
                }
                let sortedEvents = futureEvents.sorted { $0.date < $1.date }
                let nextUpcomingEvent = sortedEvents.first
                let totalPieces = inventoryVM.costumes.map(\.totalQuantity).reduce(0, +)
                let checkedOutPieces = inventoryVM.costumes.map { $0.totalQuantity - $0.availableQuantity }.reduce(0, +)
                VStack(spacing: 18) {
                    DashboardHeaderCard(
                        totalPieces: totalPieces,
                        checkedOutPieces: checkedOutPieces,
                        upcomingEvents: sortedEvents.count,
                        onAddCostume: { showAddCostume = true },
                        onAddEvent: { showAddEvent = true },
                        onQuickCheckOut: { showQuickCheckOut = true }
                    )
                    .padding(.top, 12)

                    // Stat Cards Row (tap to Inventory)
                    HStack(spacing: 16) {
                        Button(action: {
                            inventoryStatusFilter = .all
                            selectedTab = .inventory
                        }) {
                            SleekStatCard(
                                title: "Total Costumes",
                                value: "\(totalPieces)",
                                icon: "tshirt",
                                gradient: [Color.blue.opacity(0.25), Color.teal.opacity(0.12)]
                            )
                        }
                        .buttonStyle(.plain)
                        Button(action: {
                            inventoryStatusFilter = .checkedOut
                            selectedTab = .inventory
                        }) {
                            SleekStatCard(
                                title: "Checked Out",
                                value: "\(checkedOutPieces)",
                                icon: "arrow.right.arrow.left.circle",
                                gradient: [Color.orange.opacity(0.25), Color.pink.opacity(0.12)]
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    // Upcoming Event (tap to Events or Event Detail)
                    if let event = nextUpcomingEvent {
                        Button(action: { selectedTab = .events }) {
                            SleekSectionCard(
                                title: "Upcoming Event",
                                accent: Color.green.opacity(0.6)
                            ) {
                                Text(event.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(event.date, style: .date)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button(action: { selectedTab = .events }) {
                            SleekSectionCard(
                                title: "Upcoming Event",
                                accent: Color.green.opacity(0.4)
                            ) {
                                Text("No upcoming events")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    // Recently Updated
                    SleekSectionCard(
                        title: "Recently Updated",
                        accent: Color.purple.opacity(0.5)
                    ) {
                        let recent = inventoryVM.activities.prefix(2)
                        if recent.isEmpty {
                            Text("No recent updates.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(recent) { activity in
                                HStack(spacing: 10) {
                                    ActivityTypeIcon(type: activity.type)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(activity.description)
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                        Text(activity.date, style: .time)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }

                    SiriTypePromptPreview(
                        text: $aiQuery,
                        placeholder: aiPrompt
                    )
                }
                .padding()
            }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showAddCostume) {
            AddCostumeOnboardingView()
        }
        .sheet(isPresented: $showAddEvent) {
            AddEventOnboardingView()
        }
        .sheet(isPresented: $showQuickCheckOut) {
            QuickCheckOutPicker(
                costumes: inventoryVM.costumes.sorted { $0.name < $1.name },
                onSelect: { costume in
                    quickCheckOutCostume = costume
                }
            )
        }
        .sheet(item: $quickCheckOutCostume) { costume in
            CheckOutSheet(
                costume: costume,
                onCheckOut: { checkedOutBy, quantity, dueDate in
                    inventoryVM.checkOutCostume(costume, checkedOutBy: checkedOutBy, quantity: quantity, dueDate: dueDate)
                }
            )
        }
    }
}

struct SiriTypePromptPreview: View {
    @Binding var text: String
    let placeholder: String

    var body: some View {
        SleekSectionCard(
            title: "Ask Inventory AI",
            accent: Color.pink.opacity(0.75)
        ) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.pink, .orange, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    ZStack(alignment: .leading) {
                        if text.isEmpty {
                            Text(placeholder)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }

                        TextField("", text: $text)
                            .font(.subheadline)
                            .textInputAutocapitalization(.sentences)
                    }

                    Button(action: {}) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 23, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.pink.opacity(0.95),
                                    Color.purple.opacity(0.75),
                                    Color.blue.opacity(0.8)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1.6
                        )
                )
                .shadow(color: Color.pink.opacity(0.24), radius: 16, x: 0, y: 6)
            }
        }
    }
}

struct DashboardHeaderCard: View {
    let totalPieces: Int
    let checkedOutPieces: Int
    let upcomingEvents: Int
    let onAddCostume: () -> Void
    let onAddEvent: () -> Void
    let onQuickCheckOut: () -> Void

    var body: some View {
        GlassCard(tint: Color.white.opacity(0.26)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dashboard")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Inventory at a glance")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("\(totalPieces) total · \(checkedOutPieces) out · \(upcomingEvents) upcoming")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(Date(), format: .dateTime.month(.abbreviated).day())
                        Text(Date(), format: .dateTime.weekday(.abbreviated))
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                }

                HStack(spacing: 12) {
                    DashboardHeaderActionButton(
                        icon: "plus",
                        tint: .blue,
                        action: onAddCostume
                    )
                    .accessibilityLabel("Add Costume")

                    DashboardHeaderActionButton(
                        icon: "calendar.badge.plus",
                        tint: .pink,
                        action: onAddEvent
                    )
                    .accessibilityLabel("Create Event")

                    DashboardHeaderActionButton(
                        icon: "arrow.right.arrow.left.circle",
                        tint: .green,
                        action: onQuickCheckOut
                    )
                    .accessibilityLabel("Check Out")
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct DashboardHeaderActionButton: View {
    let icon: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 44, height: 44)
                .background(tint.opacity(0.12))
                .foregroundColor(tint)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - BentoCard (Reusable Box)
struct BentoCard<Content: View>: View {
    var color: Color
    var content: Content

    init(color: Color, @ViewBuilder content: () -> Content) {
        self.color = color
        self.content = content()
    }

    var body: some View {
        GlassCard(tint: color) {
            content
                .padding()
                .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 120)
        }
    }
}

// MARK: - Sleek Cards
struct SleekStatCard: View {
    let title: String
    let value: String
    let icon: String
    let gradient: [Color]

    var body: some View {
        GlassCard(tint: Color.white.opacity(0.25)) {
            ZStack {
                LinearGradient(
                    colors: gradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.primary)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(value)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text(title)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .frame(maxWidth: .infinity, minHeight: 100, maxHeight: 100)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}

struct SleekSectionCard<Content: View>: View {
    let title: String
    let accent: Color
    let content: Content

    init(title: String, accent: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.accent = accent
        self.content = content()
    }

    var body: some View {
        GlassCard(tint: Color.white.opacity(0.22)) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Capsule()
                        .fill(accent)
                        .frame(width: 4, height: 20)
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                content
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct SleekSectionBody<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        GlassCard(tint: Color.white.opacity(0.22)) {
            content
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Liquid Glass (local fallback)
struct GlassCard<Content: View>: View {
    var tint: Color? = nil
    let content: Content

    init(tint: Color? = nil, @ViewBuilder content: () -> Content) {
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.ultraThinMaterial)
                    if let tint {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(tint)
                            .opacity(0.22)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.10), radius: 8, x: 0, y: 5)
    }
}

// MARK: - StatCard
struct StatCard: View {
    var title: String
    var value: String
    var icon: String
    var color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(color)
                .padding(.trailing, 8)
            VStack(alignment: .leading) {
                Text(value)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
            }
            Spacer()
        }
    }
}

// MARK: - ActivityTypeIcon
struct ActivityTypeIcon: View {
    let type: ActivityType

    var body: some View {
        let iconName: String
        let iconColor: Color

        switch type {
        case .costumeAdded: iconName = "plus.circle.fill"; iconColor = .blue
        case .costumeEdited: iconName = "pencil.circle.fill"; iconColor = .yellow
        case .costumeDeleted: iconName = "trash.circle.fill"; iconColor = .red
        case .checkedIn: iconName = "arrow.down.circle.fill"; iconColor = .green
        case .checkedOut: iconName = "arrow.up.circle.fill"; iconColor = .orange
        case .eventAdded: iconName = "calendar.badge.plus"; iconColor = .mint
        case .eventEdited: iconName = "calendar.badge.clock"; iconColor = .purple
        case .eventDeleted: iconName = "calendar.badge.minus"; iconColor = .red
        }

        return Image(systemName: iconName)
            .foregroundColor(iconColor)
            .font(.system(size: 18))
    }
}

// MARK: - Quick Check Out Picker
struct QuickCheckOutPicker: View {
    let costumes: [Costume]
    let onSelect: (Costume) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var showOnlyAvailable = true

    private var filteredCostumes: [Costume] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return costumes.filter { costume in
            if showOnlyAvailable && costume.availableQuantity == 0 {
                return false
            }
            if query.isEmpty {
                return true
            }
            let locationDetail = costume.location.detailLine.lowercased()
            return costume.name.lowercased().contains(query) ||
                costume.category.lowercased().contains(query) ||
                costume.location.name.lowercased().contains(query) ||
                locationDetail.contains(query)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedSectionBackground(accent: .green)

                VStack(spacing: 12) {
                    HStack {
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.primary)
                                .frame(width: 36, height: 36)
                                .background(
                                    GlassSurface(level: .secondary, tint: .white.opacity(0.15), cornerRadius: 18)
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Close")
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)

                    SleekSectionBody {
                        VStack(spacing: 10) {
                            GlassTextField(placeholder: "Search costumes", text: $searchText, icon: "magnifyingglass")

                            Picker("Scope", selection: $showOnlyAvailable) {
                                Text("Available").tag(true)
                                Text("All").tag(false)
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                    .padding(.horizontal)

                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(filteredCostumes) { costume in
                                Button {
                                    dismiss()
                                    onSelect(costume)
                                } label: {
                                    QuickCheckOutCostumeRow(costume: costume)
                                }
                                .buttonStyle(.plain)
                                .disabled(costume.availableQuantity == 0)
                                .opacity(costume.availableQuantity == 0 ? 0.55 : 1)
                            }

                            if filteredCostumes.isEmpty {
                                VStack(spacing: 8) {
                                    Text("No costumes found")
                                        .font(.headline)
                                    Text("Try changing search or filter.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity, minHeight: 220)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 20)
                    }
                }
                .toolbar(.hidden, for: .navigationBar)
            }
        }
    }
}

struct QuickCheckOutCostumeRow: View {
    let costume: Costume

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
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 56, height: 56)
                    .overlay {
                        if let data = costume.imageDatas.first, let uiImage = data.cachedUIImage {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 56, height: 56)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            Image(systemName: "tshirt.fill")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.blue)
                        }
                    }

                VStack(alignment: .leading, spacing: 6) {
                    Text(costume.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    let detail = costume.location.detailLine
                    Text("Location: \(detail.isEmpty ? costume.location.name : "\(costume.location.name) • \(detail)")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Qty: \(costume.availableQuantity)/\(costume.totalQuantity)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text(costume.availableQuantity == 0 ? "Unavailable" : "Select")
                        .font(.caption.bold())
                        .foregroundColor(costume.availableQuantity == 0 ? .secondary : .blue)
                    Text(costume.status.rawValue)
                        .font(.caption2)
                        .foregroundColor(statusColor)
                        .fontWeight(.semibold)
                }
            }
        }
    }
}
