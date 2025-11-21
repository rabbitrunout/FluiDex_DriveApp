<div align="center">

# 🚗 FluiDex Drive  

**Smart vehicle maintenance & trip tracking app**

Keep your car healthy, your service history organized, and your next maintenance under control.

---

![Platform](https://img.shields.io/badge/platform-iOS-lightgrey)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-blueviolet)
![CoreData](https://img.shields.io/badge/Persistence-Core%20Data-9cf)
![Firebase](https://img.shields.io/badge/Backend-Firebase-orange)
![Status](https://img.shields.io/badge/status-Active%20Development-success)

</div>

---

## 🎯 What is FluiDex Drive?

**FluiDex Drive** is an iOS app built with SwiftUI that works like a digital health journal for your car.

The app helps beginner and busy drivers:

- remember **when to change oil, fluids, filters, tires**
- keep a **clean service history** with costs and mileage
- track **trips and distance** for smarter maintenance
- get **smart reminders** by time or odometer
- manage **multiple cars and users** in one place

> Designed and developed as a portfolio / capstone project by **Irina S.**

---

## 🌟 Core Features

### 👤 1. User & Profiles

- Email-based **sign up / login**
- Personal profile per user
- Each user can own **multiple cars**

---

### 🚗 2. Car Garage

Manage all your cars in one place:

- Brand, model, year, VIN, fuel type
- Current mileage
- Car images
- Mark **active / selected car** for the dashboard

---

### 🛠 3. Smart Maintenance & Service Log

Turn random receipts into a clean service history:

- Create **service records** with:
  - date & mileage  
  - service type (oil, tires, brakes, etc.)  
  - parts & labor cost, total cost  
  - next service date / mileage  
  - receipt photo  
- See a **timeline of all services per car**  
- Rule-based + AI-style engine to suggest what to service next  

---

### 📍 4. Trip Tracking

Understand how you actually drive:

- Log trips (date + distance)
- Use trip data to:
  - estimate when next service is due  
  - track usage per car  
- Dedicated **TripTracking** and **TripHUD** screens

---

### 🔔 5. Smart Reminders

Never miss important maintenance:

- Local push notifications  
- Time-based and mileage-based reminders  
- Per-car scheduling logic  

---

### 🔌 6. Connectivity (Work in Progress)

- **Bluetooth** connection screen  
- **OBD-II live data** preview screen  
- Future integration with real OBD adapters

---

### 🧩 7. UI & Experience

- Fully **SwiftUI-based** interface  
- Welcome & onboarding flow  
- Custom components:
  - cards  
  - banners  
  - progress indicators  
  - animated overlays  
- Sound feedback via `SoundManager`

---

## 🧱 Architecture Overview

The project uses a **feature-first modular architecture**, designed to scale:

```text
FluiDex_Drive/
├── App/
├── Features/
│   ├── Authentication/
│   ├── CarSetup/
│   ├── Dashboard/
│   ├── Maintenance/
│   ├── TripTracking/
│   ├── Profile/
│   ├── Notifications/
│   ├── Onboarding/
│   └── Bluetooth/
├── Managers/
├── Models/
├── UIComponents/
├── Sounds/
├── FluiDex_Drive/
└── Assets/
```

Architecture style

SwiftUI + ViewModel

Core Data for local persistence

Dedicated Managers layer for business logic

Partial Firebase Sync integration

🗄 Data Model (Core Data)

FluiDex Drive uses Core Data with a relational model optimized for multi-user & multi-car scenarios.

👤 User

id: UUID

name: String

email: String

password: String (demo only)

createdAt: Date

Relationships:

cars (to-many Car)

services (to-many ServiceRecord)

🚗 Car

id: UUID

name, brand, model, year, vin, fuelType

mileage: Int32

isSelected: Bool

Relationships:

owner (to-one User)

records (to-many ServiceRecord)

trips (to-many Trip)

fluids (to-many Fluid)

maintenanceItems (to-many MaintenanceItem)

rules (to-many ServiceRule)

🧾 ServiceRecord

id: UUID

date: Date

mileage: Int32

type: String

note: String

costLabor: Double

costParts: Double

totalCost: Double

nextServiceDate: Date

nextServiceKm: Int32

receiptImageData: Binary Data

Relationships:

car (to-one Car)

user (to-one User)

📍 Trip

id: UUID

date: Date

distance: Double

Relationship:

car (to-one Car)

Additional entities: Fluid, MaintenanceItem, ServiceRule.

🛠 Tech Stack

Language: Swift

UI: SwiftUI

Architecture: Feature-first, MVVM-style, managers/service layer

Persistence: Core Data

Cloud / Backend: Firebase (GoogleService-Info.plist)

System APIs: UserNotifications, Bluetooth (WIP)

Other: Custom animations, sound effects

📸 Screenshots

Coming soon – UI is under active development.

| Dashboard | Service Log | Trip Tracking | Car Setup |
|----------|-------------|---------------|-----------|
| ![](Docs/dashboard.png) | ![](Docs/service-log.png) | ![](Docs/trip.png) | ![](Docs/car-setup.png) |

🚀 Getting Started
Requirements

macOS with Xcode 15+

Swift 5.9+

iOS 16+ deployment target

🗺 Roadmap

 Full Firebase sync for users, cars & services

 Real OBD-II adapter support

 Advanced trip analytics (speed, duration, fuel estimation)

 Theme engine & dark mode polish

 Export service history to PDF/CSV

 Smarter AI-based maintenance suggestions

 🤝 Contributing

This is a portfolio / learning project.
Suggestions, ideas, or code reviews are always welcome via GitHub issues or pull requests.

👩‍💻 Author

Irina S. – Junior Mobile & Web Developer
Focus: Swift, SwiftUI, Firebase, Core Data

Feel free to explore the code, open issues, or reach out with feedback.
