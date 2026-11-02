# EF Core Basics: CRUD and Transactions (Wallet Example)

This lesson shows how a C# program talks to a **database** using **Entity Framework Core (EF Core)**, without writing SQL by hand.

You will learn how to:

| # | Task | EF Core code |
|---|---|---|
| 1 | Read all rows | `foreach (var w in context.Wallets)` |
| 2 | Read one row by id | `FirstOrDefault(x => x.Id == 2)` |
| 3 | Insert a row | `Add(...)` + `SaveChanges()` |
| 4 | Update a row | change a property + `SaveChanges()` |
| 5 | Delete a row | `Remove(...)` + `SaveChanges()` |
| 6 | Filter rows | `Where(x => x.Balance > 5000)` |
| 7 | Move money safely | `BeginTransaction()` ... `Commit()` |

---

# 1. The big idea

A database stores data in **tables** (rows and columns). Your C# program works with **objects**. EF Core is a translator between the two. It is called an **ORM** (Object-Relational Mapper).

```
  Your C# code               EF Core                  Database
 ┌─────────────┐       ┌──────────────┐        ┌──────────────┐
 │ Wallet      │       │ translates   │        │ Wallets table│
 │ object      │ ───►  │ C# to SQL    │ ───►   │ (rows)       │
 │ Balance += 1│       │ and back     │        │              │
 └─────────────┘       └──────────────┘        └──────────────┘
```

| In the database | In C# |
|---|---|
| Table `Wallets` | Class `Wallet` + property `context.Wallets` |
| A row | One `Wallet` object |
| A column | A property (`Holder`, `Balance`) |
| `SELECT ... WHERE` | LINQ: `Where(...)`, `FirstOrDefault(...)` |
| `INSERT` / `UPDATE` / `DELETE` | `Add` / change a property / `Remove`, then `SaveChanges()` |

> **LINQ you already know works here.** `Where`, `FirstOrDefault` and `Single` are the same methods you used on lists. EF Core turns them into SQL (this is the `IQueryable` idea from the LINQ lessons).

---

# 2. What the lesson code needs

The lesson uses two classes that are not shown in the code you pasted. They must look something like this (this is what I assumed):

### The entity: `Wallet` (one row)

```csharp
namespace Efcore
{
    public class Wallet
    {
        public int Id { get; set; }              // primary key (EF Core finds it because it is named Id)
        public string Holder { get; set; }       // who owns the wallet
        public decimal Balance { get; set; }     // money: always use decimal, never double

        // Makes Console.WriteLine(wallet) print something useful
        public override string ToString() => $"{Id} | {Holder} | {Balance:N2}";
    }
}
```

### The context: `AppDbContext` (the connection to the database)

```csharp
using Microsoft.EntityFrameworkCore;

namespace Efcore
{
    public class AppDbContext : DbContext
    {
        public DbSet<Wallet> Wallets { get; set; }      // = the "Wallets" table

        protected override void OnConfiguring(DbContextOptionsBuilder options)
        {
            options.UseSqlServer(@"Server=.;Database=WalletDb;Trusted_Connection=True;TrustServerCertificate=True;");
        }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Wallet>().Property(w => w.Balance).HasPrecision(18, 2);   // money needs a precision
        }
    }
}
```

| Part | Meaning |
|---|---|
| `DbContext` | The **gateway** to the database. Everything you do goes through it. |
| `DbSet<Wallet> Wallets` | Represents the table. Querying it reads rows; adding to it inserts rows. |
| `OnConfiguring` | Says **which database** to use and how to connect (the connection string). |
| `HasPrecision(18, 2)` | The `Balance` column holds up to 18 digits, 2 after the decimal point. |

> Your lesson may use another provider (for example SQLite: `options.UseSqlite("Data Source=wallet.db");`). Only that one line changes; all the code in the lesson stays the same.

---

# 3. Set up the project (once)

```bash
# 1) install the packages (SQL Server provider shown)
dotnet add package Microsoft.EntityFrameworkCore.SqlServer
dotnet add package Microsoft.EntityFrameworkCore.Design

# 2) install the EF command-line tool (once per computer)
dotnet tool install --global dotnet-ef

# 3) create the database and the Wallets table from your classes (a "migration")
dotnet ef migrations add InitialCreate
dotnet ef database update
```

Then add a few rows so you have something to play with (example data, yours may differ):

| Id | Holder | Balance |
|---|---|---|
| 1 | Ahmed | 10,000.00 |
| 2 | Sara | 20,000.00 |
| 3 | Omar | 3,000.00 |
| 4 | Mona | 8,000.00 |

---

# 4. The most important habit: `using (var context = new AppDbContext())`

