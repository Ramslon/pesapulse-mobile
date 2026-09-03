# Changelog

All notable changes to **PesaPulse** are documented in this file.

The format is based on **Keep a Changelog** and the project follows **Semantic Versioning (SemVer)**.

---

# PesaPulse v1.0.0 - 2026-08-20

## 🎉 Stable Production Release

PesaPulse v1.0.0 is the first stable production release of the modern PesaPulse Personal Finance Management System.

This release brings together the core financial management system with redesigned authentication and onboarding, guest mode, guest-to-user data migration, offline-first functionality, synchronization, intelligent analytics, budgeting, savings goals, notifications, security improvements, API rate-limit handling, cache-first loading, background refresh, responsive UI, and improved application reliability.

---

## 🚀 What's New

### 🧭 Onboarding Experience

- Added first-launch onboarding experience.
- Added interactive onboarding pages.
- Added clear introduction to PesaPulse features.
- Added "Get Started" flow.
- Added "Jump In" shortcut.
- Added dedicated authentication choice screen.
- Added persistent onboarding completion state.
- Improved navigation between onboarding and authentication.

---

### 🔐 Authentication & Account Management

- Added modern login experience.
- Added modern registration experience.
- Implemented secure authentication using Laravel Sanctum.
- Added guest mode.
- Added guest-to-user account migration.
- Added OTP verification.
- Added password reset functionality.
- Improved session management.
- Added account deletion functionality.
- Improved logout workflow.
- Improved authentication navigation.
- Improved user data ownership handling.
- Improved authenticated API request protection.
- Improved session cleanup.

---

### 👤 Guest Mode

- Added ability to use PesaPulse without creating an account.
- Added guest-specific local data ownership.
- Added guest session management.
- Added guest-to-user migration.
- Guest financial data can be migrated when a guest creates an account.
- Improved separation between guest and authenticated user data.
- Improved guest data synchronization handling.

---

## 💰 Financial Management

### 💸 Expense Management

- Added expense creation.
- Added expense editing.
- Added expense deletion.
- Added expense categorization.
- Added expense search.
- Added expense filtering.
- Added expense sorting.
- Added monthly expense tracking.
- Added offline expense management.
- Added automatic synchronization.
- Added manual synchronization.
- Added synchronization status tracking.
- Added pending changes tracking.
- Added local expense caching.

---

### 💵 Income Management

- Added income management.
- Added income sources.
- Added income records.
- Added monthly income summaries.
- Added offline income management.
- Added income synchronization.
- Added local income persistence.

---

### 📊 Budget Management

- Added monthly budget creation.
- Added budget editing.
- Added budget deletion.
- Added budget health indicators.
- Added overspending alerts.
- Added spending progress indicators.
- Added daily spending trends.
- Added budget insights.
- Added budget recommendations.
- Added smart budget status indicators.
- Added budget synchronization.
- Added offline budget management.
- Added cached budget data.
- Added pull-to-refresh support.
- Improved budget overview presentation.

---

### 🎯 Financial Goals

- Added savings goal creation.
- Added savings goal editing.
- Added savings goal deletion.
- Added goal progress tracking.
- Added goal milestone tracking.
- Added goal forecasting.
- Added goal analytics.
- Added goal completion predictions.
- Added expected progress calculations.
- Added completion estimates.
- Added recommended monthly savings calculations.
- Added goal archive and restore functionality.
- Added completed goal presentation.
- Added goal notifications.
- Improved goal cards.
- Improved goal progress visualization.
- Improved goal synchronization.

---

# 📈 Analytics

### 📊 Financial Analytics

- Added Financial Health Score.
- Added Smart Recommendations.
- Added spending trend analysis.
- Added category spending breakdown.
- Added daily spending analytics.
- Added goal progress analytics.
- Added budget insights.
- Added financial recommendations.
- Added period-based analytics processing.
- Added cached analytics for offline access.
- Added background analytics refresh.
- Improved analytics data processing.

---

### 📄 Reports

