# NDU Project - Comprehensive Understanding

**Date:** January 26, 2026  
**Project Type:** Enterprise Project Management Application  
**Framework:** Flutter 3.6.0+ (Dart SDK)  
**Platforms:** Web, iOS, Android

---

## 🎯 Project Overview

The NDU Project is a comprehensive, enterprise-grade project management application that guides users through the complete project lifecycle - from initiation through planning, execution, and closure. It's designed as a structured workflow tool with extensive AI-powered features, real-time data persistence, and multi-tier subscription support.

---

## 🏗️ Architecture & Technology Stack

### Frontend Architecture
- **Framework:** Flutter 3.6.0+ with Dart SDK
- **State Management:** 
  - Provider pattern (ChangeNotifier)
  - InheritedNotifier for global state access
  - ProjectDataProvider for centralized project data
  - AppContentProvider for content management
- **Routing:** go_router ^17.0.0 (500+ routes)
- **UI:** Material Design with custom theming (light/dark mode)
- **Fonts:** Google Fonts 6.1.0

### Backend Architecture
- **Authentication:** Firebase Auth (Email/Password + Google Sign-In)
- **Database:** Cloud Firestore (NoSQL)
- **Storage:** Firebase Storage
- **Functions:** Firebase Cloud Functions (Node.js)
- **Secrets:** Firebase Secret Manager (API keys, payment credentials)

### External Integrations
- **AI Services:** OpenAI API (via secure Cloud Function proxy)
- **Payment Providers:** Stripe, PayPal, Paystack
- **File Handling:** file_picker 8.1.2+

---

## 📂 Project Structure

```
lib/
├── main.dart                    # Main app entry point
├── main_admin.dart             # Admin dashboard entry point
├── app_strings.dart            # String constants
├── theme.dart                  # Light/dark themes
├── firebase_options.dart       # Firebase configuration
│
├── models/                     # Data models (5 files)
│   ├── project_data_model.dart      # Comprehensive project data (2200+ lines)
│   ├── user_model.dart
│   ├── program_model.dart
│   ├── coupon_model.dart
│   └── app_content_model.dart
│
├── providers/                  # State management (2 files)
│   ├── project_data_provider.dart   # Project data state + Firebase sync
│   └── app_content_provider.dart    # Content management state
│
├── screens/                    # UI screens (99+ files)
│   ├── admin/                 # Admin dashboard (6 screens)
│   ├── landing_screen.dart
│   ├── sign_in_screen.dart
│   ├── pricing_screen.dart
│   ├── project_dashboard_screen.dart
│   ├── program_dashboard_screen.dart
│   ├── portfolio_dashboard_screen.dart
│   ├── initiation_phase_screen.dart
│   ├── project_framework_screen.dart
│   ├── front_end_planning_*.dart  # 15+ FEP screens
│   ├── team_management_screen.dart
│   ├── ssher_*.dart           # 5 SSHER safety screens
│   └── [many more...]
│
├── services/                   # Business logic (25+ files)
│   ├── openai_service_secure.dart    # AI integration
│   ├── openai/openai_config.dart    # OpenAI configuration
│   ├── firebase_auth_service.dart
│   ├── project_service.dart
│   ├── program_service.dart
│   ├── subscription_service.dart
│   ├── coupon_service.dart
│   ├── user_service.dart
│   ├── access_policy.dart
│   └── [many more...]
│
├── widgets/                    # Reusable widgets (38 files)
│   ├── draggable_sidebar.dart
│   ├── kaz_ai_chat_bubble.dart
│   ├── content_text.dart
│   └── [many more...]
│
├── utils/                      # Utility functions
│   ├── auto_bullet_text_controller.dart
│   ├── project_data_helper.dart
│   ├── navigation_route_resolver.dart
│   └── [web-specific utilities]
│
└── routing/
    └── app_router.dart         # GoRouter configuration (500+ routes)
```

---

## 🔑 Core Features & Workflows

### 1. Project Lifecycle Management