```csharp
using (var context = new AppDbContext())
{
    // work with the database here
}   // <- the connection is closed and the context is cleaned up here
```

- A `DbContext` is a **short-lived work session** (called a *Unit of Work*): open it, do one job, `SaveChanges()`, close it.
- `using` guarantees that it is closed even if an error happens.
- That is why the lesson creates a **new** `AppDbContext` for each task.

**Do not** keep one context open for the whole life of the program.

---

# 5. CRUD, one operation at a time

CRUD = **C**reate, **R**ead, **U**pdate, **D**elete.

## 5.1 Read all rows

```csharp
using (var context = new AppDbContext())
{
    foreach (var wallet1 in context.Wallets)
    {
        Console.WriteLine(wallet1);
    }
}
```

SQL that EF Core sends:

```sql
SELECT [w].[Id], [w].[Balance], [w].[Holder]
FROM [Wallets] AS [w]
```

Notes:
- The query runs when the `foreach` starts (this is **deferred execution**).
- `Console.WriteLine(wallet1)` prints `Efcore.Wallet` unless the class has a `ToString()` (see the entity above).

## 5.2 Read one row by id

```csharp
using (var context = new AppDbContext())
{
    var item = context.Wallets.FirstOrDefault(x => x.Id == 2);
    Console.WriteLine(item);
}
```

```sql
SELECT TOP(1) [w].[Id], [w].[Balance], [w].[Holder]
FROM [Wallets] AS [w]
WHERE [w].[Id] = 2
```

| Method | If nothing is found | If more than one is found |
|---|---|---|
| `FirstOrDefault(rule)` | returns `null` | returns the first |
| `First(rule)` | throws an exception | returns the first |
| `SingleOrDefault(rule)` | returns `null` | throws an exception |
| `Single(rule)` | throws an exception | throws an exception |
| `Find(id)` | returns `null` | n/a (looks up by primary key; checks memory first) |

Always check for `null` when you use an `OrDefault` method:

```csharp
if (item == null) Console.WriteLine("Wallet not found");
```

## 5.3 Insert a row (Create)

```csharp
var wallet = new Wallet()
{
    Holder = "Fathy",
    Balance = 55000M          // the M means decimal
};

using (var context = new AppDbContext())
{
    context.Wallets.Add(wallet);   // 1) tell EF Core: "this is new"
    context.SaveChanges();         // 2) really send it to the database
}
```

```sql
INSERT INTO [Wallets] ([Balance], [Holder])
VALUES (55000.0, N'Fathy');
```

Notes:
- **You did not set `Id`.** The database creates it (an identity column). After `SaveChanges()`, `wallet.Id` is filled in automatically.
- `Add` alone does **nothing** to the database. Only `SaveChanges()` does.

## 5.4 Update a row

```csharp
using (var context = new AppDbContext())
{
    var wallet4 = context.Wallets.Single(x => x.Id == 4);   // 1) load the row into an object
    wallet4.Balance += 1000;                                  // 2) change the object
    context.SaveChanges();                                    // 3) save the change
}
```

```sql
UPDATE [Wallets] SET [Balance] = 9000.0
WHERE [Id] = 4;
```

There is **no** `Update()` call. EF Core **remembers** the object it loaded (change tracking, see section 6) and notices that `Balance` changed. It sends an `UPDATE` for **only the changed column**.

> Careful: this code **adds 1000 every time the program runs**. Run it 3 times and the balance has grown by 3,000.

## 5.5 Delete a row

```csharp
using (var context = new AppDbContext())
{
    var wallet5 = context.Wallets.Single(x => x.Id == 2);   // 1) load it
    context.Remove(wallet5);                                  // 2) mark it as deleted
    context.SaveChanges();                                    // 3) really delete
}
```

```sql
DELETE FROM [Wallets]
WHERE [Id] = 2;
```

`context.Wallets.Remove(wallet5)` does the same and is easier to read.

## 5.6 Filter rows (`Where`)

```csharp
using (var context = new AppDbContext())
{
    var wallet6 = context.Wallets.Where(x => x.Balance > 5000);   // the query is only DESCRIBED here
    foreach (var walle in wallet6)                                 // the query RUNS here
    {
        Console.WriteLine(walle);
    }
}
```

```sql
SELECT [w].[Id], [w].[Balance], [w].[Holder]
FROM [Wallets] AS [w]
WHERE [w].[Balance] > 5000.0
```

The filtering happens **in the database**. Only the matching rows come back to your program.

> **Important:** loop over the result **inside** the `using` block. After the block ends the context is closed and the query can no longer run. If you need the data later, call `.ToList()` inside the block.

---

# 6. How `SaveChanges()` works (change tracking)

When you load or add objects through a context, EF Core **tracks** them. Each tracked object has a **state**:

