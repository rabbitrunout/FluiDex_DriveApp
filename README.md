<div align="center">

# 🚗 FluiDex Drive  

Smart vehicle maintenance & trip tracking app for iOS  

Built with **SwiftUI**, **Core Data**, and scalable modular architecture.

![Platform](https://img.shields.io/badge/platform-iOS-lightgrey)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-blueviolet)
![CoreData](https://img.shields.io/badge/Persistence-Core%20Data-9cf)
![Firebase](https://img.shields.io/badge/Backend-Firebase-orange)

</div>

---

## 🚀 Overview

FluiDex Drive is a SwiftUI-based iOS application designed to manage vehicle maintenance, service history, and driving activity.

The project demonstrates:

- Feature-first modular architecture
- MVVM separation of concerns
- Structured Core Data modeling
- Multi-entity relationship handling
- Business logic isolation via Managers layer
- Scalability planning for hardware integration (OBD-II)

---

## 🧠 Engineering Highlights

- Designed a normalized Core Data schema with multiple entity relationships
- Implemented one-to-many and many-to-one data flows
- Built feature-first modular architecture for independent scaling
- Separated UI, business logic, and persistence layers
- Implemented local notifications (time-based & mileage-based)
- Integrated partial Firebase authentication & sync layer
- Structured Bluetooth / OBD module for future hardware expansion
- Created reusable SwiftUI components and animated overlays

---

## ⚙️ Technical Decisions

- **Core Data over Realm** for deep Apple ecosystem integration
- **Feature-first structure** to allow isolated feature expansion
- Introduced a **Managers layer** to prevent ViewModel overloading
- Abstracted notification scheduling for per-car maintenance logic
- Structured entities to support future cloud sync & analytics

---

## 🏗 Architecture

Feature-first modular structure:

```
FluiDex_Drive/
├── App/
├── Features/
│   ├── Authentication/
│   ├── Dashboard/
│   ├── Maintenance/
│   ├── TripTracking/
│   ├── CarSetup/
│   ├── Notifications/
│   ├── Bluetooth/
│   └── Profile/
├── Models/
├── Managers/
├── UIComponents/
├── Assets/
```

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

### 🚗 Vehicle Management
- Multiple cars per user
- Active car selection
- Mileage tracking

### 🛠 Maintenance Tracking
- Structured service history timeline
- Cost tracking & receipt image storage
- Rule-based next service calculation
- Per-car maintenance logic

### 📍 Trip Tracking
- Manual trip logging
- Distance-based maintenance estimation

### 🔔 Smart Reminders
- Local push notifications
- Time-based reminders
- Mileage-based reminders

### 🔌 Connectivity (Work in Progress)
- Bluetooth connection module
- OBD-II preview screen
- Future live diagnostics integration

---

## 🧠 Key Learnings

- Designing scalable Core Data schemas
- Managing complex entity relationships
- Structuring large SwiftUI projects
- Separating UI from business logic
- Planning for hardware-level integrations
- Thinking in scalable feature modules

---

## 🛠 Tech Stack

- Swift
- SwiftUI
- Core Data
- Firebase (Auth / partial sync)
- Local Notifications
- CoreBluetooth (experimental)
- Custom UI components & animations

---

## 🔜 Roadmap

- Full Firebase real-time sync
- Advanced analytics dashboard
- Real OBD-II adapter integration
- Dark mode support
- Unit testing layer
- Data export (PDF / CSV)

---

## 📸 Screenshots

| Dashboard | Service Log | Trip Tracking | Car Setup |
|----------|-------------|---------------|-----------|
| ![](2.png) | ![](11.png) | ![](6.png) | ![](3.png) |

---

## 👩‍💻 Author

Irina Safronova  
iOS Developer focused on SwiftUI & scalable mobile architecture  
