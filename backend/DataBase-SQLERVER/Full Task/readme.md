# ShopSphere – SQL Server Practice Tasks (Backend Developer Track)

**Files in this repo**

| File | Purpose |
|---|---|
| `01_ShopSphere_Setup.sql` | Your original database script (unchanged). Run it once; re-run anytime to reset. |
| `02_ShopSphere_Tasks.md` | This file – questions only. |
| `03_ShopSphere_Answers.sql` | Solutions, same IDs (`E01`, `M12`, `H07`, `X03` …). |

## How to use

- Tasks go **Easy → Medium → Hard → Expert**. Easy tasks are syntax recaps, so they are one-liners on purpose.
- Tasks are **connected**. You build a **Loyalty & Returns module** step by step (new schemas, tables, view, procedures, triggers, security). Later tasks reuse earlier objects, so do them **in order**. Each task shows `Needs:`.
- Keep your own answers in `my_solutions.sql`. If you break something, re-run the setup script and replay your file.
- "Today" = **2026-06-30**. Revenue = payments with `Status = 'Completed'`. Order total formula is in the setup script header.
- Tasks marked **🔁** change existing shared data. Wrap them in `BEGIN TRAN … ROLLBACK` until you are sure.
- Tasks marked **👥** need **two query windows** (two sessions).
- Language tags: **DQL** (SELECT) · **DDL** (structure) · **DML** (data changes) · **TCL/DTL** (transactions) · **DCL** (security) · **PROG** (procedures, functions, triggers) · **PERF** (indexes, plans) · **ADMIN** (metadata, backup).

Progress: tick each box as you finish.

---

# 🟢 LEVEL 1 – EASY (syntax recap)

### DQL basics
- [ ] **E01** · DQL – Show every column and row of `Geo.Countries`.
- [ ] **E02** · DQL – First 10 customers (by `CustomerId`): id, first name, last name, email.
- [ ] **E03** · DQL – Product name and price for products priced above 1000, most expensive first.
- [ ] **E04** · DQL – The distinct order statuses in `Sales.Orders`.
- [ ] **E05** · DQL – Customers with no phone number (id, first name, last name).
- [ ] **E06** · DQL – Products whose name starts with `Nova`.
- [ ] **E07** · DQL – Orders placed in June 2026 (id, date, status). Use a range, not `YEAR()`/`MONTH()` on the column.
- [ ] **E08** · DQL – Active products priced between 100 and 200 (inclusive).
- [ ] **E09** · DQL – Cities named Cairo, Dubai or London (use `IN`).
- [ ] **E10** · DQL – Products page 3, 20 rows per page, ordered by `ProductId`.
- [ ] **E11** · DQL – Products with a `PriceBand`: `Budget` (< 100), `Standard` (< 500), else `Premium`.
- [ ] **E12** · DQL – First 5 customers: full name (`CONCAT`), upper-case last name, email length.
- [ ] **E13** · DQL – First 10 orders: id, date, year, month, weekday name.
- [ ] **E14** · DQL – Customer id and phone, showing `N/A` when the phone is `NULL`.
- [ ] **E15** · DQL – One row: number of products, cheapest, most expensive, average price.
- [ ] **E16** · DQL – Number of orders per status.

### DDL – start the Loyalty module
- [ ] **E17** · DDL – Create schema `Loyalty`.
- [ ] **E18** · DDL – Create `Loyalty.Tiers`: `TierId` TINYINT PK (no identity), `TierName` NVARCHAR(30) unique not null, `MinPoints` INT not null (>= 0), `DiscountPercent` DECIMAL(4,2) not null default 0. Name every constraint.
- [ ] **E19** · DDL – Create `Loyalty.CustomerPoints`: `CustomerId` PK + FK to `Sales.Customers`, `Points` INT not null default 0, `TierId` TINYINT null FK to `Loyalty.Tiers`, `UpdatedAt` DATETIME2(0) not null default now.
- [ ] **E20** · DDL – Create `Loyalty.PointsLedger`: `LedgerId` BIGINT identity PK, `CustomerId` FK, `OrderId` INT null FK to `Sales.Orders`, `Points` INT not null (can be negative), `Reason` VARCHAR(30) not null, `CreatedAt` DATETIME2(0) not null default now.
- [ ] **E21** · DDL – On `PointsLedger`: add column `Note NVARCHAR(200) NULL`, widen it to 300, then drop it.
- [ ] **E22** · DDL – Add a CHECK on `PointsLedger.Reason`, allowing only: `Purchase, Review, Referral, Adjustment, Redeem, TransferIn, TransferOut, Reversal`.

