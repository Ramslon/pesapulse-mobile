![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)

![Laravel](https://img.shields.io/badge/Laravel-12-red?logo=laravel)

![PHP](https://img.shields.io/badge/PHP-8.x-purple?logo=php)

![MySQL](https://img.shields.io/badge/MySQL-Database-blue?logo=mysql)

![License](https://img.shields.io/badge/License-MIT-green)

![Version](https://img.shields.io/badge/Version-1.0.0-brightgreen)

# 💰 PesaPulse

> **Smart Personal Finance Management System**

PesaPulse is a modern personal finance application built with **Flutter** and **Laravel** that helps users manage expenses, income, budgets, savings goals, and financial insights through intelligent analytics and forecasting.

Designed with an **offline-first architecture**, PesaPulse allows users to continue managing their financial data even without internet connectivity. Data is stored locally and synchronized automatically when connectivity is restored.

---

## 🚀 What's New in v1.0.0

- Modern login and registration experience
- Secure authentication using Laravel Sanctum
- Improved authentication and session handling
- Guest mode with guest-to-user data migration
- Secure user-specific and guest-specific data ownership
- Redesigned authentication screens
- New onboarding experience with interactive pages
- Persistent onboarding completion state
- Smart analytics redesign with improved insights
- Offline-first synchronization with pending changes tracking
- Improved offline/online transition handling
- Improved synchronization reliability and error recovery
- API rate-limit detection and handling
- Protected authenticated API requests
- Centralized API request handling
- Material 3 design system with responsive layouts
- Cache-first data loading
- Background API refresh
- Reduced unnecessary network requests
- Optimized application startup and navigation
- Improved Dashboard and Analytics loading performance
- Responsive Settings loading skeleton
- Improved loading, empty and error states
- Improved application stability and performance

---

## ✨ Features

### 💰 Expense Management

- Add, edit and delete expenses
- Categorization, filtering, searching and sorting
- Monthly expense tracking
- Offline expense management
- Automatic and manual synchronization
- Sync status tracking
- Local data caching

### 💵 Income Management

- Add and track income sources
- Monthly income summary
- Offline income management
- Income synchronization
- Local data persistence

### 📊 Budget Management

- Create, edit and delete monthly budgets
- Budget health indicators
- Overspending alerts
- Spending progress bars
- Daily spending trends
- Budget insights and recommendations
- Offline budget management
- Automatic synchronization
- Cached budget data

### 🎯 Financial Goals

- Create, edit and delete savings goals
- Track progress and milestones
- Goal forecasting and analytics
- Archive and restore completed goals
- Goal completion predictions
- Offline goal management
- Goal notifications
- Background synchronization

### 📈 Analytics

- Financial Health Score
- Smart financial recommendations
- Spending trends
- Category breakdowns
- Goal progress analytics
- PDF and CSV export
- Cached analytics for offline access
- Background analytics refresh
- Period-based analytics processing

### 🔔 Notifications

- Daily reminders
- Weekly summaries
- Goal milestone alerts
- Budget alerts
- Goal deadline reminders
- Local notification support
- Preference change notifications

### 🔐 Security

- Secure authentication with Laravel Sanctum
- Protected authenticated API requests
- Session management
- OTP verification
- Password reset
- Account deletion
- User-specific data ownership
- Guest-specific data ownership
- Guest-to-user data migration
- API rate-limit handling
- Sensitive endpoint protection
- Improved authorization and validation
- Protected local financial data
- Secure session cleanup during logout

### ⚡ Performance & Reliability

- Cache-first screen initialization
- Background API refresh
- Reduced duplicate API requests
- Parallel network requests where appropriate
- Local SQLite caching
- Offline-first data access
- Background synchronization
- Connectivity-aware synchronization
- Request timeout handling
- Rate-limit handling
- Improved error recovery
- Optimized application startup
- Preserved tab state using `IndexedStack`
- Responsive loading skeletons
- Improved loading and empty states

---

## 🧭 Onboarding Experience

- First-launch onboarding with interactive pages
- Clear introduction to PesaPulse features
- "Get Started" flow
- "Jump In" shortcut
- Dedicated authentication choice screen
- Guest mode
- Guest-to-user data migration
- Persistent onboarding completion state

---

## 🏗 System Architecture

```text
┌───────────────────────────────┐
│       Flutter Mobile App      │
│                               │
│  UI / Screens / Widgets       │
│  Controllers                  │
│  Providers                    │
│  Repositories                 │
│  Services                     │
│  Local SQLite Database        │
│  Offline Sync                 │
│  Local Caching                │
└───────────────┬───────────────┘
                │ REST API
                ▼
┌───────────────────────────────┐
│        Laravel Backend        │
│                               │
│  Authentication               │
│  Authorization                │
│  Business Logic               │
│  REST API                     │
│  Laravel Sanctum              │
│  Validation                   │
│  Rate Limiting                │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│        MySQL Database         │
└───────────────────────────────┘

---

---

## 🌐 Backend API

RESTful API built using Laravel.

## Main Modules

- Authentication
- Expenses
- Budgets
- Goals
- Analytics
- Notifications
- User Preferences
- Settings

---

# 🛠 Technology Stack

## Frontend

- Flutter
- Dart

## Backend

- Laravel
- PHP

## Database

- MySQL
- SQLite (local/offline)

## Authentication

- Laravel Sanctum

## Notifications

- Flutter Local Notifications

## Architecture

- Repository Pattern
- Offline-First
- REST API
- Local Caching
- Background Sync

---

# 📂 Project Structure

```text
lib/
├── screens/
├── widgets/
├── services/
├── models/
├── repositories/
├── providers/
├── controllers/
├── utils/
└── database/

backend/
├── app/
├── routes/
├── database/
├── migrations/
└── config/

```

---

# 🚀 Installation

## Backend

```bash
git clone <repository>

cd backend

composer install

cp .env.example .env

php artisan key:generate

php artisan migrate

php artisan serve
```

---

## Flutter

```bash
flutter pub get

flutter run
```
---

# 📦 Releases

### Latest Stable Release

**PesaPulse v1.0.0**

The first stable production release of PesaPulse, incorporating the core financial management system together with authentication, offline-first functionality, synchronization, security improvements, analytics, performance optimization and responsive UI improvements.

### Historical Beta Releases

- **v0.1.0-beta** — Initial feature set
- **v0.2.0-beta** — Smart goals and advanced analytics
- **v0.3.0-beta** — Settings, notifications and branding
- **v0.4.0-beta** — Smart Analytics, Financial Health Score and Reports Center

---

# 🎥 Demo

A demonstration of PesaPulse is planned for a future release.

Demo video coming soon...

---

# 📸 Screenshots

<p align="center">
  <a href="docs/screenshots/dashboard.jpeg">
    <img src="docs/screenshots/dashboard.jpeg" alt="Dashboard" width="280"/>
  </a>

  <a href="docs/screenshots/budget_overview.jpeg">
    <img src="docs/screenshots/budget_overview.jpeg" alt="Budget Overview" width="280"/>
  </a>
</p>

<p align="center">
  <a href="docs/screenshots/analytics-dashboard.jpeg">
    <img src="docs/screenshots/analytics-dashboard.jpeg" alt="Analytics Dashboard" width="280"/>
  </a>

  <a href="docs/screenshots/settings-profile.jpeg">
    <img src="docs/screenshots/settings-profile.jpeg" alt="Profile Overview" width="280"/>
  </a>
</p>

<p align="center">
  <sub><b>Dashboard</b></sub>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <sub><b>Budget Overview</b></sub>
</p>

<p align="center">
  <sub><b>Analytics Dashboard</b></sub>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <sub><b>Profile Overview</b></sub>
</p>

---

# 🌟 Highlights

- 📱 Material 3 Design
- 📊 Smart Financial Analytics
- 💰 Intelligent Budget Management
- 🎯 Savings Goal Tracking
- 📈 Financial Health Score
- 📄 PDF & CSV Report Export
- 🌙 Dark Mode Support
- 🔔 Smart Notifications
- 👤 Guest Mode
- 🔄 Guest-to-User Data Migration
- 📡 Offline-First Architecture
- 🔄 Automatic Synchronization
- ⚡ Optimized Performance
- 📱 Responsive Mobile Experience
- 🔐 Secure Authentication
- 📊 Personalized Financial Insights
- 🛡️ API Security and Rate-Limit Handling
- 🔁 Connectivity-Aware Synchronization

---

# 📊 Version History

| Version | Release | Highlights |
|---------|---------|------------|
| **v1.0.0** | Stable | Production release with authentication, onboarding, guest mode, guest-to-user migration, offline-first synchronization, security hardening, rate-limit handling, analytics, budgets, goals, notifications, caching, background refresh and performance improvements |
| **v0.4.0-beta** | Beta | Smart Analytics redesign, Financial Health Score, Reports Center, UI polish |
| **v0.3.0-beta** | Beta | Settings redesign, password management, notifications, branding and UX improvements |
| **v0.2.0-beta** | Beta | Smart goals, advanced analytics, budget intelligence and financial insights |
| **v0.1.0-beta** | Beta | Initial PesaPulse feature set including expense tracking, budgets and authentication |
---

# 🗺 Roadmap

## ✅ Version 1.0 Stable

- The first stable production release of PesaPulse.

### 🔐 Authentication
- User registration and login
- Guest mode
- Guest-to-user migration
- OTP verification
- Password reset
- Session management
- Account deletion
- Secure authenticated API requests
- User data isolation
- Guest data isolation
- Improved authorization and validation
- Sensitive endpoint protection
- API rate-limit handling
- Improved logout reliability
- Secure local session cleanup

---

### 💰 Financial Management
- Expense management
- Budget management
- Savings goals
- Goal forecasting
- Goal analytics
- Financial analytics
- Financial Health Score
- Financial recommendations
---

### 📡 Offline-First
- Local SQLite storage
- Offline financial management
- Background synchronization
- Automatic synchronization
- Manual synchronization
- User-specific local data
- Guest-specific local data
- Connectivity-aware synchronization
- Sync status tracking
---
### 🎨 User Experience
- Onboarding experience
- Material 3 interface
- Responsive layouts
- Dark mode
- Notifications
- Improved navigation
- Custom application branding
- Responsive Settings interface
- Improved loading states
- Improved error states

---
### ⚡ Performance & Reliability
- Cache-first screen loading
- Background API refresh
- Reduced unnecessary network requests
- Parallel API requests
- Local data caching
- Improved synchronization reliability
- Improved offline/online transition handling
- Request timeout handling
- Rate-limit handling
- Error recovery
- Optimized application startup
- Improved navigation performance
- Responsive loading skeletons
- Improved loading and empty states


---

## 🚧 Version 1.1.0 — Enhancements & Intelligence

The next release will focus on new capabilities, deeper financial intelligence, enhanced customization and improvements based on user feedback, rather than the foundational stability and security work already completed in v1.0.0.

### 🧠 Financial Intelligence

- Enhanced financial intelligence
- More advanced financial forecasting
- Improved spending predictions
- Advanced financial recommendations
- More detailed financial health analysis
- Personalized financial planning

### 📊 Analytics & Reporting

- Additional financial reports
- More advanced data visualization
- Expanded analytics dashboards
- Additional export capabilities
- Comparative financial analysis
- Improved historical financial analysis

### 🔔 Notifications

- Enhanced notification system
- More personalized financial alerts
- Custom notification schedules
- Additional goal and budget notifications

### 🎨 Customization

- Additional customization options
- Expanded dashboard customization
- More personalization features
- Enhanced theme options

### ☁️ Synchronization

- Further cloud synchronization improvements
- Improved cross-device synchronization
- Expanded data recovery capabilities

## 🔮 Future Development

Future releases may introduce additional improvements based on user feedback, testing, and project requirements.

###  Potential areas include:

- Advanced financial planning
- Investment tracking
- Recurring transactions
- Subscription management
- Advanced budgeting tools
- More intelligent financial forecasting
- Additional platform support
- Expanded cloud services
- Advanced personalization
- Further security improvements
 

---

# 🤝 Contributing

Contributions, issues, and feature requests are welcome.

If you'd like to improve PesaPulse, feel free to fork the repository and submit a pull request.

When submitting an issue, please provide:

- A clear description of the issue
- Steps to reproduce the problem
- Expected behavior
- Actual behavior
- Screenshots where applicable
- Device and operating system information

---

## ❤️ Built With

- Flutter
- Dart
- Laravel
- PHP
- MySQL
- Material 3
- Laravel Sanctum
- SQLite
- Flutter Local Notifications

---

# 📄 License

This project is licensed under the MIT License.

---

## 👨‍💻 Developer

**Ramson Lonayo**

Software Engineering Student

Kirinyaga University

Passionate about Flutter, Laravel, Mobile Development and Financial Technology.

---

## ⭐ Support

If you found this project useful, consider giving it a **⭐ Star** on GitHub.
