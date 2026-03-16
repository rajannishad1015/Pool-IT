# 🚗 SmartPool — Driver App

## Product Requirements Document (PRD) v1.0

---

**Document Version:** 1.0
**Last Updated:** March 2026
**Platform:** Flutter (Android & iOS)
**Backend:** Supabase (PostgreSQL + Realtime + Storage)
**Scope:** Driver-Facing Application Only
**Depends On:** User App PRD v1.0 (completed)
**Status:** Ready for Development

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Driver vs Rider — Key Differences](#2-driver-vs-rider---key-differences)
3. [Goals & Success Metrics](#3-goals--success-metrics)
4. [Target Driver Personas](#4-target-driver-personas)
5. [Technical Architecture Overview](#5-technical-architecture-overview)
6. [Design Philosophy & UI Standards](#6-design-philosophy--ui-standards)
7. [Information Architecture](#7-information-architecture)
8. [Screen-by-Screen Specifications](#8-screen-by-screen-specifications)
   - 8.1 Onboarding & Verification Flow
   - 8.2 Home & Availability Dashboard
   - 8.3 Ride Management Flow
   - 8.4 Active Ride Flow (Driver POV)
   - 8.5 Earnings & Payouts
   - 8.6 Vehicle Management
   - 8.7 Profile & Ratings
   - 8.8 Schedule & Recurring Rides
   - 8.9 Safety Features
   - 8.10 Notifications & Activity
   - 8.11 Settings
9. [Core Driver Features Deep Dive](#9-core-driver-features-deep-dive)
10. [Driver Verification & Onboarding Logic](#10-driver-verification--onboarding-logic)
11. [Ride Matching & Acceptance Logic](#11-ride-matching--acceptance-logic)
12. [Earnings & Payout Model](#12-earnings--payout-model)
13. [Driver Rating & Incentive System](#13-driver-rating--incentive-system)
14. [Go-Online / Go-Offline Logic](#14-go-online--go-offline-logic)
15. [Navigation & Route Management](#15-navigation--route-management)
16. [Safety & Emergency Protocols](#16-safety--emergency-protocols)
17. [Non-Functional Requirements](#17-non-functional-requirements)
18. [Out of Scope — v1.0](#18-out-of-scope---v10)
19. [Dependencies & Integrations](#19-dependencies--integrations)
20. [Risks & Mitigations](#20-risks--mitigations)
21. [Appendix A — Screen Inventory](#21-appendix-a---screen-inventory)
22. [Appendix B — Driver Onboarding Checklist](#22-appendix-b---driver-onboarding-checklist)
23. [Appendix C — Driver States & Transitions](#23-appendix-c---driver-states--transitions)

---

## 1. Executive Summary

The **SmartPool Driver App** is a dedicated Flutter application for vehicle owners who wish to share their daily commute with co-passengers and earn money while reducing traffic congestion. It is a **separate app** from the Rider App, purpose-built for the driver's unique needs: route publishing, passenger management, real-time navigation, earnings tracking, and vehicle management.

Unlike ride-hailing driver apps (Ola/Uber), the SmartPool Driver App is designed around **scheduled, recurring commutes** — not on-demand taxi service. Drivers set their route once, publish it, and the system handles matching. The experience is calm, predictable, and rewarding.

### Key Driver Value Propositions

- **Earn money** on your existing daily commute (zero extra effort)
- **Offset fuel costs** completely or partially
- **Meet verified, trustworthy co-passengers**
- **Contribute to a greener city** with every shared ride

---

## 2. Driver vs Rider — Key Differences

| Dimension          | Rider App              | Driver App                                |
| ------------------ | ---------------------- | ----------------------------------------- |
| Primary Action     | Search & Book rides    | Publish & Manage rides                    |
| Verification Level | Optional (recommended) | Mandatory (DL + RC + Aadhaar)             |
| Vehicle            | Not required           | Required (add vehicle with documents)     |
| Earnings           | N/A                    | Full earnings dashboard + payout          |
| Navigation         | View only              | Turn-by-turn navigation                   |
| Availability       | Always browsable       | Online/Offline toggle (availability mode) |
| Passenger List     | See co-riders          | Manage all booked passengers              |
| Document Upload    | ID only                | DL + RC + Insurance + Pollution cert      |
| Route Control      | Select from options    | Publish own route with full control       |
| Scheduling         | Book a slot            | Create repeating schedules                |

---

## 3. Goals & Success Metrics

### Product Goals

- Onboard and verify 10,000+ active drivers within 6 months of launch
- Ensure ≥ 85% ride completion rate from driver side
- Achieve average driver earnings of ₹3,000–8,000/month
- Maintain driver rating ≥ 4.5 system-wide
- Keep driver churn < 15% monthly

### KPIs

| Metric                           | Target (6 Months) |
| -------------------------------- | ----------------- |
| Active Verified Drivers          | 10,000            |
| Rides Published per Driver/Month | 20+               |
| Ride Completion Rate             | ≥ 85%             |
| Driver Average Rating            | ≥ 4.5 / 5.0       |
| Driver Monthly Earnings (avg)    | ₹3,500+           |
| Onboarding Completion Rate       | ≥ 70%             |
| Driver No-Show Rate              | < 5%              |
| App Store Rating (Driver App)    | ≥ 4.3             |

---

## 4. Target Driver Personas

### Persona 1 — Vikram, the Daily Office Commuter Driver

- Age: 34, Senior Manager, Mumbai
- Drives 28 km daily to office, spends ₹9,000/month on petrol
- Goal: Recover fuel costs by taking 2–3 co-passengers
- Behavior: Sets recurring Mon–Fri rides; minimal app interaction needed

### Persona 2 — Sunita, the Safety-First Female Driver

- Age: 29, Teacher, Pune
- Has her own car, commutes daily but concerned about stranger safety
- Goal: Earn while commuting; only accept verified women passengers
- Behavior: Uses women-only filter, checks every passenger profile before accepting

### Persona 3 — Karthik, the Side-Income Seeker

- Age: 26, Freelancer, Bengaluru
- Flexible schedule; looks for multiple rides per day to maximize earnings
- Goal: Earn ₹5,000–8,000/month as meaningful side income
- Behavior: Power user — checks earnings dashboard daily, takes multiple different routes

### Persona 4 — Meera, the Eco-Conscious Driver

- Age: 32, NGO Professional, Delhi
- Drives to work every day; passionate about reducing carbon footprint
- Goal: Fill all seats every ride, track CO₂ impact
- Behavior: Engages with eco-impact stats, shares achievements socially

---

## 5. Technical Architecture Overview

```
SmartPool Driver App (Flutter — Android + iOS)
           │
           ▼
    Supabase Backend (shared with Rider App)
    ├── PostgreSQL
    │   ├── drivers table (profile, verification status, rating)
    │   ├── vehicles table (make, model, RC, insurance docs)
    │   ├── rides table (route, schedule, seats, status)
    │   ├── ride_bookings table (passenger-ride mapping)
    │   ├── earnings table (per-ride, payouts, ledger)
    │   └── documents table (DL, RC, insurance uploads)
    ├── Realtime Subscriptions
    │   ├── New booking alerts (live)
    │   ├── Passenger cancellations (live)
    │   ├── SOS alerts
    │   └── Chat messages
    ├── Supabase Storage
    │   ├── Vehicle photos
    │   ├── Document uploads (DL, RC, Insurance)
    │   └── Profile photos
    └── Edge Functions
        ├── Fare calculation engine
        ├── Earnings distribution
        ├── Driver availability indexing
        └── Notification dispatcher
           │
           ▼
    Third-Party Integrations
    ├── Google Maps SDK (navigation, route display)
    ├── Google Directions API (ETA, traffic-aware routing)
    ├── Razorpay (payout to bank account)
    ├── Firebase Cloud Messaging (push notifications)
    ├── DigiLocker API (Aadhaar + DL verification)
    ├── mParivahan API (RC / vehicle registration check)
    ├── Twilio / MSG91 (SMS alerts)
    └── Sentry (crash reporting)
```

---

## 6. Design Philosophy & UI Standards

### Visual Identity (Driver App — distinct from Rider App)

| Token              | Value                                           |
| ------------------ | ----------------------------------------------- |
| Primary Background | `#0D1B2A` (deep dark navy — conveys authority)  |
| Primary Accent     | `#00C896` (emerald green — earnings, go-online) |
| Secondary Accent   | `#E94560` (coral red — alerts, SOS, offline)    |
| Neutral Surface    | `#1C2B3A` (dark card surface)                   |
| Text Primary       | `#F0F4F8`                                       |
| Text Secondary     | `#8FA3B1`                                       |
| Success            | `#27AE60`                                       |
| Warning            | `#F39C12`                                       |
| Error              | `#E74C3C`                                       |
| Typography         | Inter (primary), monospace for earnings/numbers |

### Design Principles

- **Driver-first clarity:** All critical actions (Go Online, Accept Ride, Start Ride, End Ride) must be reachable in ≤ 2 taps from home screen
- **Large tap targets:** Minimum 56px for all action buttons (driver may be in motion / using one hand)
- **High contrast:** All text must meet WCAG AA in both light and dark modes
- **Distraction-minimized:** During active rides, non-essential UI elements are hidden
- **Earnings always visible:** Current balance shown in header on all main screens

### Platform Notes

- Primary platform: Android (80% of Indian drivers use Android)
- iOS support: Full parity, slightly later in QA cycle
- Minimum Android SDK: 26 (Android 8.0)
- Minimum iOS: 14.0
- Background location permission is mandatory (required for live tracking)
- Battery optimization whitelisting prompted at onboarding

---

## 7. Information Architecture

```
SmartPool Driver App
│
├── Onboarding (First Launch — Multi-step)
│   ├── Splash Screen
│   ├── Welcome Screen
│   ├── Phone / OTP Verification
│   ├── Basic Profile Setup
│   ├── Aadhaar Verification (mandatory)
│   ├── Driving Licence Upload & Verification
│   ├── Vehicle Registration (RC) Upload
│   ├── Vehicle Insurance Upload
│   ├── Pollution Certificate Upload
│   ├── Vehicle Details Form
│   ├── Vehicle Photo Upload
│   ├── Bank Account / UPI Setup (for payouts)
│   ├── Profile Photo (mandatory for drivers)
│   └── Approval Pending Screen
│
├── Home Tab (🏠)
│   ├── Driver Home / Dashboard
│   ├── Go Online / Go Offline Toggle
│   ├── Today's Ride Overview
│   └── Earnings Summary Card
│
├── My Rides Tab (🚗)
│   ├── Upcoming Rides List
│   ├── Ride Detail (pre-departure)
│   ├── Passenger List Screen
│   ├── Active Ride Screen (navigation mode)
│   ├── Ride Summary (post-completion)
│   └── Past Rides History
│
├── Schedule Tab (📅)
│   ├── Weekly Schedule Calendar
│   ├── Create New Ride
│   ├── Edit Existing Ride
│   ├── Recurring Ride Settings
│   └── Holiday / Day Off Management
│
├── Earnings Tab (💰)
│   ├── Earnings Dashboard
│   ├── Ride-wise Earnings Breakdown
│   ├── Weekly / Monthly Reports
│   ├── Payout History
│   └── Withdraw / Transfer to Bank
│
└── Profile Tab (👤)
    ├── My Profile (public view)
    ├── Edit Profile
    ├── My Vehicle
    ├── Document Center
    ├── Ratings & Reviews
    ├── Safety Center
    ├── Refer a Driver
    ├── Help & Support
    └── Settings
```

---

## 8. Screen-by-Screen Specifications

---

### 8.1 ONBOARDING & VERIFICATION FLOW

---

#### Screen 1.1 — Splash Screen

**Purpose:** App launch, brand impression, auth check
**Duration:** 2.5 seconds

**Layout:**

- Full-screen dark gradient: `#0D1B2A` → `#1C2B3A`
- Center: SmartPool logo + "Driver" label beneath (distinguishes from Rider App)
- Tagline: _"Your commute. Your earnings."_
- Thin emerald green progress line at bottom

**Logic:**

- Check auth token + driver approval status
- Approved driver → Home Dashboard
- Pending approval → Approval Pending Screen
- No token → Welcome Screen

---

#### Screen 1.2 — Welcome Screen

**Purpose:** Set expectations for driver onboarding

**Layout:**

- Dark background, emerald accent
- Headline: "Start Earning on Your Daily Commute"
- 3 value proposition rows (icon + text):
  - 💰 "Earn ₹3,000–8,000/month with your existing commute"
  - ✅ "Verified, trusted co-passengers only"
  - 🌿 "Reduce your carbon footprint every day"
- Estimated onboarding time chip: "Takes about 10 minutes"
- "Get Started as a Driver" primary CTA (full-width, emerald)
- "Already a driver? Log In" text link

---

#### Screen 1.3 — Phone Verification

**Purpose:** Account creation via phone number

**Layout:**

- "Enter Your Mobile Number" title
- Country code picker (default +91)
- 10-digit phone input
- "Send OTP" CTA
- OTP screen: 6-box input, 30-second resend timer, auto-read on Android
- Success: brief animation → Profile Setup

---

#### Screen 1.4 — Basic Profile Setup

**Purpose:** Collect driver's personal info

**Layout:**

- Progress bar: Step 1 of 7
- Mandatory profile photo upload (circular, 96px — mandatory for drivers, unlike riders)
- Full Name (text field)
- Date of Birth (date picker — must be 18+; validation blocks underage)
- Gender (Male / Female / Prefer not to say)
- Home Address (Google Places autocomplete)
- "Continue" CTA

**Validation:**

- Age check: Must be ≥ 18 years
- Profile photo mandatory — cannot skip

---

#### Screen 1.5 — Aadhaar Verification

**Purpose:** Government ID verification — mandatory for all drivers

**Layout:**

- Progress bar: Step 2 of 7
- Header: "Verify Your Identity"
- Explanation: "Required for all drivers. Your data is encrypted and never shared."
- Option A: DigiLocker OAuth (recommended — auto-fetches details)
- Option B: Manual Aadhaar number entry + OTP to registered mobile
- Privacy note: "Only last 4 digits stored after verification"
- "Verify with Aadhaar" CTA

**States:**

- Fetching: Loading with progress
- Success: Green checkmark + name confirmed
- Failed: Error message + retry option + contact support link

---

#### Screen 1.6 — Driving Licence Upload

**Purpose:** Verify driver has valid DL

**Layout:**

- Progress bar: Step 3 of 7
- Header: "Upload Driving Licence"
- Front side photo upload (camera or gallery)
- Back side photo upload (camera or gallery)
- Auto-OCR: DL number pre-filled from photo
- Manual entry fallback if OCR fails
- DL Number field (editable, pre-filled)
- Expiry Date field
- "Verify & Continue" CTA

**Backend:**

- mParivahan API called to validate DL number, check expiry, check endorsements
- DL must be valid (not expired, not suspended)
- Must have LMV (Light Motor Vehicle) endorsement

---

#### Screen 1.7 — Vehicle Registration Certificate (RC) Upload

**Purpose:** Verify vehicle ownership and registration

**Layout:**

- Progress bar: Step 4 of 7
- Header: "Add Your Vehicle — RC Book"
- Front page of RC upload
- Auto-OCR: Registration number, owner name, vehicle make/model, year pre-filled
- Manual edit all fields
- Fields:
  - Registration Number (e.g., MH 12 AB 1234)
  - Owner Name (must match Aadhaar name)
  - Make & Model (e.g., Honda City)
  - Year of Manufacture
  - Fuel Type (Petrol / Diesel / CNG / Electric)
  - Seating Capacity
- "Continue" CTA

**Validation:**

- Registration number validated via mParivahan API
- Owner name must match Aadhaar name (fuzzy match with 80% threshold)
- Vehicle must not be blacklisted

---

#### Screen 1.8 — Insurance Upload

**Purpose:** Ensure vehicle is insured

**Layout:**

- Progress bar: Step 5 of 7
- Header: "Vehicle Insurance"
- Policy document upload (photo or PDF)
- Fields (auto-filled via OCR):
  - Insurer Name
  - Policy Number
  - Valid From / Valid Until
- "Continue" CTA

**Validation:**

- Insurance must be valid (not expired)
- Warning if insurance expires within 30 days (allow onboarding, remind to renew)

---

#### Screen 1.9 — Pollution Under Control (PUC) Certificate Upload

**Purpose:** Ensure vehicle meets emission standards

**Layout:**

- Progress bar: Step 6 of 7
- Header: "Pollution Certificate (PUC)"
- Certificate photo upload
- Fields: PUC Certificate Number, Valid Until
- "Continue" CTA

**Validation:**

- PUC must be valid
- Expired PUC: driver cannot go online until renewed (soft block with reminder)

---

#### Screen 1.10 — Vehicle Details & Photo

**Purpose:** Complete vehicle profile for passengers

**Layout:**

- Progress bar: Step 7 of 7
- Header: "Vehicle Details"
- Pre-filled from RC: Make, Model, Year, Fuel Type
- Additional fields (manual):
  - Vehicle Color (color picker with 12 common car colors)
  - AC Available (Yes / No toggle)
  - Number of Passenger Seats (2 / 3 / 4 — excluding driver)
  - Vehicle photo upload (front 3/4 angle, mandatory)
  - Interior photo (optional but recommended)
- Vehicle amenity tags (multi-select chips):
  - Music System | Phone Charger | Sunroof | Water Bottle | Child Seat | Pet Friendly
- "Save Vehicle" CTA

---

#### Screen 1.11 — Bank Account / UPI Setup

**Purpose:** Set up payout destination

**Layout:**

- Header: "Set Up Payouts"
- Explanation: "Your earnings will be transferred here."
- Two tabs: UPI | Bank Account

**UPI Tab:**

- UPI ID entry field
- "Verify UPI" button (sends ₹1 test transfer, auto-reversed)

**Bank Account Tab:**

- Account Holder Name (auto-filled from Aadhaar)
- Account Number
- Re-enter Account Number
- IFSC Code (bank/branch auto-detected from IFSC)
- Account Type: Savings / Current
- "Add Bank Account" CTA

**Validation:**

- Penny drop verification (₹1 IMPS sent, auto-reversed — confirms account is active)

---

#### Screen 1.12 — Approval Pending Screen

**Purpose:** Inform driver that documents are under review

**Layout:**

- Illustration: Documents being reviewed (animated)
- Headline: "We're Reviewing Your Profile"
- Subtext: "This usually takes 2–24 hours. We'll notify you via SMS and app notification."
- Checklist with status icons:
  - Phone Verification ✅
  - Aadhaar Verification ✅
  - Driving Licence 🔄 (Under Review)
  - Vehicle RC 🔄 (Under Review)
  - Insurance 🔄 (Under Review)
  - PUC ✅
  - Bank Account ✅
- "What happens next?" expandable FAQ
- "Contact Support" link
- "Check Status" refresh button

**Rejection Handling:**

- If any document rejected: specific rejection reason shown
- Retry upload available inline
- "What was wrong?" link with examples of common errors

---

#### Screen 1.13 — Approval Approved / Welcome Screen

**Purpose:** Celebrate approval, onboard to main app

**Layout:**

- Full-screen success animation (car driving into a sunrise — Lottie animation)
- "You're Approved! 🎉" headline
- "Welcome to the SmartPool Driver community"
- Your Driver ID: #DRV-20240315-0042
- "Publish Your First Ride" primary CTA
- "Explore Dashboard" secondary CTA

---

### 8.2 HOME & AVAILABILITY DASHBOARD

---

#### Screen 2.1 — Driver Home Screen

**Purpose:** Central command center for the driver

**Layout:**

**Top Header:**

- SmartPool logo (small, left)
- Driver status chip: 🟢 Online / 🔴 Offline (tappable)
- Wallet balance: "₹ 1,250" (right, always visible)
- Notification bell (with badge)

**Big Go-Online Toggle (center, prominent):**

- Large circular toggle — dark when offline, glowing green when online
- Label: "You're Online — Available for Ride Requests"
- OR: "You're Offline — Tap to Go Online"
- When online: Animated pulse ring around toggle

**Today's Rides Card:**

- Next upcoming ride (if any): Time, Route summary, Passenger count booked, Fare
- "View All Today's Rides" link

**Earnings Today Card:**

- Amount earned today: ₹XXX
- Rides completed today: N
- Progress bar toward daily goal (if set)

**This Week's Impact Card:**

- CO₂ saved: X kg 🌿
- Fuel saved: Y litres
- Rides shared: Z

**Incoming Ride Request Banner (when online + request arrives):**

- Slide-up overlay with accept/decline (see Screen 3.2)

**Quick Actions Row:**

- ➕ Publish New Ride
- 📅 My Schedule
- 💰 Earnings
- 👥 Manage Passengers

**Driver Score Summary:**

- Rating: ★ 4.8 (compact, with "View Reviews" link)
- Completed rides badge

---

#### Screen 2.2 — Go Online Confirmation Sheet

**Purpose:** Confirm driver is ready and vehicle is ready

**Triggered:** When driver taps Go Online button

**Bottom Sheet Layout:**

- Title: "Going Online?"
- Pre-departure checklist:
  - [ ] Vehicle is clean and ready
  - [ ] Fuel/charge is sufficient
  - [ ] Documents are valid
  - [ ] Phone is charged
- Selected vehicle shown: Make, Model, Color, Seats
- "Change Vehicle" option (if multiple vehicles)
- Active route/schedule reminder: "You have a ride at 9:00 AM — Andheri to BKC"
- "Go Online" green CTA
- "Not now" cancel

---

#### Screen 2.3 — Go Offline Confirmation Sheet

**Purpose:** Confirm driver wants to go offline

**Triggered:** When driver taps online toggle while online

**Bottom Sheet Layout:**

- "Going Offline?" title
- Warning if active bookings exist: "You have 2 passengers booked for today's ride at 9:00 AM. Going offline will cancel their bookings."
- Reason for going offline (optional, for analytics):
  - Vehicle issue | Personal emergency | End of day | Other
- "Go Offline — Cancel Active Bookings" destructive CTA (red, only if active bookings exist)
- "Go Offline — No Active Bookings" green CTA (if no bookings)
- "Stay Online" cancel

---

### 8.3 RIDE MANAGEMENT FLOW

---

#### Screen 3.1 — Create / Publish New Ride

**Purpose:** Driver publishes a ride for passengers to book

**Layout:**

**Header:** "Publish a Ride"

**Route Section:**

- From Location (Google Places — auto-filled with saved home address)
- To Location (Google Places — auto-filled with saved work address)
- Route preview: Map showing the planned route (Google Maps embed)
- "Edit Route" link (opens map for manual route adjustment)
- Intermediate stops (optional): "Add Pickup/Drop Stops" — up to 3 intermediate stops

**Schedule Section:**

- Departure Date (date picker)
- Departure Time (time picker, 15-minute increments)
- Recurring toggle:
  - One-time
  - Daily (every day)
  - Weekdays (Mon–Fri)
  - Custom (day-of-week multi-select)
- End date for recurring (optional; default: 3 months from today)

**Passengers Section:**

- Total seats in vehicle (auto-filled from vehicle profile, editable)
- Seats to offer: Stepper (1 to max-1 seats, excluding driver)
- Auto-accept bookings toggle (ON = passengers auto-confirmed; OFF = driver reviews each)
- Gender preference: Any / Women only

**Ride Preferences:**

- Silent ride (no music/calls): Toggle
- AC available: Toggle (auto-filled from vehicle profile)
- Luggage allowed (small bags only / no large luggage / any): Dropdown
- Notes for passengers: Text area (150 chars) — e.g., "Meeting at Andheri station gate 2"

**Fare Section:**

- Estimated fare per seat: Auto-calculated (shown, non-editable in v1.0)
- Fare breakdown expandable: Distance × Fuel rate ÷ Seats
- "How is fare calculated?" info link

**Publish CTA:**

- "Publish Ride" — full-width emerald button
- Shows preview summary before publishing

**Post-Publish:**

- Success animation
- Ride card shown with shareable link
- "Share Ride" option (share to WhatsApp/contacts to fill seats faster)

---

#### Screen 3.2 — Incoming Ride Request Screen

**Purpose:** Alert driver of a new booking request (when auto-accept is OFF)

**Triggered:** Push notification + in-app overlay when passenger books

**Layout (full-screen overlay, high priority):**

- Slide-up from bottom (dismisses in 45 seconds if no action)
- Countdown timer: "45 seconds to respond"
- Passenger card:
  - Profile photo (48px), Name, Verified badge
  - Rating: ★ 4.7 (42 rides)
  - Joined: "Member since Jan 2024"
  - Requested seats: 1
  - Pickup: Location name + distance from driver's route
  - Drop: Location name
  - Estimated detour for this pickup: "+1.2 km | +3 min"
- Fare earned (for this passenger): ₹85
- "View Passenger Profile" link (opens full profile in bottom sheet)

**Action Buttons:**

- "Accept" — large, full-width, emerald green
- "Decline" — smaller, outlined red
- "Decline and give reason" (optional, logged for analytics)

**Decline reasons (bottom sheet if declined):**

- Route doesn't match | Already full | Personal reason | Other

**Auto-decline:** If no response in 45 seconds → auto-declined with notification to passenger

---

#### Screen 3.3 — Ride Detail Screen (Pre-Departure)

**Purpose:** Full ride overview before the ride begins

**Layout:**

**Header:**

- Route: "Andheri → BKC"
- Date/Time: "Today, 9:00 AM"
- Status chip: Upcoming / Active / Completed / Cancelled
- Edit icon (visible only if ride is >2 hours away and has no bookings)

**Route Map Card:**

- Google Maps embed: Full route with all stops marked
- Estimated total distance + duration
- Route type: Fastest / Shortest / Eco toggle

**Passenger List (most important section):**
See Screen 3.4 — Passenger List

**Ride Stats:**

- Seats offered: 4 | Booked: 3 | Available: 1
- Estimated earnings: ₹255 (3 × ₹85)

**Actions:**

- "Start Ride" CTA (active only when within 30 min of departure time)
- "Cancel Ride" link (shows cancellation policy popup)
- "Share Ride" link (share to fill remaining seats)

---

#### Screen 3.4 — Passenger List Screen

**Purpose:** Manage all passengers booked for a specific ride

**Layout:**

**Header:** "Passengers — Today 9:00 AM"

**Passenger Cards (list):**
Each card:

- Profile photo (48px), Name, Verified badge
- Rating: ★ 4.8
- Pickup location: "Andheri Station Gate 2"
- Drop location: "BKC Tower 1"
- Seats booked: 1 or 2
- Booking status: Confirmed / Pending (if manual accept) / Cancelled
- Payment status: Paid / Pending
- "Message" icon (opens chat)
- "Call" icon (masked proxy call)
- "Remove Passenger" option (long-press or swipe, with confirmation)

**No-Show Action (during ride time):**

- "Mark as No-Show" option per passenger
- No-show logged; triggers refund to passenger; penalty recorded for driver

**Waitlist (if ride is full):**

- Passengers who requested but couldn't book
- "Open a seat" option if a confirmed passenger cancels

---

#### Screen 3.5 — Edit Ride Screen

**Purpose:** Modify an existing published ride

**Accessible:** Only if ride is >2 hours away AND has 0 bookings

**Layout:**

- Same as Create Ride screen (pre-filled with existing data)
- All fields editable
- "Save Changes" CTA
- Warning if any changes affect fare (recalculated automatically)

**If ride has bookings:**

- Edit restricted to: Notes, AC toggle, Luggage preference
- Major changes (time, route) require cancellation and re-publish
- Inline warning: "You cannot change route/time as passengers are already booked."

---

#### Screen 3.6 — Cancel Ride Screen

**Purpose:** Driver cancels a published ride

**Layout (bottom sheet):**

- Warning: "Cancelling will notify all X booked passengers and trigger refunds."
- Cancellation reason (mandatory):
  - Vehicle breakdown
  - Personal emergency
  - Health issue
  - Incorrect route/time posted
  - Other (text input)
- Cancellation policy reminder:
  - > 2 hours before: No penalty
  - < 2 hours before: Warning strike (3 strikes = account review)
  - After ride started: Severe penalty
- "Confirm Cancellation" red CTA
- "Go Back" cancel link

**Post-Cancellation:**

- All booked passengers notified immediately via push + SMS
- Refunds processed automatically
- Driver strike counter updated

---

### 8.4 ACTIVE RIDE FLOW (DRIVER POV)

---

#### Screen 4.1 — Pre-Ride Checklist Screen

**Purpose:** Final check before departure; ensure driver is prepared

**Triggered:** When driver taps "Start Ride"

**Layout (bottom sheet):**

- Title: "Ready to Start Ride?"
- Passenger count confirmation: "3 passengers are booked"
- Verification reminder:
  - "Ask each passenger for their verification PIN before moving"
  - PIN for this ride: **8472** (unique per ride, shown prominently)
- Quick checklist:
  - [ ] All passengers are seated
  - [ ] Verify passenger PINs
  - [ ] Seatbelts fastened
- "Start Ride Now" emerald CTA
- "Wait, not ready yet" cancel

---

#### Screen 4.2 — Active Ride Navigation Screen

**Purpose:** Primary screen during the ride — navigation + passenger management

**Layout:**

**Full Map (Google Maps Navigation):**

- Turn-by-turn directions rendered on map
- All passenger pickup/drop pins shown with sequence numbers
- Driver's real-time location broadcasted to all passengers (every 3 sec)
- Route line with traffic overlay

**Floating Driver HUD (bottom card, compact):**

- Next action: "→ Pick up Rahul at Andheri Station in 1.2 km"
- ETA to next stop: "4 min"
- Total ride progress: "Stop 1 of 4"
- Speed indicator (optional, shows if over 80 km/h — warning)

**Passenger Status Chips (horizontal scroll):**

- Each chip: Passenger photo + name + status (Waiting / Picked up / Dropped)
- Tap chip → mark as picked up or dropped

**Action Bar (bottom, always visible):**

- 📞 Call passenger (proxy)
- 💬 Message passenger
- 🗺️ Recalculate route (if detour needed)
- 🚨 SOS (always red, always visible)

**Distraction Minimization:**

- All non-essential UI hidden during navigation
- Font sizes larger than normal
- Auto-brightness increase

**Passive tracking:**

- GPS broadcasted to Supabase Realtime every 3 seconds
- Route deviation detection: If driver goes >500m off planned route → warning logged

---

#### Screen 4.3 — Pickup Confirmation Screen

**Purpose:** Confirm each passenger has been picked up

**Triggered:** When driver taps a passenger's "Picked Up" action or reaches pickup geofence

**Layout:**

- Passenger photo (large, 80px) + Name
- PIN verification: "Ask passenger for their 4-digit PIN"
- PIN entry keypad (driver enters passenger's PIN)
- If PIN matches: ✅ "Rahul verified. Boarding confirmed."
- If PIN wrong: ⚠️ "PIN doesn't match. Check with passenger."
- Skip PIN option (emergency — logged for audit)
- "Confirm Picked Up" CTA

---

#### Screen 4.4 — Drop-off Confirmation Screen

**Purpose:** Confirm passenger has been dropped at destination

**Triggered:** When driver taps "Drop Off" for a passenger or reaches drop geofence

**Layout:**

- Passenger photo + Name
- Drop location: "BKC Tower 1 — Confirmed"
- "Confirm Drop Off" CTA
- Optional: Note about drop ("Dropped slightly before due to traffic")

**Post Drop-off:**

- Passenger's payment released from hold → transferred to driver wallet
- Passenger receives push notification to rate the ride

---

#### Screen 4.5 — End Ride Screen

**Purpose:** Complete the ride after all passengers are dropped

**Triggered:** Driver taps "End Ride" after last drop-off

**Layout:**

- "End This Ride?" confirmation sheet
- Summary:
  - Passengers carried: 3
  - Distance: 18.4 km
  - Duration: 42 min
- "Yes, End Ride" CTA

**Post End Ride:**

- Earnings calculated and credited to driver wallet
- Navigate to Ride Summary screen (Screen 4.6)

---

#### Screen 4.6 — Ride Summary Screen (Post-Ride)

**Purpose:** Post-ride recap and earnings summary

**Layout:**

**Header:** "Ride Completed 🎉"

**Route & Stats Card:**

- Route: Andheri → BKC
- Date/Time: Today, 9:00 AM – 9:42 AM
- Distance: 18.4 km
- Duration: 42 min
- CO₂ Saved: 3.2 kg per passenger × 3 = 9.6 kg total 🌿

**Earnings Card (prominent, green):**

- Total Earned: ₹255
- Breakdown: 3 × ₹85
- Platform fee deducted: -₹15
- Net credited: ₹240
- Cumulative today: ₹480

**Passenger Ratings:**

- Rate each passenger (1–5 stars)
- Tags: Punctual | Polite | On-time at pickup | No-show (if applicable)
- Optional text comment
- "Submit Ratings" CTA

**Post-Ride Actions:**

- "View Ride Receipt" link
- "Publish Return Ride" CTA (pre-fills reverse route)
- "Share Your Impact" (social share card — CO₂ saved)

---

### 8.5 EARNINGS & PAYOUTS

---

#### Screen 5.1 — Earnings Dashboard

**Purpose:** Central earnings hub — driver's most-visited financial screen

**Layout:**

**Earnings Header Card (full-width, emerald gradient):**

- Total Balance (withdrawable): ₹3,450
- "Withdraw" button
- Total Earned (lifetime): ₹18,200
- Total Rides: 214

**Period Selector:**

- Today | This Week | This Month | Custom Range

**Stats Row (selected period):**

- Rides Completed: N
- Total Earned: ₹X,XXX
- Average per Ride: ₹XX
- Hours on Road: X hrs

**Earnings Chart:**

- Bar chart: Daily earnings for selected period
- X-axis: Days / Weeks / Months
- Tap a bar → day detail popup

**Top Earning Routes Card:**

- List of routes with earnings per ride (top 3)

**Recent Transactions (list):**
Each item:

- Ride icon
- Route: "Andheri → BKC"
- Date/Time
- Passengers count
- Amount: +₹240
- Status: Credited / Pending / Processing

---

#### Screen 5.2 — Ride-wise Earnings Breakdown

**Purpose:** Detailed earnings per ride

**Layout:**

- Ride summary (route, date, time, duration)
- Passenger list with individual fare contributions
- Total fare collected
- Platform fee deducted
- Net earnings credited
- Payment status per passenger: Paid / Refunded

---

#### Screen 5.3 — Weekly / Monthly Earnings Report

**Purpose:** Financial summary for income tracking

**Layout:**

- Period selector (dropdown or date range picker)
- Summary metrics:
  - Total rides: N
  - Total gross earnings: ₹X,XXX
  - Platform fees paid: ₹XXX
  - Net earnings: ₹X,XXX
  - Cancellation penalties (if any): -₹XX
  - Bonuses / Incentives: +₹XXX
- Earnings bar chart (by day/week)
- "Download Report" (PDF generation)
- "Share with CA / Accountant" export option

---

#### Screen 5.4 — Payout / Withdrawal Screen

**Purpose:** Transfer earnings to bank account or UPI

**Layout:**

- Available balance: ₹3,450
- Minimum withdrawal: ₹100
- Amount input (numeric, with preset options: ₹500 | ₹1,000 | ₹2,000 | Full amount)
- Payout destination:
  - Saved UPI ID (default, shown with icon)
  - Saved Bank Account (last 4 digits shown)
  - "Add new payout method" link
- Processing time: "Usually within 1–2 business days"
- "Withdraw Now" CTA

**Payout History Tab:**

- List of past withdrawals
- Each: Amount, Date, Status (Success / Processing / Failed), Destination (masked)

---

### 8.6 VEHICLE MANAGEMENT

---

#### Screen 6.1 — My Vehicle Screen

**Purpose:** View and manage vehicle profile

**Layout:**

**Vehicle Card (top):**

- Vehicle photo (full-width, 200px height)
- Make + Model + Year
- Color chip
- Registration plate (partially masked: MH 12 \*\* 1234)
- Status: Active / Under Review / Suspended

**Vehicle Details:**

- Fuel type, Seating capacity, AC: Yes/No
- Amenity tags: Music System, Charger, etc.
- "Edit Vehicle Details" button

**Documents Section:**

- Driving Licence: ✅ Valid till DD/MM/YYYY
- RC (Registration): ✅ Valid
- Insurance: ⚠️ Expires in 22 days (yellow warning)
- PUC Certificate: ✅ Valid till DD/MM/YYYY
- "Update Document" links per item

**Add Second Vehicle:**

- "Add Another Vehicle" CTA (v1.0 supports up to 2 vehicles)

---

#### Screen 6.2 — Add / Edit Vehicle Screen

**Purpose:** Add a new vehicle or update existing vehicle details

**Layout:**

- Vehicle photo upload (mandatory)
- Interior photo upload (optional)
- Make (dropdown — from a curated list of 50+ Indian car brands + models)
- Model
- Year of Manufacture
- Color (color picker)
- Registration Number
- Fuel Type
- Seating Capacity
- AC Available toggle
- Amenity tags (multi-select)
- "Save Vehicle" CTA

---

#### Screen 6.3 — Document Update Screen

**Purpose:** Re-upload expired or rejected documents

**Layout:**

- Document type shown: "Insurance Certificate"
- Current status: "Expired on 14 Feb 2026"
- New document upload (camera / file picker)
- Auto-OCR for key fields
- Manual edit fields
- "Submit for Review" CTA
- Expected review time: "2–6 hours"

---

### 8.7 PROFILE & RATINGS

---

#### Screen 7.1 — Driver Public Profile Screen

**Purpose:** What passengers see when they tap on the driver

**Layout:**

**Header:**

- Cover gradient background (driver-theme dark navy)
- Profile photo (96px, circular, mandatory)
- Name + "Verified Driver" badge (green checkmark)
- "Driver since March 2023"

**Driver Stats Row:**

- Total Rides | Rating ★ | Years Active | CO₂ Saved

**Vehicle Showcase:**

- Vehicle photo + Make/Model/Color

**Trust Badges:**

- Aadhaar Verified ✅
- DL Verified ✅
- RC Verified ✅
- Insurance Valid ✅
- 100+ Rides completed 🏆

**Rating Breakdown:**

- Overall: ★ 4.8 (156 ratings)
- Punctuality bar
- Driving Safety bar
- Friendliness bar
- Vehicle Cleanliness bar

**Recent Reviews:**

- Top 3 passenger reviews
- "See All Reviews" link

---

#### Screen 7.2 — Edit Driver Profile

**Fields:**

- Profile photo (change)
- Full Name
- Bio (200 chars): e.g., "Daily commuter from Andheri to BKC. Calm driver, clean car. Let's save fuel together!"
- Languages spoken (multi-select chips)
- Music preference (Driver plays / Passengers choose / No music)
- Communication style (Chatty / Quiet / Flexible)

---

#### Screen 7.3 — My Reviews Screen

**Purpose:** View all passenger ratings and comments

**Layout:**

- Overall rating summary (large star + score + count)
- Category breakdowns with bars (Punctuality, Safety, Friendliness, Cleanliness)
- Filter: All / Most Recent / Highest / Lowest
- Review cards:
  - Passenger photo (blurred for privacy) + First name + Rating
  - Tags given by passenger
  - Written comment (if any)
  - Date of ride
  - "Report review" option (flag inappropriate content)

---

### 8.8 SCHEDULE & RECURRING RIDES

---

#### Screen 8.1 — Weekly Schedule Calendar Screen

**Purpose:** Bird's-eye view of all published rides

**Layout:**

**View Toggle:** Day | Week | Month (default: Week)

**Week View:**

- 7-day horizontal scroll calendar
- Each day: Ride pills showing time + route
- Color coding:
  - Green: Rides with full/partial bookings
  - Blue outline: Published but no bookings yet
  - Red: Cancelled rides
  - Grey: Past rides

**Day View (on tap a day):**

- Time-sorted list of rides that day
- Each ride: Time, Route, Passengers count, Status, Earnings (if completed)
- "Add Ride for this day" FAB

**FAB (Floating Action Button):**

- "+" → Opens Create Ride screen

---

#### Screen 8.2 — Holiday / Day Off Screen

**Purpose:** Manage days when driver is unavailable

**Layout:**

- Calendar for current + next month
- Tap a date to mark as "Day Off"
- Tap a marked date to unmark
- "Bulk Select" for selecting a range
- "Set Vacation Mode" toggle (marks multiple consecutive days)

**Effect of Day Off:**

- All recurring rides for that date are suspended
- Booked passengers for suspended rides are notified and refunded
- Warning shown if passengers already booked for that date

---

#### Screen 8.3 — Recurring Ride Settings Screen

**Purpose:** Manage a recurring ride template

**Layout:**

- Recurring ride info: Route, Time, Days
- Active for: Start date → End date
- Edit frequency (e.g., change from Weekdays to Mon/Wed/Fri)
- Pause recurring ride (all future dates suspended without deletion)
- Resume recurring ride
- Edit end date
- "Stop Recurring" (deletes all future unbooked instances; booked instances remain)

---

### 8.9 SAFETY FEATURES (DRIVER)

---

#### Screen 9.1 — Safety Center Screen

**Purpose:** All driver-facing safety tools in one place

**Layout:**

**Emergency Contacts Section:**

- Add up to 3 emergency contacts (name, relation, phone)
- Toggle: "Auto-share ride when I go online"

**Safety Tools:**

- 🆘 SOS — "Alert contacts + call 100 + notify SmartPool"
- 📍 Share Live Location — "Share real-time tracking with a trusted person"
- 🎙️ Auto-record trip audio — "Audio recorded locally, never uploaded unless SOS triggered"
- 🛑 Suspicious passenger alert — "Report a passenger before/during ride"
- 👤 Passenger PIN System — "Verify passenger identity before boarding"

**Driver-Specific Safety:**

- Distracted driving detection (experimental, opt-in): Uses phone accelerometer to detect erratic movement
- Fatigue reminder: "You've been driving for 2 hours. Take a break!" (configurable interval)
- Overspeed alert: Visual warning in navigation when exceeding 80 km/h in city limits

**Report a Concern:**

- "I feel unsafe with a passenger" — high-priority flow
- "Report a past incident"
- "Passenger didn't show correct PIN"

---

#### Screen 9.2 — SOS Activated Screen (Driver)

**Same protocol as Rider SOS, but with driver-specific additions:**

- All emergency contacts notified with live link
- 112 auto-dialed
- SmartPool Safety Team notified (with driver's ID + vehicle details)
- Passenger accounts flagged pending investigation
- Ride recording uploaded to secure server (if audio recording was active)
- Driver support callback initiated within 5 minutes

---

#### Screen 9.3 — Suspicious Passenger Report Screen

**Purpose:** Allow driver to flag a passenger before or during boarding

**Layout:**

- Select passenger (from current ride)
- Reason (multi-select):
  - PIN doesn't match | Behaving aggressively | Photo doesn't match | Other
- Description (text area)
- "Report and Remove Passenger" CTA
- "Report Without Removing" (for post-ride flagging)

**Effect:**

- Safety team reviews within 30 min
- Passenger flagged on system
- Automatic refund to removed passenger

---

### 8.10 NOTIFICATIONS & ACTIVITY

---

#### Screen 10.1 — Notifications Screen

**Layout:**

- Tabs: All | Ride Requests | Bookings | Earnings | Safety | System

**Notification types for Driver:**

- New booking request (with quick Accept/Decline actions inline)
- Passenger cancelled booking
- Ride starting in 30 min reminder
- Ride starting in 10 min reminder
- Passenger is waiting (if late)
- Earnings credited
- Payout processed
- Document expiry reminder (30 days, 7 days, 1 day)
- Rating received
- Incentive/bonus unlocked
- Safety alert
- Account status change
- New feature / app update

---

#### Screen 10.2 — In-App Chat Screen (Driver View)

**Purpose:** Communicate with individual passengers

**Layout:**

- Chat list view (all active conversations)
- Individual chat: Standard messaging UI
- Driver can see all passengers as separate chat threads
- Quick replies: "I'm on my way" | "Please wait 2 min" | "At the pickup point now"
- Call button (masked proxy number)
- Ride status banner pinned at top

---

#### Screen 10.3 — Ride History Screen

**Purpose:** View all past rides with full details

**Layout:**

- Tabs: Upcoming | Completed | Cancelled
- Filter: Date range, Route
- Ride summary card per ride:
  - Route, Date/Time, Passengers count, Earnings, Status
  - "View Details" → Full ride recap
  - "Republish" → Duplicates this ride as a new one
- Total summary at top: All-time rides, All-time earnings

---

### 8.11 SETTINGS

---

#### Screen 11.1 — Settings Screen

**Account:**

- Change phone number
- Change email
- Biometric login toggle
- Linked accounts (Google, Apple)
- Delete account (with data export option)

**Notifications:**

- New booking requests (toggle — critical, off = no requests received)
- Ride reminders (toggle)
- Earnings updates (toggle)
- Promotional messages (toggle)
- Notification sound selection

**Ride Preferences (Defaults):**

- Default vehicle (if multiple vehicles added)
- Default seat count to offer
- Auto-accept bookings toggle (default state)
- Default gender preference
- Default ride preferences (silent, AC, luggage)

**Navigation:**

- Default navigation app: Google Maps / Waze / In-app
- Avoid tolls toggle
- Avoid highways toggle
- Voice guidance: On / Off / Volume

**Privacy:**

- Location sharing: During rides only / Always while online
- Profile visibility: Public / Verified riders only
- Show vehicle plate to passengers: Masked / Full

**Payout:**

- Default payout method
- Auto-withdraw: Toggle (auto-withdraw when balance > ₹1,000 or custom threshold)
- Tax documents download (Form 16 equivalent for driver income)

**App:**

- Theme: System / Light / Dark
- Language
- Background location (mandatory — shows status and link to system settings)
- Battery optimization whitelist reminder
- App version + release notes

---

## 9. Core Driver Features Deep Dive

### 9.1 Driver Availability System

Drivers have three states:

- **Offline** — not visible in search, no new requests
- **Online** — visible, accepting bookings for published rides
- **In-Ride** — actively on a ride, no new booking requests accepted for other routes

Going online:

- Supabase presence channel updated
- Driver record in `driver_availability` table updated with timestamp + geolocation
- All published future rides marked as "accepting bookings"

Going offline:

- Immediate: stops new booking requests
- Grace period: 5 minutes before passengers are notified of cancellation (in case accidental tap)

### 9.2 Multi-Stop Ride Management

Drivers can add up to 3 intermediate pickup/drop stops to a single ride. The system:

- Calculates optimal stop sequence using Google Directions API (minimize total detour)
- Recalculates fare per passenger based on individual boarding/alighting points
- Updates ETA for each passenger when route is affected by traffic

### 9.3 Ride Duplication

Drivers can duplicate a past ride to republish it instantly:

- Pre-fills all route, vehicle, and preference fields
- Driver only needs to set new date/time
- One-tap republish for frequent same routes

### 9.4 Waitlist Management

If a ride is full, new interested passengers are added to a waitlist:

- Driver sees waitlist count on ride card
- If a passenger cancels → driver gets instant notification with option to auto-accept waitlisted passengers
- Driver can promote a waitlisted passenger manually

---

## 10. Driver Verification & Onboarding Logic

### Document Review Pipeline

```
Driver Submits Documents
        ↓
Automated OCR + API Validation
  ├── Aadhaar → DigiLocker API
  ├── DL → mParivahan API (validity + endorsements check)
  ├── RC → mParivahan API (ownership + validity)
  ├── Insurance → OCR + expiry check
  └── PUC → OCR + expiry check
        ↓
If all pass → Auto-Approval (within 5 minutes)
        ↓
If any flag → Manual Review Queue (admin dashboard)
  └── Reviewer approves / rejects with reason
        ↓
Driver Notified via Push + SMS
```

### Verification States per Document

| State          | Badge           | Driver Can             |
| -------------- | --------------- | ---------------------- |
| Not Submitted  | Grey dot        | Cannot publish rides   |
| Pending Review | Yellow clock    | Cannot publish rides   |
| Approved       | Green checkmark | Full access            |
| Rejected       | Red X + reason  | Re-submit only         |
| Expiring Soon  | Yellow warning  | Full access + reminder |
| Expired        | Red X           | Cannot go online       |

### Re-verification Triggers

- DL expiry: Prompt 30 days before, block online status 0 days after expiry
- Insurance expiry: Prompt 30 days before, block online status 0 days after expiry
- PUC expiry: Prompt 15 days before, block online status 0 days after expiry
- Annual re-verification: Request profile photo update once per year

---

## 11. Ride Matching & Acceptance Logic

### When a Rider Books a Driver's Published Ride

```
Rider books a seat
        ↓
System checks:
  1. Seat availability (seats_available > 0)
  2. Time validity (departure > now + 15 min)
  3. Rider verification (basic phone verification minimum)
  4. Payment pre-authorization (hold fare amount in rider wallet)
        ↓
Auto-Accept mode (driver's default):
  → Booking confirmed immediately
  → Both parties notified
        ↓
Manual Accept mode (driver opted-in):
  → Driver receives request (Screen 3.2)
  → 45-second window to accept/decline
  → No response → Auto-declined
  → If accepted → booking confirmed, both notified
  → If declined → rider notified, shown other rides
```

### Overbooking Prevention

- Seat count is decremented atomically using Supabase Row-Level Locking
- Race condition handled: If two riders book simultaneously and only 1 seat remains → first commit wins; second gets "Seat no longer available" with alternative suggestions

---

## 12. Earnings & Payout Model

### Fare Distribution

```
Rider pays: ₹85 per seat

Platform Fee (per booking): min(₹5, 5% of fare) = ₹4.25
Driver receives: ₹85 - ₹4.25 = ₹80.75 per passenger

Example — 3 passengers, ₹85 each:
Total collected: ₹255
Platform keeps: ₹12.75
Driver earns: ₹242.25
```

### Wallet Mechanics

- Fares held in escrow at booking confirmation
- Released to driver wallet within 10 minutes of ride completion
- In case of dispute: held in escrow until resolved (max 48 hours)
- Minimum payout: ₹100
- Payout processing: T+1 business day to UPI; T+2 to bank account

### Earnings Adjustments

- Passenger no-show: Driver earns full fare (passenger forfeits)
- Driver no-show: Driver earns ₹0; penalty ₹50 logged against balance
- Early driver cancellation (>2 hrs): No penalty
- Late driver cancellation (<2 hrs): ₹25 penalty + warning strike
- Passenger rate dispute: SmartPool support reviews; driver credited if valid

### Monthly Incentives (v1.0 — Starter Program)

| Milestone                             | Bonus      |
| ------------------------------------- | ---------- |
| 20 rides in a month                   | ₹200 bonus |
| 30 rides in a month                   | ₹400 bonus |
| 4.8+ rating + 20 rides                | ₹300 bonus |
| 0 cancellations in a month            | ₹150 bonus |
| Refer a driver who completes 10 rides | ₹500 bonus |

---

## 13. Driver Rating & Incentive System

### Rating Dimensions

Passengers rate drivers on:

- Overall experience (1–5 stars, mandatory)
- Punctuality (1–5 stars)
- Driving safety (1–5 stars)
- Friendliness (1–5 stars)
- Vehicle cleanliness (1–5 stars)

### Rating Algorithm

```
RatingScore = (Overall × 0.35) + (Punctuality × 0.20) +
              (Safety × 0.25) + (Friendliness × 0.10) +
              (Cleanliness × 0.10)
```

- Minimum 5 rides before a public rating is displayed
- Rolling average of last 100 ratings (older ratings decay)
- Outlier removal: single 1-star with no comment from a passenger with < 3 rides is flagged for review

### Rating Thresholds & Actions

| Rating    | Status    | Action                             |
| --------- | --------- | ---------------------------------- |
| ≥ 4.5     | Excellent | Eligible for premium badge         |
| 4.0 – 4.4 | Good      | Normal operation                   |
| 3.5 – 3.9 | Fair      | Warning + improvement tips         |
| 3.0 – 3.4 | Poor      | Account review; reduced visibility |
| < 3.0     | Critical  | Account suspended pending review   |

---

## 14. Go-Online / Go-Offline Logic

### State Machine

```
OFFLINE
  ↓ (tap Go Online)
ONLINE [publishing rides, accepting bookings]
  ↓ (ride starts)
IN_RIDE [navigation active, no new bookings for this slot]
  ↓ (all passengers dropped, tap End Ride)
ONLINE (back to available)
  ↓ (tap Go Offline)
OFFLINE
```

### Background Location

- When online: Location broadcasted to Supabase every 30 seconds (low battery)
- When in-ride: Location broadcasted every 3 seconds (high accuracy)
- When offline: No location tracking
- Foreground service notification (Android): "SmartPool — You are online. Tap to go offline."

---

## 15. Navigation & Route Management

### Navigation Modes

| Mode                | Description                                                       |
| ------------------- | ----------------------------------------------------------------- |
| In-App Navigation   | Google Maps SDK embedded; turn-by-turn voice guidance             |
| External Navigation | Redirect to Google Maps / Waze / Apple Maps with route pre-loaded |
| Route Overview      | Static map with route line (no live navigation)                   |

### Multi-Stop Sequencing

- Google Directions API called with all pickup/drop waypoints
- Optimal ordering computed by the API (minimize total distance)
- Driver sees numbered stops on map
- ETA recalculated on each stop completion

### Route Deviation Handling

- If driver deviates > 500m from planned route:
  - In-app alert: "You seem to be off route. Recalculate?"
  - Recalculate option shown
  - If deviation > 2 km for > 3 min: Passenger safety alert triggered

---

## 16. Safety & Emergency Protocols

### Driver Safety Stack

| Layer       | Feature                                                  |
| ----------- | -------------------------------------------------------- |
| Pre-ride    | Passenger PIN verification                               |
| Pre-ride    | Passenger profile + photo check                          |
| During ride | Live GPS tracking (shared with passengers)               |
| During ride | Route deviation alerts                                   |
| During ride | SOS button (one tap, always visible)                     |
| During ride | Audio recording (local, opt-in)                          |
| Post-ride   | Mutual ratings                                           |
| Post-ride   | Incident reporting                                       |
| System      | Automated anomaly detection (unusual route, speed, time) |

### Driver SOS Protocol

1. Driver taps SOS in app
2. 5-second countdown (accidental trigger prevention)
3. Emergency contacts notified via SMS with live tracking link
4. 112 auto-dialed
5. SmartPool Safety Team alerted with: driver ID, vehicle details, current GPS, all passenger details
6. All passengers notified: "Driver has triggered an emergency alert"
7. Audio recording (if active) uploaded to encrypted secure storage
8. Safety team attempts callback to driver within 3 minutes
9. Ride flagged; all passenger accounts frozen pending review

---

## 17. Non-Functional Requirements

| Requirement                         | Target                                                            |
| ----------------------------------- | ----------------------------------------------------------------- |
| App cold start time                 | < 2.5 seconds                                                     |
| Navigation render time              | < 1 second                                                        |
| GPS broadcast latency               | < 500ms                                                           |
| API response time (P95)             | < 300ms                                                           |
| Location update (in-ride)           | Every 3 seconds                                                   |
| Location update (online, idle)      | Every 30 seconds                                                  |
| App crash rate                      | < 0.5%                                                            |
| Background service uptime           | 99.5% (while online/in-ride)                                      |
| Battery drain (online, idle)        | < 3% per hour                                                     |
| Battery drain (in-ride, navigation) | < 8% per hour                                                     |
| Offline graceful degradation        | Ride details cached; GPS buffered                                 |
| Data encryption                     | AES-256 at rest, TLS 1.3 in transit                               |
| Document storage                    | End-to-end encrypted, restricted access                           |
| Compliance                          | India IT Act 2000 + PDPB + RTO regulations                        |
| Accessibility                       | WCAG 2.1 AA                                                       |
| Supported OS                        | Android 8.0+ / iOS 14.0+                                          |
| App install size                    | < 45 MB                                                           |
| Background location                 | Foreground service (Android) / Significant location changes (iOS) |

---

## 18. Out of Scope — v1.0

The following features are explicitly deferred to v2.0+:

- Admin dashboard (separate PRD — pending)
- In-app fuel tracking and expense management
- Vehicle service reminders (oil change, tyre check)
- EV charging stop integration on route
- Driver insurance products (in-app trip insurance)
- Multi-city operations beyond Phase 1 cities (Bengaluru, Mumbai, Pune, Delhi NCR)
- Carpooling for inter-city / highway routes
- Corporate driver accounts (B2B)
- Driver partner app for fleet operators
- Automated tax filing / ITR assistance
- Driver health benefits program
- Gamification leaderboards for drivers
- Advanced anti-fatigue detection (AI-based)
- Vehicle telematics integration (OBD-II)

---

## 19. Dependencies & Integrations

| Integration          | Purpose                          | Provider                     |
| -------------------- | -------------------------------- | ---------------------------- |
| Maps & Navigation    | Route display, turn-by-turn nav  | Google Maps SDK              |
| Directions & ETA     | Live traffic routing, multi-stop | Google Directions API        |
| Geocoding            | Address → coordinates            | Google Geocoding API         |
| Vehicle Verification | RC + DL validation               | mParivahan API               |
| Aadhaar Verification | Driver identity verification     | DigiLocker OAuth             |
| Payout to Bank       | Bank transfer + UPI payout       | Razorpay Payouts             |
| Push Notifications   | All real-time alerts             | Firebase FCM                 |
| SMS                  | OTP + critical alerts            | Twilio / MSG91               |
| Crash Reporting      | Error tracking                   | Sentry                       |
| Analytics            | Driver behavior funnels          | Mixpanel                     |
| A/B Testing          | Feature experiments              | Firebase Remote Config       |
| Document Storage     | DL, RC, Insurance files          | Supabase Storage (encrypted) |
| PDF Generation       | Earnings reports, receipts       | Flutter PDF library          |

---

## 20. Risks & Mitigations

| Risk                                      | Probability | Impact   | Mitigation Strategy                                                                  |
| ----------------------------------------- | ----------- | -------- | ------------------------------------------------------------------------------------ |
| Low driver supply at launch               | High        | Critical | Pre-registration campaign; referral bonuses; partner with RWAs and offices           |
| Document fraud (fake DL/RC)               | Medium      | High     | mParivahan API validation + manual review for edge cases                             |
| Safety incidents (passenger harm)         | Low         | Critical | Multi-layer verification, SOS, audio recording, 24/7 safety team                     |
| Driver no-shows impacting rider trust     | Medium      | High     | Penalty system, no-show tracking, auto-replacement suggestions                       |
| GPS spoofing / location fraud             | Low         | High     | Server-side route validation, anomaly detection, speed plausibility checks           |
| Background location killed by OS          | Medium      | Medium   | Foreground service (Android), APNS silent push (iOS), battery optimization whitelist |
| PUC / Insurance expiry disruptions        | Medium      | Medium   | Automated 30/15/7/1 day reminders; grace period with limited functionality           |
| Low earnings leading to driver churn      | Medium      | High     | Incentive program, transparent earnings model, guaranteed minimum program (v2)       |
| Risky passenger getting onboarded         | Medium      | High     | Rider verification, mutual rating history, blocked user list                         |
| Payment disputes between rider and driver | Low         | Medium   | Escrow system, SmartPool arbitration, evidence trail (GPS + timestamps)              |

---

## 21. Appendix A — Screen Inventory

**Total Screens: 40**
**P0 (Must-Have): 26 | P1 (Important): 11 | P2 (Nice-to-Have): 3**

| #    | Screen Name                  | Priority | Sprint   |
| ---- | ---------------------------- | -------- | -------- |
| 1.1  | Splash Screen                | P0       | Sprint 1 |
| 1.2  | Welcome Screen               | P0       | Sprint 1 |
| 1.3  | Phone / OTP Verification     | P0       | Sprint 1 |
| 1.4  | Basic Profile Setup          | P0       | Sprint 1 |
| 1.5  | Aadhaar Verification         | P0       | Sprint 1 |
| 1.6  | Driving Licence Upload       | P0       | Sprint 1 |
| 1.7  | RC Upload & Verification     | P0       | Sprint 1 |
| 1.8  | Insurance Upload             | P0       | Sprint 2 |
| 1.9  | PUC Certificate Upload       | P0       | Sprint 2 |
| 1.10 | Vehicle Details & Photo      | P0       | Sprint 2 |
| 1.11 | Bank Account / UPI Setup     | P0       | Sprint 2 |
| 1.12 | Approval Pending Screen      | P0       | Sprint 2 |
| 1.13 | Approval Approved Screen     | P0       | Sprint 2 |
| 2.1  | Driver Home Dashboard        | P0       | Sprint 3 |
| 2.2  | Go Online Confirmation       | P0       | Sprint 3 |
| 2.3  | Go Offline Confirmation      | P0       | Sprint 3 |
| 3.1  | Create / Publish New Ride    | P0       | Sprint 3 |
| 3.2  | Incoming Ride Request        | P0       | Sprint 3 |
| 3.3  | Ride Detail (Pre-Departure)  | P0       | Sprint 3 |
| 3.4  | Passenger List Screen        | P0       | Sprint 3 |
| 3.5  | Edit Ride Screen             | P1       | Sprint 4 |
| 3.6  | Cancel Ride Screen           | P0       | Sprint 4 |
| 4.1  | Pre-Ride Checklist           | P0       | Sprint 4 |
| 4.2  | Active Ride Navigation       | P0       | Sprint 4 |
| 4.3  | Pickup Confirmation          | P0       | Sprint 4 |
| 4.4  | Drop-off Confirmation        | P0       | Sprint 4 |
| 4.5  | End Ride Confirmation        | P0       | Sprint 4 |
| 4.6  | Ride Summary (Post-Ride)     | P0       | Sprint 4 |
| 5.1  | Earnings Dashboard           | P0       | Sprint 5 |
| 5.2  | Ride-wise Earnings Breakdown | P1       | Sprint 5 |
| 5.3  | Weekly / Monthly Report      | P1       | Sprint 5 |
| 5.4  | Payout / Withdrawal Screen   | P0       | Sprint 5 |
| 6.1  | My Vehicle Screen            | P0       | Sprint 5 |
| 6.2  | Add / Edit Vehicle           | P1       | Sprint 5 |
| 6.3  | Document Update Screen       | P1       | Sprint 5 |
| 7.1  | Driver Public Profile        | P1       | Sprint 6 |
| 7.2  | Edit Driver Profile          | P1       | Sprint 6 |
| 7.3  | My Reviews Screen            | P1       | Sprint 6 |
| 8.1  | Weekly Schedule Calendar     | P1       | Sprint 6 |
| 8.2  | Holiday / Day Off Screen     | P1       | Sprint 6 |
| 8.3  | Recurring Ride Settings      | P1       | Sprint 6 |
| 9.1  | Safety Center                | P0       | Sprint 6 |
| 9.2  | SOS Activated Screen         | P0       | Sprint 6 |
| 9.3  | Suspicious Passenger Report  | P1       | Sprint 6 |
| 10.1 | Notifications Screen         | P1       | Sprint 7 |
| 10.2 | In-App Chat Screen           | P1       | Sprint 7 |
| 10.3 | Ride History Screen          | P1       | Sprint 7 |
| 11.1 | Settings Screen              | P2       | Sprint 7 |

---

## 22. Appendix B — Driver Onboarding Checklist

Complete checklist a driver must pass before going live:

```
PERSONAL VERIFICATION
  [✅] Phone number verified (OTP)
  [✅] Profile photo uploaded (face clearly visible)
  [✅] Full name entered
  [✅] Date of birth (must be 18+)
  [✅] Home address set
  [✅] Aadhaar verified (via DigiLocker or manual)

DRIVING CREDENTIALS
  [✅] Driving Licence uploaded (front + back)
  [✅] DL number validated via mParivahan API
  [✅] DL is valid (not expired, not suspended)
  [✅] DL has LMV endorsement

VEHICLE DOCUMENTS
  [✅] RC (Registration Certificate) uploaded
  [✅] RC validated via mParivahan API
  [✅] Owner name matches Aadhaar name (fuzzy match)
  [✅] Vehicle Insurance uploaded
  [✅] Insurance is valid (not expired)
  [✅] PUC Certificate uploaded
  [✅] PUC is valid

VEHICLE PROFILE
  [✅] Vehicle make/model/year/color filled
  [✅] Vehicle photo uploaded (front 3/4 view)
  [✅] Seating capacity confirmed
  [✅] Fuel type confirmed

PAYOUT SETUP
  [✅] Bank account or UPI ID added
  [✅] Penny drop verification passed

FINAL
  [✅] Terms & Conditions accepted
  [✅] Community Guidelines accepted
  [✅] Background location permission granted
  [✅] Notification permission granted
  [✅] Battery optimization whitelist (Android)
```

---

## 23. Appendix C — Driver States & Transitions

```
┌─────────────────────────────────────────────────────────┐
│                   DRIVER STATE MACHINE                  │
└─────────────────────────────────────────────────────────┘

NEW_USER
   │ (submits all documents)
   ▼
PENDING_REVIEW
   │ (documents approved by system/admin)
   ▼
APPROVED_INACTIVE
   │ (driver taps Go Online)
   ▼
ONLINE ◄──────────────────────────────────────────────────┐
   │                                                      │
   │ (passenger books & ride time approaches)             │
   ▼                                                      │
RIDE_STARTING (30 min before departure)                   │
   │ (driver taps Start Ride)                             │
   ▼                                                      │
IN_RIDE_PICKING_UP ──► (all passengers picked up) ──►     │
IN_RIDE_EN_ROUTE ──► (all passengers dropped + End Ride) ─┘
   │
   └─► (driver taps Go Offline at any ONLINE state)
         ▼
       OFFLINE
         │ (document expired)
         ▼
       BLOCKED (until document renewed)
         │ (document renewed + approved)
         ▼
       ONLINE

Suspension States:
  ONLINE/OFFLINE → SUSPENDED (safety violation / rating < 3.0)
  SUSPENDED → REINSTATED (admin review + appeal)
  SUSPENDED → PERMANENTLY_BANNED (severe violation)
```

---

_Document Owner: Product Team_
_Related Documents: User App PRD v1.0 | Admin Dashboard PRD (Pending)_
_Next Review: April 2026_
_Admin Dashboard PRD: Pending_
