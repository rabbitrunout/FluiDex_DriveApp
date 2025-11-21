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

## 🧱 8.  Architecture Overview

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


Architecture style:
- **SwiftUI + ViewModel**
- **Core Data** for local persistence  
- **Managers layer** for business logic  
- Partial **Firebase Sync** layer  

---

## 🗄 9. Core Data Model (Summary)

### User
- id, name, email, password (demo), createdAt  
- relationships: cars, services  

### Car
- id, name, brand, model, year, vin, fuelType, mileage, isSelected  
- relationships: owner, records, trips, fluids, maintenanceItems, rules  

### ServiceRecord
- id, date, mileage, type, costs, nextServiceDate/Km, receiptImageData  
- relationships: car, user  

### Trip
- id, date, distance  
- relationship: car  

Additional: Fluid, MaintenanceItem, ServiceRule  

---

## 🛠 10. Tech Stack

- **Swift**, **SwiftUI**  
- **MVVM / feature-first architecture**  
- **Core Data**  
- **Firebase** (Auth/Sync — partial)  
- **Bluetooth / OBD (work in progress)**  
- **Local Notifications**  
- Custom animations & UI components  

---

## 🚀 Getting Started

1. Clone the repository  
2. Open the project in Xcode  
3. (Optional) add your `GoogleService-Info.plist` for Firebase  
4. Run the app on a simulator or device  

---

## 🗺 Roadmap

- Full Firebase sync  
- Real OBD-II adapter support  
- Advanced trip analytics  
- Theme engine / dark mode  
- PDF/CSV export  
- Improved AI maintenance engine  

---

## 📸 Screenshots

Coming soon – UI is under active development.

| Dashboard | Service Log | Trip Tracking | Car Setup |
|----------|-------------|---------------|-----------|
| ![](Docs/dashboard.png) | ![](Docs/service-log.png) | ![](Docs/trip.png) | ![](Docs/car-setup.png) |


 🤝 Contributing

This is a portfolio / learning project.
Suggestions, ideas, or code reviews are always welcome via GitHub issues or pull requests.

## 👩‍💻 Author  
**Irina Safronova**  
Junior Mobile & Web Developer  
Swift • SwiftUI • Firebase • Core Data 

Feel free to explore the code, open issues, or reach out with feedback.