### DML basics
- [ ] **E23** · DML – Insert 4 tiers in one statement: 1 Bronze (0 pts, 0 %), 2 Silver (1000, 3 %), 3 Gold (5000, 5 %), 4 Platinum (15000, 8 %).
- [ ] **E24** · DML – Insert **yourself** as a customer (only the required columns, CityId 1, email `test.student@mail.com`), capture the new id, then insert a default address for that customer. *(You are the test customer for later tasks.)*
- [ ] **E25** · DML – Update your customer's phone to `+201000000000`.
- [ ] **E26** · DML – Insert coupon `TEST50` (50 %, valid 2026-06-30 → 2026-07-31, 10 uses) and delete it again.
- [ ] **E27** · DML – `INSERT … SELECT`: put every **active** customer into `Loyalty.CustomerPoints` with 0 points and the Bronze tier. *(Needs E23, E24.)*
- [ ] **E28** · DML/DDL – `SELECT … INTO` a scratch copy of `Geo.Cities` named `Loyalty.ScratchCities`, delete the Egyptian rows, `TRUNCATE` it, then drop it.

---

# 🟡 LEVEL 2 – MEDIUM

### Joins, grouping, subqueries
- [ ] **M01** · DQL – Products with category name and brand name.
- [ ] **M02** · DQL – First 20 customers with city and **country** name (3 tables).
- [ ] **M03** · DQL – Customers who **never placed an order** (list + count). Compare your count with the header comment of the setup script. *Do they match? Why or why not?*
- [ ] **M04** · DQL – Every order with customer full name and sales-rep full name. Online orders (no rep) must show `Online`. *Watch out: what does `CONCAT` return for NULL inputs?*
- [ ] **M05** · DQL – Lines of order **1001**: product name, quantity, unit price, discount %, line total (rounded to 2 decimals).
- [ ] **M06** · DQL – Revenue per month for Jan–Jun 2026 (completed payments).
- [ ] **M07** · DQL – Customers with **more than 40 orders** (id, name, order count).
- [ ] **M08** · DQL – Top 10 customers by completed revenue (name, order count, revenue).
- [ ] **M09** · DQL – Products that were **never ordered** (use `NOT EXISTS`).
- [ ] **M10** · DQL – Products priced **above the average of their own category** (correlated subquery).
- [ ] **M11** · DQL – Customers who used coupon `VIP25` on at least one order (`EXISTS`).
- [ ] **M12** · DQL – Set operators: (a) cities that have customers but **no warehouse**; (b) cities that have both; (c) all distinct emails from customers + employees + suppliers, and compare `UNION` vs `UNION ALL` counts.
- [ ] **M13** · DQL – Self join: each employee with manager name (heads show `(none)`); then number of direct reports per manager, highest first.
- [ ] **M14** · DQL – Customers who were referred: referred name + referrer name.
- [ ] **M15** · DQL – Average delivery time in hours per carrier (delivered shipments only) + shipment count.
- [ ] **M16** · DQL – Per product: average rating, review count, number of reviews without comment. Keep products with **≥ 5 reviews**, best first.
- [ ] **M17** · DQL – Per order year: count of orders as columns `Delivered`, `Cancelled`, `Returned`, `Shipped` (conditional aggregation).
- [ ] **M18** · DQL – For orders 1–10: one row per order with all product names in one string (`STRING_AGG`, sorted).
- [ ] **M19** · DQL – (a) Stock rows where `QuantityOnHand < ReorderLevel` with warehouse and product names; (b) number of such alerts per warehouse.
- [ ] **M20** · DQL – List **all categories** with their full path like `Electronics > Phones > Smartphones` (self joins + `CONCAT_WS`).

### DDL – objects that support the module
- [ ] **M21** · DDL – Create view `Sales.vw_OrderTotals`: `OrderId, CustomerId, OrderDate, Status, ShippingFee, CouponPercent, ItemsTotal, OrderTotal` using the header formula. *(Reused by many later tasks.)*
- [ ] **M22** · DDL – Add a **persisted computed column** `MarginPct` to `Catalog.Products` = `(UnitPrice − CostPrice) * 100 / UnitPrice`, DECIMAL(5,2).
- [ ] **M23** · DDL – Create sequence `Sales.seq_TicketNo` (start 1000) and table `Sales.ReturnRequests`: `ReturnId` identity PK, `TicketNo` default `NEXT VALUE FOR` the sequence (unique), `OrderId` FK, `Reason` NVARCHAR(200), `Status` (`Open/Approved/Rejected/Closed`, default `Open`), `RequestedAt` default now. Add a **filtered unique index** so an order can have **only one Open** request.
- [ ] **M24** · DML – Seed `ReturnRequests`: one row (`Status = 'Closed'`) for every order whose status is `Returned`, requested 7 days after the order date. *(Needs M23.)*
- [ ] **M25** · DQL – Temp tables: store the top 100 customers by revenue in `#TopCustomers`, then join it back to show each one's latest order date.

