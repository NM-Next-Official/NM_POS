<div align="center">

# 🚀 NM_POS
### *A Modern, Cross-Platform Point of Sale (POS) & Inventory System*

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-%23316192.svg?style=for-the-badge&logo=postgresql&logoColor=white)](https://www.postgresql.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge](https://opensource.org/licenses/MIT)

</div>

---

## 📌 Overview

**NM_POS** is a robust, lightning-fast Point of Sale and inventory application engineered for retail and service workflows. Built using **Flutter**, it delivers a seamless native experience across **Windows Desktop, Web, and Mobile**, backed by a secure **PostgreSQL** database backend, hardware peripherals integration, and Gmail OTP verification.

---

## ✨ Key Features

* **⚡ Cross-Platform Support:** Runs natively on Windows Desktop, Web browsers, and mobile platforms.
* **🐘 Transactional PostgreSQL Integration:** Isolated accounts per sign-in. Checkout handles stock locking, availability verification, snapshot tracking, discount/gross profit calculations, and inventory reduction within a single atomic database transaction.
* **📷 Advanced Barcode Scanning:** Supports phone camera scanning (`mobile_scanner`) and USB/Bluetooth HID keyboard barcode scanners.
* **🖨️ Thermal Receipt Printing:** ESC/POS-compatible thermal printer support via USB and Bluetooth Low Energy (`universal_ble`, `bluez`).
* **🔐 Secure Authentication & OTP:** Integrated user authentication with automated Gmail API email OTP verification.

---

## 🛠️ Tech Stack

* **Frontend:** Flutter / Dart (Desktop, Web, Mobile)
* **Database:** PostgreSQL (`postgres