#### **Initiation Phase**
- Project name and solution identification
- Business case development
- Potential solutions analysis (AI-powered)
- Preferred solution selection with risk analysis
- Stakeholder identification
- Management level selection
- Project charter creation

#### **Planning Phase**
- Project framework selection (Waterfall/Agile/Hybrid)
- Project goals definition (3 goals with milestones)
- Milestone planning with deadlines
- Work Breakdown Structure (WBS) with criteria
- Front-End Planning (FEP) with 15+ subsections
- Cost estimation and analysis
- Risk assessment and identification

#### **Front-End Planning (FEP) Suite** - Most Comprehensive Module
1. **Requirements Screen** - Project requirements with types
2. **Risks Screen** - Risk identification and assessment
3. **Opportunities Screen** - Opportunity capture
4. **Procurement Screen** - Procurement planning
5. **Contracts Screen** - Contract management
6. **Vendor Quotes Screen** - Vendor quote comparison
7. **Infrastructure Screen** - Infrastructure considerations
8. **Technology Screen** - Technology requirements
9. **Personnel Screen** - Team planning
10. **Security Screen** - Security requirements and access control
11. **Allowance Screen** - Budget allowances
12. **Summary Screens** - FEP summary and final review

**FEP Features:**
- Auto-save to Firebase on navigation
- AI-powered content generation
- Data persistence across all screens
- Notes fields with auto-bullet formatting
- Scenario matrix for impact/gap analysis
- Technical debt tracking
- Risk register items

#### **Execution Phase**
- Progress tracking
- Schedule management board
- Issue management log
- Change management
- Cost tracking
- Quality management
- Team meetings
- Risk tracking
- Contract details dashboard
- Execution plan with interface management

#### **Closure Phase**
- Project close-out
- Contract close-out
- Vendor account close-out
- Lessons learned
- Team demobilization
- Deliverables roadmap

### 2. SSHER (Safety, Health, Environment, Risk)

Dedicated safety management suite with:
- Safety item tracking (4 screens)
- Risk assessment
- Compliance management
- Full safety view dashboard
- Safety entries with categories, departments, risk levels

### 3. Team Management

- Team roles and responsibilities
- Staff team identification
- Training and building
- Team meetings
- Operations team identification
- Transition to production team
- Team member management with email, roles, responsibilities

### 4. AI Integration (OpenAI)

**Services:**
- `OpenAiAutocompleteService` - Lightweight autocomplete suggestions
- `OpenAiDiagramService` - Strategic reasoning diagrams
- `OpenAiServiceSecure` - Full AI service with secure proxy

**Features:**
- Solution generation from business case
- Requirements generation
- Risk identification
- Cost analysis
- Infrastructure recommendations
- IT considerations
- Core stakeholder identification
- Diagram generation for strategic planning

**Security:**
- API keys stored in Firebase Secret Manager
- Cloud Function proxy prevents client-side exposure
- Environment variable support (OPENAI_PROXY_API_KEY, OPENAI_PROXY_ENDPOINT)
- Optional authentication requirement
- Rate limiting support
- CORS handling for web

### 5. Payment & Subscription System

**Payment Providers:**
- Stripe (primary)
- PayPal
- Paystack

**Subscription Tiers:**
- **Project:** $79/month or $790/year
- **Program:** $189/month or $1,890/year
- **Portfolio:** $449/month or $4,490/year

**Features:**
- Multi-provider payment support
- Coupon system with usage tracking
- Invoice history tracking
- Subscription management (active, cancelled, expired, trial)
- Trial periods support
- Subscription pausing
- Payment verification
- Cloud Functions for secure payment processing

**Cloud Functions:**
- `createStripeCheckout` - Creates Stripe checkout session
- `verifyStripePayment` - Verifies payment completion
- `createPayPalOrder` - Creates PayPal order
- `verifyPayPalPayment` - Captures PayPal payment
- `createPaystackTransaction` - Initializes Paystack transaction
- `verifyPaystackPayment` - Verifies Paystack payment
- `applyCoupon` - Validates and calculates discounted price
- `useCoupon` - Increments coupon usage count
- `getUserInvoices` - Fetches payment history
- `recordInvoice` - Records invoice
- `cancelSubscription` - Cancels active subscription

