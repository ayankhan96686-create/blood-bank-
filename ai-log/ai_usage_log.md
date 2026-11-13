# AI Usage & Governance Log
**Course:** DBMS CSL0311 – Problem-Based & Project-Based Learning  
**Project:** AI-Assisted Blood Bank and Donor Matching System (ITM University Gwalior)  
**Authors:** Diya Motwani, Gaurav Agrawal, Ayan Khan, Ch. Mohith  

---

## Mandatory AI Usage Log (Section 10 Compliance)

| Date | Project Stage | AI Tool | Prompt Summary | Validation Method | Modifications / Changes Made | Responsible Member |
| :---: | :---: | :---: | :--- | :--- | :--- | :--- |
| **2026-10-18** | Requirements | Claude 3.7 Sonnet | "Draft 15 business rules for blood banking including 90-day whole blood interval and cold-chain quarantine thresholds." | Reviewed against DGHS Blood Bank Standards and Drugs & Cosmetics Act Schedule F. | Added explicit temperature boundaries (2°C–6°C for RBC, -30°C for FFP, 20°C–24°C for Platelets). | Diya Motwani |
| **2026-10-22** | Conceptual Design | ChatGPT-4o | "Generate Mermaid ER diagram modeling technician supervision hierarchy and weak entity for temperature events." | Visual review of foreign key constraints and cardinality checks. | Corrected recursive supervisor relationship (`supervisor_id -> tech_id`) and composite key on `cold_chain_events`. | Gaurav Agrawal |
| **2026-10-26** | Logical Design & BCNF | Gemini 1.5 Pro | "Audit functional dependencies of blood_units and allocations relations for BCNF compliance." | Mathematical proof checking determinants against candidate keys. | Split equipment attributes into separate `inventory_locations` table to eliminate transitive dependencies. | Diya Motwani |
| **2026-10-30** | SQL Development | GitHub Copilot | "Generate PL/pgSQL trigger to enforce 90-day donor interval on donations before insert." | Syntax execution in PostgreSQL test instance with edge-case unit tests. | Found critical flaw: AI checked calendar months instead of exact 90 elapsed days. Corrected to `(NEW.collection_date - v_last_date) < 90`. | Ch. Mohith |
| **2026-11-02** | Concurrency Design | Claude 3.7 Sonnet | "Write ACID transaction to allocate rare O- blood unit without double booking under concurrent requests." | Stress-tested with concurrent threads executing `sp_allocate_blood_units`. | AI omitted `SKIP LOCKED`, which caused waiting threads to lock up; added `SELECT ... FOR UPDATE SKIP LOCKED`. | Gaurav Agrawal |
| **2026-11-05** | Performance & Indexing | ChatGPT-4o | "Suggest indexes for FEFO allocation query on blood_units table." | Ran `EXPLAIN (ANALYZE, BUFFERS)` in PostgreSQL. | Replaced broad B-tree index with a partial composite index filtering `WHERE status = 'Available'`. | Ch. Mohith |
| **2026-11-08** | Machine Learning | Gemini 1.5 Pro | "Create scikit-learn pipeline to predict blood shortages using UCI Transfusion dataset." | Cross-validation RMSE and feature importance inspection. | Added 7-day rolling request volume from historical requests to blend real clinical demand with UCI donor recency. | Ayan Khan |

