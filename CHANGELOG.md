# Changelog

All notable changes to **PesaPulse** are documented in this file.

The format is based on **Keep a Changelog** and the project follows **Semantic Versioning (SemVer)**.

---

# PesaPulse v1.0.0 - 2026-08-20

## 🎉 Stable Production Release

PesaPulse v1.0.0 is the first stable production release of the modern PesaPulse Personal Finance Management System.

This release introduces a redesigned user experience, improved authentication, guest mode, guest-to-user data migration, offline-first financial management, synchronization, intelligent analytics, budgeting, savings goals, notifications, and improved application reliability.

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

### 🔐 Authentication

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

---

### 👤 Guest Mode

- Added ability to use PesaPulse without creating an account.
- Added guest-specific local data ownership.
- Added guest session management.
- Added guest-to-user migration.
- Guest financial data can be migrated when a guest creates an account.
- Improved separation between guest and authenticated user data.

---

## 💰 Financial Management

### 💸 Expense Management

- Add expenses.
- Edit expenses.
- Delete expenses.
- Categorize expenses.
- Search expenses.
- Filter expenses.
- Sort expenses.
- Track monthly expenses.
- Added offline expense management.
- Added automatic synchronization.
- Added manual synchronization.
- Added synchronization status tracking.
- Added pending changes tracking.

---

### 💵 Income Management

- Added income management.
- Add income sources.
- Track income records.
- Added monthly income summaries.
- Added offline income management.
- Added income synchronization.

---

### 📊 Budget Management

- Create monthly budgets.
- Edit budgets.
- Delete budgets.
- Added budget health indicators.
- Added overspending alerts.
- Added spending progress indicators.
- Added daily spending trends.
- Added budget insights.
- Added budget recommendations.
- Added smart budget status indicators.
- Added budget synchronization.
- Added offline budget management.
- Added pull-to-refresh support.
- Improved budget overview presentation.

---

### 🎯 Financial Goals

- Create savings goals.
- Edit savings goals.
- Delete savings goals.
- Track goal progress.
- Track goal milestones.
- Added goal forecasting.
- Added goal analytics.
- Added goal completion predictions.
- Added expected progress calculations.
- Added completion estimates.
- Added recommended monthly savings calculations.
- Added archive and restore functionality.
- Added completed goal presentation.
- Added goal notifications.
- Improved goal cards and progress visualization.

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
- Added cached analytics for offline access.

---

### 📄 Reports

- Added Reports Center.
- Added PDF report export.
- Added CSV report export.
- Added report history.
- Added report history management.
- Added report history clearing.

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
- Redesigned analytics skeleton loading.
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
- Improved notification persistence.

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
- Improved offline-to-online transition handling.

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
- Improved loading states.
- Improved empty states.
- Improved dialogs.
- Improved snackbar messages.
- Improved form validation.
- Improved application branding.
- Improved overall visual consistency.

---

## ⚡ Performance

- Reduced unnecessary widget rebuilds.
- Optimized navigation.
- Improved application startup.
- Improved background synchronization.
- Reduced unnecessary network requests.
- Improved local database performance.
- Optimized animations.
- Improved layout efficiency.
- Improved responsive behavior.
- Removed unused code and variables.
- Improved state management.

---

## 🛡️ Security

- Secure authentication using Laravel Sanctum.
- Protected API routes.
- Improved session handling.
- Improved token management.
- Added user-specific data ownership.
- Added guest-specific data ownership.
- Improved input validation.
- Improved account deletion workflow.
- Improved password management.
- Improved protection of local financial data.

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
- Fixed goal archive and restore workflow.
- Fixed various analytics UI issues.
- Fixed budget alert rendering issues.
- Fixed layout overflow issues.
- Fixed multiple minor UI bugs.

---

## 🛠 Backend

- Laravel 12 REST API.
- Laravel Sanctum authentication.
- MySQL database integration.
- Authentication APIs.
- Expense APIs.
- Income APIs.
- Budget APIs.
- Financial goal APIs.
- Analytics APIs.
- Notification APIs.
- User preference APIs.
- Settings APIs.
- Improved API validation.
- Improved API responses.
- Improved user ownership validation.

---

## 📱 Mobile Application

- Flutter mobile application.
- Dart implementation.
- Material 3 interface.
- Repository-based architecture.
- SQLite local database.
- Offline-first architecture.
- REST API integration.
- Background synchronization.
- Local notifications.
- Responsive mobile layouts.

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