<<<<<<< HEAD
# Revouge_Srh
Built a reverse-logistics app prototype to improve returns visibility and process tracking (requirements → workflow design → prototype)
=======
# revogue4

A new Flutter project.
 # ♻️ REVOUGE: Sustainable Reverse Logistics Platform

> **SRH Berlin University of Applied Sciences | Digital Supply Chain Management**

Revouge is a mobile-first platform designed to optimize and simplify the reverse logistics process for retail and fashion. Our app digitizes the entire journey—from return initiation to quality check and resale—increasing recovery value, cutting warehouse costs, and extending product lifecycles.

---

## 🚀 Project Overview

**The Problem:** Traditional returns are costly, slow, and environmentally damaging. Items sit in warehouses losing value.
**The Solution:** Revouge introduces a **"Loop Mode"**, allowing verified returns to be resold directly to the next buyer (Peer-to-Peer), skipping the warehouse entirely.

### Key Features
* **🔄 Dual-Interface System:** A single app serving both **Returners** (Sellers) and **Buyers**.
* **📸 AI-Simulated Grading:** Users upload photos of returns; the system assigns a condition score (New, Like-New, Used) and Confidence Level.
* **📦 Smart Routing Logic:**
    * **Loop Mode:** High-quality items are offered immediately to local buyers.
    * **Classic Mode:** Lower-quality items are routed to the warehouse for refurbishment.
* **🛍️ Marketplace:** A dedicated Buyer interface to purchase sustainable, "Loop" items at a discount.
* **📊 Admin Dashboard:** Real-time KPIs (Trips Saved, Acceptance Rate) and an Exceptions Queue for management.

---

## 📱 Application Flow

The application is built with a **Wrapper Architecture** in Flutter, allowing dynamic role switching:

1.  **Login:** Users sign in and are routed based on role (Customer vs. Company).
2.  **Customer Hub:**
    * **Shop:** Browse the "Buy" interface for deals.
    * **Return:** Initiate returns, upload photos, and track status.
3.  **Company Portal:** Admins view dashboards, manage rules, and handle exceptions.

---

## 🛠️ Technology Stack

* **Framework:** Flutter (Dart)
* **Architecture:** Modular file structure with Provider state management.
* **Backend Logic:** Local simulated state (`AppState` & `MockData`).
* **UI/UX:** Material Design 3 with Transparent Glassmorphism styling.

---

## ⚙️ Installation & Setup

To run this project locally for grading:

1.  **Clone the repository**
    ```bash
    git clone [https://github.com/gloria-24/ReVouge_SRH-MAPA-.git](https://github.com/gloria-24/ReVouge_SRH-MAPA-.git)
    ```
2.  **Install Dependencies**
    ```bash
    flutter pub get
    ```
3.  **Run the App**
    ```bash
    flutter run
    ```

> **Note:** The app uses a transparent background image. Ensure `assets/Revouge.jpg` is present.
