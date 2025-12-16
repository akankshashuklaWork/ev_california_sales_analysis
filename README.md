# 🚗⚡ California Electric Vehicle Market Analysis

SQL & Tableau Data Analytics Project

## 📊 Project Overview

Comprehensive analysis of California's EV market combining **sales data** and **vehicle population data** to uncover trends and growth patterns.

**Technologies:** MySQL | SQL | Tableau Public | GitHub

---

## 🎯 Objectives

- Analyze EV sales trends across California counties (2008-2024)
- Compare sales
- Identify market leaders and growth opportunities
- Build interactive Tableau dashboards

---

## 📈 Key Findings

- **Total EVs Analyzed:** 4,628,460 vehicles
- **Top County:** Los Angeles with highest market share
- **Leading Make:** Tesla
- **Leading model in top county:** Model 3 ( Tesla )

---

## 🗄️ Database Design

**Star Schema Implementation:**
- **2 Fact Tables:** fact_ev_sales, fact_ev_population
- **8 Dimension Tables:** Time, County, State, Make, Model, Fuel Type, City, Utility

![ER Diagram](er_diagram/er_diagram.png)

---

## 🔧 Technologies Used

- **MySQL 8.0** - Database & ETL
- **SQL** - Data cleaning, normalization, analysis
- **Tableau Public** - Data visualization
- **GitHub** - Version control

---

## 📁 Project Structure
```
├── sql/                 # All SQL scripts (ETL pipeline)
├── er_diagram/          # Database design diagram
├── tableau/             # Dashboard screenshots
├── docs/                # Documentation
└── README.md            # This file
```

---

## 🔍 Advanced SQL Techniques

✅ Subqueries & CTEs  
✅ Window Functions (LAG, RANK, NTILE)  
✅ Advanced Analytics (Cohort, Pareto analysis)  
✅ Data normalization (3NF)

---

## 📊 Tableau Dashboards

🔗 **https://public.tableau.com/app/profile/akanksha.shukla2009/viz/ev_sales_project_final/EVSALESDASHBOARD**

### Dashboard Previews:

![Sales Trends](tableau/dashboard_screenshots/dashboard_1.png)


---



---

## 🚀 How to Run

1. Import database schema:
```sql
mysql -u username -p < sql/04_dimension_tables.sql
mysql -u username -p < sql/05_fact_tables.sql
```

2. Load and clean data:
```sql
mysql -u username -p < sql/02_data_quality.sql
mysql -u username -p < sql/03_data_cleaning.sql
```

3. Run analysis queries:
```sql
mysql -u username -p < sql/07_analysis_queries.sql
```

---

## 📧 Contact

https://www.linkedin.com/in/akanksha-shukla-4b0562154/ | Akanksha.shukla@sjsu.edu |

---

## 📄 License

MIT License