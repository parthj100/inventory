import SwiftUI
import UIKit

enum PlaceholderCategory {
    case location
    case costume
    case event
}

struct PlaceholderOption: Identifiable, Hashable {
    let id: String
    let title: String
    let symbol: String
    let background: UIColor
    let foreground: UIColor
}

enum PlaceholderArtwork {
    static let locationOptions: [PlaceholderOption] = [
        PlaceholderOption(id: "loc_hanger", title: "Hanger", symbol: "hanger", background: UIColor.systemPink.withAlphaComponent(0.30), foreground: .white),
        PlaceholderOption(id: "loc_box", title: "Box", symbol: "archivebox.fill", background: UIColor.systemBlue.withAlphaComponent(0.30), foreground: .white),
        PlaceholderOption(id: "loc_shipping", title: "Storage", symbol: "shippingbox.fill", background: UIColor.systemOrange.withAlphaComponent(0.30), foreground: .white),
        PlaceholderOption(id: "loc_stage", title: "Stage", symbol: "theatermasks.fill", background: UIColor.systemPurple.withAlphaComponent(0.28), foreground: .white),
        PlaceholderOption(id: "loc_building", title: "Room", symbol: "building.2.fill", background: UIColor.systemTeal.withAlphaComponent(0.28), foreground: .white)
    ]

    static let costumeOptions: [PlaceholderOption] = [
        PlaceholderOption(id: "cos_shirt", title: "Costume", symbol: "tshirt.fill", background: UIColor.systemBlue.withAlphaComponent(0.30), foreground: .white),
        PlaceholderOption(id: "cos_crown", title: "Royal", symbol: "crown.fill", background: UIColor.systemYellow.withAlphaComponent(0.34), foreground: .white),
        PlaceholderOption(id: "cos_dance", title: "Dance", symbol: "figure.dance", background: UIColor.systemPink.withAlphaComponent(0.32), foreground: .white),
        PlaceholderOption(id: "cos_drama", title: "Drama", symbol: "theatermasks.fill", background: UIColor.systemPurple.withAlphaComponent(0.30), foreground: .white),
        PlaceholderOption(id: "cos_prop", title: "Prop", symbol: "wand.and.stars", background: UIColor.systemIndigo.withAlphaComponent(0.30), foreground: .white)
    ]

    static let eventOptions: [PlaceholderOption] = [
        PlaceholderOption(id: "evt_calendar", title: "Calendar", symbol: "calendar", background: UIColor.systemRed.withAlphaComponent(0.30), foreground: .white),
        PlaceholderOption(id: "evt_party", title: "Party", symbol: "party.popper.fill", background: UIColor.systemOrange.withAlphaComponent(0.30), foreground: .white),
        PlaceholderOption(id: "evt_music", title: "Music", symbol: "music.note", background: UIColor.systemBlue.withAlphaComponent(0.30), foreground: .white),
        PlaceholderOption(id: "evt_stage", title: "Stage", symbol: "theatermasks.fill", background: UIColor.systemPink.withAlphaComponent(0.30), foreground: .white),
        PlaceholderOption(id: "evt_star", title: "Special", symbol: "star.fill", background: UIColor.systemPurple.withAlphaComponent(0.30), foreground: .white)
    ]

    static func options(for category: PlaceholderCategory) -> [PlaceholderOption] {
        switch category {
        case .location: return locationOptions
        case .costume: return costumeOptions
        case .event: return eventOptions
        }
    }

    static func option(id: String?, category: PlaceholderCategory) -> PlaceholderOption {
        let options = self.options(for: category)
        if let id, let found = options.first(where: { $0.id == id }) {
            return found
        }
        return options.first!
    }

    static func imageData(for option: PlaceholderOption, size: CGSize = CGSize(width: 800, height: 800)) -> Data? {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { _ in
            let rect = CGRect(origin: .zero, size: size)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: min(size.width, size.height) * 0.18)
            option.background.setFill()
            path.fill()

            let isCostumeOption = option.id.hasPrefix("cos_")
            let symbolSize = min(size.width, size.height) * (isCostumeOption ? 0.34 : 0.44)
            let symbolConfig = UIImage.SymbolConfiguration(pointSize: symbolSize, weight: .regular)
            let symbolImage = UIImage(systemName: option.symbol, withConfiguration: symbolConfig)?
                .withTintColor(option.foreground, renderingMode: .alwaysOriginal)
            let frame = CGRect(
                x: (size.width - symbolSize) / 2,
                y: (size.height - symbolSize) / 2,
                width: symbolSize,
                height: symbolSize
            )
            symbolImage?.draw(in: frame)
        }
        return image.jpegData(compressionQuality: 0.92)
    }
}

struct PlaceholderOptionPicker: View {
    let category: PlaceholderCategory
    var selectedID: String? = nil
    let onSelect: (PlaceholderOption) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(PlaceholderArtwork.options(for: category)) { option in
                    let isSelected = selectedID == option.id
                    Button {
                        onSelect(option)
                    } label: {
                        VStack(spacing: 6) {
                            ZStack(alignment: .topTrailing) {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(option.background))
                                    .frame(width: 54, height: 54)
                                    .overlay(
                                        Image(systemName: option.symbol)
                                            .font(.system(size: 22, weight: .medium))
                                            .foregroundColor(Color(option.foreground))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2.5)
                                    )

                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.accentColor)
                                        .background(Color.white, in: Circle())
                                        .padding(1)
                                }
                            }
                            .frame(width: 60, height: 60, alignment: .center)
                            Text(option.title)
                                .font(.caption2)
                                .foregroundColor(isSelected ? .primary : .secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 2)
        }
    }
}
