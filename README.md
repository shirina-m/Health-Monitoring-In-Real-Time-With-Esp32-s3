# Health Monitoring App

A real-time health monitoring mobile application built using **Flutter** and **Firebase**, designed to track patient vitals and send alerts to caregivers. This project was developed as part of my Software Engineering graduation project and includes both software and hardware components.

---

##  App Features

-  Real-time vital monitoring: heart rate, oxygen level, body temperature, and more.
-  Dynamic charts: visualizes last hour of data using smooth, padded graphs.
-  Push notifications: alerts caregivers of abnormal readings or medication times.
-  Secure cloud data: stores and syncs patient data using Firebase Realtime Database and Firestore.
-  Cross-platform UI: responsive design built using Flutter.

---

##  Hardware Integration (Electrical Part)

The system uses a set of health sensors connected to a **microcontroller (e.g., ESP32)**, which reads the patient’s vital signs and transmits them via **Wi-Fi** to the mobile app.

### Sensors used:
- Heart Rate Sensor (e.g., MAX30100 or pulse sensor)
- Temperature Sensor (e.g., LM35 or DHT11)
- Oxygen Sensor (SpO2 module)

### How it works:
- Microcontroller reads sensor values
- Sends data via BLE or HTTP to the app
- The app timestamps the data and updates Firebase
- Alert system and visualization are handled on the app side

---

## 🛠️ Tech Stack

- **Flutter** – Cross-platform mobile app development
- **Firebase**
  - Realtime Database (for live data)
  - Firestore (for user/config storage)
  - Cloud Messaging (for alerts)
  - Cloud Functions (for scheduled notifications)
- **ESP32** (hardware layer)
- **Dart** (programming language)

---

