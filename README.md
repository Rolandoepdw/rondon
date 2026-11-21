<div align="center">

# 🛡️ Rondón
### **Community Security Shift Management & Volunteer Coordination Platform**

[![Flutter](https://img.shields.io/badge/Flutter-3.13%2B-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.1%2B-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![SQLite](https://img.shields.io/badge/SQLite-ACID-003B57?style=for-the-badge&logo=sqlite&logoColor=white)](https://www.sqlite.org)
[![Clean Architecture](https://img.shields.io/badge/Architecture-Pragmatic%20Clean-FF6F00?style=for-the-badge)](https://clean-code-blog.com/uncle-bobs-clean-architecture-summary/)

*A robust, local-first desktop & mobile application designed to coordinate, schedule, replan, and audit community security patrols and volunteer neighbor shifts.*

</div>

---

## 🌟 Core Features

| Feature | Description |
| :--- | :--- |
| 🔄 **Smart Cycle Generation** | Fair-share scheduling engine respecting rest periods (`min_days_between_shifts`), operational profiles (`ACTIVE`, `SUPPORT`), and gender policies. |
| 👥 **Squad & Neighbor Management** | Complete registry of community members, operational profiles (`ACTIVE`, `SUPPORT`), and base affinities. |
| ⚖️ **Score Ledger (Point Balance)** | Immutable accounting ledger tracking attendance, unexcused absences, voluntary coverages, and administrative adjustments. |
| 🔄 **Intelligent Substitutions** | Automated absence replacement workflow calculating penalty points and prioritizing candidates by debt balance. |
| 📋 **Post-Shift Auditing** | Comprehensive attendance verification interface to close out shifts and update member balances. |

---

## 🏗️ Technical Architecture

Rondon is built using **Pragmatic Clean Architecture** combined with **Cubit** state management and **GetIt** dependency injection.

```mermaid
graph TD
    UI[Presentation / Pages & Cubits] --> Repo[Repositories]
    Repo --> DB[(SQLite Database & Triggers)]
    DB --> |Triggers AFTER INSERT/UPDATE| Bal[Neighbors.balance Synchronization]
```

### Domain Types & Constants (Domain Enums)
- **`Gender`**: `MALE`, `FEMALE`
- **`OperationalProfile`**: `ACTIVE`, `SUPPORT`
- **`AllowedGenderPolicy`**: `FEMALE_ONLY`, `MALE_ONLY`, `MIXED`

---

## 💾 Local Persistence & ACID Triggers

The local SQLite database (`rondon.db`) enforces strict relational integrity:
- **Automated Balance Triggers**: SQLite triggers (`AFTER INSERT`, `AFTER UPDATE`, `AFTER DELETE` on `balance_ledger_records`) automatically compute and update `neighbors.balance`, guaranteeing 100% data consistency.
- **Ledger Protection**: Foreign key constraints (`ON DELETE RESTRICT`) prevent accidental deletion of neighbors with active financial/point history.

---

## 🚀 Getting Started

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/rondon.git
   cd rondon
   ```
2. **Install dependencies**:
   ```bash
   flutter pub get
   ```
3. **Run the application**:
   ```bash
   flutter run
   ```

---

## 🧪 Testing

Rondon features a comprehensive unit and integration test suite:

```bash
flutter test
```