### DML that thinks
- [ ] **M26** · DML – Fill `Loyalty.PointsLedger`: for every completed payment insert `Purchase` points = whole currency units paid (floor), dated at the payment date. *(Needs E20, E22.)*
- [ ] **M27** · DML – `UPDATE … JOIN`: set `CustomerPoints.Points` = sum of each customer's ledger. *(Needs E27, M26.)*
- [ ] **M28** · DML – `MERGE`: re-sync `CustomerPoints` from the ledger – insert missing customers (Bronze), update changed balances. Which customers were missing, and why? *(Needs M27.)*
- [ ] **M29** · DML – Assign each customer the **highest tier** whose `MinPoints` ≤ their points (`UPDATE` + `CROSS APPLY`).
- [ ] **M30** · DML – Duplicate cleanup: create `Loyalty.CitiesDup` holding all cities plus a second copy of the Egyptian ones, then delete duplicates keeping the lowest `CityId` (CTE + `ROW_NUMBER`). Drop it afterwards.
- [ ] **M31** · DML 🔁 – In a transaction, raise prices by 10 % for brand `NovaTech`, capture old/new price with `OUTPUT` into a **table variable**, show it, then roll back. *After the rollback, does the table variable still contain rows? Why?*
- [ ] **M32** · ADMIN – One query listing every user table (`schema.table`) with its row count, biggest first (catalog/DMV views).

---

# 🟠 LEVEL 3 – HARD

### Window functions & CTEs
- [ ] **H01** · DQL – Latest order of each customer 1–20 (`ROW_NUMBER`).
- [ ] **H02** · DQL – Top 3 products by revenue **inside each category** (`DENSE_RANK`). Ignore cancelled/returned orders.
- [ ] **H03** · DQL – Monthly completed revenue with **running total**, **3-month moving average** and **month-over-month %** (`SUM/AVG OVER`, `LAG`).
- [ ] **H04** · DQL – Days between consecutive orders per customer (`LAG`). Show the 10 customers with the smallest average gap among those having ≥ 10 gaps.
- [ ] **H05** · DQL – `NTILE(4)` customers by lifetime revenue. Per quartile: customers, revenue, min, max, and **% share of total revenue**.
- [ ] **H06** · DQL – **Recursive CTE**: whole category tree with `Level` and `Path`. Then (b) count products per **top-level** category.
- [ ] **H07** · DQL – **Recursive CTE** on employees: level + chain (`Head > Manager > Staff`). Then payroll and headcount per department head's tree.
- [ ] **H08** · DQL – **Date spine**: every day of June 2026 with completed revenue, `0` on days with none (recursive calendar + `LEFT JOIN`).
- [ ] **H09** · DQL – `CROSS APPLY`: for the top 10 customers by revenue, their 3 latest orders with totals (use `vw_OrderTotals`). *(Needs M21.)*
- [ ] **H10** · DQL – `PIVOT`: revenue for Jan–Jun 2026, one row per month, columns = payment method. Then `UNPIVOT` it back.

### Programmability
- [ ] **H11** · PROG – Inline table-valued function `Sales.fn_CustomerOrders(@CustomerId)`, used with `CROSS APPLY` for customers 1–5. *(Needs M21.)* Also write scalar `Loyalty.fn_TierFor(@Points)` returning the tier id. *Which of the two is usually worse for performance, and why?*
- [ ] **H12** · PROG – Procedure `Loyalty.usp_AddPoints(@CustomerId, @Points, @Reason, @OrderId = NULL, @NewBalance OUTPUT)`: validates input (`THROW`), creates the points row if missing, forbids negative balances, writes the ledger, recalculates the tier, all in one transaction. *(Needs E19–E22.)*
- [ ] **H13** · PROG – Create schema `Audit` and table `Audit.PriceChanges` (product, old/new price, who, when). Add an `AFTER UPDATE` trigger on `Catalog.Products` that logs **only real price changes**, correct for multi-row updates. Test in a rolled-back transaction.
- [ ] **H14** · PROG – `INSTEAD OF DELETE` trigger on `Catalog.Products` that turns deletes into `IsActive = 0`. Test it. *(Does the H13 trigger fire? why?)*
- [ ] **H15** · PROG – `AFTER INSERT` trigger on `Sales.Payments`: for `Completed` payments, add `Purchase` ledger points (floor of amount) unless that order already has a `Purchase` row. Must work for multi-row inserts. *(Needs M26.)*
- [ ] **H16** · DDL/PERF – **Indexed view** `Sales.vw_ProductRevenue` (per product: lines, units, revenue) with `SCHEMABINDING` and a unique clustered index. Query it with and without `NOEXPAND`.

