# FluiDex Drive 🚗📱  
Smart vehicle maintenance & trip tracking app

**FluiDex Drive** is an iOS app built with SwiftUI that helps drivers track car condition, service history, mileage, trips, and upcoming maintenance.  
Designed as a portfolio & capstone project by **Irina S.**

---

## ✨ Overview

FluiDex Drive works like a digital health journal for your car.  
The app helps drivers:

- remember **when to change oil, fluids, filters, tires**  
- view a full **service history** with costs and mileage  
- track **trips and distance** for smarter maintenance  
- get **smart reminders** based on date or odometer  
- store **multiple cars** and receipts in one place  

---

## 🌟 Key Features

### 👤 Authentication & Profiles
- Email-based sign up & login  
- Each user can manage multiple cars  

### 🚗 Car Management
- Add cars with brand, model, year, VIN, fuel type, mileage, image  
- Select an active car for dashboard and tracking  

### 🛠 Smart Maintenance & Service Log
- Create service records:
  - date, mileage  
  - service type  
  - parts & labor cost  
  - next service date / mileage  
  - receipt photo  
- View complete service history  
- Rule-based and AI-assisted maintenance suggestions  

### 📍 Trip Tracking
- Log trips with date and distance  
- Use trip data to predict upcoming maintenance  
- Trip Tracking screen + trip HUD  

### 🔔 Notifications
- Local reminders for upcoming maintenance  
- Date-based and mileage-based alerts  

### 🔌 Connectivity (in progress)
- Bluetooth connection UI  
- OBD-II live data preview  

### 🧩 UI & Experience
- Fully SwiftUI interface  
- Custom animations  
- Welcome / onboarding flow  
- Reusable UI components:
  - cards  
  - progress indicators  
  - banners  
  - overlays  
- Sound effects for user actions  

---

## 🧱 Architecture

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

## 🗄 Core Data Model (Summary)

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

## 🛠 Tech Stack

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

## 👩‍💻 Author  
**Irina S.**  
Junior Mobile & Web Developer  
Swift • SwiftUI • Firebase • Core Data  

---

