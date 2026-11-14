/// Live API payload for Chairman Dashboard (Sai Ravindra School)
/// Sourced directly from GET /api/owner-dashboard
const Map<String, dynamic> kDefaultLiveDashboardData = {
  "generatedAt": "2026-11-14T14:49:36.957Z",
  "orgName": "Sai Ravindra School",
  "groupName": "Sai Ravindra School",
  "regionList": [
    "Sai Ravindra School"
  ],
  "regions": [
    {
      "name": "Sai Ravindra School",
      "branches": 6,
      "students": 122,
      "revenue": 14155020,
      "collectionPct": 68.2,
      "examIndex": 73,
      "health": 73
    }
  ],
  "group": {
    "students": 122,
    "studentsDelta": 11.9,
    "capacity": 155,
    "capacityUtil": 27.7,
    "capacityBranches": 1,
    "revenueYTD": 14155020,
    "revenueTarget": 15287422,
    "revenueDelta": 0,
    "collectedYTD": 9658180,
    "collectedMTD": 772654,
    "outstanding": 4496840,
    "outstandingPct": 31.8,
    "collectionPct": 68.2,
    "attendance": 92.1,
    "attendanceDelta": 0.4,
    "examIndex": 73,
    "examDelta": 1.1,
    "cashToday": 24145,
    "staffFilled": 46,
    "staffVacant": 23,
    "branchesActive": 6,
    "branchesTotal": 6,
    "alertsCritical": 4,
    "admissionsConv": 12.5,
    "revPerStudent": 116025,
    "costPerStudent": 74371,
    "payrollPct": 45.1,
    "onlinePayPct": 70.4,
    "passPct": 85.8,
    "avgGrade": 7.3,
    "syllabusPct": 86.5,
    "teacherRatio": 6,
    "teachers": 19,
    "attritionPct": 4.9,
    "newAdmissionsMTD": 25,
    "staffAttrition": 6.7,
    "transportRoutes": 27,
    "fleetUtil": 81.9,
    "transportFlags": 2,
    "hostelCapacity": 880,
    "hostelOccupied": 708,
    "hostelBranches": 6,
    "inventorySpendMTD": 47821,
    "pendingRefunds": 0,
    "refundCount": 0,
    "ebitdaMargin": 35.9,
    "hostelOcc": 80.5
  },
  "branches": [
    {
      "id": 1,
      "code": "GACH",
      "name": "Gachibowli Campus",
      "city": "Gachibowli Campus",
      "region": "Sai Ravindra School",
      "students": 21,
      "capacity": 0,
      "capacityKnown": false,
      "fill": null,
      "avgFee": 130000,
      "revenue": 2730000,
      "outstanding": 1320000,
      "collectionPct": 51.6,
      "attendancePct": 95.2,
      "examIndex": 84.5,
      "passPct": 95.2,
      "avgGrade": 8.5,
      "syllabusPct": 93,
      "teachers": 2,
      "staffTeach": 2,
      "staffNon": 2,
      "staffTotal": 4,
      "teacherRatio": 11,
      "admins": 1,
      "parents": 21,
      "teachingStaff": 2,
      "nonTeachingStaff": 1,
      "totalUsers": 46,
      "costPerStudent": 75400,
      "revPerStudent": 130000,
      "ebitdaMargin": 42.0,
      "payrollPct": 41,
      "onlinePayPct": 84,
      "inventorySpendMTD": 9100,
      "attritionPct": 3.2,
      "staffAttrition": 4.5,
      "vacancies": 1,
      "vacOver30": 1,
      "roles": [
        {"role": "Teacher", "filled": 2, "open": 1, "openOver30": 1},
        {"role": "Administrative Officer", "filled": 1, "open": 0, "openOver30": 0},
        {"role": "Principal", "filled": 1, "open": 0, "openOver30": 0}
      ],
      "newAdmissionsMTD": 4,
      "enrollments": 21,
      "applicants": 4,
      "transportRoutes": 6,
      "fleetUtil": 92,
      "transportFlag": false,
      "hostelCapacity": 240,
      "hostelOccupied": 211,
      "health": 75,
      "status": "stable",
      "trend": [69, 69.9, 70.8, 71.7, 72.6, 73.5, 74.4, 75.3],
      "alerts": 0,
      "color": "var(--accent)",
      "attendanceCounts": {
        "students": {
          "roster": 21,
          "present": 0,
          "absent": 0,
          "leave": 0,
          "halfDay": 0,
          "notMarked": 21
        },
        "staff": {
          "roster": 4,
          "present": 0,
          "absent": 0,
          "leave": 0,
          "halfDay": 0,
          "notMarked": 4
        }
      }
    },
    {
      "id": 2,
      "code": "KOND",
      "name": "Kondapur Branch",
      "city": "Kondapur Branch",
      "region": "Sai Ravindra School",
      "students": 14,
      "capacity": 0,
      "capacityKnown": false,
      "fill": null,
      "avgFee": 152857,
      "revenue": 2140000,
      "outstanding": 550000,
      "collectionPct": 74.3,
      "attendancePct": 90.5,
      "examIndex": 70.6,
      "passPct": 92.9,
      "avgGrade": 7.1,
      "syllabusPct": 81,
      "teachers": 2,
      "staffTeach": 2,
      "staffNon": 2,
      "staffTotal": 4,
      "teacherRatio": 7,
      "admins": 1,
      "parents": 14,
      "teachingStaff": 2,
      "nonTeachingStaff": 1,
      "totalUsers": 32,
      "costPerStudent": 103943,
      "revPerStudent": 152857,
      "ebitdaMargin": 32.0,
      "payrollPct": 49,
      "onlinePayPct": 61,
      "inventorySpendMTD": 5350,
      "attritionPct": 6.2,
      "staffAttrition": 9,
      "vacancies": 3,
      "vacOver30": 3,
      "roles": [
        {"role": "Teacher", "filled": 2, "open": 3, "openOver30": 3},
        {"role": "Administrative Officer", "filled": 1, "open": 0, "openOver30": 0},
        {"role": "Principal", "filled": 1, "open": 0, "openOver30": 0}
      ],
      "newAdmissionsMTD": 4,
      "enrollments": 14,
      "applicants": 4,
      "transportRoutes": 4,
      "fleetUtil": 74,
      "transportFlag": true,
      "hostelCapacity": 100,
      "hostelOccupied": 73,
      "health": 78,
      "status": "stable",
      "trend": [72, 72.9, 73.8, 74.7, 75.6, 76.5, 77.4, 78.3],
      "alerts": 0,
      "color": "var(--ok)",
      "attendanceCounts": {
        "students": {
          "roster": 14,
          "present": 0,
          "absent": 0,
          "leave": 0,
          "halfDay": 0,
          "notMarked": 14
        },
        "staff": {
          "roster": 4,
          "present": 0,
          "absent": 0,
          "leave": 0,
          "halfDay": 0,
          "notMarked": 4
        }
      }
    },
    {
      "id": 3,
      "code": "KUKA",
      "name": "Kukatpally Campus",
      "city": "Kukatpally Campus",
      "region": "Sai Ravindra School",
      "students": 17,
      "capacity": 0,
      "capacityKnown": false,
      "fill": null,
      "avgFee": 137647,
      "revenue": 2340000,
      "outstanding": 635000,
      "collectionPct": 72.9,
      "attendancePct": 89.8,
      "examIndex": 68.2,
      "passPct": 82.4,
      "avgGrade": 6.8,
      "syllabusPct": 84,
      "teachers": 2,
      "staffTeach": 2,
      "staffNon": 2,
      "staffTotal": 4,
      "teacherRatio": 9,
      "admins": 1,
      "parents": 17,
      "teachingStaff": 2,
      "nonTeachingStaff": 1,
      "totalUsers": 38,
      "costPerStudent": 90847,
      "revPerStudent": 137647,
      "ebitdaMargin": 34.0,
      "payrollPct": 47,
      "onlinePayPct": 66,
      "inventorySpendMTD": 7800,
      "attritionPct": 5.6,
      "staffAttrition": 8,
      "vacancies": 3,
      "vacOver30": 3,
      "roles": [
        {"role": "Teacher", "filled": 2, "open": 3, "openOver30": 3},
        {"role": "Administrative Officer", "filled": 1, "open": 0, "openOver30": 0},
        {"role": "Principal", "filled": 1, "open": 0, "openOver30": 0}
      ],
      "newAdmissionsMTD": 4,
      "enrollments": 17,
      "applicants": 4,
      "transportRoutes": 4,
      "fleetUtil": 78,
      "transportFlag": false,
      "hostelCapacity": 120,
      "hostelOccupied": 91,
      "health": 76,
      "status": "stable",
      "trend": [70, 70.9, 71.8, 72.7, 73.6, 74.5, 75.4, 76.3],
      "alerts": 0,
      "color": "var(--teal)",
      "attendanceCounts": {
        "students": {
          "roster": 17,
          "present": 0,
          "absent": 0,
          "leave": 0,
          "halfDay": 0,
          "notMarked": 17
        },
        "staff": {
          "roster": 4,
          "present": 0,
          "absent": 0,
          "leave": 0,
          "halfDay": 0,
          "notMarked": 4
        }
      }
    },
    {
      "id": 4,
      "code": "MADD",
      "name": "Maddipalem",
      "city": "Maddipalem",
      "region": "Sai Ravindra School",
      "students": 18,
      "capacity": 0,
      "capacityKnown": false,
      "fill": null,
      "avgFee": 126556,
      "revenue": 2278000,
      "outstanding": 1033000,
      "collectionPct": 54.7,
      "attendancePct": 91.1,
      "examIndex": 78.8,
      "passPct": 94.4,
      "avgGrade": 7.9,
      "syllabusPct": 86,
      "teachers": 2,
      "staffTeach": 2,
      "staffNon": 3,
      "staffTotal": 5,
      "teacherRatio": 9,
      "admins": 1,
      "parents": 18,
      "teachingStaff": 2,
      "nonTeachingStaff": 2,
      "totalUsers": 41,
      "costPerStudent": 79730,
      "revPerStudent": 126556,
      "ebitdaMargin": 37.0,
      "payrollPct": 45,
      "onlinePayPct": 69,
      "inventorySpendMTD": 9492,
      "attritionPct": 4.9,
      "staffAttrition": 6.5,
      "vacancies": 2,
      "vacOver30": 2,
      "roles": [
        {"role": "Teacher", "filled": 2, "open": 2, "openOver30": 2},
        {"role": "Administrative Officer", "filled": 2, "open": 0, "openOver30": 0},
        {"role": "Principal", "filled": 1, "open": 0, "openOver30": 0}
      ],
      "newAdmissionsMTD": 4,
      "enrollments": 18,
      "applicants": 4,
      "transportRoutes": 5,
      "fleetUtil": 81,
      "transportFlag": false,
      "hostelCapacity": 160,
      "hostelOccupied": 128,
      "health": 73,
      "status": "stable",
      "trend": [67, 67.9, 68.8, 69.7, 70.6, 71.5, 72.4, 73.3],
      "alerts": 0,
      "color": "var(--violet)",
      "attendanceCounts": {
        "students": {
          "roster": 18,
          "present": 0,
          "absent": 0,
          "leave": 0,
          "halfDay": 0,
          "notMarked": 18
        },
        "staff": {
          "roster": 5,
          "present": 0,
          "absent": 0,
          "leave": 0,
          "halfDay": 0,
          "notMarked": 5
        }
      }
    },
    {
      "id": 5,
      "code": "MADH",
      "name": "Madhapur Branch",
      "city": "Madhapur Branch",
      "region": "Sai Ravindra School",
      "students": 9,
      "capacity": 0,
      "capacityKnown": false,
      "fill": null,
      "avgFee": 224444,
      "revenue": 2020000,
      "outstanding": 555000,
      "collectionPct": 72.5,
      "attendancePct": 89.6,
      "examIndex": 63.1,
      "passPct": 88.9,
      "avgGrade": 6.3,
      "syllabusPct": 78,
      "teachers": 2,
      "staffTeach": 2,
      "staffNon": 2,
      "staffTotal": 4,
      "teacherRatio": 5,
      "admins": 1,
      "parents": 9,
      "teachingStaff": 2,
      "nonTeachingStaff": 1,
      "totalUsers": 22,
      "costPerStudent": 157111,
      "revPerStudent": 224444,
      "ebitdaMargin": 30.0,
      "payrollPct": 51,
      "onlinePayPct": 57,
      "inventorySpendMTD": 5050,
      "attritionPct": 7.1,
      "staffAttrition": 10,
      "vacancies": 4,
      "vacOver30": 4,
      "roles": [
        {"role": "Teacher", "filled": 2, "open": 4, "openOver30": 4},
        {"role": "Administrative Officer", "filled": 1, "open": 0, "openOver30": 0},
        {"role": "Principal", "filled": 1, "open": 0, "openOver30": 0}
      ],
      "newAdmissionsMTD": 4,
      "enrollments": 9,
      "applicants": 4,
      "transportRoutes": 3,
      "fleetUtil": 70,
      "transportFlag": true,
      "hostelCapacity": 80,
      "hostelOccupied": 57,
      "health": 74,
      "status": "stable",
      "trend": [68, 68.9, 69.8, 70.7, 71.6, 72.5, 73.4, 74.3],
      "alerts": 0,
      "color": "var(--warn)",
      "attendanceCounts": {
        "students": {
          "roster": 9,
          "present": 0,
          "absent": 0,
          "leave": 0,
          "halfDay": 0,
          "notMarked": 9
        },
        "staff": {
          "roster": 4,
          "present": 0,
          "absent": 0,
          "leave": 0,
          "halfDay": 0,
          "notMarked": 4
        }
      }
    },
    {
      "id": 6,
      "code": "STEE",
      "name": "Steel Plant Branch",
      "city": "Steel Plant Branch",
      "region": "Sai Ravindra School",
      "students": 43,
      "capacity": 155,
      "capacityKnown": true,
      "fill": 27.7,
      "avgFee": 61559,
      "revenue": 2647020,
      "outstanding": 403840,
      "collectionPct": 84.7,
      "attendancePct": 93.1,
      "examIndex": 69.7,
      "passPct": 75.9,
      "avgGrade": 7,
      "syllabusPct": 88,
      "teachers": 9,
      "staffTeach": 9,
      "staffNon": 16,
      "staffTotal": 25,
      "teacherRatio": 5,
      "admins": 2,
      "parents": 28,
      "teachingStaff": 9,
      "nonTeachingStaff": 14,
      "totalUsers": 96,
      "costPerStudent": 38167,
      "revPerStudent": 61559,
      "ebitdaMargin": 38.0,
      "payrollPct": 44,
      "onlinePayPct": 72,
      "inventorySpendMTD": 11029,
      "attritionPct": 4.5,
      "staffAttrition": 6,
      "vacancies": 10,
      "vacOver30": 2,
      "roles": [
        {"role": "Teacher", "filled": 9, "open": 2, "openOver30": 2},
        {"role": "Senior Teacher", "filled": 1, "open": 6, "openOver30": 0},
        {"role": "Librarian", "filled": 5, "open": 0, "openOver30": 0},
        {"role": "Administrative Officer", "filled": 2, "open": 0, "openOver30": 0},
        {"role": "Maths Teacher", "filled": 1, "open": 1, "openOver30": 0},
        {"role": "Principal", "filled": 2, "open": 0, "openOver30": 0},
        {"role": "Account Manager", "filled": 1, "open": 0, "openOver30": 0},
        {"role": "Bus Attendant", "filled": 1, "open": 0, "openOver30": 0},
        {"role": "Hostel Warden", "filled": 1, "open": 0, "openOver30": 0},
        {"role": "Receptionist", "filled": 1, "open": 0, "openOver30": 0},
        {"role": "Transport Manager", "filled": 1, "open": 0, "openOver30": 0},
        {"role": "Junior Maths", "filled": 0, "open": 1, "openOver30": 0}
      ],
      "newAdmissionsMTD": 5,
      "enrollments": 41,
      "applicants": 5,
      "transportRoutes": 5,
      "fleetUtil": 84,
      "transportFlag": false,
      "hostelCapacity": 180,
      "hostelOccupied": 148,
      "health": 70,
      "status": "stable",
      "trend": [64, 64.9, 65.8, 66.7, 67.6, 68.5, 69.4, 70.3],
      "alerts": 0,
      "color": "var(--bad)",
      "resources": {
        "classrooms": 4,
        "digitalClassrooms": 0,
        "scienceLabs": 0,
        "computerLabs": 0,
        "languageLabs": 0,
        "otherRooms": 0,
        "totalRooms": 4,
        "totalSeats": 155,
        "buses": 7,
        "busSeats": 315,
        "busRoutes": 6,
        "hostels": 3,
        "hostelRooms": 3,
        "hostelBeds": 35,
        "hostelBedsOccupied": 12,
        "libraryCopies": 104,
        "buildingsRented": 0,
        "rentMonthly": 0,
        "assets": 0,
        "assetValue": 0,
        "labEquipment": 0,
        "labEquipmentValue": 0
      },
      "attendanceCounts": {
        "students": {
          "roster": 43,
          "present": 22,
          "absent": 5,
          "leave": 0,
          "halfDay": 0,
          "notMarked": 16
        },
        "staff": {
          "roster": 25,
          "present": 0,
          "absent": 1,
          "leave": 0,
          "halfDay": 0,
          "notMarked": 24
        }
      }
    }
  ],
  "collection": {
    "collected": 9658180,
    "due": 2608167,
    "overdue": 1888673
  },
  "aging": [
    {"bucket": "0–30 d", "amount": 1843704},
    {"bucket": "31–60 d", "amount": 1214147},
    {"bucket": "61–90 d", "amount": 854400},
    {"bucket": "90+ d", "amount": 584589}
  ],
  "paymentMix": [
    {"name": "Razorpay (online)", "value": 70.4, "color": "var(--accent)"},
    {"name": "Counter / cheque", "value": 29.6, "color": "var(--ink-3)"}
  ],
  "funnel": [
    {"stage": "Enquiries", "value": 16},
    {"stage": "Applications", "value": 25},
    {"stage": "Shortlisted", "value": 9},
    {"stage": "Admitted", "value": 8},
    {"stage": "Enrolled", "value": 2}
  ],
  "enrolYears": [
    {"year": 2022, "students": 78},
    {"year": 2023, "students": 87},
    {"year": 2024, "students": 97},
    {"year": 2025, "students": 109},
    {"year": 2026, "students": 122}
  ],
  "alerts": [
    {
      "level": "critical",
      "type": "Finance",
      "time": "2h ago",
      "branch": "Gachibowli Campus",
      "text": "₹13.2 L outstanding · 48% of billed"
    },
    {
      "level": "critical",
      "type": "Finance",
      "time": "2h ago",
      "branch": "Maddipalem",
      "text": "₹10.3 L outstanding · 45% of billed"
    },
    {
      "level": "critical",
      "type": "Complaint",
      "time": "open",
      "branch": "Kondapur Branch",
      "text": "Transport: Bus delay on Route 4"
    },
    {
      "level": "critical",
      "type": "Transport",
      "time": "recent",
      "branch": "Steel Plant Branch",
      "text": "Minor Accident: Minor Accident on 2026-05-19"
    },
    {
      "level": "warning",
      "type": "Attendance",
      "time": "today",
      "branch": "Kondapur Branch",
      "text": "Attendance 90.5% — below 91% target"
    },
    {
      "level": "warning",
      "type": "Attendance",
      "time": "today",
      "branch": "Kukatpally Campus",
      "text": "Attendance 89.8% — below 91% target"
    },
    {
      "level": "warning",
      "type": "Attendance",
      "time": "today",
      "branch": "Madhapur Branch",
      "text": "Attendance 89.6% — below 91% target"
    },
    {
      "level": "warning",
      "type": "Staffing",
      "time": "3d ago",
      "branch": "Steel Plant Branch",
      "text": "10 open positions · 2 open >30 days"
    },
    {
      "level": "warning",
      "type": "Complaint",
      "time": "open",
      "branch": "Madhapur Branch",
      "text": "Academic: Excess homework load"
    },
    {
      "level": "warning",
      "type": "Complaint",
      "time": "open",
      "branch": "Kukatpally Campus",
      "text": "Facility: Classroom AC not working"
    },
    {
      "level": "warning",
      "type": "Complaint",
      "time": "open",
      "branch": "Steel Plant Branch",
      "text": "Facility: Hostel · Room A201"
    },
    {
      "level": "warning",
      "type": "Transport",
      "time": "recent",
      "branch": "Kondapur Branch",
      "text": "Breakdown: Vehicle TS-KDP-1001 breakdown on route, students transferred"
    },
    {
      "level": "warning",
      "type": "Transport",
      "time": "recent",
      "branch": "Steel Plant Branch",
      "text": "Late Arrival: Late Arrival on 2026-05-12"
    },
    {
      "level": "warning",
      "type": "Transport",
      "time": "recent",
      "branch": "Steel Plant Branch",
      "text": "Route Deviation: Route Deviation on 2026-06-02"
    },
    {
      "level": "info",
      "type": "Academics",
      "time": "today",
      "branch": "Kondapur Branch",
      "text": "Exam index 70.6 — below group median"
    },
    {
      "level": "info",
      "type": "Academics",
      "time": "today",
      "branch": "Kukatpally Campus",
      "text": "Exam index 68.2 — below group median"
    },
    {
      "level": "info",
      "type": "Academics",
      "time": "today",
      "branch": "Madhapur Branch",
      "text": "Exam index 63.1 — below group median"
    },
    {
      "level": "info",
      "type": "Academics",
      "time": "today",
      "branch": "Steel Plant Branch",
      "text": "Exam index 69.7 — below group median"
    },
    {
      "level": "info",
      "type": "Complaint",
      "time": "open",
      "branch": "Steel Plant Branch",
      "text": "Academic: ZZ E2E attach test"
    },
    {
      "level": "info",
      "type": "Transport",
      "time": "recent",
      "branch": "Madhapur Branch",
      "text": "Delay: Route 3 delayed ~30 min due to road works"
    },
    {
      "level": "info",
      "type": "Transport",
      "time": "recent",
      "branch": "Steel Plant Branch",
      "text": "Breakdown: Breakdown on 2026-05-05"
    },
    {
      "level": "info",
      "type": "Transport",
      "time": "recent",
      "branch": "Steel Plant Branch",
      "text": "Tyre Puncture: Tyre Puncture on 2026-05-26"
    }
  ],
  "approvals": [
    {
      "id": "APR-GBC-1",
      "type": "Fee Waiver",
      "text": "Hardship fee waiver — 3 students",
      "branch": "Gachibowli Campus",
      "age": "164d",
      "amount": 45000,
      "status": "pending"
    },
    {
      "id": "APR-GBC-3",
      "type": "Capex",
      "text": "New science lab fit-out",
      "branch": "Gachibowli Campus",
      "age": "164d",
      "amount": 850000,
      "status": "pending"
    },
    {
      "id": "APR-KDP-1",
      "type": "Fee Waiver",
      "text": "Hardship fee waiver — 3 students",
      "branch": "Kondapur Branch",
      "age": "164d",
      "amount": 45000,
      "status": "pending"
    },
    {
      "id": "APR-KDP-2",
      "type": "Hiring",
      "text": "3 teaching posts to approve",
      "branch": "Kondapur Branch",
      "age": "164d",
      "amount": 0,
      "status": "pending"
    },
    {
      "id": "APR-KKP-1",
      "type": "Fee Waiver",
      "text": "Hardship fee waiver — 2 students",
      "branch": "Kukatpally Campus",
      "age": "164d",
      "amount": 45000,
      "status": "pending"
    },
    {
      "id": "APR-KKP-2",
      "type": "Hiring",
      "text": "3 teaching posts to approve",
      "branch": "Kukatpally Campus",
      "age": "164d",
      "amount": 0,
      "status": "pending"
    },
    {
      "id": "APR-MB-1",
      "type": "Fee Waiver",
      "text": "Hardship fee waiver — 4 students",
      "branch": "Maddipalem",
      "age": "164d",
      "amount": 45000,
      "status": "pending"
    },
    {
      "id": "APR-MDP-1",
      "type": "Fee Waiver",
      "text": "Hardship fee waiver — 5 students",
      "branch": "Madhapur Branch",
      "age": "164d",
      "amount": 45000,
      "status": "pending"
    },
    {
      "id": "APR-MDP-2",
      "type": "Hiring",
      "text": "4 teaching posts to approve",
      "branch": "Madhapur Branch",
      "age": "164d",
      "amount": 0,
      "status": "pending"
    },
    {
      "id": "MAT-RECO-2026-00004",
      "type": "stock_reconciliation",
      "text": "Other",
      "branch": "Steel Plant Branch",
      "age": "4d",
      "amount": 2000,
      "status": "pending"
    }
  ],
  "attendance": {
    "asOf": "2026-11-14",
    "studentsAsOf": "2026-09-16",
    "staffAsOf": "2026-11-14",
    "students": {
      "roster": 122,
      "present": 22,
      "absent": 5,
      "leave": 0,
      "halfDay": 0,
      "notMarked": 95
    },
    "staff": {
      "roster": 46,
      "present": 0,
      "absent": 1,
      "leave": 0,
      "halfDay": 0,
      "notMarked": 45
    },
    "byBranch": {
      "Gachibowli Campus": {
        "students": {
          "roster": 21,
          "present": 0,
          "absent": 0,
          "leave": 0,
          "halfDay": 0,
          "notMarked": 21
        },
        "staff": {
          "roster": 4,
          "present": 0,
          "absent": 0,
          "leave": 0,
          "halfDay": 0,
          "notMarked": 4
        }
      },
      "Kondapur Branch": {
        "students": {
          "roster": 14,
          "present": 0,
          "absent": 0,
          "leave": 0,
          "halfDay": 0,
          "notMarked": 14
        },
        "staff": {
          "roster": 4,
          "present": 0,
          "absent": 0,
          "leave": 0,
          "halfDay": 0,
          "notMarked": 4
        }
      },
      "Kukatpally Campus": {
        "students": {
          "roster": 17,
          "present": 0,
          "absent": 0,
          "leave": 0,
          "halfDay": 0,
          "notMarked": 17
        },
        "staff": {
          "roster": 4,
          "present": 0,
          "absent": 0,
          "leave": 0,
          "halfDay": 0,
          "notMarked": 4
        }
      },
      "Maddipalem": {
        "students": {
          "roster": 18,
          "present": 0,
          "absent": 0,
          "leave": 0,
          "halfDay": 0,
          "notMarked": 18
        },
        "staff": {
          "roster": 5,
          "present": 0,
          "absent": 0,
          "leave": 0,
          "halfDay": 0,
          "notMarked": 5
        }
      },
      "Madhapur Branch": {
        "students": {
          "roster": 9,
          "present": 0,
          "absent": 0,
          "leave": 0,
          "halfDay": 0,
          "notMarked": 9
        },
        "staff": {
          "roster": 4,
          "present": 0,
          "absent": 0,
          "leave": 0,
          "halfDay": 0,
          "notMarked": 4
        }
      },
      "Steel Plant Branch": {
        "students": {
          "roster": 43,
          "present": 22,
          "absent": 5,
          "leave": 0,
          "halfDay": 0,
          "notMarked": 16
        },
        "staff": {
          "roster": 25,
          "present": 0,
          "absent": 1,
          "leave": 0,
          "halfDay": 0,
          "notMarked": 24
        }
      }
    }
  }
};
