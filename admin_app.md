# 🛡️ SmartPool — Admin Dashboard

## Product Requirements Document (PRD) v1.0

---

**Document Version:** 1.0
**Last Updated:** March 2026
**Platform:** Web Application (nextjs + TypeScript) + flutter app both
**Backend:** Supabase (shared with Driver & Rider apps)
**Scope:** Internal Admin & Operations Dashboard
**Depends On:** User App PRD v1.0 | Driver App PRD v1.0
**Access:** Internal SmartPool staff only (role-based)
**Status:** Ready for Development

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Admin Roles & Permission Matrix](#2-admin-roles--permission-matrix)
3. [Goals & Success Metrics](#3-goals--success-metrics)
4. [Technical Architecture Overview](#5-technical-architecture-overview)
5. [Design Philosophy & UI Standards](#6-design-philosophy--ui-standards)
6. [Information Architecture](#7-information-architecture)
7. [Screen-by-Screen Specifications](#8-screen-by-screen-specifications)
   - 7.1 Auth & Access
   - 7.2 Main Dashboard (Command Center)
   - 7.3 User Management (Riders)
   - 7.4 Driver Management
   - 7.5 Document Verification Center
   - 7.6 Ride Management & Monitoring
   - 7.7 Safety & Incident Management
   - 7.8 Payments & Financial Operations
   - 7.9 Support & Helpdesk
   - 7.10 Analytics & Reports
   - 7.11 Notifications & Communications
   - 7.12 Content Management
   - 7.13 Configuration & System Settings
8. [Core Operations Workflows](#8-core-operations-workflows)
9. [Document Verification Workflow](#9-document-verification-workflow)
10. [Safety & Incident Response Workflow](#10-safety--incident-response-workflow)
11. [Fraud Detection & Prevention](#11-fraud-detection--prevention)
12. [Financial Operations & Reconciliation](#12-financial-operations--reconciliation)
13. [Notification & Communication System](#13-notification--communication-system)
14. [Audit Logging & Compliance](#14-audit-logging--compliance)
15. [Non-Functional Requirements](#15-non-functional-requirements)
16. [Out of Scope — v1.0](#16-out-of-scope---v10)
17. [Dependencies & Integrations](#17-dependencies--integrations)
18. [Risks & Mitigations](#18-risks--mitigations)
19. [Appendix A — Screen Inventory](#19-appendix-a---screen-inventory)
20. [Appendix B — Admin Role Definitions](#20-appendix-b---admin-role-definitions)
21. [Appendix C — KPI Definitions & Formulas](#21-appendix-c---kpi-definitions--formulas)
22. [Appendix D — Incident Severity Levels](#22-appendix-d---incident-severity-levels)

---

## 1. Executive Summary

The **SmartPool Admin Dashboard** is an internal web application used exclusively by SmartPool's operations, support, safety, finance, and product teams. It serves as the command-and-control center for the entire platform — enabling staff to manage users, verify driver documents, monitor live rides, resolve disputes, handle safety incidents, manage payouts, and configure the platform.

The dashboard is **role-based** — different team members see different modules based on their function. It is built for desktop-first use (1440px+ viewport) with a clean, data-dense design optimized for efficiency.

### Key Responsibilities of the Admin Dashboard

- **Onboard & verify drivers** through a structured document review pipeline
- **Monitor the platform in real-time** — live ride map, active users, safety alerts
- **Handle safety incidents** with a rapid-response SOS management workflow
- **Resolve disputes** between riders and drivers (payment, safety, conduct)
- **Manage financial operations** — payouts, refunds, reconciliation, incentives
- **Communicate with users** — push notifications, in-app messages, email campaigns
- **Track KPIs** and generate reports for leadership

---

## 2. Admin Roles & Permission Matrix

### Roles

| Role                   | Description                                                                |
| ---------------------- | -------------------------------------------------------------------------- |
| **Super Admin**        | Full access to all modules; can create/delete admin accounts               |
| **Operations Manager** | User management, driver management, ride monitoring, reports               |
| **Document Reviewer**  | Document verification only (DL, RC, Insurance, PUC, Aadhaar)               |
| **Safety Officer**     | Safety incidents, SOS alerts, account suspensions, incident reports        |
| **Finance Admin**      | Payments, payouts, refunds, financial reports, reconciliation              |
| **Support Agent**      | Helpdesk tickets, user/driver profile view (read-only), dispute resolution |
| **Marketing Admin**    | Notifications, banners, promo codes, content management                    |
| **Analyst**            | Analytics & reports (read-only access to all data)                         |

### Permission Matrix

| Module                | Super Admin | Ops Manager | Doc Reviewer | Safety Officer | Finance Admin | Support Agent | Marketing | Analyst |
| --------------------- | ----------- | ----------- | ------------ | -------------- | ------------- | ------------- | --------- | ------- |
| Main Dashboard        | ✅ Full     | ✅ Full     | 👁️ View      | ✅ Full        | 👁️ View       | 👁️ View       | 👁️ View   | 👁️ View |
| User Management       | ✅ Full     | ✅ Full     | ❌           | ✅ Suspend     | 👁️ View       | 👁️ View       | ❌        | 👁️ View |
| Driver Management     | ✅ Full     | ✅ Full     | 👁️ View      | ✅ Suspend     | 👁️ View       | 👁️ View       | ❌        | 👁️ View |
| Document Verification | ✅ Full     | ✅ Full     | ✅ Full      | ❌             | ❌            | ❌            | ❌        | ❌      |
| Ride Monitoring       | ✅ Full     | ✅ Full     | ❌           | ✅ Full        | ❌            | 👁️ View       | ❌        | 👁️ View |
| Safety & Incidents    | ✅ Full     | ✅ Full     | ❌           | ✅ Full        | ❌            | 👁️ View       | ❌        | 👁️ View |
| Payments & Finance    | ✅ Full     | 👁️ View     | ❌           | ❌             | ✅ Full       | 👁️ View       | ❌        | 👁️ View |
| Support / Helpdesk    | ✅ Full     | ✅ Full     | ❌           | ✅ Full        | 👁️ View       | ✅ Full       | ❌        | 👁️ View |
| Analytics & Reports   | ✅ Full     | ✅ Full     | ❌           | 👁️ View        | ✅ Full       | ❌            | 👁️ View   | ✅ Full |
| Notifications         | ✅ Full     | ✅ Full     | ❌           | ✅ Safety only | ❌            | ❌            | ✅ Full   | ❌      |
| Content Management    | ✅ Full     | ✅ Full     | ❌           | ❌             | ❌            | ❌            | ✅ Full   | ❌      |
| System Settings       | ✅ Full     | ❌          | ❌           | ❌             | ❌            | ❌            | ❌        | ❌      |
| Admin User Mgmt       | ✅ Full     | ❌          | ❌           | ❌             | ❌            | ❌            | ❌        | ❌      |

---

## 3. Goals & Success Metrics

### Operational Goals

- Reduce driver document verification time to < 2 hours (P95)
- Resolve safety incidents within 5 minutes of SOS trigger
- Process all refund requests within 24 hours
- Resolve support tickets within 4 hours (P90)
- Maintain platform uptime visibility at all times

### Admin Dashboard KPIs

| Metric                         | Target      |
| ------------------------------ | ----------- |
| Document review turnaround     | < 2 hours   |
| SOS response time              | < 5 minutes |
| Support ticket resolution time | < 4 hours   |
| Refund processing time         | < 24 hours  |
| False fraud flag rate          | < 2%        |
| Admin dashboard uptime         | 99.9%       |

---

## 4. Technical Architecture Overview

```
Admin Dashboard (React + TypeScript + Vite)
    │
    ├── UI Framework: shadcn/ui + Tailwind CSS
    ├── State Management: Zustand
    ├── Data Fetching: React Query + Supabase JS client
    ├── Charts: Recharts / Chart.js
    ├── Tables: TanStack Table (AG Grid for heavy data)
    ├── Maps: Google Maps JS API (live ride monitoring)
    ├── Auth: Supabase Auth (email + password + MFA mandatory)
    └── Realtime: Supabase Realtime (live alerts, SOS, ride updates)
           │
           ▼
    Supabase Backend (shared with mobile apps)
    ├── PostgreSQL (all data)
    ├── Row Level Security (RLS) policies per admin role
    ├── Realtime channels (SOS alerts, live rides, new verifications)
    ├── Storage (documents, photos — admin read access)
    └── Edge Functions (bulk operations, report generation)
           │
           ▼
    Admin-Specific Backend Services
    ├── Report Generation (PDF/CSV export via Edge Functions)
    ├── Bulk Notification Service (FCM batch send)
    ├── Audit Log Service (every admin action logged immutably)
    ├── Fraud Detection Engine (rule-based + anomaly scoring)
    └── Financial Reconciliation Engine
```

### Security Requirements

- MFA (TOTP) mandatory for all admin accounts
- IP allowlisting (office VPN + approved IPs only)
- Session timeout: 8 hours (auto-logout)
- All admin actions logged with: admin ID, timestamp, IP, action, affected entity
- Sensitive data masking: Aadhaar numbers, bank accounts shown partially
- PII access logging: Any access to full PII (name, phone, address) is logged

---

## 5. Design Philosophy & UI Standards

### Design Principles

- **Data-dense but not cluttered:** Maximum information per viewport, no wasted whitespace
- **Action-first layout:** Most common actions visible immediately, no deep navigation
- **Status at a glance:** Color-coded badges and chips for all statuses
- **Alert prominence:** Safety alerts, SOS events always in top-right corner with sound
- **Keyboard-friendly:** All critical workflows completable without mouse

### Visual Style

| Token           | Value                       |
| --------------- | --------------------------- |
| Background      | `#F8FAFC` (light grey)      |
| Sidebar         | `#0F172A` (dark navy)       |
| Primary Accent  | `#3B82F6` (blue)            |
| Success         | `#22C55E` (green)           |
| Warning         | `#F59E0B` (amber)           |
| Danger          | `#EF4444` (red)             |
| Neutral         | `#64748B` (slate)           |
| Typography      | Inter                       |
| Table Row Hover | `#EFF6FF`                   |
| Card Shadow     | `0 1px 3px rgba(0,0,0,0.1)` |

### Layout

- **Left sidebar** (240px, collapsible to 64px): Navigation
- **Top header** (64px): Search, alerts, admin profile, notifications
- **Main content area:** Full remaining viewport
- **Breadcrumb navigation:** Always present on inner pages
- **Sticky table headers:** On all data tables
- **Right panel / drawer:** For quick-view details without leaving current table

---

## 6. Information Architecture

```
Admin Dashboard
│
├── 🏠 Main Dashboard (Command Center)
│   ├── Platform Health Overview
│   ├── Live Activity Map
│   ├── Real-time KPI Cards
│   └── Alert Feed
│
├── 👥 User Management
│   ├── All Users (Riders)
│   ├── User Profile Detail
│   ├── User Activity Log
│   └── Banned / Suspended Users
│
├── 🚗 Driver Management
│   ├── All Drivers
│   ├── Driver Profile Detail
│   ├── Driver Activity Log
│   └── Suspended / Banned Drivers
│
├── 📄 Document Verification Center
│   ├── Verification Queue (Pending)
│   ├── In-Review
│   ├── Approved
│   ├── Rejected
│   └── Expiring Soon
│
├── 🗺️ Ride Management
│   ├── Live Rides Monitor
│   ├── All Rides
│   ├── Ride Detail
│   └── Cancelled / Disputed Rides
│
├── 🚨 Safety & Incidents
│   ├── Active SOS Alerts (real-time)
│   ├── All Incidents
│   ├── Incident Detail & Resolution
│   ├── Flagged Accounts
│   └── Safety Reports
│
├── 💰 Payments & Finance
│   ├── Transaction Overview
│   ├── Payout Management
│   ├── Refund Management
│   ├── Disputes
│   ├── Promo Codes & Incentives
│   └── Financial Reports
│
├── 🎫 Support & Helpdesk
│   ├── All Tickets
│   ├── Ticket Detail
│   ├── Canned Responses Library
│   └── Support Metrics
│
├── 📊 Analytics & Reports
│   ├── Growth Dashboard
│   ├── Operational Metrics
│   ├── Driver Analytics
│   ├── Rider Analytics
│   ├── Financial Analytics
│   ├── Safety Analytics
│   └── Custom Report Builder
│
├── 📢 Notifications & Communications
│   ├── Push Notification Campaigns
│   ├── SMS Campaigns
│   ├── In-App Banners
│   └── Email Broadcasts
│
├── 🎨 Content Management
│   ├── Onboarding Slides
│   ├── FAQ Management
│   ├── App Banners / Promotions
│   └── Help Articles
│
└── ⚙️ System Settings
    ├── Fare Configuration
    ├── Matching Algorithm Settings
    ├── City & Zone Management
    ├── Feature Flags
    ├── Admin User Management
    ├── Role & Permission Management
    └── Audit Logs
```

---

## 7. Screen-by-Screen Specifications

---

### 7.1 AUTH & ACCESS

---

#### Screen 1.1 — Login Page

**Purpose:** Secure admin access

**Layout:**

- SmartPool Admin logo (center, above card)
- Login card (480px wide, centered):
  - Title: "Admin Dashboard"
  - Email input
  - Password input
  - "Sign In" CTA (primary blue)
- Post-password: TOTP (Google Authenticator) 6-digit code entry
- "Forgot password?" link (sends reset to registered email)
- No "Sign Up" option (accounts created by Super Admin only)
- Version number in footer

**Security:**

- Rate limiting: 5 failed attempts → 15-minute lockout
- All login attempts logged (success + failure)
- Session: JWT with 8-hour expiry, refresh on activity

---

#### Screen 1.2 — Admin Profile & Security Settings

**Purpose:** Personal admin account settings

**Sections:**

- Profile: Name, Email, Role (read-only), Last login info
- Change password (current + new + confirm)
- Two-Factor Authentication:
  - Status: Enabled ✅ (mandatory — cannot disable)
  - "Re-setup 2FA" option (generates new QR code)
  - Backup codes (one-time view, download)
- Active Sessions list (device, IP, location, last active)
  - "Revoke" button per session
  - "Revoke All Other Sessions" button
- Notification preferences (email alerts for: SOS events, critical platform alerts)

---

### 7.2 MAIN DASHBOARD (COMMAND CENTER)

---

#### Screen 2.1 — Main Dashboard

**Purpose:** At-a-glance platform health; first screen after login

**Layout: 3-column grid**

**Top Alert Bar (sticky, red when active):**

- Live SOS alert notifications (sound + visual pulse)
- "2 Active SOS Alerts" → click opens Safety module
- Critical system alerts (payment gateway down, API errors)

**Row 1 — Real-Time KPI Cards (6 cards):**

- 🟢 Active Rides Right Now: 342
- 👥 Active Riders (last 30 min): 1,204
- 🚗 Drivers Online: 487
- 📄 Pending Verifications: 23
- 🎫 Open Support Tickets: 47
- 🚨 Active Incidents: 2
- Each card: Current value (large), trend arrow vs yesterday, sparkline (24h)

**Row 2 — Live Activity Map (full width, 400px height):**

- Google Maps with:
  - Green dots: Online drivers (not in ride)
  - Blue moving dots: Drivers in active rides
  - Red pulsing dot: SOS alert locations
  - Heatmap toggle: Rider demand density
  - City zone polygons overlay toggle
- Map controls: Zoom, City selector dropdown, Filter by status
- Click a driver dot → quick-info popup (name, vehicle, ride status, "View Profile" link)

**Row 3 — Three columns:**

**Column 1 — Today's Summary:**

- Total rides today: 1,842
- Completed: 1,701 (92.3%)
- Cancelled (driver): 89
- Cancelled (rider): 52
- New user signups: 234
- New driver applications: 18

**Column 2 — Recent Activity Feed:**

- Real-time event stream (auto-updating):
  - 🚨 SOS triggered — Driver #DRV-4421 — 2 min ago [View]
  - ✅ Driver verified — Vikram S. — 3 min ago
  - 💰 Payout failed — ₹2,400 — Driver #DRV-2210 [Retry]
  - 🎫 New ticket — #TKT-8821 — Refund request [Open]
  - 👤 New driver application — Priya M. — 5 min ago [Review]
- Filters: All | Safety | Finance | Drivers | Riders
- "View Full Log" link

**Column 3 — Pending Actions (Actionable Queue):**

- Documents to review: 23 [Review Queue →]
- Refund requests: 8 [Process →]
- Disputes awaiting: 5 [Resolve →]
- Tickets unassigned: 12 [Assign →]
- Failed payouts: 3 [Retry →]

**Row 4 — Performance Charts:**

- Rides chart (last 7 days): Line chart — completed vs cancelled
- Revenue chart (last 7 days): Bar chart — gross revenue + platform fees
- Driver supply vs Rider demand chart (last 7 days)

---

#### Screen 2.2 — Global Search

**Triggered:** Cmd+K or click search bar in header

**Layout (modal overlay):**

- Search input (autofocused)
- Recent searches (last 5)
- Results (real-time as typing):
  - Users section: Avatar, Name, Phone, Status badge
  - Drivers section: Photo, Name, Vehicle, Status badge
  - Rides section: Ride ID, Route, Date, Status
  - Tickets section: Ticket ID, Subject, Status
  - Transactions section: Transaction ID, Amount, Status
- Keyboard navigation (↑↓ to select, Enter to open)

---

### 7.3 USER MANAGEMENT (RIDERS)

---

#### Screen 3.1 — All Users (Riders) List

**Purpose:** Browse, search, filter all rider accounts

**Layout:**

**Header:**

- Title: "Riders" + Total count badge
- Search bar (name, phone, email, user ID)
- Filter button → filter panel
- "Export CSV" button

**Filter Panel (right drawer or inline):**

- Status: All / Active / Suspended / Banned / Unverified
- Verification: Phone only / ID Verified / Aadhaar Verified
- Registration date range
- Last active date range
- City
- Rating range
- Total rides range

**Table (sortable columns):**
| # | User | Phone | Email | City | Rating | Total Rides | Status | Joined | Last Active | Actions |

- User cell: Avatar + Name + ID chip
- Status: Colored badge (Active / Suspended / Banned)
- Actions: View | Suspend | Message

**Row click → opens User Detail (right drawer or new page)**

**Bulk Actions (on row checkbox select):**

- Suspend selected
- Send notification
- Export selected

---

#### Screen 3.2 — Rider Profile Detail

**Purpose:** Full view and management of a single rider

**Layout (full page):**

**Header:**

- Breadcrumb: Riders > Rohan Sharma
- Profile: Avatar (96px), Name, User ID, Phone, Email
- Status badge + "Change Status" dropdown (Active / Suspend / Ban)
- Created: Date | Last active: Date

**Tab Navigation:**

- Overview | Rides | Payments | Reviews | Activity Log | Support Tickets

**Overview Tab:**

- Personal info: Name, Phone, Email, DOB, Gender, City
- Verification status: Phone ✓ | Email ✓ | Aadhaar ✓
- Rating: ★ 4.7 (42 ratings) — with breakdown bars
- Stats: Total rides, Total spent, Cancellation rate, No-show count
- Devices: Device model, OS, App version, Last seen
- Emergency contacts (if any)
- Referral info: Referred by / Referrals made

**Rides Tab:**

- Paginated table of all rides
- Columns: Date, Route, Driver, Seats, Fare, Status, Rating given
- Click ride → Ride Detail

**Payments Tab:**

- Wallet balance (current)
- Transaction history (paginated)
- Payment methods on file (masked)
- Promo codes used

**Reviews Tab:**

- Reviews given by this user to drivers
- Reviews received from drivers
- Flag/remove review option

**Activity Log Tab:**

- Timestamped log of all user actions on the platform
- Filters: All / Login / Booking / Payment / Safety

**Support Tickets Tab:**

- All tickets raised by this user
- Status per ticket
- "Create Ticket on behalf of user" option

**Admin Actions Panel (right sidebar):**

- "Suspend Account" (with reason + duration)
- "Ban Account" (with reason — permanent)
- "Send Push Notification" (custom message to this user)
- "Send In-App Message"
- "Issue Wallet Credit" (goodwill credit with reason)
- "Reset Password" (triggers email)
- "View Raw Data" (JSON — Super Admin only)
- "Add Internal Note" (visible to admins only)

---

#### Screen 3.3 — Suspend / Ban User Modal

**Purpose:** Structured process for account action

**Layout (modal):**

- User info summary (avatar, name, ID)
- Action: Suspend / Ban (radio)
- Suspension Duration (if suspend): 1 day / 3 days / 7 days / 30 days / Custom
- Reason (mandatory dropdown):
  - Policy violation | Fake account | Payment fraud | Inappropriate behavior | Safety violation | Other
- Internal notes (text area — for audit record)
- Notify user checkbox (default: ON) — sends push + email
- "Confirm Action" red CTA
- All fields required; confirmation requires typing user's ID

---

### 7.4 DRIVER MANAGEMENT

---

#### Screen 4.1 — All Drivers List

**Purpose:** Browse, search, filter all driver accounts

**Layout (same pattern as Riders):**

**Additional Filter Options vs Riders:**

- Verification status: Pending / Approved / Rejected / Resubmission needed
- Online status: Currently online / Offline
- Approval date range
- Vehicle type
- Documents expiring within X days

**Table Columns:**
| Photo | Name + ID | Phone | Vehicle | City | Rating | Total Rides | Online Status | Approval Status | Joined | Actions |

**Status Chips:**

- Online (green) | Offline (grey) | In-Ride (blue) | Suspended (red) | Pending Verification (yellow)

**Quick Actions from list:**

- View Profile
- View Documents
- Suspend
- Go-Online force (emergency — Super Admin only)

---

#### Screen 4.2 — Driver Profile Detail

**Purpose:** Full driver profile management

**Layout:**

**Header:**

- Breadcrumb: Drivers > Vikram Mehta
- Driver photo (96px), Name, Driver ID, Phone, Email
- Status badge + change action
- Online status indicator (live)

**Tab Navigation:**

- Overview | Documents | Rides | Earnings | Vehicle | Reviews | Activity Log | Support Tickets

**Overview Tab:**

- Personal info + verification badges
- Approval status with history (who approved, when)
- Rating breakdown (Punctuality, Safety, Friendliness, Cleanliness)
- Stats: Total rides, Total earned, Completion rate, Cancellation rate, No-show count
- Incentives earned (cumulative)
- Warning strikes: 0/3 (shows history of strike reasons)
- Device info: Model, OS, App version, last GPS ping

**Documents Tab:**

- See Section 7.5 (Document Verification Detail)
- All documents listed with status + expiry + "Review" action

**Rides Tab:**

- All rides published by this driver
- Each: Date, Route, Seats offered, Booked, Completed, Earnings, Status

**Earnings Tab:**

- Total lifetime earnings
- Pending in wallet
- Total withdrawn
- Payout history
- Pending payouts
- Failed payouts with retry option

**Vehicle Tab:**

- Vehicle photo, Make/Model/Year/Color
- Registration plate
- All documents status (RC, Insurance, PUC)
- "Add note about vehicle" option

**Admin Actions Panel:**

- "Approve Driver" (if pending)
- "Reject with Reason"
- "Request Document Resubmission" (select specific documents)
- "Suspend Account"
- "Ban Account"
- "Send Push Notification"
- "Force Go Offline" (emergency — removes from live map immediately)
- "Issue Manual Payout" (bypass normal cycle)
- "Remove Warning Strike" (with justification)
- "Add Internal Note"

---

#### Screen 4.3 — Driver Application Review Queue

**Purpose:** Process new driver applications efficiently

**Layout:**

**Header:**

- Title: "New Driver Applications"
- Count: 23 pending
- Sort: Oldest first (default) | Newest first
- Filter: All / Auto-verified / Needs manual review / Resubmission

**Queue Cards (list view):**
Each card:

- Driver photo, Name, City, Applied: X hours ago
- Document completion indicator: 7/7 documents uploaded
- Auto-verification result: "5/7 Auto-approved | 2 need manual review"
- Documents needing review (chips): "Driving Licence" "Insurance"
- "Review Now" primary CTA → opens Document Verification Screen

---

### 7.5 DOCUMENT VERIFICATION CENTER

---

#### Screen 5.1 — Verification Queue Dashboard

**Purpose:** Overview of all pending document verifications

**Layout:**

**Status Tabs with counts:**

- Pending Review (23) | In Review (5) | Approved | Rejected | Expiring Soon (41)

**Pending Queue (list):**

- Sort: Oldest first (FIFO — fairness)
- Each row: Driver photo, Name, Document type, Submitted, Auto-check result, Assign to me button
- Status: Unassigned / Assigned (reviewer name)
- Priority flag: ⚡ High (driver has bookings waiting)

**Expiring Soon Tab:**

- Documents expiring within 30 days
- Columns: Driver, Document type, Expiry date, Days remaining, Status
- Sorted by: Most urgent first
- Bulk action: "Send renewal reminder to all"

**Metrics sidebar:**

- Avg review time today: 48 min
- Reviews completed today: 34
- By reviewer leaderboard (gamification for reviewers)

---

#### Screen 5.2 — Document Verification Detail

**Purpose:** Review a single driver's pending document(s)

**Layout (full-screen, 2-panel):**

**Left Panel — Document Viewer (60%):**

- Document type selector tabs: Aadhaar | DL | RC | Insurance | PUC | Vehicle Photo
- Document image viewer (zoomable, rotatable)
- Multiple pages (front/back) with arrow navigation
- Image enhancement tools: Brightness, Contrast, Zoom
- "Flag image issue" (blurry, incomplete, wrong document)

**Right Panel — Review Form (40%):**

**Auto-Verification Results section:**

- API check results per field:
  - ✅ DL Number: Valid
  - ✅ DL Not Expired (expires: 12 Mar 2030)
  - ✅ LMV Endorsement: Present
  - ⚠️ Name mismatch: "Vikram Mehta" vs "Vikram S. Mehta" — Review required
  - ✅ No blacklist flag

**Driver Info Panel:**

- Name (from Aadhaar), Phone, City
- Existing verification history (if resubmission)

**Manual Review Fields (pre-filled from OCR, editable):**
For DL:

- DL Number, Holder Name, DOB, Issue Date, Expiry Date, Endorsements, Issuing RTO
  For RC:
- Reg. Number, Owner Name, Make/Model, Year, Fuel Type, Seating Capacity
  For Insurance:
- Policy Number, Insurer, Valid From, Valid Until
  For PUC:
- PUC Number, Valid Until

**Decision Panel:**

- "Approve" — green CTA
- "Reject" — red CTA → opens Rejection Reason modal
- "Request Resubmission" — yellow CTA → select specific issue + message to driver
- Internal note (optional, saved to driver record)

**Rejection Reason Modal:**

- Reason dropdown (mandatory):
  - Image unclear / unreadable
  - Document expired
  - Name mismatch (explain)
  - Document appears tampered
  - Wrong document type uploaded
  - DL endorsement missing
  - Vehicle ownership mismatch
  - Other (text required)
- Rejection note to driver (editable template, sent via push + in-app)
- "Confirm Rejection" CTA

**Keyboard shortcuts (for power reviewers):**

- A → Approve | R → Reject | N → Next document | P → Previous | Z → Zoom

---

#### Screen 5.3 — Document Verification History

**Purpose:** Audit trail for all document decisions

**Layout:**

- Table: Driver, Document type, Submitted, Reviewed by, Decision, Timestamp, Reason (if rejected)
- Filter: Date range, Reviewer, Decision, Document type
- Click row → opens document viewer (read-only) with full decision history

---

### 7.6 RIDE MANAGEMENT & MONITORING

---

#### Screen 6.1 — Live Rides Monitor

**Purpose:** Real-time view of all active rides on the platform

**Layout (map-first):**

**Full-Screen Map:**

- All active ride routes shown as colored polylines
- Driver pins (moving, colored by status):
  - Blue: En route to pickup
  - Green: Passengers onboard, in ride
  - Red: SOS active
  - Yellow: Route deviation detected
- Click any ride pin → Ride Quick Info popup

**Ride Quick Info Popup:**

- Driver: Photo, Name, Rating
- Passengers: Count + profile thumbnails
- Route: Pickup → Drop
- ETA to destination
- Current speed
- "View Full Ride" link
- "Send Alert to Driver" option
- "Trigger Support Call" option

**Left Panel — Live Rides List (320px, scrollable):**

- Count: 342 active rides
- Each item: Driver name + route + status chip + passenger count
- Sort: Newest | By status | By city
- Search by driver/passenger name
- Filter: By status, By city

**Alert Strip (top, conditionally visible):**

- Yellow: "Route deviation detected — Ride #RD-4421"
- Red: "SOS Active — 2 rides"
- These auto-dismiss when resolved

---

#### Screen 6.2 — All Rides Table

**Purpose:** Comprehensive view of all rides (past + present)

**Layout:**

**Filters:**

- Date range (default: today)
- Status: All / Upcoming / Active / Completed / Cancelled / Disputed
- City
- Driver
- Rider

**Table Columns:**
| Ride ID | Driver | Passengers | Route | Date/Time | Distance | Fare | Status | Action |

**Row click → Ride Detail (Screen 6.3)**

**Export:** CSV / Excel / PDF

---

#### Screen 6.3 — Ride Detail

**Purpose:** Full information about a single ride

**Layout:**

**Header:**

- Ride ID: #RD-20240315-1821
- Status badge (color-coded)
- Date/Time
- "Flag this ride" option

**Route Section:**

- Map snapshot: Full route with all stops
- Pickup → Intermediate stops → Drop
- Actual GPS route overlaid (blue line) vs planned (grey line) — deviation highlighted in red

**Participants Section:**

- Driver card: Photo, Name, Rating, Vehicle, "View Driver Profile" link
- Passengers list: Each with photo, name, seat count, pickup/drop, payment status, rating given

**Timeline (vertical event log):**

- Ride published: 08:30 PM (day before)
- Booking confirmed — Rohan: 9:15 PM
- Booking confirmed — Priya: 9:45 PM
- Driver went online: 8:45 AM
- Driver departed: 9:02 AM
- Rohan picked up: 9:18 AM (PIN verified ✅)
- Priya picked up: 9:31 AM (PIN verified ✅)
- Destination reached: 9:44 AM
- Ride ended: 9:44 AM
- Rohan rated driver ★5: 9:46 AM
- Priya rated driver ★4: 9:48 AM
- Earnings credited to driver: 9:54 AM

**Financial Section:**

- Per-passenger fare: ₹85
- Total collected: ₹170
- Platform fee: ₹8.50
- Driver credited: ₹161.50
- Payment method per passenger

**GPS Data:**

- Route map with GPS trail
- Max speed recorded
- Any speed violations (>80 km/h flagged in red)
- Route deviation log (if any)

**Admin Actions:**

- Issue refund (for a passenger)
- Adjust driver earnings (with justification)
- Flag for safety review
- Add internal note
- Download full ride data (JSON)

---

#### Screen 6.4 — Cancelled / Disputed Rides

**Purpose:** Manage problematic rides

**Layout:**

- Tabs: Cancelled by Driver | Cancelled by Rider | Disputed
- Table with cancellation reasons, refund status, penalty applied
- "Resolve Dispute" action → opens dispute resolution workflow

---

### 7.7 SAFETY & INCIDENT MANAGEMENT

---

#### Screen 7.1 — Safety Dashboard (Active Alerts)

**Purpose:** Real-time safety monitoring — highest priority module

**Layout:**

**🚨 Active SOS Alerts Section (top, red background when active):**

- Alert card per active SOS:
  - Who: Driver/Rider photo + Name + ID
  - Type: Driver SOS / Rider SOS
  - Location: Address + mini map
  - Triggered: X minutes ago
  - Ride ID (link to ride detail)
  - Co-participants: Other driver/passengers in this ride
  - Actions:
    - "Call Now" (masked proxy call to the person)
    - "Dispatch Support" (mark as being handled)
    - "Resolve Alert" (with resolution notes)
    - "Escalate to Police" (logs escalation + notifies senior admin)

**Sound alert:** Persistent alarm sound for unacknowledged SOS (must be manually acknowledged)

**Active Incident Tracker:**

- Ongoing incidents being handled by safety officers
- Assigned to: Officer name
- Status: Investigating / On Call / Escalated / Resolved

**Today's Safety Summary:**

- SOS triggered: N
- Incidents resolved: N
- Average resolution time: X min
- Accounts flagged: N
- Accounts suspended (safety): N

---

#### Screen 7.2 — All Incidents List

**Purpose:** Full history of all safety incidents

**Layout:**

**Filters:**

- Type: SOS / Complaint / Suspicious behavior / Route deviation / Accident report / Other
- Severity: Critical / High / Medium / Low
- Status: Open / Investigating / Resolved / Escalated / Closed
- Date range
- Assigned to (safety officer)
- City

**Table Columns:**
| Incident ID | Type | Severity | Who | Ride | Reported | Assigned To | Status | Actions |

---

#### Screen 7.3 — Incident Detail & Resolution

**Purpose:** Full case management for a single incident

**Layout:**

**Header:**

- Incident ID: #INC-20240315-042
- Type: Rider SOS | Severity: Critical 🔴
- Status: Investigating
- Assigned to: Safety Officer — Sneha R.
- Created: 14 Mar 2026, 9:23 AM
- SLA: Resolve within 30 min | ⏱️ 12 min remaining

**Involved Parties:**

- Rider: Photo, Name, Contact (masked), "Call" button, "View Profile" link
- Driver: Photo, Name, Contact (masked), "Call" button, "View Profile" link
- Other passengers (if any)

**Incident Context:**

- Associated Ride ID (link)
- Location at time of SOS (map)
- GPS trail leading up to SOS trigger
- Speed at time of SOS
- Route deviation (if any, highlighted)

**Evidence Section:**

- Audio recording (if enabled) — playback with waveform
- Screenshots submitted (if any)
- GPS data export

**Communication Log:**

- All calls made from this incident (time, duration, who was called, outcome)
- In-app messages from the ride
- Admin notes (add note with timestamp)

**Resolution Workflow:**

- Status selector: Investigating → Resolved / Escalated to Police / Closed — No Action
- Resolution summary (mandatory text)
- Action taken:
  - Account suspended (link to account — pre-selects action)
  - Ride refunded (link to refund action)
  - Police notified
  - No action required
  - Other (text)
- "Close Incident" CTA (confirmation required)

**Post-Resolution:**

- Incident marked as resolved with timestamp
- Parties notified (configurable)
- Audit trail locked (immutable)

---

#### Screen 7.4 — Flagged Accounts

**Purpose:** List of accounts flagged for review

**Layout:**

- Tabs: Drivers | Riders
- Table: Account, Flag reason, Flagged by (user/system), Date, Status, Action
- Actions: Review → opens profile | Dismiss flag | Escalate | Suspend

**Auto-flag triggers (system-generated):**

- Rating drops below 3.0
- 3 or more cancellation strikes
- Multiple SOS incidents involving same person
- GPS anomaly detected (speed > 120 km/h, teleportation)
- Multiple failed payment attempts
- Account created from flagged device ID / IP

---

#### Screen 7.5 — Safety Reports

**Purpose:** Aggregated safety analytics for leadership

**Layout:**

- Incident trend charts (weekly/monthly)
- Incident type breakdown (pie chart)
- Resolution time trend
- City-wise safety heatmap
- Driver safety score distribution
- Rider report frequency
- "Download Safety Report (PDF)" — formatted for executive audience

---

### 7.8 PAYMENTS & FINANCIAL OPERATIONS

---

#### Screen 8.1 — Financial Overview Dashboard

**Purpose:** Platform's financial health at a glance

**Layout:**

**Header KPI Row:**

- Gross Transaction Volume (today): ₹4,82,000
- Platform Revenue (today): ₹24,100 (5% of GTV)
- Pending Payouts: ₹1,82,000 (to drivers)
- Failed Transactions (today): 14 | ₹12,400
- Refunds Processed (today): 8 | ₹4,200
- Active Wallet Balances (riders): ₹8,42,000 total

**Charts:**

- GTV trend (last 30 days): Line chart
- Revenue trend (last 30 days)
- Payout volume (last 30 days)
- Transaction success rate trend

**Alerts:**

- Payment gateway status: Razorpay — ✅ Operational
- Failed payout batch (if any): "3 payouts failed in last batch — Retry now"

---

#### Screen 8.2 — Transaction Management

**Purpose:** View and manage all financial transactions

**Layout:**

**Filters:**

- Date range
- Type: Ride payment / Wallet topup / Payout / Refund / Penalty / Incentive
- Status: Success / Pending / Failed / Disputed
- Amount range
- User / Driver

**Table Columns:**
| Transaction ID | Type | User / Driver | Ride ID | Amount | Gateway | Status | Timestamp | Actions |

**Actions per row:**

- View details
- Retry (if failed)
- Refund (if eligible)
- Flag as suspicious

**Bulk actions:**

- Retry all failed
- Export selected

---

#### Screen 8.3 — Payout Management

**Purpose:** Manage driver payouts

**Layout:**

**Payout Queue Tab:**

- Payouts ready to process (eligible: balance > ₹100, bank/UPI verified)
- Columns: Driver, Amount, Destination, Requested, Status
- Bulk: "Process All Eligible Payouts" → confirmation → Razorpay batch API call
- Individual: "Pay Now" per driver

**Payout History Tab:**

- All past payouts
- Filter: Date, Driver, Status (Success / Failed / Processing)
- Columns: Driver, Amount, Method, Reference ID, Initiated, Settled, Status

**Failed Payouts Tab:**

- Payouts that failed
- Failure reason: Invalid bank account / UPI ID changed / Insufficient funds (shouldn't happen) / API timeout
- Actions: Retry / Update bank details (trigger in-app notification to driver) / Manual transfer (mark as done externally)

---

#### Screen 8.4 — Refund Management

**Purpose:** Process passenger refunds

**Layout:**

**Refund Queue:**

- Pending refund requests
- Each: Rider, Ride ID, Amount, Reason, Requested at, Status
- Actions: Approve + Process | Reject with reason | Escalate

**Refund Detail Panel:**

- Full ride context
- Original transaction details
- Refund reason (submitted by user or support agent)
- Policy check: Eligible? (% based on cancellation time)
- Suggested refund amount (auto-calculated per policy)
- Override amount option (with justification — finance admin only)
- "Process Refund" CTA

**Refund Policy Config (link to System Settings → Fare Config):**

- Cancellation > 2 hrs: 100%
- Cancellation < 2 hrs: 50%
- Driver no-show: 100%
- Rider no-show: 0% (forfeited)

---

#### Screen 8.5 — Disputes

**Purpose:** Resolve financial disputes between riders and drivers

**Layout:**

**Dispute Queue:**

- Open disputes
- Columns: Dispute ID, Type (Fare / Refund / Payout), Rider, Driver, Amount, Opened, Status, Assigned To

**Dispute Detail:**

- Dispute context: Ride ID, both parties' claims
- Evidence: GPS data, chat transcript, payment records
- Policy reference
- Resolution options:
  - Full refund to rider
  - Partial refund
  - No refund — reject dispute
  - Manual adjustment (custom amount)
- Resolution note (mandatory)
- Both parties notified on resolution

---

#### Screen 8.6 — Promo Codes & Incentives

**Purpose:** Create and manage promotional offers

**Promo Code List:**

- All active/past codes
- Columns: Code, Type (% off / flat off / free ride), Value, Usage limit, Used count, Valid till, Status
- "Create New Code" CTA

**Create Promo Code Form:**

- Code (auto-generate or custom)
- Type: Percentage discount / Flat amount / First ride free
- Value
- Minimum ride value (to apply)
- Max discount cap
- Usage limit (total / per user)
- Valid from / Valid until
- Applicable to: All riders / New riders only / Specific city / Specific user segment
- "Create" CTA

**Driver Incentive Programs:**

- Active incentive rules
- Create/edit incentive (rides milestone → bonus amount)
- Incentive payout history

---

#### Screen 8.7 — Financial Reports

**Purpose:** Accounting-grade reports

**Report Types:**

- Daily revenue report
- Monthly P&L summary
- Transaction reconciliation (gateway transactions vs Supabase records)
- GST report (platform fees collected — for tax filing)
- Driver earnings report (for issuing income certificates)
- Refund summary
- Failed transaction analysis

**Export Formats:** PDF (formatted) | CSV (raw data) | Excel (formatted with charts)

**Schedule Reports:**

- Set up automated email delivery (daily/weekly/monthly)
- Recipients: Finance team email list

---

### 7.9 SUPPORT & HELPDESK

---

#### Screen 9.1 — All Tickets

**Purpose:** Manage all user and driver support requests

**Layout:**

**Filters:**

- Status: Open / In Progress / Pending User / Resolved / Closed
- Priority: Critical / High / Medium / Low
- Type: Refund / Safety / Technical / Account / Payment / Ride dispute / Other
- Assigned to
- User type: Rider / Driver
- Date range

**Table Columns:**
| Ticket ID | Subject | From | Type | Priority | Status | Created | Last Updated | Assigned To | Actions |

**Priority Coloring:**

- Critical: Red row highlight
- High: Orange left border
- Medium: Yellow left border
- Low: No highlight

**Bulk Actions:**

- Assign to agent
- Close
- Change priority

---

#### Screen 9.2 — Ticket Detail

**Purpose:** Full ticket view and resolution

**Layout (2-column):**

**Left: Conversation Thread (60%)**

- Full message history (user + agent messages)
- Message input box
- Attach file (for screenshots, receipts)
- "Send" CTA
- Rich text formatting (bold, links)
- Internal note toggle (visible to agents only — yellow background)

**Right: Ticket Info & Actions (40%)**

**Ticket Info:**

- Ticket ID, Created, Priority, Type
- Status selector (dropdown)
- Assigned to (agent dropdown)

**User/Driver Card:**

- Photo, Name, ID, Rating, Member since
- Quick links: View Profile | Ride History | Wallet

**Related Context (auto-fetched):**

- If ride-related: Ride card (route, date, amount, participants)
- If payment-related: Transaction card

**SLA Timer:**

- Time elapsed since ticket created
- SLA target based on priority
- Color: Green / Yellow (50% elapsed) / Red (overdue)

**Actions:**

- Resolve Ticket (status → Resolved, notifies user)
- Issue Wallet Credit (with reason — auto-sends to user's wallet)
- Process Refund (links to refund workflow)
- Escalate to Safety (converts to Safety incident)
- Merge tickets (if duplicate)
- Close Ticket (without resolution notification)

**Canned Responses:**

- Search/select from library
- Auto-fills message input
- Customizable before sending

---

#### Screen 9.3 — Canned Responses Library

**Purpose:** Pre-written responses for common issues

**Layout:**

- Category tabs: Refunds | Technical | Account | Rides | Payments | Safety | General
- Search
- Response cards: Title, Preview, Category, Last updated, Edit | Delete
- "Create New Response" CTA

**Create/Edit Form:**

- Title (internal name)
- Category
- Body (rich text, supports {{user_name}}, {{ride_id}} placeholders)
- Preview
- "Save" CTA

---

#### Screen 9.4 — Support Metrics Dashboard

**Purpose:** Track support team performance

**Metrics:**

- Total tickets (this week): N
- Resolved (this week): N | Resolution rate: 94%
- Average first response time: 18 min
- Average resolution time: 3.2 hours
- CSAT score (user rating of support): 4.2/5
- Tickets by type (pie chart)
- Tickets by agent (bar chart — for performance review)
- SLA breach rate trend
- Ticket volume trend (last 30 days)

---

### 7.10 ANALYTICS & REPORTS

---

#### Screen 10.1 — Growth Dashboard

**Purpose:** Platform growth KPIs for leadership

**Period Selector:** Today | This Week | This Month | Last 3 Months | Custom

**Metrics:**

- Total Users (riders): N | +X% vs last period
- Total Drivers (active): N | +X% vs last period
- Total Rides Completed: N | +X% vs last period
- New User Signups: N | DAU/MAU ratio
- New Driver Approvals: N
- Ride Match Rate: X% (rides that found a match / rides searched)
- Cities active: N

**Charts:**

- User growth line chart (Riders + Drivers)
- Daily/Weekly rides completed
- DAU (Daily Active Users) trend
- Retention cohort table (Week 1, Week 2, Week 4 retention by signup cohort)
- City-wise user distribution (map + table)

---

#### Screen 10.2 — Operational Metrics

**Purpose:** Day-to-day operations health

**Metrics:**

- Ride completion rate: % completed of all started
- Driver no-show rate
- Rider no-show rate
- Avg rides per driver per month
- Avg rides per rider per month
- Avg match time (ride search → first match shown)
- Peak hours heatmap (time of day × day of week × ride volume)
- Avg detour per ride (km added for pickups)

**Charts:**

- Hourly ride volume (24h view)
- Completion vs cancellation trend
- Supply vs demand gap (by city, by hour)

---

#### Screen 10.3 — Driver Analytics

**Metrics:**

- Total approved drivers
- Active drivers (rode in last 30 days)
- Churned drivers (no rides in 60+ days)
- Driver onboarding funnel: Applied → Documents submitted → Approved → First ride
- Drop-off rates per onboarding step (where drivers abandon verification)
- Avg driver lifetime value (total earnings over account life)
- Driver rating distribution histogram
- Earnings distribution (percentile breakdown)
- Document expiry forecast (X drivers' DL expiring in next 30 days)

---

#### Screen 10.4 — Rider Analytics

**Metrics:**

- Total riders
- Active riders (rode in last 30 days)
- Rider acquisition source breakdown
- Booking funnel: Searched → Matches found → Viewed detail → Booked → Completed
- Abandonment by funnel step
- Avg rides per rider per month
- Avg spend per rider per month
- Rider lifetime value
- Top routes (most searched + most booked)
- Gender split, city split, age range distribution

---

#### Screen 10.5 — Financial Analytics

**Metrics:**

- Gross Transaction Volume trend
- Net Revenue trend (platform fees)
- Revenue per ride trend
- Payout ratio (driver earnings / GTV)
- Refund rate trend
- Failed payment rate
- Promo code redemption rate + discount impact on revenue
- Wallet topup trend (predictor of future ride volume)
- City-wise revenue breakdown

---

#### Screen 10.6 — Safety Analytics

**Metrics:**

- SOS rate (SOS per 1,000 rides)
- Incident type distribution
- Average incident resolution time trend
- Route deviation frequency
- Accounts suspended (safety-related) per month
- Safety incident city heatmap
- Peak time for safety incidents (correlated with ride hours)

---

#### Screen 10.7 — Custom Report Builder

**Purpose:** Self-serve report creation for analysts

**Layout:**

- Left: Data source selector (Users / Drivers / Rides / Transactions / Incidents / Reviews)
- Center: Field selector (drag-drop columns to include)
- Filter builder: Add conditions (AND/OR logic)
- Grouping: Group by city / date / driver / status
- Aggregation: Count / Sum / Avg / Min / Max
- "Preview" button (shows first 100 rows)
- "Export" button (CSV / Excel / PDF)
- "Save Report" (save query as named report for reuse)
- Scheduled delivery setup (email on schedule)

---

### 7.11 NOTIFICATIONS & COMMUNICATIONS

---

#### Screen 11.1 — Push Notification Campaigns

**Purpose:** Send targeted push notifications to users/drivers

**Campaigns List:**

- All | Draft | Scheduled | Sent | Failed
- Table: Campaign name, Target, Sent count, Open rate, Created, Sent at, Status
- "Create Campaign" CTA

**Create Campaign Screen:**

**Step 1 — Content:**

- Title: Notification headline (max 50 chars)
- Body: Notification message (max 150 chars)
- Deep link: Where the notification opens in-app (dropdown: Home / Earnings / Schedule / Promo / Custom)
- Image (optional, for rich notifications)
- Preview card: Shows how it looks on Android + iOS

**Step 2 — Audience:**

- Target: All Riders | All Drivers | Both
- Filters:
  - City (multi-select)
  - Last active: Active in last 7/30/90 days / Never active
  - Rider: Verified only / Has X+ rides / New users (0 rides)
  - Driver: Approved / Pending / Has X+ rides
  - Language
  - Custom segment (from saved user segment)
- Estimated reach: "~12,400 users will receive this"

**Step 3 — Schedule:**

- Send now
- Schedule: Date + Time picker (with timezone)
- Recurring (for weekly tips/reminders)

**Step 4 — Review & Send:**

- Full summary
- A/B test option (v1.0 optional): Split 50/50 with variant B
- "Send / Schedule" CTA

---

#### Screen 11.2 — SMS Campaigns

**Purpose:** Send SMS to users (for critical announcements or non-app users)

**Layout (similar to Push):**

- Character counter (160 chars for 1 SMS, 306 for 2)
- Cost estimator: "₹0.12 × 12,400 recipients = ₹1,488"
- Audience selection (same as push)
- Approval required (Super Admin sign-off for bulk SMS > 10,000 recipients)

---

#### Screen 11.3 — In-App Banners

**Purpose:** Manage promotional banners shown in the Rider/Driver app home screen

**Layout:**

- Active banners list (drag to reorder priority)
- Each banner: Preview image, Target (riders/drivers), Valid dates, CTA action, Status
- "Create Banner" CTA

**Create Banner:**

- Banner image upload (exact dimensions: 800×200px for home banner)
- Title + Subtitle text overlay
- CTA button text + action (Open URL / Navigate to screen / Dismiss)
- Target app: Rider / Driver / Both
- Target segment (same as push)
- Valid from/until
- Preview on device mock
- "Publish" CTA

---

#### Screen 11.4 — Email Broadcasts

**Purpose:** Send emails to registered users (transactional + marketing)

**Layout:**

- Template selector (pre-designed templates)
- Subject line
- Email body (rich text editor)
- Variable substitution: {{first_name}}, {{city}}, {{ride_count}}
- Preview: Desktop + Mobile
- Test send (send to admin's own email first)
- Audience + Schedule (same pattern as push)
- Unsubscribe handling: Automatic (respects user preferences)

---

### 7.12 CONTENT MANAGEMENT

---

#### Screen 12.1 — App Onboarding Slides

**Purpose:** Update onboarding value proposition slides without app deployment

**Layout:**

- Current slides preview (3 cards, drag to reorder)
- Edit each slide: Headline, Body, Illustration (upload), Background color
- Add new slide / Remove slide
- Platform target: Rider app / Driver app / Both
- "Publish changes" CTA
- Changes take effect on next app launch (fetched from CMS)

---

#### Screen 12.2 — FAQ Management

**Purpose:** Manage FAQ content shown in Help sections of both apps

**Layout:**

- Category list (drag to reorder): General / Rides / Payments / Safety / Account / Driver
- FAQ list per category (drag to reorder)
- Create FAQ: Question + Answer (rich text) + Category + Platform (Rider/Driver/Both)
- Edit / Delete per FAQ
- "Publish" button (deploys to app via CMS API)

---

#### Screen 12.3 — Help Articles

**Purpose:** Long-form help articles for Support Center

**Layout:**

- Article list: Title, Category, Last updated, Published status
- "Create Article" CTA
- Rich text editor with: Headings, Bold/Italic, Lists, Images, Links, Code blocks
- Category assignment
- Platform target
- "Preview" + "Publish" / "Save Draft" CTAs
- Version history (last 5 versions, rollback available)

---

### 7.13 CONFIGURATION & SYSTEM SETTINGS

---

#### Screen 13.1 — Fare Configuration

**Purpose:** Control fare calculation parameters

**Layout:**

- Per-city fare settings (tab per city)
- Fields:
  - Fuel rate per km: ₹X.XX (editable)
  - Platform fee type: Flat / Percentage
  - Platform fee value: ₹X or X%
  - Platform fee cap: ₹X
  - Minimum fare per seat: ₹X
  - Maximum fare per seat: ₹X (safety cap)
  - Surge pricing toggle (v1.0: OFF)
- "Save Changes" with confirmation dialog
- Change history (who changed what, when)

---

#### Screen 13.2 — Matching Algorithm Settings

**Purpose:** Tune the matching engine parameters

**Layout:**

- Fields:
  - Pickup radius: XXX meters (default: 500m)
  - Drop radius: X km (default: 1km)
  - Time window: ±XX minutes (default: ±30 min)
  - Minimum route overlap: XX% (default: 60%)
  - Max detour per pickup: X km
  - Matching score weights:
    - Route overlap weight: 0.40
    - Time compatibility weight: 0.30
    - Location proximity weight: 0.20
    - Rating score weight: 0.10
  - Results returned: Top X matches (default: 10)
- Save with confirmation

---

#### Screen 13.3 — City & Zone Management

**Purpose:** Manage operational cities and zones

**Layout:**

- Active cities list: City name, State, Launch date, Status (Active / Paused / Coming soon)
- Add new city: Name, State, Polygon boundary (draw on map), Fare config
- Zone management within a city: Draw zones for demand analysis
- "Pause City Operations" toggle (emergency)

---

#### Screen 13.4 — Feature Flags

**Purpose:** Enable/disable platform features without app deployment

**Layout:**

- Table: Feature name, Description, Status (ON/OFF toggle), Target (All / % rollout / Specific users), Last changed by
- Features controlled:
  - `audio_recording_enabled`: Driver audio recording
  - `women_only_rides`: Women-only filter
  - `auto_accept_default`: Default auto-accept setting
  - `recurring_rides`: Recurring ride scheduling
  - `community_tab`: Community/eco impact tab
  - `in_app_navigation`: In-app turn-by-turn (vs external maps)
  - `driver_incentives`: Monthly incentive program
  - `surge_pricing`: Surge pricing module
  - `waitlist`: Ride waitlist feature
  - `referral_program`: Rider/driver referral
- Percentage rollout: e.g., "Enable for 10% of users" (for gradual rollout)

---

#### Screen 13.5 — Admin User Management

**Purpose:** Create and manage admin accounts (Super Admin only)

**Layout:**

- Admin users table: Name, Email, Role, Last login, Status, Actions
- "Add Admin User" CTA
  - Name, Work email
  - Role (dropdown — all roles except Super Admin)
  - "Create account" → sends invite email with temporary password + 2FA setup
- Edit role: Change role (confirmation required)
- Deactivate account (does not delete — for audit trail)
- View admin's action history

---

#### Screen 13.6 — Role & Permission Management

**Purpose:** View and adjust role definitions (Super Admin only)

**Layout:**

- Role list with description
- Permission matrix (same as Section 2, editable)
- Custom permission overrides per admin user (for edge cases)
- Changes to role permissions require 2-admin confirmation

---

#### Screen 13.7 — Audit Log Viewer

**Purpose:** Immutable log of all admin actions

**Layout:**

**Filters:**

- Date range
- Admin user
- Action type: Login / User action / Document decision / Suspension / Payout / Config change / Data export
- Target entity: User ID / Driver ID / Ride ID
- Severity: Critical / High / Normal

**Table Columns:**
| Timestamp | Admin | Role | Action | Target | IP Address | Details |

**Example rows:**

- 09:22 AM | Sneha R. (Safety Officer) | Suspended Account | Driver #DRV-4421 | Reason: Safety incident
- 09:18 AM | Rahul K. (Finance Admin) | Processed Refund | ₹170 | Rider #USR-1102 | Ride #RD-4881
- 09:14 AM | Amit S. (Doc Reviewer) | Document Approved | Driver #DRV-4409 | DL Verification

**Properties:**

- Read-only (no edit, no delete — ever)
- Retained for: 3 years (compliance)
- Exportable: CSV (with date range limit of 90 days per export)
- Anomaly alerts: If unusual admin activity detected (mass deletions, config changes at odd hours)

---

## 8. Core Operations Workflows

### 8.1 New Driver Approval Workflow

```
Driver submits all documents via Driver App
          ↓
Automated Pipeline (Supabase Edge Function):
  • OCR extract all document fields
  • API calls: mParivahan (DL + RC), Penny drop (bank)
  • Score each document: Pass / Warning / Fail
          ↓
Auto-Approve Condition:
  All documents Pass → Auto-approved in < 5 min
  → Driver notified
  → Onboarded immediately
          ↓
Manual Review Trigger (if any Warning/Fail):
  → Added to Verification Queue in Admin Dashboard
  → Assigned to next available Document Reviewer (FIFO)
  → Reviewer sees OCR results + API results + document images
  → Decision: Approve / Reject / Request Resubmission
          ↓
Driver notified via Push + SMS:
  • Approved → Welcome screen + can go online
  • Rejected → Specific reason + which documents to re-upload
  • Resubmission → Instructions + deadline (72 hours)
          ↓
SLA: Manual review completed within 2 hours of assignment
```

### 8.2 SOS Response Workflow

```
SOS Triggered (Rider or Driver)
          ↓
Immediate Automated Actions (< 30 seconds):
  • Emergency contacts SMS'd with live tracking link
  • 112 auto-dial initiated on device
  • SmartPool Safety Team alerted (push + email + Slack webhook)
  • Audio recording uploaded to secure storage (if active)
  • Incident record created in DB (#INC-XXXXXX)
          ↓
Admin Dashboard Alert:
  • Red alert strip appears on ALL admin screens
  • Alarm sound plays (until acknowledged)
  • On-call Safety Officer sees incident card
          ↓
Safety Officer Actions (SLA: acknowledge within 2 min):
  • Reviews location, GPS trail, ride context
  • Calls the person (proxy call via admin dashboard)
  • Calls the other party if needed
  • Assesses situation
          ↓
Resolution Paths:
  A) False alarm → Mark resolved, log reason
  B) Needs support → Coordinate with local support/police
  C) Escalate → Notify police department + senior admin
          ↓
Post-Resolution:
  • Incident report completed
  • Accounts flagged/suspended if necessary
  • User follow-up scheduled
  • Report added to monthly safety summary
```

### 8.3 Dispute Resolution Workflow

```
Dispute raised (by Rider or Driver via support ticket or auto-flagged)
          ↓
Support Agent reviews:
  • Retrieves ride details, GPS data, payment records, chat transcript
  • Checks against policy
          ↓
Decision made:
  A) Clear-cut → Apply policy automatically (e.g., driver no-show = full refund)
  B) Gray area → Escalate to Ops Manager
          ↓
Action executed:
  • Refund issued (Finance Admin approves if > ₹500)
  • Penalty applied to offending party
  • Both parties notified
          ↓
Ticket closed with resolution summary
Repeat offender flagged for account review
```

---

## 9. Document Verification Workflow

### Automated Checks per Document

| Document          | Automated Checks                                        | API Used                  |
| ----------------- | ------------------------------------------------------- | ------------------------- |
| Aadhaar           | Name + DOB + ID number validity                         | DigiLocker OAuth          |
| Driving Licence   | DL validity, expiry, LMV endorsement, name match        | mParivahan API            |
| RC (Vehicle Reg.) | Reg. number validity, owner name match, vehicle details | mParivahan API            |
| Insurance         | Expiry date (via OCR), policy number format             | OCR only (no API in v1.0) |
| PUC Certificate   | Expiry date (via OCR)                                   | OCR only                  |
| Bank Account      | Account active, name match                              | Razorpay Penny Drop       |

### Manual Review Triggers

Manual review is triggered if:

- API returns mismatch on any field
- OCR confidence < 85%
- Name between Aadhaar and DL/RC differs by > 20% (fuzzy match)
- DL category does not include LMV
- Document image fails quality check (blur, glare, incomplete)
- Previous rejection history for this driver

### Reviewer SLA & Escalation

- Normal queue: Reviewed within 2 hours (business hours)
- Priority (driver has active bookings): Reviewed within 30 min
- After-hours: Queued for next morning (with max 12-hour SLA)
- Reviewer dispute: Second reviewer assigned; majority decision
- Suspected fraud: Escalated to Ops Manager; driver cannot proceed

---

## 10. Safety & Incident Response Workflow

### Incident Severity Classification

| Level         | Definition                       | Response SLA | Example                          |
| ------------- | -------------------------------- | ------------ | -------------------------------- |
| P0 — Critical | Active physical danger           | < 2 minutes  | SOS triggered mid-ride           |
| P1 — High     | Safety threat, no current danger | < 15 minutes | Harassment complaint post-ride   |
| P2 — Medium   | Policy violation, no safety risk | < 2 hours    | Route deviation, no-show dispute |
| P3 — Low      | General complaints, feedback     | < 24 hours   | Ride quality complaint           |

### Escalation Matrix

- P0: On-call Safety Officer → Safety Lead → CEO (if unresolved in 10 min)
- P1: On-call Safety Officer → Safety Lead
- P2: Support Agent → Ops Manager
- P3: Support Agent (self-resolve)

---

## 11. Fraud Detection & Prevention

### Automated Fraud Signals

| Signal                                 | Threshold                                | Action                  |
| -------------------------------------- | ---------------------------------------- | ----------------------- |
| Multiple accounts same device          | 2 accounts, 1 device                     | Auto-flag for review    |
| Multiple accounts same phone           | —                                        | Auto-merge prompt       |
| GPS teleportation                      | >200 km/hr impossible movement           | Flag + log              |
| Speed violation                        | >120 km/hr                               | Alert safety officer    |
| Fake ride completion (no GPS movement) | Ride ended with < 500m movement          | Hold payment, flag      |
| Repeated failed payments               | 5+ in 24 hours                           | Temporary payment block |
| Promo abuse                            | >3 promo accounts per device/IP          | Flag + block codes      |
| Rating manipulation                    | Sudden spike in 5-star from new accounts | Flag + investigate      |
| Fake documents                         | OCR mismatch + API fail + visual anomaly | Reject + escalate       |

### Fraud Review Queue

- All auto-flagged accounts appear in fraud queue
- Reviewer: Ops Manager or Safety Officer
- Actions: Dismiss flag / Suspend / Permanent ban / Escalate to legal

---

## 12. Financial Operations & Reconciliation

### Daily Reconciliation Process

```
End of Day (auto-scheduled at 11:59 PM):
  1. Pull all Razorpay transactions from Gateway API
  2. Compare against Supabase transaction records
  3. Flag any mismatches:
     - Payment received by gateway but not recorded in DB
     - Payment recorded in DB but not confirmed by gateway
     - Duplicate transactions
  4. Generate reconciliation report → sent to Finance Admin + CFO
  5. Manual resolution queue for mismatches
```

### Payout Batch Schedule

- Automatic payout batch: Daily at 2:00 AM
- Eligibility check: Balance ≥ ₹100 + active bank/UPI
- Batch size: Up to 5,000 payouts per batch (Razorpay limit)
- Multiple batches if needed
- Finance Admin can trigger manual batch at any time

### Tax & Compliance Reports

- GST report: Monthly (platform fee is taxable supply)
- TDS on driver earnings: Quarterly (if applicable above threshold)
- Annual income certificate for drivers (issued on request via Driver App)
- All financial data retained for 7 years (India compliance requirement)

---

## 13. Notification & Communication System

### Notification Types & Channels

| Type                       | Push | SMS | Email        | In-App |
| -------------------------- | ---- | --- | ------------ | ------ |
| Booking confirmed          | ✅   | ✅  | ❌           | ✅     |
| Ride reminder (30 min)     | ✅   | ❌  | ❌           | ✅     |
| Driver approaching         | ✅   | ❌  | ❌           | ✅     |
| Ride completed             | ✅   | ❌  | ✅ (receipt) | ✅     |
| Payment success            | ✅   | ❌  | ✅           | ✅     |
| Payout processed (driver)  | ✅   | ✅  | ✅           | ✅     |
| Document approved/rejected | ✅   | ✅  | ✅           | ✅     |
| SOS emergency contacts     | ❌   | ✅  | ❌           | ❌     |
| Promo / Marketing          | ✅   | ❌  | ✅           | ✅     |
| Support ticket update      | ✅   | ❌  | ✅           | ✅     |
| Account suspension         | ✅   | ✅  | ✅           | ✅     |

### Notification Throttling Rules

- Max push notifications per user per day: 5 (excluding transactional)
- Max SMS per user per week: 3 (marketing)
- Notification quiet hours: 10 PM – 8 AM (non-transactional only)
- User opt-out respected for all non-transactional notifications

---

## 14. Audit Logging & Compliance

### What is Logged

Every admin action is logged with:

- `admin_id`: Who performed the action
- `admin_role`: Their role at the time
- `action_type`: Enum of all possible actions
- `target_entity_type`: user / driver / ride / transaction / document / config
- `target_entity_id`: ID of affected record
- `old_value` (JSON): State before action
- `new_value` (JSON): State after action
- `ip_address`: Admin's IP
- `user_agent`: Browser/device info
- `timestamp`: UTC
- `session_id`: Which session performed the action

### High-Sensitivity Actions (require 2-admin confirmation)

- Permanent account ban
- Bulk user data export
- Fare configuration changes
- Matching algorithm parameter changes
- Feature flag changes affecting > 50% of users
- Manual payout override > ₹10,000
- Role/permission changes

### Data Retention

| Data Type              | Retention Period                         |
| ---------------------- | ---------------------------------------- |
| Audit logs             | 3 years                                  |
| Financial records      | 7 years (India law)                      |
| User personal data     | Account lifetime + 2 years post-deletion |
| Driver documents       | Account lifetime + 3 years post-deletion |
| Ride GPS data          | 1 year                                   |
| Incident records       | 5 years                                  |
| Audio recordings (SOS) | 6 months (or until case closed)          |
| Support tickets        | 3 years                                  |

---

## 15. Non-Functional Requirements

| Requirement               | Target                                                      |
| ------------------------- | ----------------------------------------------------------- |
| Dashboard load time       | < 2 seconds (P95)                                           |
| Table render (1000 rows)  | < 500ms                                                     |
| Real-time alert latency   | < 2 seconds (SOS)                                           |
| Report generation (large) | < 30 seconds                                                |
| Concurrent admin users    | Support 50 simultaneous users                               |
| Browser support           | Chrome 100+ / Firefox 100+ / Safari 15+ / Edge 100+         |
| Viewport target           | 1440px primary, 1280px minimum                              |
| Uptime SLA                | 99.9% (< 8.7 hours downtime/year)                           |
| Authentication            | MFA mandatory (TOTP)                                        |
| Data encryption           | AES-256 at rest, TLS 1.3 in transit                         |
| PII masking               | Aadhaar, bank accounts masked by default                    |
| Session security          | 8-hour timeout, IP-based anomaly detection                  |
| Audit log integrity       | Append-only, no edit/delete, cryptographic hash chain       |
| Accessibility             | WCAG 2.1 AA for admin dashboard                             |
| Backup                    | Database: Continuous WAL; Backups: Daily + 30-day retention |

---

## 16. Out of Scope — v1.0

Deferred to v2.0+:

- Native mobile admin app (iOS/Android) — web only in v1.0
- AI-powered document verification (ML model — v2.0; v1.0 uses API + OCR)
- AI-powered fraud detection (ML — v2.0; v1.0 uses rules engine)
- Live chat with users from admin (v1.0: async ticket only)
- Automated A/B testing platform (v1.0: manual Firebase Remote Config)
- Predictive demand forecasting dashboard
- Driver supply optimization recommendations
- Automated escalation to police API (v1.0: manual logging)
- Corporate account management (B2B module)
- Multi-language admin interface
- White-label admin for city operations partners
- API for third-party BI tools (Tableau, Power BI connector)
- Advanced ML-based rating manipulation detection
- Real-time revenue alerting (Slack integration for finance alerts — v2.0)

---

## 17. Dependencies & Integrations

| Integration             | Purpose                                             | Used In                  |
| ----------------------- | --------------------------------------------------- | ------------------------ |
| Supabase JS Client      | All DB reads/writes, auth, realtime                 | All modules              |
| Supabase Realtime       | Live ride map, SOS alerts, activity feed            | Dashboard, Safety, Rides |
| Google Maps JS API      | Live ride map, incident location, zone drawing      | Dashboard, Rides, Safety |
| Razorpay Dashboard API  | Transaction data, payout processing, reconciliation | Finance                  |
| mParivahan API          | DL + RC verification                                | Document Verification    |
| DigiLocker API          | Aadhaar verification                                | Document Verification    |
| Firebase Admin SDK      | Push notification campaigns, FCM batch send         | Notifications            |
| Twilio / MSG91          | SMS campaigns, bulk SMS                             | Notifications            |
| Sentry                  | Frontend error tracking                             | All modules              |
| Mixpanel (Admin events) | Track admin usage patterns                          | Analytics                |
| PDF generation lib      | Report exports, receipts                            | Finance, Support         |
| CSV export              | Data exports                                        | All list views           |

---

## 18. Risks & Mitigations

| Risk                                       | Probability | Impact   | Mitigation                                                                            |
| ------------------------------------------ | ----------- | -------- | ------------------------------------------------------------------------------------- |
| Admin credential compromise                | Medium      | Critical | MFA mandatory, IP allowlisting, anomaly detection, privileged access review           |
| Unauthorized data access                   | Low         | Critical | Row-Level Security, role-based access, PII masking, access audit logs                 |
| Reviewer bias / fraud in document approval | Low         | High     | Dual-reviewer system for flagged docs, audit trail, reviewer performance monitoring   |
| SOS alert missed by safety team            | Low         | Critical | Persistent alarm, escalation chain, on-call rotation, SLA enforcement                 |
| Financial reconciliation errors            | Medium      | High     | Automated daily reconciliation, mismatch alerts, dual-approval for manual overrides   |
| Admin dashboard downtime                   | Low         | High     | 99.9% SLA, health monitoring, failover, status page                                   |
| Bulk notification abuse                    | Low         | Medium   | Approval workflow for large campaigns, throttle limits, audit trail                   |
| Insider threat (admin misuse)              | Low         | High     | Immutable audit logs, anomaly detection, separation of duties, periodic access review |
| Data export leading to data breach         | Low         | Critical | Export logging, size limits, approval for large exports, watermarking                 |
| Feature flag misconfiguration              | Medium      | Medium   | Staged rollout, rollback capability, change confirmation dialog                       |

---

## 19. Appendix A — Screen Inventory

**Total Admin Screens: 52**
**P0 (Must-Have): 31 | P1 (Important): 16 | P2 (Nice-to-Have): 5**

| #    | Screen Name                   | Priority | Sprint   |
| ---- | ----------------------------- | -------- | -------- |
| 1.1  | Login Page                    | P0       | Sprint 1 |
| 1.2  | Admin Profile & Security      | P1       | Sprint 1 |
| 2.1  | Main Dashboard                | P0       | Sprint 1 |
| 2.2  | Global Search                 | P1       | Sprint 1 |
| 3.1  | All Riders List               | P0       | Sprint 2 |
| 3.2  | Rider Profile Detail          | P0       | Sprint 2 |
| 3.3  | Suspend / Ban User Modal      | P0       | Sprint 2 |
| 4.1  | All Drivers List              | P0       | Sprint 2 |
| 4.2  | Driver Profile Detail         | P0       | Sprint 2 |
| 4.3  | Driver Application Queue      | P0       | Sprint 2 |
| 5.1  | Verification Queue Dashboard  | P0       | Sprint 2 |
| 5.2  | Document Verification Detail  | P0       | Sprint 2 |
| 5.3  | Document Verification History | P1       | Sprint 3 |
| 6.1  | Live Rides Monitor (Map)      | P0       | Sprint 3 |
| 6.2  | All Rides Table               | P0       | Sprint 3 |
| 6.3  | Ride Detail                   | P0       | Sprint 3 |
| 6.4  | Cancelled / Disputed Rides    | P1       | Sprint 3 |
| 7.1  | Safety Dashboard (Active SOS) | P0       | Sprint 3 |
| 7.2  | All Incidents List            | P0       | Sprint 3 |
| 7.3  | Incident Detail & Resolution  | P0       | Sprint 3 |
| 7.4  | Flagged Accounts              | P0       | Sprint 4 |
| 7.5  | Safety Reports                | P1       | Sprint 4 |
| 8.1  | Financial Overview Dashboard  | P0       | Sprint 4 |
| 8.2  | Transaction Management        | P0       | Sprint 4 |
| 8.3  | Payout Management             | P0       | Sprint 4 |
| 8.4  | Refund Management             | P0       | Sprint 4 |
| 8.5  | Disputes                      | P1       | Sprint 4 |
| 8.6  | Promo Codes & Incentives      | P1       | Sprint 5 |
| 8.7  | Financial Reports             | P0       | Sprint 5 |
| 9.1  | All Tickets                   | P0       | Sprint 5 |
| 9.2  | Ticket Detail                 | P0       | Sprint 5 |
| 9.3  | Canned Responses Library      | P1       | Sprint 5 |
| 9.4  | Support Metrics Dashboard     | P1       | Sprint 5 |
| 10.1 | Growth Dashboard              | P0       | Sprint 5 |
| 10.2 | Operational Metrics           | P1       | Sprint 5 |
| 10.3 | Driver Analytics              | P1       | Sprint 6 |
| 10.4 | Rider Analytics               | P1       | Sprint 6 |
| 10.5 | Financial Analytics           | P1       | Sprint 6 |
| 10.6 | Safety Analytics              | P1       | Sprint 6 |
| 10.7 | Custom Report Builder         | P2       | Sprint 6 |
| 11.1 | Push Notification Campaigns   | P0       | Sprint 6 |
| 11.2 | SMS Campaigns                 | P1       | Sprint 6 |
| 11.3 | In-App Banners                | P1       | Sprint 6 |
| 11.4 | Email Broadcasts              | P2       | Sprint 7 |
| 12.1 | Onboarding Slides CMS         | P2       | Sprint 7 |
| 12.2 | FAQ Management                | P1       | Sprint 7 |
| 12.3 | Help Articles                 | P1       | Sprint 7 |
| 13.1 | Fare Configuration            | P0       | Sprint 7 |
| 13.2 | Matching Algorithm Settings   | P0       | Sprint 7 |
| 13.3 | City & Zone Management        | P0       | Sprint 7 |
| 13.4 | Feature Flags                 | P0       | Sprint 7 |
| 13.5 | Admin User Management         | P0       | Sprint 7 |
| 13.6 | Role & Permission Management  | P1       | Sprint 7 |
| 13.7 | Audit Log Viewer              | P0       | Sprint 7 |

---

## 20. Appendix B — Admin Role Definitions

| Role            | Full Name                        | Team                | Key Responsibilities                                                              |
| --------------- | -------------------------------- | ------------------- | --------------------------------------------------------------------------------- |
| Super Admin     | Platform Super Administrator     | Engineering / CTO   | Full platform access, admin management, config changes, emergency actions         |
| Ops Manager     | Operations Manager               | Operations          | Day-to-day platform management, driver approvals, ride monitoring, KPI tracking   |
| Doc Reviewer    | Document Verification Specialist | Operations          | Process driver onboarding document queue; approve/reject/request resubmission     |
| Safety Officer  | Trust & Safety Officer           | Trust & Safety      | Handle SOS events, investigate incidents, suspend unsafe accounts, safety reports |
| Finance Admin   | Finance Administrator            | Finance             | Process payouts, handle refunds, reconciliation, financial reporting              |
| Support Agent   | Customer Support Agent           | Customer Experience | Handle tickets, resolve rider/driver issues, issue goodwill credits               |
| Marketing Admin | Marketing Administrator          | Growth / Marketing  | Manage notifications, banners, promo codes, content                               |
| Analyst         | Data Analyst                     | Analytics           | Read-only access to all data; build custom reports, provide insights              |

---

## 21. Appendix C — KPI Definitions & Formulas

| KPI                     | Definition                                        | Formula                                                                     |
| ----------------------- | ------------------------------------------------- | --------------------------------------------------------------------------- |
| Ride Completion Rate    | % of started rides that completed normally        | Completed Rides / (Completed + Cancelled by Driver + Cancelled during ride) |
| Match Rate              | % of ride searches that returned ≥ 1 match        | Searches with ≥ 1 result / Total searches                                   |
| Driver Utilization Rate | % of published ride seats that got booked         | Booked seats / Total offered seats                                          |
| Driver No-Show Rate     | % of rides where driver didn't show               | Driver no-shows / Total rides with bookings                                 |
| Document Review TAT     | Average time from submission to decision          | Sum(decision_time - submission_time) / Count(decisions)                     |
| SOS Resolution Time     | Average time from SOS trigger to incident closure | Sum(closed_time - triggered_time) / Count(SOS incidents)                    |
| Ticket Resolution Time  | Average time from ticket open to resolved         | Sum(resolved_time - created_time) / Count(resolved tickets)                 |
| Platform Revenue        | Net revenue earned by SmartPool                   | Sum of platform fees collected - refunded platform fees                     |
| Driver Churn Rate       | % of approved drivers who stop riding             | Drivers with 0 rides in 60 days / Total approved drivers                    |
| Rider Retention         | % of riders who ride again within 30 days         | Riders with ≥ 2 rides in 30 days / New riders                               |

---

## 22. Appendix D — Incident Severity Levels

| Level | Name     | Description                                                             | Auto-Alert?                | Response SLA | Escalation                   |
| ----- | -------- | ----------------------------------------------------------------------- | -------------------------- | ------------ | ---------------------------- |
| P0    | Critical | Physical danger, active SOS, accident                                   | ✅ Immediate sound + popup | 2 minutes    | On-call Officer → Lead → CEO |
| P1    | High     | Assault / harassment complaint, route deviation with unreachable driver | ✅ Push to safety officer  | 15 minutes   | On-call Officer → Lead       |
| P2    | Medium   | Driver/rider conduct complaint, payment dispute, no-show                | ✅ Queue notification      | 2 hours      | Support Agent → Ops Manager  |
| P3    | Low      | App feedback, ride quality complaint, minor issues                      | ❌ Queue only              | 24 hours     | Support Agent (self-resolve) |

---

_Document Owner: Product Team_
_Related Documents: User App PRD v1.0 | Driver App PRD v1.0_
_Next Review: April 2026_
_All three PRDs complete — SmartPool v1.0 specification finalized._
