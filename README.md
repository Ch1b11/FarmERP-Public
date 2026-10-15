# FarmERP — Workforce & Employee Management Module

> **Public Architecture Showcase:**  
> This repository contains a production-grade feature slice extracted from **FarmERP**, a multi-tenant enterprise resource planning system built with Flutter and Dart. It showcases Clean Architecture, event-driven state management (BLoC), offline-first repository patterns, and responsive UI design across 48 Dart files.

---

## 🏛️ Architectural Overview

The module follows a strict **Feature-First Clean Architecture** pattern, enforcing absolute separation between domain business rules, data infrastructure, and presentation logic:

```text
features/employees/
├── domain/                  # Pure Dart domain logic (zero framework dependencies)
│   ├── entities/            # Core business models (Employee, Department, WorkPeriod)
│   ├── repositories/        # Abstract repository contracts (IEmployeesRepository, IWorkPeriodsRepository)
│   ├── usecases/            # 15 isolated command/query use cases
│   └── utils/               # Domain calculations (WorkPeriodCalculator: worked days, wages, net pay)
│
├── data/                    # Infrastructure implementation & data access
│   ├── datasources/         # Separate Remote (REST) and Local (Hive cache) data sources
│   ├── models/              # DTOs with JSON serialization & local storage mapping
│   └── repositories/        # Repository implementations coordinating network & local cache
│
└── presentation/            # User interface & reactive state management
    ├── bloc/                # BLoCs, Events, and States (EmployeesBloc, EmployeeProfileBloc)
    ├── screens/             # Top-level screen widgets (EmployeesScreen, EmployeeProfileScreen)
    ├── utils/               # UI presentation helpers, color coding, and initials generation
    └── widgets/             # Reusable UI components, sheets, and adaptive layouts
        └── components/      # Responsive layout trees (Mobile, Tablet, Desktop)
```

---

## 🔑 Key Engineering Highlights

### 1. Pure Domain Layer & Use Case Separation
* **15 Granular Use Cases:** Every operation—from employee creation and deactivation to attendance check-in (`StartWorkPeriodUseCase`), salary completion (`CompleteAndSettlePeriodUseCase`), and mid-period cash advances (`AddWithdrawalUseCase`)—is encapsulated into an isolated, testable Use Case class.
* **Deterministic Calculation Utility:** `WorkPeriodCalculator` computes worked day fractions (morning full shift vs. afternoon half shift), gross wage calculations, and net payable balances entirely within the domain layer.

### 2. Dual BLoC State Management
* **`EmployeesBloc`:** Manages directory-level operations including paginated fetching, department filtering, search queries, employee creation, and deactivation. Employs optimistic state updates backed by local persistence.
* **`EmployeeProfileBloc`:** Orchestrates complex employee profile states: instant loading from local cache, non-blocking background synchronization, active work period tracking, bonus/withdrawal transactions, and final settlement workflows.

### 3. Offline-First Data Layer Design
* **Interface Segregation:** Abstract data sources (`EmployeesRemoteDataSource` vs. `EmployeesLocalDataSource`) decouple network I/O from disk storage.
* **Functional Error Handling:** Repository contracts return `Either<Failure, T>` using functional typing (`dartz`), preventing uncaught runtime exceptions and standardizing error states across UI layers.
* **Optimistic Local Caching:** Queries read immediately from local Hive cache while triggering non-blocking remote synchronization.

### 4. Tri-Tier Responsive Presentation
* **Adaptive Breakpoints:** Every screen adapts across three distinct form-factors:
  * **Mobile (`< 600px`):** Single-column stacked cards, modal bottom sheets (`EmployeeEditorSheet`, `CompletePeriodSheet`), and compact metrics.
  * **Tablet (`600px – 1023px`):** Multi-column split views and side drawers.
  * **Desktop (`≥ 1024px`):** Full data grids, persistent side panels, and expanded operation workflows.

---

## 🛠️ Tech Stack & Dependencies

* **Language & Framework:** Dart, Flutter
* **Architecture:** Clean Architecture (Feature-First)
* **State Management:** `flutter_bloc`
* **Functional Programming:** `dartz` (`Either<Failure, T>`)
* **Value Equality:** `equatable`
* **Networking:** `dio`
* **Persistence:** `hive`
* **Navigation:** `go_router`