- Added Reports Center.
- Added PDF report export.
- Added CSV report export.
- Added report history.
- Added report history management.
- Added report history clearing.
- Improved report export actions.
- Improved report presentation.

---

### 🎨 Analytics UI & UX

- Redesigned Analytics Overview card.
- Added improved visual hierarchy.
- Added Financial Health Score card with dynamic status indicators.
- Added Smart Recommendation card.
- Added budget status badge.
- Added category insights.
- Added budget usage progress indicator.
- Added animated analytics transitions.
- Redesigned statistics cards.
- Added themed circular icons.
- Added color-coded statistic icons.
- Improved PDF and CSV export actions.
- Improved analytics section headers.
- Improved chart responsiveness.
- Improved Reports Center presentation.
- Added analytics skeleton loading.
- Improved consistency with Dashboard and Budget screens.

---

## 🔔 Notifications

- Added local notification service.
- Added daily reminders.
- Added weekly financial summaries.
- Added budget alerts.
- Added budget deadline reminders.
- Added expense alerts.
- Added goal milestone notifications.
- Added goal completion notifications.
- Added notification preferences.
- Added backend notification preference synchronization.
- Added preference change notifications.
- Improved notification persistence.
- Improved notification error handling.

---

## 📡 Offline-First Architecture

- Added local SQLite database.
- Added offline financial management.
- Added offline expense management.
- Added offline income management.
- Added offline budget management.
- Added offline goal management.
- Added cached analytics.
- Added pending changes tracking.
- Added automatic synchronization.
- Added manual synchronization.
- Added background synchronization.
- Added synchronization status tracking.
- Added user-specific local data ownership.
- Added guest-specific local data ownership.
- Added connectivity-aware synchronization.
- Improved offline-to-online transition handling.
- Improved synchronization reliability.
- Improved synchronization error recovery.
- Improved handling of pending local changes.

---

## 💾 Local Caching & Cache-First Loading

- Added cache-first Dashboard initialization.
- Added cache-first Analytics initialization.
- Added cache-first Settings initialization.
- Added cached profile data.
- Added cached dashboard statistics.
- Added cached budget data.
- Added cached analytics data.
- Added cached financial insights.
- Added local SQLite-backed application caching.
- Added background API refresh after cached data is displayed.
- Reduced dependency on network availability during screen initialization.
- Improved offline startup experience.
- Improved local data availability.

---

## 🔄 Background Synchronization & Refresh

- Added background API refresh.
- Added background analytics refresh.
- Added background Dashboard refresh.
- Added background Settings refresh.
- Added connectivity-aware synchronization.
- Added automatic synchronization after connectivity recovery.
- Reduced duplicate API requests.
- Improved synchronization reliability.
- Improved background error handling.
- Improved rate-limit handling during background operations.
- Improved silent recovery when background requests fail.

---

## ⚡ Performance & Reliability

- Reduced unnecessary widget rebuilds.
- Optimized application startup.
- Optimized navigation.
- Preserved tab state using `IndexedStack`.
- Reduced unnecessary network requests.
- Added parallel API requests where appropriate.
- Improved local database performance.
- Optimized background synchronization.
- Improved cache-first screen loading.
- Added background API refresh.
- Improved request timeout handling.
- Improved rate-limit handling.
- Improved error recovery.
- Improved offline/online transition handling.
- Improved loading performance.
- Added responsive loading skeletons.
- Improved loading states.
- Improved empty states.
- Improved error states.
- Removed unused code and variables.
- Improved state management.
- Improved application stability.

---

## 🛡️ Security

- Implemented secure authentication using Laravel Sanctum.
- Protected authenticated API routes.
- Improved authenticated API request handling.
- Improved session management.
- Improved token management.
- Added user-specific data ownership.
- Added guest-specific data ownership.
- Improved user data isolation.
- Improved guest data isolation.
- Improved input validation.
- Improved authorization handling.
- Added sensitive endpoint protection.
- Improved account deletion workflow.
- Improved password management.
- Improved protection of local financial data.
- Improved session cleanup during logout.
- Improved API request security.
- Improved authentication error handling.

