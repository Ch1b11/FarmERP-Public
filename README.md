# FarmERP — Workforce & Employee Management Module

> **Public Architecture Showcase:**  
> This repository contains a production-grade feature slice extracted from **FarmERP**, a multi-tenant enterprise resource planning system built with Flutter and Dart. It showcases Clean Architecture, event-driven state management (BLoC), offline-first repository patterns, and responsive UI design across 48 Dart files.

---

## 🏛️ Architectural Overview

The application follows a strict **Feature-First Clean Architecture** pattern, enforcing absolute separation between domain business rules, data infrastructure, and presentation logic. Below is the full architectural tree map showing the enterprise shared core foundation alongside the 20 modular feature domains, spotlighting the showcased **Employees** workforce feature:

```text
lib/
├── core/                        # Enterprise Shared Infrastructure & Foundations
│   ├── constants/
│   │   └── constants.dart       # Global API routes, timeouts, and design tokens
│   ├── di/
│   │   └── injection_container.dart # Centralized GetIt service locator & factories
│   ├── errors/
│   │   ├── exceptions.dart      # Low-level network & storage exceptions
│   │   └── failures.dart        # Typed domain failure hierarchy (Server, Network, Cache, Auth)
│   ├── layout_manager/
│   │   └── adaptive_layout_manager.dart # Tri-tier responsive builder (Mobile, Tablet, Desktop)
│   ├── models/
│   │   └── drawer_item_model.dart # Navigation drawer abstractions
│   ├── network/
│   │   ├── api_client.dart      # Base HTTP client configuration
│   │   ├── auth_event_bus.dart  # Cross-cutting auth event broadcast stream
│   │   ├── auth_interceptor.dart # JWT injection, tenant header & 401 token refresh queue
│   │   ├── basic_network_interceptor.dart # Request logging & network diagnostics
│   │   └── network_info.dart    # Connectivity check abstractions
│   ├── routing/
│   │   ├── app_router.dart      # GoRouter configuration & deep link mappings
│   │   ├── go_router_refresh_stream.dart # Reactive router listenable for BLoC auth streams
│   │   └── rbac_guard.dart      # Role-based route access controller & permissions guard
│   ├── services/
│   │   ├── session_manager.dart # Active session & farm context state
│   │   └── storage_service.dart # Multi-tenant partitioned Hive storage manager
│   ├── shell/
│   │   └── main_app_shell.dart  # Adaptive shell scaffold with drawer & bottom nav
│   ├── sync/
│   │   ├── async_lock.dart      # Async mutex lock for race-free queue execution
│   │   ├── pending_mutation.dart # Serialized outbox mutation DTO
│   │   └── sync_service.dart    # Background FIFO offline sync & cascading ID swap engine
│   ├── theme/
│   │   ├── app_spacing.dart     # Canonical padding & margin design tokens
│   │   ├── language_cubit.dart  # Language & RTL locale state management
│   │   ├── theme.dart           # Light/Dark Material 3 theme configurations
│   │   ├── theme_cubit.dart     # Dynamic theme switching Cubit
│   │   └── theme_state.dart     # Theme state models
│   ├── utils/
│   │   ├── app_snack_bar.dart   # Floating UI toast & notification utilities
│   │   ├── asset_type_utils.dart # File & MIME resolution helpers
│   │   ├── date_formatter.dart  # Localized date & time formatting
│   │   ├── dio_error_parser.dart # Backend ProblemDetails & rate limit error parser
│   │   ├── field_update.dart    # Partial update helpers
│   │   ├── id_utils.dart        # UUID & numeric ID parsing utilities
│   │   ├── live_markdown_controller.dart # In-line regex markdown highlighting controller
│   │   ├── logger.dart          # Production-safe logging wrappers
│   │   ├── markdown_utils.dart  # Markdown sanitization & link parsing
│   │   ├── snackbar_utils.dart  # Context-free snackbar dispatchers
│   │   ├── sort_utils.dart      # Id-based and timestamp sorting algorithms
│   │   └── task_parser.dart     # Embedded task syntax parser
│   └── widgets/
│       ├── app_action_button.dart
│       ├── app_circular_indicator.dart
│       ├── app_content_card.dart
│       ├── app_drawer.dart
│       ├── app_dropdown.dart
│       ├── app_editor_sheet.dart
│       ├── app_feature_card.dart
│       ├── app_item_card.dart
│       ├── app_responsive_grid.dart
│       ├── app_selection_modal.dart
│       ├── app_status_badge.dart
│       ├── app_step_row.dart
│       ├── app_text_field.dart
│       ├── app_underlined_text_field.dart
│       ├── breadcrumbs.dart
│       ├── compact_tree_icon.dart
│       ├── custom_appbar.dart
│       ├── drawer_category_header.dart
│       ├── drawer_menu_list.dart
│       ├── drawer_menu_tile.dart
│       ├── empty_state_indicator.dart
│       ├── event_card_widget.dart
│       ├── financial_summary_card.dart
│       ├── processing_dialog.dart
│       ├── quick_action_button.dart
│       ├── section_header.dart
│       ├── shared_app_bar.dart
│       ├── skeleton_loader.dart
│       └── theme_toggle_icon.dart
│
└── features/                    # 20 Enterprise Feature Domains
    ├── auth/                    # Authentication, login, password recovery & token storage
    ├── contracts/               # Commercial contracts, renewals, and lifecycle operations
    ├── crop_types/              # Crop catalog and botanical management
    ├── customer_statements/     # Customer account ledger statements & PDF exports
    ├── customers/               # Customer relationship management & contacts
    ├── dashboard/               # Executive KPI metrics, cards & quick actions
    ├── deliveries/              # Harvest delivery dispatching & tracking
    ├── departments/             # Organizational hierarchy & department CRUD
    ├── employees/               # [Spotlighted in this Repository]
    │   ├── domain/              # Pure Dart domain logic (zero framework dependencies)
    │   │   ├── entities/        # Core business models (Employee, Department, WorkPeriod)
    │   │   ├── repositories/    # Abstract repository contracts (IEmployeesRepository, etc.)
    │   │   ├── usecases/        # 15 isolated command/query use cases
    │   │   └── utils/           # Domain calculations (WorkPeriodCalculator: worked days, wages, net pay)
    │   ├── data/                # Infrastructure implementation & data access
    │   │   ├── datasources/     # Remote (REST) and Local (Hive cache) data sources
    │   │   ├── models/          # DTOs with JSON serialization & local storage mapping
    │   │   └── repositories/    # Repository implementations coordinating network & local cache
    │   └── presentation/        # User interface & reactive state management
    │       ├── bloc/            # BLoCs, Events, and States (EmployeesBloc, EmployeeProfileBloc)
    │       ├── screens/         # Top-level screen widgets (EmployeesScreen, EmployeeProfileScreen)
    │       ├── utils/           # UI presentation helpers, color coding, and initials generation
    │       └── widgets/         # Reusable UI components, sheets, and adaptive layouts
    │           └── components/  # Responsive layout trees (Mobile, Tablet, Desktop)
    ├── fertilizer_categories/   # Agricultural fertilizer categories & specifications
    ├── fertilizer_usage/        # Crop-field chemical application tracking
    ├── fields/                  # Farm plots, field boundaries, and area tracking
    ├── finance/                 # General ledger, payables, receivables & atomic transfers
    ├── inventory/               # Tri-category inventory (crops, fertilizers, equipment)
    ├── planting_batches/        # Sowing batches, field assignment & lifecycle tracking
    ├── purchase_orders/         # Supplier procurement & purchase orders
    ├── reports/                 # Financial, operational, and agronomic reports
    ├── sales_orders/            # Sales pipeline, orders, and fulfillment
    ├── tenants/                 # Multi-tenant farm switching & tenant portal
    └── users/                   # RBAC user management, roles & invitations
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
