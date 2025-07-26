# 🩺 Real-Time Health Monitoring System with Wearable Device

This system is a complete real-time health monitoring solution that integrates a **wearable device** with a **cross-platform mobile application**. It enables users to continuously monitor vital signs like **heart rate**, **SpO₂**, and **body temperature** via Wi-Fi using Firebase.

---

## 📱 Project Summary

This project tackles the limitations of traditional health devices by delivering:

- ✅ Real-time monitoring of vital signs
- ✅ A compact, wearable device (wristband)
- ✅ A mobile app with role-based access (patients, caregivers)
- ✅ Push notifications for medication reminders
- ✅ Firebase-powered backend for real-time data sync and user authentication

---

## 🧰 Technologies Used

### 🔌 Hardware
- **XIAO ESP32S3** microcontroller  
- **MAX30102** (heart rate and SpO₂ sensor)  
- **MLX90614** (contactless body temperature sensor)  
- **3.7V LiPo Battery** with built-in charging  
- **Custom PCB** (designed with KiCAD)

### 💻 Software
- **Flutter (Dart)** – Cross-platform mobile development  
- **Firebase** – Realtime Database, Authentication, Cloud Messaging  
- **Arduino IDE** – Firmware development for ESP32S3  
- **Figma** – UI/UX wireframes and app design  

---

## 🏗️ System Architecture

1. **Wearable Device** collects sensor data every 3 seconds.
2. Data is transmitted over Wi-Fi to **Firebase Realtime Database**.
3. **Mobile App** retrieves and displays this data in real time.
4. **Notifications** remind users to take scheduled medications.

---

## 📲 App Features

- **Home Tab:** View live heart rate, SpO₂, and body temperature  
- **Patients Tab:** Caregivers monitor linked users’ vitals  
- **Medication Tab:** Add medications and receive reminders  
- **Profile Tab:** View account and personal information  
- **Firebase Authentication:** Secure email/password login  

---

## 🔐 Security

- All communications use HTTPS  
- Data is stored in Firebase under authenticated user IDs  
- Access is limited based on user relationships (not fixed roles)

---

## ⚙️ Hardware Details

| Component | Function |
|----------|----------|
| MAX30102 | Heart rate & SpO₂ sensing |
| MLX90614 | Infrared body temperature sensing |
| ESP32S3  | Wi-Fi microcontroller for data handling |
| LiPo Battery | 400mAh, rechargeable |
| PCB | Custom-designed for wearable size |
| Wi-Fi | Device and app must be on same network |

---

## 🧪 Testing & Validation

- ✅ Compared sensor data with medical-grade references  
- ✅ Verified real-time performance under weak Wi-Fi  
- ✅ Functional testing of reminders, authentication, and dashboard  
- ✅ Achieved <1s latency from sensor → cloud → app  
- ✅ 8+ hour battery life confirmed during field testing  

---
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

