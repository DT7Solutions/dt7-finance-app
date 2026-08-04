# 🚀 DT7 Agency Full-Stack Mobile & Web Finance Application

Full-stack financial management solution featuring a **Python Django REST Framework API** backend and a **Flutter cross-platform** mobile/web frontend.

For the full step-by-step setup roadmap, local Wi-Fi environment configurations, mobile build instructions, and backend guide, please refer to:

👉 **[Flutter App README & Setup Guide](file:///d:/mobile_app/dt7-finance-app/finance_app/README.md)**

---

## ⚡ Quick Start Summary

### 1. Start Django Backend (Local Network)
```bash
cd backend
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver 0.0.0.0:8000
```

### 2. Start Flutter App (Local Network / Wi-Fi)
```bash
cd finance_app
flutter pub get
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

### 3. Connect from Laptop & Phone
- **Laptop**: `http://localhost:8080`
- **Phone (Same Wi-Fi)**: `http://<YOUR_LAPTOP_IP>:8080` (e.g., `http://192.168.0.7:8080`)

---
© 2026 DT7 Agency. All rights reserved.