### Transactions (TCL / DTL)
- [ ] **H17** · TCL – Show `@@TRANCOUNT` through nested `BEGIN TRAN`, `COMMIT`, `ROLLBACK`. What does an inner `COMMIT` really do? What does `ROLLBACK` do to all levels? Use a harmless update on `Loyalty.Tiers`.
- [ ] **H18** · TCL – `SAVE TRANSACTION`: update two tiers, roll back to the savepoint after the second one, commit, and verify only the first change survived.
- [ ] **H19** · TCL/PROG – `Loyalty.usp_TransferPoints(@From, @To, @Points)` with `TRY/CATCH`, `SET XACT_ABORT ON`, `XACT_STATE()` and `THROW`. Reuse `usp_AddPoints` (`TransferOut` / `TransferIn`). Prove that a transfer larger than the balance leaves **both** customers unchanged. *(Needs H12.)*
- [ ] **H20** · TCL 👥 – **Blocking**: session 1 updates a customer row without committing; session 2 reads it. Find the blocker (`sys.dm_exec_requests`, `sys.dm_tran_locks`). Then remove the blocking with `READ_COMMITTED_SNAPSHOT` and explain what readers see now.
- [ ] **H21** · TCL 👥 – **Deadlock**: create one on `Loyalty.Tiers` with two sessions updating rows in opposite order. Fix it by consistent ordering, then add a **retry loop** for error 1205.

### Security (DCL)
- [ ] **H22** · DCL – Create role `role_reporting` and user `u_report` (`WITHOUT LOGIN`). Grant read on schemas Sales, Catalog, Geo, HR, but **deny the `Salary` column**. Test with `EXECUTE AS USER` / `REVERT`: does `SELECT *` on `HR.Employees` work? Can he `UPDATE`?
- [ ] **H23** · DCL – Role `role_app` + user `u_app`: `EXECUTE` on schema `Loyalty` but **no** table access. Show that `EXEC Loyalty.usp_AddPoints` works while `SELECT` on `Loyalty.CustomerPoints` fails. Explain **ownership chaining**. *(Needs H12, H22 pattern.)*
- [ ] **H24** · DCL – **Dynamic Data Masking** on `Sales.Customers.Email` (`email()`) and `Phone` (`partial`). Test as `u_report`, then grant/revoke `UNMASK`.

### Performance, data quality, JSON, temporal
- [ ] **H25** · PERF – Query orders of one customer since 2026-01-01. Read `STATISTICS IO`, note the scan, create a nonclustered index (with `INCLUDE`), compare reads. Then show why `WHERE YEAR(OrderDate) = 2026` is not index-friendly and rewrite it.
- [ ] **H26** · PERF/ADMIN – Query the catalog for **foreign-key columns with no supporting index**, then create indexes for the 5 you think matter most.
- [ ] **H27** · DQL – Data-quality hunt (uses `vw_OrderTotals`): (a) payments that differ from the computed order total; (b) shipments still `Shipped` for > 14 days before 2026-06-30; (c) orders shipped to an address that belongs to another customer; (d) orders that used a coupon **outside its validity dates**; (e) customers registered **after** their first order.
- [ ] **H28** · DQL – JSON: (a) order 1001 as one JSON document with nested `Items` (`FOR JSON PATH`); (b) `OPENJSON` to turn `[{"ProductId":5,"Quantity":2},{"ProductId":9,"Quantity":1}]` into rows joined to products with line totals.
- [ ] **H29** · DDL – **Temporal table**: make `Catalog.Suppliers` system-versioned (hidden period columns + history table). Change a rating twice, then query `FOR SYSTEM_TIME ALL` and `AS OF`.

---

# 🔴 LEVEL 4 – EXPERT (capstones)

