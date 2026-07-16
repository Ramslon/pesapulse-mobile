# Changelog

All notable changes to **PesaPulse** are documented in this file.

The format is based on **Keep a Changelog** and the project follows **Semantic Versioning (SemVer)**.

---
## PesaPulse v2.2.1 - 2026-07-16

### 🎨 Analytics UI & UX Polish

This release focuses on refining the Analytics experience with a cleaner, more professional interface that matches the overall PesaPulse design system.

### ✨ Added
- Redesigned Analytics Overview card with improved visual hierarchy.
- New Financial Health Score card with dynamic colors and status indicators.
- Smart Recommendation card with:
  - Budget status badge.
  - Category insights.
  - Budget usage progress indicator.
  - Financial recommendations.
- Animated transitions for analytics sections using fade and slide effects.
- Redesigned statistic cards with themed circular icons.
- Color-coded statistic icons for improved readability.
- Distinct colors for PDF and CSV export actions.
- Improved section headers for better navigation.

### 🎨 Improved
- Unified card styling across the Analytics screen.
- Consistent spacing, padding, and border radius.
- Improved typography for headings, statistics, and descriptions.
- Better visual hierarchy throughout the Analytics page.
- Enhanced chart responsiveness for portrait and landscape modes.
- Improved Reports Center layout and presentation.
- Analytics skeleton loading redesigned to match other application screens.
- Better consistency with Dashboard and Budget screens.

### ⚡ Performance
- Reduced unnecessary widget rebuilds.
- Removed unused code and variables.
- Optimized animation behavior.
- Improved layout efficiency and responsiveness.

### 🐞 Fixed
- Fixed budget status color synchronization between Dashboard and Budget screens.
- Fixed analytics progress indicator animation.
- Fixed animated budget usage percentage display.
- Fixed analytics skeleton background inconsistency.
- Fixed recommendation card status color handling.
- Improved overall UI consistency across Analytics.

### 📱 Responsive Design
- Improved support for landscape orientation.
- Adaptive chart heights based on screen size.
- Responsive spacing for different device sizes.
- Better layout behavior on tablets and larger screens.

---

# PesaPulse v2.2.0

Release Date: mid July 2026

## ✨ New Features

• Financial Health Score
• Smart Budget Insights
• Category Spending Analysis
• Daily Spending Analytics
• Budget Recommendations
• Budget Floating Action Button
• Budget Edit/Delete
• Pull-to-Refresh across major screens
• Smart Budget Status Indicator
• Material 3 Navigation
• Accessibility Improvements
• Landscape Responsiveness

## 🎨 UI Improvements

• Redesigned Dashboard
• Improved Analytics Cards
• Better Empty States
• Premium Bottom Navigation
• Responsive Dashboard Cards
• Improved Navigation Icons

## ⚡ Performance

• Optimized navigation using IndexedStack
• Reduced unnecessary rebuilds
• Improved code organization
• Navigation cleanup

## 🐞 Bug Fixes

• Fixed gigantic text issue
• Fixed Bottom Overflow errors
• Fixed Budget screen launched from Dashboard
• Fixed dashboard budget badge synchronization
• Fixed multiple responsive layout issues

---

# [2.1.0] - 2026-07-03

## 🎉 Major Update – Settings & User Experience

This release focuses on improving the overall user experience with a complete redesign of the Profile module into a fully featured **Settings** screen, enhanced account management, improved security, cleaner UI, and better application branding.

---

## ✨ Added

### ⚙️ Settings Module
- Replaced the Profile screen with a comprehensive **Settings** screen.
- Added a modern profile overview card displaying:
  - User avatar
  - Name
  - Email
  - Edit Profile shortcut
- Added application statistics dashboard including:
  - Goals Created
  - Completed Goals
  - Budgets Created
  - Expenses Recorded

### 🔐 Security
- Added secure **Change Password** functionality.
- Implemented password validation.
- Automatically redirects users to the login screen after a successful password change.
- Added secure session confirmation before logout.

### 🎨 Appearance
- Added Dark Mode synchronization with backend preferences.
- Improved theme persistence across sessions.
- Added descriptive appearance settings.

### 🔔 Notifications
- Added notification preferences for:
  - Daily Reminders
  - Expense Alerts
  - Weekly Financial Summary
- Synced notification settings with the backend.

### ℹ️ About
- Added:
  - About PesaPulse
  - Privacy Policy
  - Terms of Service
  - Application Version

### 💬 Support
- Added:
  - Contact Support
  - Rate App
  - Share Application

### 🏷 Footer & Branding
- Added branded Settings footer.
- Added application version badge.
- Added copyright information.
- Added "Designed & Developed with ❤️ in Kenya".

---

## 🎨 UI Improvements

### Settings Screen
- Completely redesigned the Settings UI.
- Introduced consistent rounded cards.
- Added modern icon badges using colored avatars.
- Improved typography and spacing.
- Standardized section headers.
- Improved visual hierarchy throughout the screen.

### Profile Overview
- Redesigned profile information layout.
- Added better avatar presentation.
- Improved edit profile experience.

### Statistics
- Redesigned statistics cards.
- Added colored icons.
- Improved labels and spacing.
- Better responsive layout.

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
- Better loading indicators.
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
- Enhanced charts and financial insights.
- Improved statistics cards.
- Better layout and responsiveness.
- Cleaner data visualization.

---

## 💰 Budget Improvements

- Improved Budget Overview interface.
- Enhanced budget summary presentation.
- Better progress indicators.
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
- Better persistence across sessions.

---

## 🔄 Backend Integration

### User Preferences
- Synced Dark Mode with backend.
- Synced notification preferences.
- Improved preference loading.
- Improved error handling.

