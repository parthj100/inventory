# Inventory (iOS)

`Inventory` is a SwiftUI app for managing costume inventory, check-outs, events, and storage locations.

It is designed for costume departments that need quick visibility into:
- what is available vs checked out
- where items are stored (room + box/rack/shelf/hanging)
- which costumes are assigned to upcoming events

## Features

- Dashboard with:
  - total pieces
  - checked-out count
  - upcoming event preview
  - recent activity feed
- Inventory management:
  - list and gallery views
  - search, status filters, sort options
  - multi-select + bulk move between locations
  - check-out / check-in flow with quantity control
- Event management:
  - upcoming and completed tabs
  - all-day or timed events
  - status support (upcoming, ongoing, done)
  - assign costumes to events
- Location management:
  - add/edit/delete locations
  - room + storage type + label model
  - location image / placeholders
  - view costumes grouped by location
- Media support:
  - photo picker integration
  - multiple costume photos
  - placeholder artwork options for costumes/events/locations
- Demo tools:
  - load demo data for screenshots/testing
  - reset all data

## Tech Stack

- `SwiftUI`
- `Core Data`
- `UIKit` interop (image/photo handling)
- Local file storage for image assets

## Data Model (High Level)

- `Costume`
  - name, size, color, category, totalQuantity, availableQuantity, status
  - location reference
  - checkout records
  - multiple image references
- `Event`
  - name, date, all-day flag, completion flag, organizer
  - assigned costumes
  - notes + image/icon
- `Location`
  - name, room, storage type, storage label
  - image/icon
- `Activity`
  - timestamped app activity log

## Requirements

- Xcode 26+
- iOS 26+ deployment target

## Getting Started

1. Clone the repo:
   ```bash
   git clone <your-repo-url>
   cd "Costume Inventory"
   ```
2. Open the project:
   ```bash
   open "Costume Inventory.xcodeproj"
   ```
3. Select an iOS 26 simulator/device and run.

## Project Structure

- `/Costume Inventory/ContentView.swift` — app tab shell/navigation
- `/Costume Inventory/DashboardView.swift` — dashboard + quick actions
- `/Costume Inventory/CostumeListView.swift` — inventory list/gallery UI
- `/Costume Inventory/CostumeDetailView.swift` — costume details + check-in/out
- `/Costume Inventory/EventListView.swift` — events list/tabs
- `/Costume Inventory/EventDetailView.swift` — event details
- `/Costume Inventory/ManageLocationsView.swift` — location management
- `/InventoryViewModel.swift` — business logic + persistence orchestration
- `/Costume Inventory/Persistence.swift` — Core Data stack
- `/Costume Inventory/Models.swift` — domain models

## Notes

- App is currently configured to render in light appearance for consistent visuals across device dark/light settings.
- Images are persisted through local storage paths referenced by Core Data entities.

## Roadmap Ideas

- AI command bar for natural-language actions (query inventory, create events, run check-outs)
- On-device vision flow for photo-to-inventory intake
- Export/reporting (CSV/PDF snapshots)
- Role-based permissions and cloud sync