---

## 🚦 API Rate Limiting

- Added centralized API request handling.
- Added HTTP 429 rate-limit detection.
- Added rate-limit exception handling.
- Added support for `Retry-After` response headers.
- Added support for remaining request information.
- Added rate-limit message handling from API responses.
- Improved handling of rate limits across authenticated API requests.
- Improved background refresh behavior when rate limits are encountered.
- Prevented rate-limit failures from unnecessarily interrupting local cached data display.
- Improved application resilience against excessive API requests.

---

## 🌐 API & Network Reliability

- Added centralized HTTP request handling.
- Added request timeout handling.
- Added authenticated API request protection.
- Added standardized API response handling.
- Improved network error handling.
- Improved API exception handling.
- Improved background request failure recovery.
- Improved offline request behavior.
- Improved handling of unavailable backend services.
- Reduced duplicate network requests.
- Improved network-aware application behavior.

---

## 🎨 User Experience

- Introduced Material 3 design system.
- Redesigned authentication screens.
- Redesigned onboarding experience.
- Improved Dashboard interface.
- Improved Budget interface.
- Improved Analytics interface.
- Improved Settings interface.
- Improved navigation.
- Added responsive layouts.
- Added landscape responsiveness.
- Added tablet-friendly layouts.
- Added dark mode support.
- Added responsive loading skeletons.
- Improved loading states.
- Improved empty states.
- Improved error states.
- Improved dialogs.
- Improved snackbar messages.
- Improved form validation.
- Improved application branding.
- Improved overall visual consistency.

---

## 📱 Responsive Design

- Added responsive mobile layouts.
- Added landscape layouts.
- Added tablet-friendly layouts.
- Added responsive Dashboard components.
- Added responsive Analytics components.
- Added responsive Settings components.
- Added responsive loading skeletons.
- Added centralized `ResponsiveHelper`.
- Improved spacing across different screen sizes.
- Improved card sizing across screen sizes.
- Improved grid responsiveness.
- Improved content width handling.
- Improved orientation handling.

---

## 🐞 Bug Fixes

- Fixed budget status color synchronization.
- Fixed analytics progress indicator animation.
- Fixed animated budget usage percentage display.
- Fixed analytics skeleton background inconsistency.
- Fixed recommendation card status color handling.
- Fixed multiple responsive layout issues.
- Fixed UI spacing inconsistencies.
- Fixed navigation inconsistencies.
- Fixed session management issues.
- Fixed authentication workflow issues.
- Fixed guest session handling issues.
- Fixed guest data ownership issues.
- Fixed guest-to-user migration workflow issues.
- Fixed goal archive and restore workflow.
- Fixed various analytics UI issues.
- Fixed budget alert rendering issues.
- Fixed layout overflow issues.
- Fixed synchronization issues.
- Fixed offline/online transition issues.
- Fixed background refresh handling.
- Fixed multiple minor UI bugs.

---

## 🛠 Backend

- Added Laravel 12 REST API.
- Added Laravel Sanctum authentication.
- Added MySQL database integration.
- Added authentication APIs.
- Added expense APIs.
- Added income APIs.
- Added budget APIs.
- Added financial goal APIs.
- Added analytics APIs.
- Added notification APIs.
- Added user preference APIs.
- Added settings APIs.
- Added guest data migration API.
- Improved API validation.
- Improved API responses.
- Improved user ownership validation.
- Improved authorization.
- Added API rate limiting.
- Improved authenticated endpoint protection.
- Improved backend error handling.

---

## 📱 Mobile Application

- Added Flutter mobile application.
- Added Dart implementation.
- Added Material 3 interface.
- Added repository-based architecture.
- Added controller/service architecture.
- Added SQLite local database.
- Added offline-first architecture.
- Added REST API integration.
- Added background synchronization.
- Added background API refresh.
- Added local caching.
- Added local notifications.
- Added responsive mobile layouts.
- Added connectivity-aware operations.
- Improved application startup.
- Improved navigation performance.
- Improved screen loading performance.