### 6. Admin Dashboard

**Features:**
- User management
- Project management
- Coupon management
- Subscription lookup
- Content management (editable app content)
- Access control (host-based restrictions)
- Admin authentication wrapper

**Access Control:**
- Host-based restrictions (admin.nduproject.com)
- Email whitelist for admin access
- Separate admin router (`main_admin.dart`)

### 7. Data Persistence System

**Architecture:**
- Centralized `ProjectDataModel` capturing all project data
- `ProjectDataProvider` manages state and Firebase sync
- Auto-save on navigation between screens
- Checkpoint system for resuming projects
- Real-time data flow across all screens

**Data Model Sections:**
- Initiation Phase Data
- Project Framework Data
- Planning Phase Data
- Work Breakdown Structure Data
- Front End Planning Data
- SSHER Data
- Team Management Data
- Launch Checklist Data
- Cost Analysis Data
- Cost Estimate Data
- IT Considerations Data
- Infrastructure Considerations Data
- Core Stakeholders Data
- Design Deliverables Data
- Execution Phase Data
- AI Usage Counts
- AI Integrations
- AI Recommendations

**Firebase Schema:**
- Collection: `projects`
- Fields: All ProjectDataModel fields (flattened JSON)
- Metadata: `ownerId`, `ownerName`, `ownerEmail`, `checkpointRoute`, `checkpointAt`, `createdAt`, `updatedAt`

---

## 🔐 Security & Authentication

### Authentication Flow
1. User signs in via email/password or Google Sign-In
2. Firebase Auth handles authentication
3. User record created/updated in Firestore
4. Access policy checks (admin host restrictions)
5. Route to appropriate dashboard (admin vs. client)

### Access Control
- **Admin Host:** `admin.nduproject.com` (restricted access)
- **Email Whitelist:** Only specific emails allowed on admin host
- **User Roles:** Admin flag in Firestore `users` collection
- **Auth Wrappers:** `AuthWrapper` and `AdminAuthWrapper` for route protection

### API Security
- OpenAI API keys in Firebase Secret Manager
- Cloud Function proxy (no client-side exposure)
- Firebase Auth token verification
- CORS configuration for web
- Rate limiting support

---

## 📊 State Management Flow

### Project Data Flow
1. User fills form on Screen A
2. Screen A updates `ProjectDataProvider` with form data
3. Screen A saves to Firebase with current checkpoint
4. Screen A navigates to Screen B
5. Screen B reads data from provider and pre-populates fields
6. Repeat for subsequent screens

### Provider Pattern
```dart
// Access the provider
final provider = ProjectDataInherited.of(context);

// Read current data
final projectData = provider.projectData;

// Update data
provider.updatePlanningData(
  potentialSolution: 'New solution',
  projectObjective: 'New objective',
);

// Save to Firebase (automatic on navigation)
await provider.saveToFirebase(checkpoint: 'planning_phase');
```

---

## 🛣️ Navigation & Routing

### Router Configuration
- **Main Router:** `AppRouter.main` (for client app)
- **Admin Router:** `AppRouter.admin` (for admin dashboard)
- **Route Constants:** `AppRoutes` class with named routes
- **Error Handling:** Custom 404 page with navigation

### Key Routes
- `/` - Landing page
- `/sign-in` - Authentication
- `/pricing` - Subscription selection
- `/dashboard` - Project dashboard
- `/admin-home` - Admin dashboard
- `/front-end-planning` - FEP workspace
- `/execution-plan` - Execution phase
- [500+ more routes]

---

## 🔧 Key Services

### ProjectService
- CRUD operations for projects
- Project name uniqueness checking
- Project listing with filters
- Project status management

### SubscriptionService
- Subscription management
- Payment initiation (Stripe, PayPal, Paystack)
- Payment verification
- Active subscription streaming
- Coupon application