### Authentication
- Improved session handling.
- Better token management.
- Improved logout workflow.
- Better password update flow.

---

## 🛠 Improved

- Improved navigation flow.
- Improved responsiveness across screens.
- Better loading states.
- Better snackbar messages.
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
- Fixed various UI spacing inconsistencies.
- Fixed multiple visual alignment issues.

---

## 📦 Internal

- Refactored Settings module.
- Refactored reusable UI widgets.
- Improved API integration.
- Improved code organization.
- Cleaned project structure.
- Removed debugging code.
- Prepared project for future v2.2.0 development.

---

# [2.0.0] - 2026-06-27

## 🚀 Major Release

PesaPulse 2.0 introduces intelligent financial planning, advanced goal management, richer analytics, improved budgeting, smarter notifications, and a significantly enhanced user experience.

---

## ✨ Added

### 🎯 Goals

- Goal Analytics Dashboard
  - Total Goals
  - Active Goals
  - Completed Goals
  - Completion Rate

- Goal Forecasting Engine
  - Ahead of Schedule
  - On Track
  - Behind Schedule

- Goal Forecast API
  - Expected Progress
  - Actual Progress
  - Remaining Days
  - Remaining Amount
  - Estimated Completion Date
  - Recommended Monthly Saving

- Upcoming Deadline Card

- Goal Analytics Summary Cards

- Goal Archive System
  - Archive completed goals
  - Archive confirmation dialog
  - Archived Goals screen
  - Restore archived goals
  - Archive API endpoints

- Goal completion improvements
  - Completed badge
  - Completion percentage
  - Archived date
  - Progress indicators

- Goal UI improvements
  - Better card spacing
  - Better progress indicators
  - Currency formatting
  - Target date display
  - Cleaner milestone layout

---

### 📊 Analytics

- Financial Health Score

- Goal Status Doughnut Chart

- Monthly Spending Trend Chart

- Category Breakdown Chart

- Reports Center

- Smart Insights

- Smart Recommendation Engine

- Export Analytics to PDF

- Export Analytics to CSV

- Report History

- Report History Management

- Clear Report History

---

### 💰 Budget

- Budget Overview Card

- Budget Usage Progress Bar

- Budget Summary
  - Budget
  - Spent
  - Remaining

- Budget Alerts
  - Safe
  - Warning
  - Critical

- Smart Budget Recommendation Card

- Highest Spending Category Insight

- Budget Health Indicators

- Improved Budget Dashboard UI

---

### 👤 Profile

- User Statistics Cards
  - Goals
  - Completed Goals
  - Budgets
  - Expenses

- Update Profile

- Notification Settings
  - Daily Reminder
  - Expense Alerts
  - Weekly Summary

- Dark Mode Toggle

- Improved Profile Layout

---

### 🔔 Notifications

- Local Notification Service

- Daily Reminder Notifications

- Milestone Notifications
  - 25%
  - 50%
  - 75%
  - 100%

- Goal Completion Notifications

- Notification Preferences

- notification_service.dart implementation

---

### 🎨 UI / UX

- Improved Goal Cards

- Improved Analytics Dashboard

- Improved Budget Dashboard

- Improved Profile Dashboard

- Better spacing throughout the app

- Cleaner cards

- Improved typography

- Better icon usage

- Consistent color palette

- Improved responsiveness

- Better loading states

- Improved SnackBars

- Better dialogs

---

## ⚡ Improved

### Backend

- Smarter Goal Forecast Algorithm

- Better expected progress calculations

- Improved completion estimation

- Better recommended saving calculations

- More accurate remaining time calculations

- Improved archive validation

- Improved goal ownership validation

- Better API responses

---

### Frontend

- Cleaner Goal UI

- Better Goal Progress visualization

- Improved currency formatting

- Better date formatting

- Faster dashboard loading

- Reduced duplicate widgets

- Better state management

---

## 🐞 Fixed

- Duplicate Goal Achievement card

- Upcoming Deadline text color issues

- Currency formatting inconsistencies

- Archive endpoint issues

- Forecast calculation inaccuracies

- Target date display issues

- Analytics UI inconsistencies

- Budget alert rendering issues

- Goal completion card spacing

- Multiple layout overflow issues

- Various minor UI bugs

---

# [1.0.0] - 2026-05-30

## 🎉 Initial Release

Initial public release of **PesaPulse**.

---

## ✨ Added

### 🔐 Authentication

- User Registration

- User Login

- JWT Authentication

- Logout

- Protected API routes

---

### 💸 Expense Management

- Add Expense

- Edit Expense

- Delete Expense

- Expense Categories

- Expense History

- Monthly Expense Tracking

---

### 💰 Budget

- Create Monthly Budget

- Edit Budget

- Budget Tracking

- Remaining Budget Calculation

---

### 🎯 Goals

- Create Financial Goals

- Update Goal Progress

- Goal Progress Bars

- Goal Milestone Tracking

- Goal Completion

---

### 📈 Dashboard

- Financial Summary

- Total Spending

- Budget Overview

- Goal Progress Overview

---

### 📊 Analytics

- Spending Charts

- Monthly Spending Reports

- Category Analysis

---

### 📄 Reports

- Generate PDF Reports

---

### 👤 Profile

- User Profile

- Update User Information

---

### 🌐 Backend

- Laravel REST API

- MySQL Database

- Secure Authentication

- Expense APIs

- Budget APIs

- Goal APIs

- Analytics APIs

---

### 📱 Mobile App

- Flutter Frontend

- Responsive UI

- Material Design

- API Integration

---

## 🎨 UI

- Dark Theme

- Bottom Navigation

- Dashboard Cards

- Progress Indicators

- Charts

---

## 🚀 Deployment

- Laravel Backend deployed

- Flutter application connected to production backend

- Production database configured