| State | Meaning | Becomes SQL when you call `SaveChanges()` |
|---|---|---|
| `Unchanged` | Loaded from the database, not modified | nothing |
| `Added` | You called `Add` | `INSERT` |
| `Modified` | You changed a property | `UPDATE` (only the changed columns) |
| `Deleted` | You called `Remove` | `DELETE` |
| `Detached` | Not tracked by this context | nothing |

```
Load a wallet          Change Balance          SaveChanges()
 (Unchanged)    ───►     (Modified)     ───►   UPDATE ... ──► (Unchanged again)
```

Key rules:
1. **Nothing reaches the database until `SaveChanges()`.**
2. `SaveChanges()` sends **all** pending changes together in **one transaction** (all succeed, or none).
3. It returns the **number of rows affected**, which is handy to check: `int rows = context.SaveChanges();`

---

# 7. Transaction: transfer money safely

## 7.1 The problem

Transferring **500** from wallet 1 to wallet 2 needs **two** changes:

```
Wallet 1:  10,000  →  9,500      (minus 500)
Wallet 2:  20,000  →  20,500     (plus 500)
```

What if the program **crashes after the first change** and before the second?

```
Wallet 1:   9,500      ← the 500 left...
Wallet 2:  20,000      ← ...and never arrived. Money disappeared!
```

## 7.2 The solution: a transaction

A **transaction** groups several steps into **one unit**: **all of them happen, or none of them**. (Think of a bank transfer or of buying something: either the whole thing goes through, or nothing changes.)

```csharp
using (var context = new AppDbContext())
{
    using (var transaction = context.Database.BeginTransaction())    // 1) start
    {
        var emp1 = context.Wallets.Single(x => x.Id == 1);
        var emp2 = context.Wallets.Single(x => x.Id == 2);

        var TransferAmount = 500;

        emp1.Balance -= TransferAmount;
        context.SaveChanges();                // saved, but only "temporarily" inside the transaction

        emp2.Balance += TransferAmount;
        context.SaveChanges();                // saved, but still not final

        transaction.Commit();                 // 2) make everything permanent
    }
}
```

| Step | What happens |
|---|---|
| `BeginTransaction()` | The database starts a transaction |
| `SaveChanges()` (twice) | The `UPDATE`s are sent, but are **not final yet** |
| `Commit()` | Both updates become permanent **together** |
| An error before `Commit()` | The transaction is **rolled back**: both updates are undone, as if nothing happened |

SQL, simplified:

```sql
BEGIN TRANSACTION;
UPDATE [Wallets] SET [Balance] = 9500.0  WHERE [Id] = 1;
UPDATE [Wallets] SET [Balance] = 20500.0 WHERE [Id] = 2;
COMMIT;
```

## 7.3 Result

| Id | Holder | Before | After |
|---|---|---|---|
| 1 | Ahmed | 10,000.00 | 9,500.00 |
| 2 | Sara | 20,000.00 | 20,500.00 |

The total money in the system stays the same (30,000).

## 7.4 ACID in simple words

A transaction promises four things:

| Letter | Word | Simple meaning |
|---|---|---|
| **A** | Atomic | All steps happen, or none |
| **C** | Consistent | The data never ends in an invalid state (money is not created or lost) |
| **I** | Isolated | Other users do not see the half-finished transfer |
| **D** | Durable | After `Commit()`, the result is saved even if the power goes off |

## 7.5 A safer version of the same transfer

The lesson code works. Here is the same idea with three improvements: a **balance check**, a **`try/catch` with `Rollback`**, and **better names**.

```csharp
using (var context = new AppDbContext())
using (var transaction = context.Database.BeginTransaction())
{
    try
    {
        var source = context.Wallets.Single(x => x.Id == 1);
        var target = context.Wallets.Single(x => x.Id == 2);
        decimal amount = 500m;

        if (source.Balance < amount)
            throw new InvalidOperationException("Not enough balance.");

        source.Balance -= amount;
        target.Balance += amount;
        context.SaveChanges();           // ONE SaveChanges is enough here

        transaction.Commit();
    }
    catch
    {
        transaction.Rollback();          // undo everything
        throw;                           // show the error to the caller
    }
}
```

Small but useful facts:
- A **single** `SaveChanges()` is **already a transaction**. Both `UPDATE`s above are sent together, all-or-nothing.
- You **need** an explicit `BeginTransaction()` when you want **several** `SaveChanges()` calls, or EF code plus other SQL, to be one unit (like the lesson code).
- If an exception happens and you never call `Commit()`, disposing the transaction **rolls it back** automatically. The `try/catch` just makes it explicit.

---

# 8. Things to notice in the lesson code