---

## 🏗 Architecture Improvements

- Improved separation between UI, controllers, repositories and services.
- Improved repository-based data access.
- Improved local database abstraction.
- Improved API service centralization.
- Improved session management architecture.
- Improved offline synchronization architecture.
- Added cache-first data loading strategy.
- Added background refresh strategy.
- Improved connectivity-aware operations.
- Improved state management.
- Improved error handling across application layers.
- Improved separation between guest and authenticated user data.

---

## 📦 Dependencies & Platform

- Updated Flutter application dependencies.
- Updated Laravel backend dependencies.
- Improved compatibility with current Flutter tooling.
- Improved compatibility with Laravel 12.
- Improved SQLite integration.
- Improved local notification integration.
- Improved HTTP networking integration.
- Improved connectivity handling.

---

# 🗺 Roadmap

## ✅ Version 1.0.0 — Stable

The first stable production release includes the foundational financial management system and the major security, reliability, synchronization and performance improvements required for a stable application.

### Completed

- Authentication and account management
- Guest mode
- Guest-to-user data migration
- Expense management
- Income management
- Budget management
- Savings goals
- Goal forecasting and analytics
- Financial Health Score
- Financial recommendations
- Notifications
- Offline-first architecture
- Local SQLite caching
- Automatic synchronization
- Background synchronization
- Cache-first screen loading
- Background API refresh
- Connectivity-aware operations
- API rate-limit handling
- Centralized API request handling
- Secure authenticated API requests
- User and guest data isolation
- Responsive layouts
- Material 3 interface
- Onboarding experience
- Performance optimization
- Improved application reliability

---

## 🚧 Version 1.1.0 — Enhancements & Intelligence

The next release will focus on **new capabilities, deeper financial intelligence, enhanced customization and improvements based on user feedback**, rather than foundational security and stability work already completed in v1.0.0.

### 🧠 Financial Intelligence

- Enhanced financial intelligence.
- More advanced financial forecasting.
- Improved spending predictions.
- Advanced financial recommendations.
- More detailed financial health analysis.
- Personalized financial planning.

### 📊 Analytics & Reporting

- Additional financial reports.
- More advanced data visualization.
- Expanded analytics dashboards.
- Additional export capabilities.
- Comparative financial analysis.
- Improved historical financial analysis.

### 🔔 Notifications

- Enhanced notification system.
- More personalized financial alerts.
- Custom notification schedules.
- Additional goal and budget notifications.

### 🎨 Customization

- Additional customization options.
- Expanded dashboard customization.
- More personalization features.
- Enhanced theme options.

### ☁️ Synchronization

- Further cloud synchronization improvements.
- Improved cross-device synchronization.
- Expanded data recovery capabilities.

---

# 🔮 Future Development

Future releases may introduce additional improvements based on user feedback, testing and project requirements.

### Potential Areas

- Advanced financial planning.
- Investment tracking.
- Recurring transactions.
- Subscription management.
- Advanced budgeting tools.
- More intelligent financial forecasting.
- Additional platform support.
- Expanded cloud services.
- Advanced personalization.
- Further security improvements.

---

# 📄 Release Notes

## v1.0.0

PesaPulse v1.0.0 represents the transition from beta development to the first stable production release.

The release consolidates the core financial management features with major improvements to authentication, guest mode, offline-first operation, synchronization, analytics, caching, performance, API reliability and security.

The application is now structured around a **cache-first and background-refresh architecture**, allowing locally available data to be displayed quickly while network operations continue in the background.

---

# PesaPulse v0.4.0-beta - 2026-07-16

## 🎨 Analytics UI & UX Polish

This beta release focused on refining the Analytics experience with a cleaner and more professional interface that matches the overall PesaPulse design system.

### ✨ Added

- Redesigned Analytics Overview card.
- New Financial Health Score card.
- Smart Recommendation card.
- Budget status badge.
- Category insights.
- Budget usage progress indicator.
- Financial recommendations.
- Animated analytics transitions.
- Redesigned statistic cards.
- Themed circular icons.
- Color-coded statistic icons.
- Distinct PDF and CSV export actions.
- Improved analytics section headers.