- [ ] **X01** · PROG/TCL – `Sales.usp_PlaceOrder`: table type `Sales.OrderLineList (ProductId, Quantity)` as a **TVP**; validate customer/default address, coupon (by code, valid today), active products; **check and reserve stock** (take it from the warehouse with most stock); insert order + lines (price snapshot) atomically; return the new `OrderId`. Test success and a failing case that must leave no trace.
- [ ] **X02** · PROG/TCL – `Sales.usp_ApproveReturn(@OrderId, @Reason)`: only `Delivered` orders; set order `Returned`, payment `Refunded`, request `Approved` (create if none), **restock** into the shipment's warehouse (upsert), **reverse loyalty points** (`Reversal`). Must be **idempotent** (second call = no-op). *(Needs M23, H12.)*
- [ ] **X03** · DQL – **RFM segmentation**: recency (days to 2026-06-30), frequency, monetary, each `NTILE(5)`; label segments (Champion, Loyal, Recent, At Risk, Lost, Regular) and count customers per segment.
- [ ] **X04** · DQL – **Cohort retention**: cohort = month of first order; show `M0…M6` retention **percentages** per cohort.
- [ ] **X05** · DQL – **Gaps & islands**: each customer's longest streak of consecutive months with at least one order; top 10 customers.
- [ ] **X06** · DQL – **Market basket**: top 10 product pairs bought together with `Together`, `Support` and `Lift`.
- [ ] **X07** · DQL/DML 🔁 – **Reconciliation**: classify every order (`MISSING PAYMENT`, `UNDERPAID`, `OVERPAID`, `RETURN NOT REFUNDED`, `CANCELLED BUT CHARGED`), summarise per issue with money at stake, then write a transactional fix script that inserts adjustment payments for the shortfalls and verifies zero remaining before commit. *(Needs M21.)*
- [ ] **X08** · DQL – **Manager roll-up**: for each employee, own revenue vs. revenue of their **whole subtree** (recursive closure), ranked within department.
- [ ] **X09** · PROG/SECURITY – `Sales.usp_RevenueReport(@GroupBy, @From, @To, @TopN)` with **dynamic SQL** (`sp_executesql`), grouping by Country / City / Category / Brand via a **whitelist**. Show that an injection attempt in `@GroupBy` fails.
- [ ] **X10** · PERF – **Pagination**: OFFSET/FETCH deep page vs **keyset** pagination on `(OrderDate DESC, OrderId DESC)`; compare `STATISTICS IO`.
- [ ] **X11** · DCL – **Row-Level Security**: a sales rep (session context `EmployeeId`) sees only their own orders; role `role_manager` and `db_owner` see all. Test with `EXECUTE AS`, then drop the policy.
- [ ] **X12** · TCL 👥 – **Race condition**: reproduce a duplicate-key failure of "IF NOT EXISTS then INSERT" on `CustomerPoints` with two sessions, then fix it with `UPDLOCK, HOLDLOCK`. Explain why `H12` is safe.
- [ ] **X13** · PERF – **Columnstore**: add a nonclustered columnstore index on `Sales.OrderItems`; compare an aggregation query with and without it (`IGNORE_NONCLUSTERED_COLUMNSTORE_INDEX`); look for **Batch** mode in the plan.
- [ ] **X14** · ADMIN – **Backup & restore**: full backup, differential, switch to FULL recovery + log backup, `RESTORE VERIFYONLY`, restore as `ShopSphere_Copy` with `MOVE`, and a **point-in-time** restore sequence.
- [ ] **X15** · CAPSTONE – `Sales.usp_ExecDashboard(@Month)` returning **4 result sets**: (1) KPIs: revenue, orders, average order value, cancel rate %, new vs. repeat customers; (2) top 5 categories with revenue share; (3) 10 lowest-stock products (total stock ÷ total reorder level); (4) stuck shipments as of month end. Keep every predicate index-friendly.

---

## Dependency map (what to finish before what)

```
E17-E22 (Loyalty schema/tables) ──► E23,E27 ──► M26-M29 ──► H12 ──► H19, X02, X12
M21 (vw_OrderTotals) ─────────────► H09, H11, H27, X07
M23 (ReturnRequests) ─► M24 ───────► X02
H13 (Audit) ───────────────────────► H14 (trigger interplay)
H22 (roles/users) ─► H23, H24 ─────► X11
```

**Stretch idea for your docs:** for every task, add a "what I learned / gotcha" line under your solution. The gotchas worth writing down are `CONCAT` vs NULL (M04), table variables surviving `ROLLBACK` (M31), and undocumented data quirks (M03, H27).
