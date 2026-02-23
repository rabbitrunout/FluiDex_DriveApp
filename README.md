<div align="center">

# 🚗 FluiDex Drive  

Smart vehicle maintenance & trip tracking app for iOS  

Built with SwiftUI, Core Data, and scalable modular architecture.

![Platform](https://img.shields.io/badge/platform-iOS-lightgrey)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-blueviolet)
![CoreData](https://img.shields.io/badge/Persistence-Core%20Data-9cf)
![Firebase](https://img.shields.io/badge/Backend-Firebase-orange)

</div>

---

## 🚀 Overview

FluiDex Drive is a SwiftUI-based iOS application designed to manage vehicle maintenance, service history, and driving activity.

The app demonstrates:

- Feature-first architecture
- MVVM separation
- Structured Core Data modeling
- Multi-entity relationships
- Scalable module organization
- Business-logic separation via Managers layer

---

## 🧠 Engineering Highlights

- Designed a normalized Core Data schema with multiple entity relationships
- Implemented one-to-many and many-to-one data flows
- Built feature-first modular architecture for scalability
- Separated UI, business logic, and persistence layers
- Implemented local notifications (time & mileage-based)
- Integrated partial Firebase Auth & sync
- Structured Bluetooth / OBD module for future hardware integration
- Created reusable SwiftUI components and animated overlays

---

## 🏗 Architecture

Feature-first modular structure:

FluiDex_Drive/
├── App/
├── Features/
│ ├── Authentication/
│ ├── Dashboard/
│ ├── Maintenance/
│ ├── TripTracking/
│ ├── CarSetup/
│ ├── Notifications/
│ ├── Bluetooth/
│ └── Profile/
├── Models/
├── Managers/
├── UIComponents/
├── Assets/


Architecture style:
- SwiftUI + MVVM
- Core Data persistence layer
- Business logic isolated in Managers
- Modular feature grouping
- Firebase integration layer (partial)

---

## 🗄 Core Data Model

### Entities

- **User**
- **Car**
- **ServiceRecord**
- **Trip**
- **Fluid**
- **MaintenanceItem**
- **ServiceRule**

### Relationships

- User → Cars (1-to-many)
- Car → ServiceRecords (1-to-many)
- Car → Trips (1-to-many)
- ServiceRecord → Car (many-to-one)
- Trip → Car (many-to-one)

Data integrity and cascading logic handled within persistence layer.

---

## 📱 Core Functionalities

### Vehicle Management
- Multiple cars per user
- Active car selection
- Mileage tracking

### Maintenance Tracking
- Service history timeline
- Cost tracking
- Receipt image storage
- Rule-based next service calculation

### Trip Tracking
- Manual trip logging
- Distance-based maintenance estimation

### Smart Reminders
- Local notifications
- Time-based reminders
- Mileage-based reminders

### Connectivity (WIP)
- Bluetooth module
- OBD-II preview
- Future live diagnostics integration

---

## 🛠 Tech Stack

- Swift
- SwiftUI
- Core Data
- Firebase (Auth / partial sync)
- Local Notifications
- Bluetooth (CoreBluetooth – experimental)
- Custom UI components & animations

---

## 🔜 Roadmap

- Full Firebase real-time sync
- Advanced analytics dashboard
- Real OBD-II adapter integration
- Dark mode support
- Unit testing layer
- Data export (PDF/CSV)

---

## 📸 Screenshots

| Dashboard | Service Log | Trip Tracking | Car Setup |
|----------|-------------|---------------|-----------|
| ![](Docs/dashboard.png) | ![](Docs/service-log.png) | ![](Docs/trip.png) | ![](Docs/car-setup.png) |

---

## 👩‍💻 Author

Irina Safronova  
iOS & Frontend Developer