### 🎨 Improved

- Unified card styling across Analytics.
- Consistent spacing and padding.
- Consistent border radius.
- Improved typography.
- Improved visual hierarchy.
- Improved chart responsiveness.
- Improved Reports Center layout.
- Redesigned analytics skeleton loading.
- Better consistency with Dashboard and Budget screens.

### ⚡ Performance

- Reduced unnecessary widget rebuilds.
- Removed unused code and variables.
- Optimized animation behavior.
- Improved layout efficiency.
- Improved responsiveness.

### 🐞 Fixed

- Fixed budget status color synchronization.
- Fixed analytics progress indicator animation.
- Fixed animated budget usage percentage display.
- Fixed analytics skeleton background inconsistency.
- Fixed recommendation card status color handling.
- Improved overall Analytics UI consistency.

### 📱 Responsive Design

- Improved landscape orientation support.
- Added adaptive chart heights.
- Improved responsive spacing.
- Improved tablet layout behavior.
- Improved larger-screen layouts.

---

# PesaPulse v0.3.0-beta - 2026-07-03

## 🎉 Major Update – Settings & User Experience

This release focused on improving the overall user experience with a redesigned Settings module, enhanced account management, improved security, cleaner UI, and stronger application branding.

---

## ✨ Added

### ⚙️ Settings Module

- Replaced the Profile screen with a comprehensive Settings screen.
- Added modern profile overview card.
- Added user avatar.
- Added user name and email.
- Added Edit Profile shortcut.
- Added application statistics dashboard.
- Added Goals Created statistics.
- Added Completed Goals statistics.
- Added Budgets Created statistics.
- Added Expenses Recorded statistics.

### 🔐 Security

- Added Change Password functionality.
- Added password validation.
- Added automatic redirect after successful password change.
- Added secure session confirmation before logout.

### 🎨 Appearance

- Added Dark Mode synchronization.
- Improved theme persistence.
- Added descriptive appearance settings.

### 🔔 Notifications

- Added Daily Reminder preference.
- Added Expense Alerts preference.
- Added Weekly Financial Summary preference.
- Added backend notification synchronization.

### ℹ️ About

- Added About PesaPulse.
- Added Privacy Policy.
- Added Terms of Service.
- Added application version information.

### 💬 Support

- Added Contact Support.
- Added Rate App.
- Added Share Application.

### 🏷️ Branding

- Added branded Settings footer.
- Added application version badge.
- Added copyright information.
- Added "Designed & Developed with ❤️ in Kenya."

---

## 🎨 UI Improvements

### Settings

- Completely redesigned Settings interface.
- Introduced consistent rounded cards.
- Added modern icon badges.
- Improved typography.
- Improved spacing.
- Improved visual hierarchy.

### Profile

- Redesigned profile information layout.
- Improved avatar presentation.
- Improved profile editing experience.

### Statistics

- Redesigned statistics cards.
- Added colored icons.
- Improved labels and spacing.
- Improved responsive layout.

### Appearance

- Redesigned Dark Mode tile.
- Added explanatory subtitles.
- Improved switch styling.

### Notifications

- Redesigned notification cards.
- Added descriptive subtitles.
- Improved switch appearance.
- Added consistent icon styling.

### Security

- Redesigned Change Password section.
- Added Security Status card.
- Improved password dialog.
- Added better loading indicators.
- Improved confirmation dialog.

### About & Support

- Redesigned About section.
- Redesigned Support section.
- Added consistent navigation arrows.
- Added informative subtitles.

### Session

- Redesigned Logout section.
- Added secure session card.
- Improved logout confirmation dialog.

---

## 📊 Analytics Improvements

- Improved analytics dashboard presentation.
- Enhanced charts.
- Improved financial insights.
- Improved statistics cards.
- Improved layout responsiveness.
- Cleaner data visualization.

---

## 💰 Budget Improvements

