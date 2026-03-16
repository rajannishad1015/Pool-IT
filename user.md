# 🚗 SmartPool — Smart Carpooling & Ride-Sharing Platform
## Product Requirements Document (PRD) — User App v1.0

---

**Document Version:** 1.0  
**Last Updated:** March 2026  
**Platform:** Flutter (Android & iOS)  
**Backend:** Supabase (PostgreSQL + Realtime + Storage)  
**Scope:** User-Facing Application Only  
**Status:** Ready for Development

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Problem Statement](#2-problem-statement)
3. [Goals & Success Metrics](#3-goals--success-metrics)
4. [Target Users & Personas](#4-target-users--personas)
5. [Technical Architecture Overview](#5-technical-architecture-overview)
6. [Design Philosophy & UI Standards](#6-design-philosophy--ui-standards)
7. [Information Architecture](#7-information-architecture)
8. [Screen-by-Screen Specifications](#8-screen-by-screen-specifications)
   - 8.1 Onboarding & Auth Flow
   - 8.2 Home & Discovery
   - 8.3 Ride Booking Flow
   - 8.4 Active Ride Flow
   - 8.5 Profile & Settings
   - 8.6 Payments & Wallet
   - 8.7 Safety Features
   - 8.8 Notifications & Activity
9. [Core Features Deep Dive](#9-core-features-deep-dive)
10. [Matching Algorithm Logic](#10-matching-algorithm-logic)
11. [Fare Splitting Model](#11-fare-splitting-model)
12. [Safety & Trust Framework](#12-safety--trust-framework)
13. [Non-Functional Requirements](#13-non-functional-requirements)
14. [Out of Scope (v1.0)](#14-out-of-scope-v10)
15. [Dependencies & Integrations](#15-dependencies--integrations)
16. [Risks & Mitigations](#16-risks--mitigations)

---

## 1. Executive Summary

**SmartPool** is a Flutter-based mobile application that connects commuters traveling similar routes, enabling them to share rides, reduce travel costs, and minimize environmental impact. Unlike traditional ride-hailing apps (Uber/Ola), SmartPool focuses on peer-to-peer carpooling where verified community members share their personal vehicles.

The app delivers a **premium, Uber-grade UI/UX** while building a community-first product rooted in trust, transparency, and sustainability.

---

## 2. Problem Statement

| Problem | Impact |
|---|---|
| Each commuter uses individual vehicles for similar routes | 40–60% of urban vehicles carry only 1 person |
| High fuel costs per individual | ₹3,000–8,000/month on commute |
| Traffic congestion in metro cities | 40–60 min daily time loss |
| Carbon emissions from private vehicles | 70% of urban CO₂ from road transport |
| No trusted community platform for carpooling | Safety concerns prevent adoption |

---

## 3. Goals & Success Metrics

### Product Goals
- Enable intelligent route-based rider matching
- Reduce per-person travel cost by 40–60%
- Build a trusted, verified community of commuters
- Provide real-time tracking and communication

### Success Metrics (KPIs)

| Metric | Target (6 months) |
|---|---|
| Monthly Active Users | 50,000 |
| Successful Rides Completed | 200,000 |
| Average Rating Score | ≥ 4.5 / 5 |
| Cost Savings per User/Month | ₹1,500+ |
| App Store Rating | ≥ 4.4 |
| Ride Match Success Rate | ≥ 75% |

---

## 4. Target Users & Personas

### Persona 1 — Rohan, the Daily Office Commuter
- Age: 28, Software Engineer, Pune
- Commutes 22 km one-way, 5 days/week
- Spending ₹6,000/month on petrol
- Goal: Save money, meet like-minded professionals

### Persona 2 — Priya, the Safety-Conscious Rider
- Age: 25, Marketing Executive, Mumbai
- Prefers sharing rides only with verified, rated co-passengers
- Goal: Safe, affordable, and punctual commute

### Persona 3 — Amit, the Environmental Advocate
- Age: 31, Startup Founder, Bengaluru
- Wants to reduce his carbon footprint
- Goal: Community-driven sustainable travel

---

## 5. Technical Architecture Overview

```
Flutter App (Android + iOS)
        │
        ▼
  Supabase Backend
  ├── PostgreSQL (user data, rides, bookings)
  ├── Realtime Subscriptions (live tracking, chat)
  ├── Supabase Auth (phone/email/Google OAuth)
  ├── Supabase Storage (profile photos, documents)
  └── Edge Functions (matching algorithm, fare calc)
        │
        ▼
  Third-Party Integrations
  ├── Google Maps SDK (maps, routing, geocoding)
  ├── Razorpay / Stripe (payments)
  ├── Firebase Cloud Messaging (push notifications)
  ├── Twilio (SMS OTP backup)
  └── DigiLocker / Aadhaar (ID verification)
```

---

## 6. Design Philosophy & UI Standards

### Visual Design Language
- **Style:** Modern minimalism, Uber-inspired with warm community feel
- **Primary Color:** `#1A1A2E` (deep navy) + `#E94560` (vibrant coral accent)
- **Secondary:** `#0F3460` (trust blue), `#16213E` (dark surface)
- **Typography:** Inter (primary), SF Pro Display (iOS fallback)
- **Corner Radius:** 16px cards, 12px buttons, 24px bottom sheets
- **Elevation:** Soft shadows, no harsh lines

### Component System
- Bottom navigation bar (5 tabs)
- Floating action buttons for primary actions
- Swipeable cards for ride discovery
- Bottom sheets for confirmations
- Persistent map view on key screens
- Skeleton loaders (no spinners)
- Haptic feedback on key interactions

### Dark/Light Mode
Full support for both modes. Default follows system setting.

---

## 7. Information Architecture

```
SmartPool App
│
├── Onboarding (First Launch)
│   ├── Splash Screen
│   ├── Welcome / Value Prop Slides (3 slides)
│   ├── Sign Up / Log In
│   ├── Phone OTP Verification
│   ├── Profile Setup
│   └── ID Verification (optional, recommended)
│
├── Home Tab (🏠)
│   ├── Home Screen (Map + Quick Actions)
│   ├── Search Ride Screen
│   ├── Available Rides List
│   ├── Ride Detail Screen
│   └── Booking Confirmation
│
├── My Rides Tab (🚗)
│   ├── Upcoming Rides
│   ├── Active Ride (Tracking Screen)
│   ├── Past Rides History
│   └── Ride Receipt
│
├── Community Tab (👥)
│   ├── My Co-Passengers (past)
│   ├── Public Leaderboard (eco-savings)
│   └── Referral Program
│
├── Wallet Tab (💳)
│   ├── Wallet Balance
│   ├── Add Money
│   ├── Transaction History
│   └── Payment Methods
│
└── Profile Tab (👤)
    ├── My Profile
    ├── Edit Profile
    ├── Verification Status
    ├── Ratings & Reviews
    ├── Settings
    ├── Safety Center
    ├── Help & Support
    └── About / Legal
```

---

## 8. Screen-by-Screen Specifications

---

### 8.1 ONBOARDING & AUTH FLOW

---

#### Screen 1.1 — Splash Screen

**Purpose:** Brand impression, app initialization  
**Duration:** 2.5 seconds  

**Layout:**
- Full-screen gradient background (`#1A1A2E` → `#0F3460`)
- Center: SmartPool logo (animated — car icon morphing into a group of people)
- Tagline fade-in: *"Travel Together. Save More."*
- Bottom: Loading indicator (thin progress line)

**Logic:**
- Check auth token → if valid, skip onboarding → go to Home
- If new user → go to Welcome Slides

---

#### Screen 1.2 — Welcome Onboarding Slides

**Purpose:** Communicate value proposition  
**Slides:** 3 screens, swipeable

**Slide 1 — Save Money**
- Illustration: Two people in a car, coins floating
- Headline: "Cut Your Commute Cost in Half"
- Body: "Share rides with verified commuters going your way."

**Slide 2 — Beat Traffic**
- Illustration: Map with fewer cars on road
- Headline: "Fewer Cars, Faster Roads"
- Body: "Help reduce congestion by pooling on your daily route."

**Slide 3 — Travel Safely**
- Illustration: Shield + rating stars + profile photos
- Headline: "Verified. Rated. Trusted."
- Body: "Every rider is ID-verified with a community rating."

**Bottom Controls:**
- Dot indicators (3 dots)
- "Skip" link (top right)
- "Get Started" button on last slide (CTA, full-width, coral)

---

#### Screen 1.3 — Sign Up / Log In Screen

**Purpose:** Authentication entry point  

**Layout:**
- Logo at top center
- Tagline: "Your smart commute starts here"
- Phone number input field (with country code picker — default +91)
- "Continue with Phone" primary CTA button
- Divider: "or continue with"
- Google Sign-In button
- Apple Sign-In button (iOS only)
- Footer: "Already have an account? Log In" toggle
- Privacy policy & Terms link (small text, bottom)

**Validation:**
- 10-digit mobile validation (India)
- Inline error states with red underline + message

---

#### Screen 1.4 — OTP Verification Screen

**Purpose:** Phone number verification  

**Layout:**
- Back arrow (top left)
- Title: "Verify Your Number"
- Subtitle: "We sent a 6-digit OTP to +91 XXXXX XXXXX"
- 6-box OTP input (auto-focuses next box on entry)
- "Resend OTP" with 30-second countdown timer
- "Verify" CTA button (activates after all 6 digits entered)
- Auto-detect OTP from SMS (Android)

**States:**
- Loading state after submit
- Error state: "Incorrect OTP. 2 attempts remaining."
- Success: Brief tick animation → navigate forward

---

#### Screen 1.5 — Profile Setup Screen

**Purpose:** Collect basic user information  
**Required fields only; rest optional**

**Layout:**
- Progress indicator (step 1 of 2)
- Profile photo upload circle (camera icon, tap to upload)
- Full Name (text field)
- Date of Birth (date picker)
- Gender (segmented: Male / Female / Prefer not to say)
- Home Location (auto-complete using Google Places)
- Work/College Location (auto-complete, optional)
- "Continue" CTA button

**Notes:**
- Name pulled from Google if Google Sign-In used
- Profile photo optional at this step; prompted later

---

#### Screen 1.6 — ID Verification Screen (Optional at Onboarding)

**Purpose:** Build trust, unlock full features  

**Layout:**
- Header: "Get Verified ✓"
- Explanation card: "Verified riders get more matches and are trusted by the community."
- Options:
  - Aadhaar Card (via DigiLocker OAuth)
  - PAN Card (manual upload)
  - Driving Licence (manual upload)
- "Skip for Now" text link
- "Verify Now" CTA button

**Verification States:**
- Pending (clock icon, yellow badge)
- Verified (checkmark, green badge)
- Rejected (cross icon, retry option)

---

### 8.2 HOME & DISCOVERY

---

#### Screen 2.1 — Home Screen (Main Dashboard)

**Purpose:** Central hub — find or offer rides  
**This is the most critical screen**

**Layout:**

**Top Section (Header)**
- Left: Greeting "Good morning, Rohan 👋"
- Right: Notification bell (with badge count) + Avatar

**Map Area (60% of screen)**
- Full-width embedded Google Map
- User's current location pin (animated pulse)
- Nearby active rides shown as small car icons on map
- Map auto-centers on user's location
- "Use my location" floating button

**Ride Search Card (Floating bottom card)**
- "From" field (auto-filled with current location)
- "From ↕ To" swap icon button
- "To" field (type to search destination)
- Date & Time selector (default: Now, option for Schedule)
- Passenger count selector (1–4)
- "Find Rides" primary CTA button (full-width, coral)

**Quick Actions Row (horizontal scroll, icon chips)**
- 🏢 Office (saved workplace)
- 🏠 Home (saved home)
- ✈️ Airport
- 🏥 Hospital
- ➕ Add Place

**Saved Routes Section**
- Horizontal scrollable cards
- Each card: Route name, frequency, "Ride Now" button
- "Add Route" card at end

**Promo/Info Banner (dismissible)**
- "🌱 You've saved 12 kg CO₂ this month!"
- Or referral prompt: "Invite friends, earn ₹100"

**Bottom Navigation Bar**
- Home | Rides | Community | Wallet | Profile
- Active tab has coral underline + icon fill

---

#### Screen 2.2 — Search / Destination Input Screen

**Purpose:** Enter and confirm destination  

**Layout:**
- Full-screen takeover (modal-style slide up)
- Back arrow (top left)
- Search fields:
  - "From" (editable, pre-filled)
  - "To" (focused, cursor blinking)
- Recent Searches (list, 5 items max)
- Saved Places (Home, Work, tagged locations)
- Search Results (real-time as user types)
  - Each result: Place name, address, distance chip
- Map preview at bottom (small, 120px height)

**Interaction:**
- On selecting destination → slide back with destination filled
- Map updates to show both pins + route preview

---

#### Screen 2.3 — Available Rides List Screen

**Purpose:** Show matched rides for user's route  

**Layout:**

**Header:**
- Back arrow
- Route summary: "Andheri → BKC"
- Date/time chip: "Today, 9:00 AM"
- Filter icon (top right)

**Filter Sheet (bottom sheet, on filter tap):**
- Sort by: Departure time / Price / Rating
- Preferences: Female-only ride, AC vehicle, Direct route
- Max detour: Slider (0–5 km)
- Vehicle type: Any / Sedan / SUV / Hatchback
- "Apply Filters" CTA

**Ride Cards (scrollable list):**

Each ride card contains:
- Driver's photo (circular, 48px) + Name + Verified badge
- Star rating (4.8 ⭐) + Total rides count (234 rides)
- Vehicle: Make/Model + Color (e.g., "White Honda City")
- Departure time: "9:15 AM" + "Leaves in 23 min" chip
- Route: Pickup point → Drop point (with intermediate stops)
- Fare: "₹85 per seat" (bold) + Fare split breakdown icon
- Seats available: "2 of 4 seats left"
- Tags: 🌿 Eco-friendly | 🎵 Music on | 🔇 Silent ride | 💨 AC
- "View Details" button | "Book Now" button (coral, filled)

**Empty State:**
- Illustration of empty road
- "No rides found for this route"
- "Try adjusting your time or route"
- "Set Alert for this Route" CTA button

---

#### Screen 2.4 — Ride Detail Screen

**Purpose:** Full information before booking  

**Layout:**

**Top: Map Preview**
- Full route on map (pickup → destination with driver's path)
- Pickup pin + Drop pin labeled
- Estimated route line

**Driver Card:**
- Large profile photo (80px), Name, Verified badge
- Rating: ★ 4.8 (156 ratings)
- Member since: "March 2023"
- Total rides: 312
- Bio: Short text if added by driver
- "View Full Profile" link

**Vehicle Section:**
- Vehicle photo (if uploaded)
- Make, Model, Year, Color
- License plate (partially masked: MH 12 XX 1234)
- AC/Non-AC indicator
- Cleanliness rating

**Route & Stops:**
- Visual timeline (vertical): Pickup → intermediate stops → drop
- Each stop: Time, Location name, Distance from origin

**Passengers Section:**
- "Already Booked" section shows co-passengers (blurred if not confirmed)
- Passenger count + seat map (visual, 4-seat layout)
- Available seats highlight

**Fare Breakdown:**
- Base fare per seat: ₹70
- Fuel contribution: ₹12
- Platform fee: ₹3
- Total: ₹85 per seat
- "How is this calculated?" info link

**Action Area (sticky bottom):**
- Seat selector (1–N available)
- Total fare dynamically updates
- "Book This Ride" primary CTA button

---

#### Screen 2.5 — Booking Confirmation Screen

**Purpose:** Final confirmation step  

**Layout:**
- Summary card:
  - Route, Date/Time, Driver name, Vehicle
  - Number of seats, Total fare
- Pickup location (map snapshot + address)
- Payment method selector:
  - SmartPool Wallet (balance shown)
  - UPI (Google Pay / PhonePe)
  - Card
- Add a note for driver (optional text input)
- Promo code field (expandable)
- Terms acknowledgment checkbox
- "Confirm Booking" CTA (full-width coral button)

**Post-Confirmation:**
- Success animation (checkmark + confetti micro-animation)
- Booking ID displayed
- "Add to Calendar" prompt
- "Share Ride Details" option
- Auto-navigate to upcoming rides after 3 seconds

---

### 8.3 RIDE BOOKING FLOW (Offer a Ride)

---

#### Screen 3.1 — Offer a Ride (Entry)

**Note:** Accessible from Home screen "Offer Ride" CTA

**Layout:**
- Header: "Share Your Ride"
- From Location (auto-fill or type)
- To Location
- Departure Date picker
- Departure Time picker
- Number of seats to offer (1–4 stepper)
- Recurring ride toggle (Daily / Weekly / Custom days)
- Vehicle: Pre-filled from profile, or "Add Vehicle" prompt
- Detour preference: "Max 2 km detour to pick up passengers" (slider)
- Preferences toggles:
  - Women only
  - Silent ride
  - No food/drinks
  - Pets allowed
- "Publish Ride" CTA button

---

### 8.4 ACTIVE RIDE FLOW

---

#### Screen 4.1 — Pre-Ride: Waiting for Driver

**Purpose:** Screen shown after booking, before ride starts  

**Layout:**
- Map with driver's live location (moving pin)
- Driver card (compact): Photo, Name, Rating, Vehicle
- ETA chip: "Driver arrives in 8 min"
- Animated car moving along route on map
- Countdown timer (if scheduled)

**Actions:**
- "Call Driver" button (masked number via proxy call)
- "Message Driver" button (in-app chat)
- "Cancel Ride" (with cancellation policy popup)
- "Share Ride" (share ETA + tracking link with contact)
- SOS button (top right, red, always visible)

---

#### Screen 4.2 — Active Ride (In Progress)

**Purpose:** Live tracking during the ride  

**Layout:**
- Full-map view (Google Maps embed)
- Floating compact card (bottom):
  - Driver info (small)
  - ETA to destination: "Arrive in 24 min"
  - Current speed (optional)
  - "Stop Sharing" / "Share Live Location" toggle
- Co-passengers tab (horizontal scroll chips)
- SOS button (always visible, top right, red)
- "Report Issue" link

**Live Updates:**
- Map auto-rotates with vehicle direction
- ETA updates in real-time
- Push notification if driver deviates from route

---

#### Screen 4.3 — Ride Completed Screen

**Purpose:** Post-ride actions  

**Layout:**
- Success header: "You've arrived! 🎉"
- Route summary: From → To
- Stats:
  - Distance: 18.4 km
  - Duration: 42 min
  - CO₂ Saved: 3.2 kg (tree icon)
  - Money Saved: ₹240
- Amount deducted from wallet (animated)
- Fare receipt breakdown (expandable)

**Rating Section:**
- "Rate your ride" heading
- Star rating (1–5) for driver
- Star rating for co-passengers
- Tags: "Punctual", "Friendly", "Clean Car", "Safe Driver" (multi-select chips)
- Optional text feedback
- "Submit Rating" CTA

**Post-Ride CTAs:**
- "Download Receipt" (PDF)
- "Book Return Ride" (pre-fills reverse route)
- "Share Your Impact" (social share card with CO₂ saved)

---

#### Screen 4.4 — Ride Receipt Screen

**Purpose:** Detailed receipt for a completed ride  

**Layout:**
- SmartPool logo + "Ride Receipt" title
- Booking ID: #SP2024031501
- Date & Time
- Route: Pickup → Drop (with map snapshot)
- Driver: Name + Vehicle
- Duration + Distance
- Fare breakdown table:
  - Fuel contribution, Platform fee, Promo discount
  - Total paid
- Payment method used
- "Download PDF" button
- "Share" button

---

### 8.5 PROFILE & SETTINGS

---

#### Screen 5.1 — My Profile Screen

**Purpose:** User's public-facing and personal profile  

**Layout:**

**Header:**
- Cover gradient background
- Profile photo (96px, circle, editable)
- Name + Verified badge
- "Edit Profile" button

**Stats Row:**
- Rides Taken | Rides Shared | CO₂ Saved | ₹ Saved

**Trust Score Card:**
- Overall Rating: ★ 4.7
- Total ratings count
- Breakdown bar chart: Punctuality, Friendliness, Cleanliness, Safety

**Verification Badges Row:**
- Phone ✓ | Email ✓ | Aadhaar ✓ | Driving Licence (pending)

**Recent Reviews:**
- 3 most recent, "View All" link

**Vehicle Section:**
- If driver: vehicle card with photo, make, model
- "Add Vehicle" if none added

---

#### Screen 5.2 — Edit Profile Screen

**Fields:**
- Profile photo (change)
- Full name
- Bio (150 char max)
- Date of birth
- Gender
- Email
- Home location
- Work/College location
- Communication preferences (WhatsApp / In-app / SMS)
- Language preference

---

#### Screen 5.3 — Settings Screen

**Sections:**

**Account**
- Change phone number
- Change email
- Password / Biometric login
- Linked accounts (Google, Apple)
- Delete account

**Notifications**
- Ride reminders (toggle)
- Booking confirmations (toggle)
- Driver updates (toggle)
- Promotions & offers (toggle)
- App sounds (toggle)

**Ride Preferences**
- Default seats (1–4)
- Max detour tolerance (slider)
- Preferred co-passenger gender
- Silent ride by default (toggle)
- AC preference

**Privacy**
- Show full name to co-passengers (toggle)
- Show profile photo (toggle)
- Location sharing (During ride only / Always)
- Data & Privacy policy link

**App**
- Theme (System / Light / Dark)
- Language
- App version
- Licenses

---

### 8.6 PAYMENTS & WALLET

---

#### Screen 6.1 — Wallet Screen

**Purpose:** Manage in-app wallet and payments  

**Layout:**

**Balance Card (top, gradient card):**
- SmartPool Wallet balance: ₹1,250.00
- "Add Money" button | "Withdraw" button

**Quick Add Row:**
- ₹100 | ₹250 | ₹500 | ₹1000 chips

**Cashback & Rewards:**
- Active cashback offers
- Reward points balance

**Transaction History (list):**

Each item:
- Icon (debit/credit indicator)
- Description: "Ride to BKC — Feb 14"
- Amount: -₹85 (red) or +₹200 (green)
- Date & Time
- Status chip: Success / Pending / Failed

---

#### Screen 6.2 — Add Money Screen

**Layout:**
- Amount input (numeric, big font)
- Quick amount chips: ₹100, ₹250, ₹500, ₹1000
- Payment methods:
  - UPI (GPay, PhonePe, Paytm)
  - Debit/Credit Card
  - Net Banking
- Cashback offer banner (if active)
- "Proceed to Pay" CTA

---

#### Screen 6.3 — Payment Methods Screen

**Layout:**
- Saved UPI IDs list (edit/delete)
- Saved Cards list (masked number, type icon)
- "Add New UPI" option
- "Add New Card" option
- Default payment method toggle

---

### 8.7 SAFETY FEATURES

---

#### Screen 7.1 — Safety Center Screen

**Purpose:** Central hub for all safety features  

**Layout:**
- Header: "Your Safety, Our Priority"

**Emergency Contacts Section:**
- "Add Emergency Contact" (up to 3)
- Each contact: Name, Relation, Phone
- Toggle: "Auto-share ride with contacts"

**Safety Features List:**
- 🆘 SOS Button — "Tap to alert emergency contacts + call 100"
- 📍 Live Location Share — "Share real-time location with anyone"
- 🔒 Ride Verification PIN — "Confirm driver identity with 4-digit PIN"
- 📸 Driver Photo Check — "Match driver photo before boarding"
- 🎙️ Audio Recording — "Auto-record trip audio (stored locally)"
- 🛑 Unsafe Route Alert — "Notify if route deviates significantly"

**Report a Concern:**
- "I feel unsafe right now" (high-priority, red button)
- "Report a past incident"
- "Give feedback on safety"

**Tips Section:**
- Safety tips carousel (swipeable)

---

#### Screen 7.2 — SOS Activated Screen

**Purpose:** Emergency state  

**Layout:**
- Full-screen red overlay
- Large "SOS ACTIVATED" text
- Countdown: "Calling emergency contacts in 5..."
- Cancel button (to avoid accidental trigger)
- Auto-dials 112 (emergency) after countdown
- Sends SMS with live location to all emergency contacts
- Notifies SmartPool Safety Team

---

#### Screen 7.3 — Driver Verification Screen (Pre-Boarding)

**Purpose:** Confirm driver identity before getting in vehicle  

**Layout:**
- Header: "Verify Your Driver"
- Show expected driver photo (from profile)
- Show vehicle details: Color, Make, Model, plate
- PIN verification: "Ask driver for their PIN: 4821"
- Checklist:
  - [ ] Photo matches driver
  - [ ] Vehicle matches booking
  - [ ] PIN confirmed
- "All confirmed, Start Ride" green CTA
- "Something doesn't match" red link → escalation flow

---

### 8.8 NOTIFICATIONS & ACTIVITY

---

#### Screen 8.1 — Notifications Screen

**Categories (tabbed):**
- All | Rides | Promotions | Safety | Community

**Notification Card:**
- Icon (context-based)
- Title (bold)
- Body text
- Timestamp
- Action button if applicable ("View Ride", "Rate Now")

**Notification Types:**
- Ride confirmed/cancelled
- Driver en route
- Driver arrived
- Ride started/completed
- Rating reminder
- Payment success/failure
- New match for saved route
- Promo/offer alerts
- Safety alerts

---

#### Screen 8.2 — In-App Chat Screen

**Purpose:** Communication between matched rider & driver  

**Layout:**
- Standard chat UI (WhatsApp-style)
- Driver/Passenger name + photo in header
- Call button (masked)
- Message input + send
- Quick reply chips: "I'm on my way", "Running 5 min late", "Please wait"
- Ride status banner (pinned top): "Ride in 45 mins"

**Privacy:** Phone numbers are never revealed; all calls are routed through proxy numbers.

---

#### Screen 8.3 — Ride History Screen

**Layout:**
- Tab: Upcoming | Past | Cancelled
- Ride card (compact):
  - Route, Date, Driver name
  - Fare, Status badge
  - "View Details" | "Book Again" actions
- Filter: Last 7 days / Last month / Custom range
- Total savings summary at top

---

#### Screen 8.4 — Community / Eco Impact Screen

**Purpose:** Gamification + environmental awareness  

**Layout:**

**Your Impact Card:**
- CO₂ Saved: 48.2 kg (tree growing animation)
- Fuel Saved: 24 litres
- Rides Shared: 32
- Money Saved: ₹4,800

**Community Leaderboard:**
- Top eco-savers this month
- User's rank highlighted
- Badges earned: 🌿 Green Rider | 🏆 Top Pooler | ⭐ 5-Star Rider

**Referral Section:**
- Referral code card
- Share to earn ₹100 per successful invite
- "Invite Friends" CTA

---

## 9. Core Features Deep Dive

### 9.1 Smart Route Matching

The matching engine compares:
- Pickup coordinates (within 500m radius)
- Drop coordinates (within 1 km radius)
- Departure time (within ±30 min window, configurable)
- Route overlap percentage (minimum 60%)
- Detour calculation for driver (maximum configurable by driver)

Matching score formula:
```
MatchScore = (RouteOverlap × 0.4) + (TimeCompatibility × 0.3) + (LocationProximity × 0.2) + (RatingScore × 0.1)
```

### 9.2 Recurring Rides

Users can set up recurring rides (e.g., Mon–Fri, 9:00 AM, Andheri to BKC). The system:
- Auto-matches for upcoming dates
- Sends daily reminders at 7 PM for next-day ride
- Allows bulk cancel for specific days (holiday mode)

### 9.3 Real-Time Tracking

- Supabase Realtime channels per ride
- Driver app broadcasts GPS every 3 seconds
- Rider app subscribes and renders on Google Maps
- ETA computed using Google Directions API (live traffic)
- Geofencing trigger when driver is 500m away → notification

### 9.4 Offline Graceful Handling

- Last known route cached on-device
- Booking summary available offline
- Queue actions (chat messages) to retry on reconnect

---

## 10. Matching Algorithm Logic

```
Input:
  - Rider: Pickup(lat, lng), Drop(lat, lng), Departure(timestamp), Seats(n)

Process:
  1. Spatial Index Query: Find all driver rides with pickup within 2 km of rider's pickup
  2. Time Filter: rides departing ±30 min from rider's preferred time
  3. Route Overlap: Compute polyline intersection (Google Roads API)
  4. Detour Check: Calculate driver's additional time/distance per pickup
  5. Capacity Check: Available seats ≥ requested seats
  6. Preference Match: Gender filter, silent ride, AC
  7. Score & Rank: Apply MatchScore formula
  8. Return top 10 ranked results

Output: Sorted list of matching driver rides with score metadata
```

---

## 11. Fare Splitting Model

### Calculation Basis
- Fuel cost per km (current city average)
- Total route distance (Google Maps)
- Number of seats occupied

### Formula
```
TotalFuelCost = Distance(km) × FuelRate(₹/km)
FarePerSeat = (TotalFuelCost / TotalSeatsOccupied) + PlatformFee
PlatformFee = min(₹5, 5% of FuelCost)
```

### Example (Mumbai, 18 km, 3 passengers):
- Fuel rate: ₹8/km
- Total fuel: ₹144
- Per person: ₹48 + ₹3 platform fee = ₹51
- Driver collects: ₹153 (covers their full fuel cost + platform absorbs service fee)

### Payment Flow:
1. Rider's wallet debited at ride confirmation (pre-authorization hold)
2. Actual debit on ride completion
3. Driver receives amount in their driver wallet within 24 hours
4. Cancellation refunds: 100% if >2 hrs before; 50% if <2 hrs

---

## 12. Safety & Trust Framework

### Verification Levels

| Level | Badge | Unlocked By |
|---|---|---|
| Basic | Grey | Phone verified |
| Verified | Blue ✓ | Phone + ID document |
| Premium | Gold ✓✓ | Aadhaar + 10 rides + 4.5+ rating |

### Rating System
- All users rate after each ride (1–5 stars)
- Ratings are mutual (both rider rates driver and vice versa)
- Minimum 3 rides to establish rating
- Low rated users (< 3.5) suspended and reviewed
- Report categories: Unsafe driving, Inappropriate behavior, No-show, Route deviation

### Emergency Protocol
1. User taps SOS → in-app alert logged
2. Emergency contacts receive SMS with live map link
3. 112 auto-dial initiated
4. SmartPool safety team alerted via internal dashboard
5. Ride flagged for review; driver account frozen pending investigation

---

## 13. Non-Functional Requirements

| Requirement | Target |
|---|---|
| App launch time (cold) | < 2.5 seconds |
| API response time (P95) | < 300ms |
| Map render time | < 1 second |
| Location update frequency | Every 3 seconds |
| App crash rate | < 0.5% |
| Offline availability | Core read functions |
| Data encryption | AES-256 at rest, TLS 1.3 in transit |
| GDPR / IT Act compliance | Full |
| Accessibility | WCAG 2.1 AA |
| Supported OS | Android 8.0+ / iOS 14+ |
| App size | < 40 MB |

---

## 14. Out of Scope (v1.0)

The following features are planned for v2.0 and beyond:
- Driver app (separate PRD)
- Admin dashboard (separate PRD)
- Corporate/enterprise carpooling accounts
- Scheduled/automated ride offers
- In-app navigation (turn-by-turn for drivers)
- Multi-city support (Phase 1: Bengaluru, Mumbai, Pune, Delhi NCR only)
- EV-specific features (charging stops on route)
- International payments
- Group trips / long-distance intercity rides

---

## 15. Dependencies & Integrations

| Integration | Purpose | Provider |
|---|---|---|
| Maps & Routing | Map display, route calc, geocoding | Google Maps SDK |
| Payments | In-app wallet, UPI, card | Razorpay |
| Push Notifications | Ride alerts, chat | Firebase FCM |
| SMS OTP | Phone verification fallback | Twilio / MSG91 |
| ID Verification | Aadhaar, DL verification | DigiLocker API |
| Analytics | User behavior, funnel tracking | Mixpanel |
| Crash Reporting | Error monitoring | Sentry |
| A/B Testing | Feature experiments | Firebase Remote Config |

---

## 16. Risks & Mitigations

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Low initial driver supply | High | High | Launch driver app simultaneously; incentive program |
| Safety incidents | Medium | Very High | Robust verification, SOS, 24/7 safety team |
| Fake/fraudulent accounts | Medium | High | Aadhaar verification, ML fraud detection |
| GPS inaccuracy in urban areas | Medium | Medium | Location smoothing algorithm, manual correction UI |
| Payment failures | Low | Medium | Retry logic, fallback payment methods |
| Driver no-show | Medium | High | Penalty system, auto-rematching within 5 min |
| Privacy concerns | Medium | High | Data minimization, user controls, privacy audit |
| App performance on low-end devices | Medium | Medium | Flutter performance profiling, lazy loading |

---

## Appendix A — Screen Inventory Summary

| # | Screen Name | Priority | Sprint |
|---|---|---|---|
| 1.1 | Splash Screen | P0 | Sprint 1 |
| 1.2 | Onboarding Slides | P0 | Sprint 1 |
| 1.3 | Sign Up / Log In | P0 | Sprint 1 |
| 1.4 | OTP Verification | P0 | Sprint 1 |
| 1.5 | Profile Setup | P0 | Sprint 1 |
| 1.6 | ID Verification | P1 | Sprint 2 |
| 2.1 | Home Screen | P0 | Sprint 2 |
| 2.2 | Search Destination | P0 | Sprint 2 |
| 2.3 | Available Rides List | P0 | Sprint 2 |
| 2.4 | Ride Detail | P0 | Sprint 2 |
| 2.5 | Booking Confirmation | P0 | Sprint 2 |
| 3.1 | Offer a Ride | P0 | Sprint 3 |
| 4.1 | Waiting for Driver | P0 | Sprint 3 |
| 4.2 | Active Ride Tracking | P0 | Sprint 3 |
| 4.3 | Ride Completed + Rating | P0 | Sprint 3 |
| 4.4 | Ride Receipt | P1 | Sprint 3 |
| 5.1 | My Profile | P0 | Sprint 4 |
| 5.2 | Edit Profile | P1 | Sprint 4 |
| 5.3 | Settings | P1 | Sprint 4 |
| 6.1 | Wallet | P0 | Sprint 4 |
| 6.2 | Add Money | P0 | Sprint 4 |
| 6.3 | Payment Methods | P1 | Sprint 4 |
| 7.1 | Safety Center | P0 | Sprint 5 |
| 7.2 | SOS Activated | P0 | Sprint 5 |
| 7.3 | Driver Verification | P0 | Sprint 5 |
| 8.1 | Notifications | P1 | Sprint 5 |
| 8.2 | In-App Chat | P1 | Sprint 5 |
| 8.3 | Ride History | P1 | Sprint 5 |
| 8.4 | Community / Eco Impact | P2 | Sprint 6 |

**Total Screens: 29**  
**P0 (Must-have): 19 screens**  
**P1 (Important): 8 screens**  
**P2 (Nice-to-have): 2 screens**

---

*Document Owner: Product Team*  
*Next Review: April 2026*  
*Driver App PRD: Pending*  
*Admin Dashboard PRD: Pending*