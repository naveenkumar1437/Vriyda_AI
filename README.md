# Vriyda School Management System

> **How your school runs on Vriyda — every role, every module, end to end.**  
> *13 Roles · 18 Modules · Web Portal & Mobile Apps · AI-Powered by Medha*

---

## 📌 Overview

**Vriyda** is a comprehensive, enterprise-grade school management platform designed for educational trusts, multi-branch institutions, and standalone schools. It unifies administrative operations, academics, finance, student lifecycles, and day-to-day campus management into one integrated ecosystem.

- **Unified Access:** Every stakeholder (management, office staff, teachers, students, parents, and campus staff) logs in once and accesses only the screens, workflows, and data pertinent to their role.
- **Cross-Platform:** Available as a web portal for administration and management, and native/cross-platform mobile apps (Android & iOS) for teachers, parents, students, and ground staff.
- **Medha AI:** Built-in AI assistant across all pages providing contextual answers, intelligent insights, automated clash-free timetable generation, and curriculum lesson planning.

---

## 🏛️ Institutional Hierarchy & Scopes

Vriyda maps directly to the operational hierarchy of educational organizations:

```
Organisation (Trust / Group)
 └── Branch (City / Campus)
      └── Academic Year & Terms (e.g. 2026–27 / Term 1)
           └── Classes / Programs (e.g. Class 6)
                └── Sections / Student Groups (e.g. 6-A)
                     └── Courses / Subjects (e.g. Mathematics)
                          └── Students & Linked Guardians
```

### Data Visibility & Scope

| Scope | Roles Included | Visibility |
| :--- | :--- | :--- |
| **All Branches** | Chairman, Central Admin | Complete bird's-eye view across all group branches, consolidated financials, global policies, and cross-branch insights. |
| **Single Branch** | Principal, Branch Admin, Front Office, Account Manager | Full operational data within the specific campus. |
| **Classroom / Contextual** | Teacher, Hostel Warden, Transport Manager, Librarian, Bus Attendant | Respective classes, hostels, routes, or catalogs. |
| **Personal / Family** | Student, Parent | Student's own records, or parent viewing all their enrolled children under one login. |

---

## 👥 The 13 User Roles

1. **Chairman:** Executive visibility across all branches, macro-level KPIs (enrolments, fee collections, staff performance), and high-value approvals.
2. **Central Admin:** Manages group-level standards, branch configurations, academic calendars, and common policies.
3. **Principal:** Academic leadership, curriculum delivery, lesson plan sign-offs, examination management, discipline, and branch-level approvals.
4. **Branch Admin:** Daily branch execution, student master data, class/section allocations, staff records, ID cards, and annual promotions.
5. **Teacher:** Digital attendance, lesson plan creation, homework dispatch, exam marks entry, and parent-teacher communication.
6. **Student:** Timetable, homework submissions, study resources, exam results, dues, library records, and live bus details.
7. **Parent:** Multi-child dashboard, online fee payments, leave applications, direct teacher chat, and bus tracking.
8. **Front Office:** Enquiries & CRM, visitor management (integrated with FaceGuard facial recognition), postal registers, and counter fee receipts.
9. **Account Manager:** Fee structures, payment gateways (Razorpay), banking reconciliation, payroll, inventory, and ledger accounting.
10. **Librarian:** Book cataloging, member management, barcode/RFID issue-returns, reservations, and fine management.
11. **Hostel Warden:** Dormitory room and bed allocations, night attendance/roll call, gate pass approvals, and mess/hostel fee tracking.
12. **Transport Manager:** Route planning, vehicle compliance calendars, fuel/driver tracking, and bus change requests.
13. **Bus Attendant:** Mobile-first boarding and drop-off verification per stop with real-time sync.

---

## 📦 The 18 Core Modules

1. **Admissions & Front Office:** Inquiry tracking pipeline, campus visits, entrance tests, call logs, postal registers, and FaceGuard visitor tracking.
2. **Student Information System (SIS):** Central student repository, documents, family details, behavioral logs, batch transitions, and bulk promotions.
3. **Academics & Timetable:** Academic calendars, periods, subject allocation, and AI-powered automated clash-free timetable generation.
4. **Attendance & Leave:** Daily & period-wise attendance, parent leave requests, automated SMS/WhatsApp alerts for absentees.
5. **Examinations & Results:** Exam scheduling, hall plan allocation, marks entry, configurable grading scales, progress report generation, and merit lists.
6. **Lesson Plans & Study Material:** AI-assisted lesson plan creation, syllabus pacing tracking, study material uploads, and Learnify integration.
7. **Fees & Online Payments:** Custom fee categories and schedules, online payment integration via Razorpay, counter receipts, and automatic bank reconciliation.
8. **HR & Payroll:** Staff registry, leave policies, biometric/app attendance locking, automatic salary structure calculation, and self-service payslips.
9. **Inventory & School Store:** Multi-warehouse management, material requisition, PO approvals, goods receipt notes (GRN), and student store sales (uniforms/books).
10. **Accounts:** Double-entry ledger accounting, chart of accounts, bank accounts, income/expense tracking, and automated Profit & Loss statements.
11. **Library Management:** Cataloging, circulation desk (issue/return), overdue fines, reservations, and reading lists.
12. **Hostel & Dormitory:** Building/room/bed allocation, daily night roll call, gate pass workflows, and monthly boarding fees.
13. **Transport Management:** Routes, vehicle maintenance & document compliance, bus driver allocations, real-time GPS tracking, and parent tracking.
14. **Communication & Complaints:** Broadcast notices, targeted SMS/WhatsApp/email alerts, class chats, parent-teacher messaging, and confidential grievance ticketing.
15. **ID Cards & Certificates:** Automated badge generation from templates, Transfer Certificates (TC) and Bonafide Certificates with automated pending dues validation.
16. **Approvals Engine:** Centralized multi-tier inbox for leaves, timetable publications, unbudgeted purchases, marketing spends, and fee concessions.
17. **Marketing & Admission Campaigns:** Seasonal marketing budget allocation, campaign tracking links, lead attribution, and ROI reporting.
18. **Dashboards, Insights & Medha AI:** Role-tailored KPIs, trend explanations in plain natural language, and instant query answering over institution data.

---

## 🔌 Connected Ecosystem

- **Payment Processing:** Razorpay (UPI, Credit/Debit cards, Net Banking)
- **Omnichannel Communication:** WhatsApp Business API, SMS Gateways, and transactional Email
- **FaceGuard:** Computer vision & facial recognition for campus visitor and security management
- **Learnify:** Digital learning content and homework integration
- **IoT & Telematics:** GPS bus trackers for real-time fleet telematics

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (`^3.9.0` or higher)
- Android Studio / Xcode (for mobile development)
- Chrome / Web browser (for web portal development)

### Quick Start

```bash
# Clone the repository
git clone <repo-url>
cd Vriyda

# Fetch dependencies
flutter pub get

# Run on your preferred target
flutter run -d chrome    # For Web Portal
flutter run -d android   # For Android
flutter run -d ios       # For iOS
```

---

## 📄 License & Confidentiality

**Classification:** Confidential  
Prepared by **Vriyda / Innovorex**. All rights reserved.