| What you see | Why it matters |
|---|---|
| Many lines are commented out | Good for practice: run one example at a time. If you run everything, the insert and delete would change the table every time. |
| The **update** (`wallet4.Balance += 1000`) is *not* commented out | It runs every time and adds 1000 each run. |
| `Single(x => x.Id == 4)` | Throws an exception if no row has Id 4 (for example after you deleted it). Use `SingleOrDefault` and check for `null` if the row might be missing. |
| The delete example removes **Id 2**, and the transfer uses **Id 2** | If you run the delete first, the transfer fails because wallet 2 no longer exists. |
| The transfer has no balance check | Wallet 1 could go **negative**. See the safer version in 7.5. |
| `var TransferAmount = 500;` | The type is `int`. It works because `int` converts to `decimal`, but `decimal amount = 500m;` is clearer. C# names for local variables usually start with a lowercase letter (`transferAmount`). |
| `emp1`, `emp2` | These are wallets, not employees. Names like `source` and `target` are clearer. |
| `Console.WriteLine(item)` | Prints the class name unless `Wallet` overrides `ToString()`. |
| A new `AppDbContext` for each task | Correct. Short-lived contexts are the recommended way. |

---

# 9. Cheat sheet

| I want to... | Code |
|---|---|
| Read everything | `context.Wallets.ToList()` |
| Read one by id | `context.Wallets.Find(2)` or `.FirstOrDefault(x => x.Id == 2)` |
| Filter | `context.Wallets.Where(x => x.Balance > 5000)` |
| Count | `context.Wallets.Count()` |
| Add | `context.Wallets.Add(wallet); context.SaveChanges();` |
| Update | load it, change a property, `context.SaveChanges();` |
| Delete | load it, `context.Wallets.Remove(wallet); context.SaveChanges();` |
| Several steps, all-or-nothing | `BeginTransaction()` ... `Commit()` |
| Undo a transaction | `Rollback()` (or let an exception skip `Commit()`) |
| See the SQL | `query.ToQueryString()` or `options.LogTo(Console.WriteLine)` in `OnConfiguring` |

Remember the rhythm:

```
open context  →  query / change objects  →  SaveChanges()  →  close context
```

---

# 10. Common errors

| Error message (short) | Meaning | Fix |
|---|---|---|
| `Sequence contains no elements` | `Single`/`First` found no row | Check the Id exists, or use `...OrDefault` and test for `null` |
| `Sequence contains more than one element` | `Single` found several rows | The condition is not unique |
| `NullReferenceException` after `FirstOrDefault` | The row was not found (`null`) and you used it | Check `if (item == null)` first |
| Nothing changed in the database | You forgot `SaveChanges()` | Call it after `Add` / change / `Remove` |
| `Cannot access a disposed context` | You used the query after the `using` block ended | Use the result inside the block, or call `.ToList()` there |
| `Invalid object name 'Wallets'` | The table does not exist | Run `dotnet ef database update` |
| `Cannot insert explicit value for identity column` | You set `Id` on an insert | Leave `Id` empty; the database creates it |
| Warning about decimal precision | EF Core does not know the size of `Balance` | `HasPrecision(18, 2)` in `OnModelCreating` |

---

# 11. Exercises

1. **Print all wallets** with a `ToString()` and show the table before and after each step.
2. **Insert** two new wallets in one `SaveChanges()` (use `AddRange`). Print their new `Id` values.
3. **Update safely.** Add 1000 to the wallet of a given holder name. Handle the case where there is no such holder.
4. **Delete** the wallets with a balance below 1000 (hint: `RemoveRange`).
5. **Filter and sort.** Show the wallets with `Balance > 5000` ordered by balance (highest first).
6. **Break the transfer on purpose.** In the lesson's transfer code, throw an exception between the two `SaveChanges()` calls. Check that wallet 1 is **unchanged** after the program stops. Then try again **without** the transaction and see the difference.
7. **Write a method** `Transfer(int fromId, int toId, decimal amount)` that checks the balance and returns `true` or `false`.
8. **See the SQL.** Add `options.LogTo(Console.WriteLine)` in `OnConfiguring` and compare the printed SQL with this README.

---

# Summary

| Idea | One line |
|---|---|
| EF Core | Lets you work with database tables as C# objects and LINQ |
| `DbContext` | A short-lived session; create it in a `using` block |
| `DbSet<Wallet>` | The `Wallets` table |
| Read | `foreach`, `Where`, `FirstOrDefault`, `Single` |
| Insert / Update / Delete | `Add` / change a property / `Remove`, then **`SaveChanges()`** |
| Change tracking | EF Core remembers what you changed and writes only that |
| Transaction | Several steps become **all-or-nothing** (`BeginTransaction`, `Commit`, rollback on error) |