### UserService
- User record management
- Admin status checking
- User profile updates

### OpenAI Services
- `OpenAiAutocompleteService` - Text autocomplete
- `OpenAiDiagramService` - Diagram generation
- `OpenAiServiceSecure` - Full AI service

### Other Services
- `ProgramService` - Program management
- `CouponService` - Coupon management
- `ContractService` - Contract management
- `ExecutionPhaseService` - Execution phase data
- `AppContentService` - Content management
- `AccessPolicy` - Access control logic

---

## 📱 Platform-Specific Features

### Web
- WebView support for embedded content
- CORS handling
- Web-specific utilities
- Download helpers

### Mobile (iOS/Android)
- Platform-specific Google Sign-In adapters
- File picker integration
- Secure storage

---

## 🚀 Deployment

### Firebase Setup
1. Firebase project initialization
2. Firestore database configuration
3. Firebase Auth setup
4. Firebase Storage setup
5. Cloud Functions deployment
6. Firebase Hosting (for web)

### Secrets Configuration
```bash
firebase functions:secrets:set OPENAI_API_KEY
firebase functions:secrets:set STRIPE_SECRET_KEY
firebase functions:secrets:set PAYPAL_CLIENT_ID
firebase functions:secrets:set PAYPAL_CLIENT_SECRET
firebase functions:secrets:set PAYSTACK_SECRET_KEY
```

### Cloud Functions Deployment
```bash
firebase deploy --only functions
```

---

## 📈 Project Statistics

- **Total Screens:** 99+ screens
- **Routes:** 500+ routes
- **Services:** 25+ services
- **Widgets:** 38+ reusable widgets
- **Models:** 5 data models
- **Providers:** 2 state management providers
- **Cloud Functions:** 10+ functions

---

## 🎨 UI/UX Features

- Material Design with custom theming
- Light/Dark mode support
- Responsive design
- Loading states (shimmer effects)
- Error handling with friendly messages
- Auto-save indicators
- Navigation breadcrumbs
- Sidebar navigation
- Drag-and-drop interfaces
- Markdown rendering
- PDF generation
- Export capabilities

---

## 🔄 Data Flow Summary

1. **User Input** → Screen Widget
2. **Screen Widget** → Updates ProjectDataProvider
3. **ProjectDataProvider** → Notifies listeners
4. **Navigation** → Triggers auto-save
5. **Auto-save** → Firebase Firestore
6. **Firebase** → Persists data
7. **Next Screen** → Loads from Provider (cached) or Firebase

---

## 🎯 Key Design Patterns

1. **Provider Pattern** - State management
2. **InheritedWidget Pattern** - Global state access
3. **Repository Pattern** - Service layer abstraction
4. **Factory Pattern** - Model creation from JSON
5. **Singleton Pattern** - Service instances
6. **Observer Pattern** - State change notifications

---

## 📝 Important Notes

1. **Data Persistence:** All project data is automatically saved to Firebase when navigating between screens
2. **Checkpoint System:** Users can resume projects from any checkpoint
3. **AI Integration:** OpenAI services use secure Cloud Function proxy
4. **Payment Security:** All payment processing happens server-side via Cloud Functions
5. **Access Control:** Admin access is restricted by host and email whitelist
6. **Multi-Platform:** Supports Web, iOS, and Android
7. **Real-time Updates:** Firestore streams for real-time data updates
8. **Error Handling:** Comprehensive error handling with user-friendly messages

---

## 🔍 Areas for Future Enhancement

1. **Data Persistence:** Some screens still need integration with ProjectDataProvider
2. **Testing:** Unit and integration tests
3. **Performance:** Optimization for large projects
4. **Offline Support:** Local caching and offline mode
5. **Collaboration:** Multi-user project editing
6. **Reporting:** Advanced reporting and analytics
7. **Export:** Enhanced export formats (Excel, PDF, etc.)

---

This document provides a comprehensive understanding of the NDU Project application, its architecture, features, and implementation details.