- Improved Budget Overview interface.
- Enhanced budget summary presentation.
- Improved progress indicators.
- Cleaner card layouts.
- Improved budget insights.

---

## 🎯 Financial Goals Improvements

- Added archived goals support.
- Added goal restore functionality.
- Improved completed goals presentation.
- Redesigned goal cards.
- Enhanced progress tracking.
- Improved financial insights.
- Added forecasting improvements.

---

## 🔔 Notifications

- Integrated notification service.
- Added backend synchronization.
- Improved notification preferences.
- Improved notification persistence.

---

## 🔄 Backend Integration

### User Preferences

- Synced Dark Mode with backend.
- Synced notification preferences.
- Improved preference loading.
- Improved error handling.

### Authentication

- Improved session handling.
- Improved token management.
- Improved logout workflow.
- Improved password update workflow.

---

## 🛠 Improved

- Improved navigation flow.
- Improved responsiveness.
- Improved loading states.
- Improved snackbar messages.
- Improved dialogs.
- Improved form validation.
- Cleaner application branding.
- Better overall UX consistency.

---

## 🐛 Fixed

- Fixed login flow after password updates.
- Fixed notification preference synchronization.
- Fixed Dark Mode synchronization.
- Fixed archived goals display.
- Fixed goal restore workflow.
- Fixed session management issues.
- Fixed backend authentication handling.
- Fixed boolean preference conversion.
- Fixed UI spacing inconsistencies.
- Fixed visual alignment issues.

---

## 📦 Internal

- Refactored Settings module.
- Refactored reusable UI widgets.
- Improved API integration.
- Improved code organization.
- Cleaned project structure.
- Removed debugging code.

---

# PesaPulse v0.2.0-beta - 2026-06-27

## 🚀 Major Release – Intelligent Financial Planning

This beta release introduced intelligent financial planning, advanced goal management, richer analytics, improved budgeting, smarter notifications, and an enhanced user experience.

---

## ✨ Added

### 🎯 Financial Goals

- Goal Analytics Dashboard.
- Total Goals statistics.
- Active Goals statistics.
- Completed Goals statistics.
- Goal Completion Rate.
- Goal Forecasting Engine.
- Ahead of Schedule status.
- On Track status.
- Behind Schedule status.
- Goal Forecast API.
- Expected Progress.
- Actual Progress.
- Remaining Days.
- Remaining Amount.
- Estimated Completion Date.
- Recommended Monthly Saving.
- Upcoming Deadline Card.
- Goal Analytics Summary Cards.
- Goal Archive System.
- Archive completed goals.
- Archive confirmation dialog.
- Archived Goals screen.
- Restore archived goals.
- Archive API endpoints.
- Completed goal badges.
- Completion percentage.
- Archived date.
- Improved progress indicators.

---

### 📊 Analytics

- Financial Health Score.
- Goal Status Doughnut Chart.
- Monthly Spending Trend Chart.
- Category Breakdown Chart.
- Reports Center.
- Smart Insights.
- Smart Recommendation Engine.
- Analytics PDF export.
- Analytics CSV export.
- Report History.
- Report History Management.
- Clear Report History.

---

### 💰 Budget

- Budget Overview Card.
- Budget Usage Progress Bar.
- Budget Summary.
- Budget amount.
- Spent amount.
- Remaining amount.
- Budget Alerts.
- Safe status.
- Warning status.
- Critical status.
- Smart Budget Recommendation Card.
- Highest Spending Category Insight.
- Budget Health Indicators.
- Improved Budget Dashboard UI.

---

### 👤 Profile

- User Statistics Cards.
- Goals statistics.
- Completed Goals statistics.
- Budgets statistics.
- Expenses statistics.
- Update Profile.
- Notification Settings.
- Daily Reminder.
- Expense Alerts.
- Weekly Summary.
- Dark Mode Toggle.
- Improved Profile Layout.

---

### 🔔 Notifications

- Local Notification Service.
- Daily Reminder Notifications.
- Milestone Notifications.
- 25% milestone.
- 50% milestone.
- 75% milestone.
- 100% milestone.
- Goal Completion Notifications.
- Notification Preferences.

---

### 🎨 UI / UX

- Improved Goal Cards.
- Improved Analytics Dashboard.
- Improved Budget Dashboard.
- Improved Profile Dashboard.
- Better spacing.
- Cleaner cards.
- Improved typography.
- Better icon usage.
- Consistent color palette.
- Improved responsiveness.
- Better loading states.
- Improved SnackBars.
- Improved dialogs.

---

## ⚡ Improved

### Backend

- Improved goal forecast algorithm.
- Improved expected progress calculations.
- Improved completion estimation.
- Improved recommended saving calculations.
- Improved remaining time calculations.
- Improved archive validation.
- Improved goal ownership validation.
- Improved API responses.

### Frontend

- Cleaner Goal UI.
- Better Goal Progress visualization.
- Improved currency formatting.
- Better date formatting.
- Faster dashboard loading.
- Reduced duplicate widgets.
- Better state management.

---

## 🐞 Fixed

- Fixed duplicate Goal Achievement card.
- Fixed Upcoming Deadline text color issues.
- Fixed currency formatting inconsistencies.
- Fixed archive endpoint issues.
- Fixed forecast calculation inaccuracies.
- Fixed target date display issues.
- Fixed Analytics UI inconsistencies.
- Fixed Budget alert rendering issues.
- Fixed Goal completion card spacing.
- Fixed layout overflow issues.
- Fixed various minor UI bugs.

---

# PesaPulse v0.1.0-beta - 2026-05-30

## 🎉 Initial Beta Release

Initial beta release of **PesaPulse**, introducing the core personal finance management functionality.

---

## ✨ Added

### 🔐 Authentication

- User Registration.
- User Login.
- Authentication system.
- Logout.
- Protected API routes.

---

### 💸 Expense Management

- Add Expense.
- Edit Expense.
- Delete Expense.
- Expense Categories.
- Expense History.
- Monthly Expense Tracking.

---

### 💰 Budget

- Create Monthly Budget.
- Edit Budget.
- Budget Tracking.
- Remaining Budget Calculation.

---

### 🎯 Financial Goals

- Create Financial Goals.
- Update Goal Progress.
- Goal Progress Bars.
- Goal Milestone Tracking.
- Goal Completion.

---

### 📈 Dashboard

- Financial Summary.
- Total Spending.
- Budget Overview.
- Goal Progress Overview.

---

### 📊 Analytics

- Spending Charts.
- Monthly Spending Reports.
- Category Analysis.

---

### 📄 Reports

- Generate PDF Reports.

---

### 👤 Profile

- User Profile.
- Update User Information.

---

### 🌐 Backend

- Laravel REST API.
- MySQL Database.
- Secure API authentication.
- Expense APIs.
- Budget APIs.
- Goal APIs.
- Analytics APIs.

---

### 📱 Mobile Application

- Flutter Frontend.
- Responsive UI.
- Material Design.
- REST API integration.

---

## 🎨 UI

- Dark Theme.
- Bottom Navigation.
- Dashboard Cards.
- Progress Indicators.
- Charts.

---

## 🚀 Deployment

- Laravel Backend deployed.
- Flutter application connected to backend.
- Production database configured.

---

# Version History

| Version | Release | Date | Description |
|---------|---------|------|-------------|
| **v1.0.0** | Stable | 2026-08-20 | First stable production release |
| **v0.4.0-beta** | Beta | 2026-07-16 | Analytics UI/UX polish and responsive improvements |
| **v0.3.0-beta** | Beta | 2026-07-03 | Settings redesign, security, notifications and UX improvements |
| **v0.2.0-beta** | Beta | 2026-06-27 | Intelligent financial planning, goals, analytics, budgeting and notifications |
| **v0.1.0-beta** | Beta | 2026-05-30 | Initial PesaPulse feature set |

---

## Current Release

**PesaPulse v1.0.0**

This is the current stable production release.

For upcoming development, see the project roadmap in `README.md`.