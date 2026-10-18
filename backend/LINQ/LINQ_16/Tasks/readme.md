# LINQ Session 17: Tasks (`IEnumerable` vs `IQueryable`)

## How to use

1. Create a new Console project (.NET 6 or later).
2. Replace `Program.cs` with the **Starter Code** below. **No database, no NuGet packages, no shared project** are needed.
3. The starter code contains a **fake database** (`FakeDatabase`). You do **not** need to read or change it. It does three things:
   - pretends the 8 employees live on a database server,
   - **counts** the **rows transferred** to your program and the **round trips** to the server,
   - **prints the query** it receives, like `[DB] Employees.Where(e => (e.Age > 30))`.
4. Use `db.ResetCounters()` **before** each experiment and `db.ShowCounters("label")` **after** it.

```csharp
db.GetAllRows()   // IEnumerable<Employee>: the server sends EVERY row to your program
db.Employees      // IQueryable<Employee>:  your query is sent to the server, only the result comes back
```

## The data

| Id | Name | Department | Age | Salary |
|---|---|---|---|---|
| 1 | Sara Hassan | HR | 29 | 45,000 |
| 2 | Sam Adel | IT | 34 | 90,000 |
| 3 | Ali Mahmoud | HR | 24 | 30,000 |
| 4 | Salma Youssef | Finance | 38 | 70,000 |
| 5 | Omar Khaled | IT | 45 | 120,000 |
| 6 | Mona Fathy | IT | 31 | 55,000 |
| 7 | Hany Samir | Sales | 27 | 38,000 |
| 8 | Nour Ibrahim | Sales | 33 | 62,000 |

> Rules of the fake database: a **single value** (`Count`, `Any`, `Sum`...) counts as **1 row** transferred. A list counts as **one row per employee** returned.

---

## Starter Code (copy into `Program.cs`)

```csharp
#nullable disable
using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Linq.Expressions;

namespace LinqSession17Tasks
{
    // ---------- Model ----------
    public class Employee
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public string Department { get; set; }
        public int Age { get; set; }
        public decimal Salary { get; set; }

        public override string ToString() =>
            $"{Id,2} | {Name,-14} | {Department,-7} | {Age,2} | {Salary,8:N0}";
    }

    // ---------- Data ----------
    public static class Repository
    {
        public static List<Employee> LoadEmployees() => new()
        {
            new Employee { Id = 1, Name = "Sara Hassan",   Department = "HR",      Age = 29, Salary = 45_000  },
            new Employee { Id = 2, Name = "Sam Adel",      Department = "IT",      Age = 34, Salary = 90_000  },
            new Employee { Id = 3, Name = "Ali Mahmoud",   Department = "HR",      Age = 24, Salary = 30_000  },
            new Employee { Id = 4, Name = "Salma Youssef", Department = "Finance", Age = 38, Salary = 70_000  },
            new Employee { Id = 5, Name = "Omar Khaled",   Department = "IT",      Age = 45, Salary = 120_000 },
            new Employee { Id = 6, Name = "Mona Fathy",    Department = "IT",      Age = 31, Salary = 55_000  },
            new Employee { Id = 7, Name = "Hany Samir",    Department = "Sales",   Age = 27, Salary = 38_000  },
            new Employee { Id = 8, Name = "Nour Ibrahim",  Department = "Sales",   Age = 33, Salary = 62_000  },
        };
    }

    // =====================================================================
    //  FAKE DATABASE  (ready-made: you do NOT need to read or change it)
    //
    //    RowsTransferred = rows that travelled from the "server" to your program
    //    RoundTrips      = times your program contacted the "server"
    //
    //    db.GetAllRows()  -> IEnumerable<Employee> : the server sends EVERY row
    //    db.Employees     -> IQueryable<Employee>  : the server receives your
    //                        query (an expression tree) and sends back only the result
    // =====================================================================
    public class FakeDatabase
    {
        private readonly List<Employee> _rows = Repository.LoadEmployees();

        public int RowsTransferred { get; private set; }
        public int RoundTrips { get; private set; }

        public void ResetCounters() { RowsTransferred = 0; RoundTrips = 0; }

        public void ShowCounters(string label) =>
            Console.WriteLine($"  >> {label}: rows transferred = {RowsTransferred}, round trips = {RoundTrips}");

        // IEnumerable style: lazy, and every row is sent to the client
        public IEnumerable<Employee> GetAllRows()
        {
            RoundTrips++;
            Console.WriteLine("  [DB] SELECT * FROM Employees");
            foreach (var row in _rows)
            {
                RowsTransferred++;
                yield return row;
            }
        }

        // IQueryable style: the query travels to the "server" as an expression tree
        public IQueryable<Employee> Employees =>
            new FakeQueryable<Employee>(new FakeQueryProvider(this, _rows.AsQueryable()));

        internal void TripStarted(Expression query)
        {
            RoundTrips++;
            Console.WriteLine($"  [DB] {query}");
        }

        internal void RowsSent(int count) => RowsTransferred += count;
    }

    public class FakeQueryProvider : IQueryProvider
    {
        private readonly FakeDatabase _db;
        private readonly IQueryable<Employee> _serverData;

        public FakeQueryProvider(FakeDatabase db, IQueryable<Employee> serverData)
        {
            _db = db;
            _serverData = serverData;
        }

        public IQueryable CreateQuery(Expression expression)
        {
            var elementType = expression.Type.GetInterfaces().Append(expression.Type)
                .First(i => i.IsGenericType && i.GetGenericTypeDefinition() == typeof(IEnumerable<>))
                .GetGenericArguments()[0];
            return (IQueryable)Activator.CreateInstance(
                typeof(FakeQueryable<>).MakeGenericType(elementType), this, expression);
        }

        public IQueryable<TElement> CreateQuery<TElement>(Expression expression) =>
            new FakeQueryable<TElement>(this, expression);

        public object Execute(Expression expression)
        {
            _db.TripStarted(expression);
            var result = _serverData.Provider.Execute(Rewrite(expression));
            _db.RowsSent(1);
            return result;
        }

        // Used by Count(), First(), Any(), Sum() ... (a single value comes back)
        public TResult Execute<TResult>(Expression expression)
        {
            _db.TripStarted(expression);
            var result = _serverData.Provider.Execute<TResult>(Rewrite(expression));
            _db.RowsSent(1);
            return result;
        }

        // Used when you loop over the query (foreach, ToList ...)
        internal IEnumerable<T> ExecuteEnumerable<T>(Expression expression)
        {
            _db.TripStarted(expression);
            var rows = _serverData.Provider.CreateQuery<T>(Rewrite(expression)).ToList();   // runs on the "server"
            _db.RowsSent(rows.Count);
            return rows;
        }

        // Replaces the root of the query with the real data on the "server"
        private Expression Rewrite(Expression expression) => new RootReplacer(this, _serverData).Visit(expression);

        private class RootReplacer : ExpressionVisitor
        {
            private readonly FakeQueryProvider _provider;
            private readonly IQueryable<Employee> _data;

            public RootReplacer(FakeQueryProvider provider, IQueryable<Employee> data)
            {
                _provider = provider;
                _data = data;
            }

            protected override Expression VisitConstant(ConstantExpression node) =>
                node.Value is IQueryable q && q.Provider == _provider
                    ? Expression.Constant(_data, node.Type)
                    : base.VisitConstant(node);
        }
    }

    public class FakeQueryable<T> : IOrderedQueryable<T>
    {
        private readonly FakeQueryProvider _provider;

        public FakeQueryable(FakeQueryProvider provider, Expression expression = null)
        {
            _provider = provider;
            Expression = expression ?? Expression.Constant(this, typeof(IQueryable<T>));
        }

        public Type ElementType => typeof(T);
        public Expression Expression { get; }
        public IQueryProvider Provider => _provider;

        public IEnumerator<T> GetEnumerator() => _provider.ExecuteEnumerable<T>(Expression).GetEnumerator();
        IEnumerator IEnumerable.GetEnumerator() => GetEnumerator();

        public override string ToString() => "Employees";   // makes the printed query easy to read
    }

    // ---------- Helper ----------
    public static class Extensions
    {
        public static void Print<T>(this IEnumerable<T> source, string title)
        {
            Console.WriteLine();
            Console.WriteLine($"=== {title} ===");
            foreach (var item in source)
                Console.WriteLine(item);
        }
    }

    internal class Program
    {
        // A normal C# method (a database cannot translate it to SQL)
        static bool IsGoodName(string name) => name.Length > 8;

        // TODO (Task 4.3): write GetPage here
        // TODO (Task 5.1): write Search here

        static void Main(string[] args)
        {
            var db = new FakeDatabase();
            var employees = Repository.LoadEmployees();     // a plain in-memory list

            // ===================== PART 1: Same query, two executions =====================
            // TODO: Task 1.1 ... 1.6


            // ===================== PART 2: Seeing the query tree =====================
            // TODO: Task 2.1 ... 2.5


            // ===================== PART 3: The traps =====================
            // TODO: Task 3.1 ... 3.5


            // ===================== PART 4: Real queries at the source =====================
            // TODO: Task 4.1 ... 4.6


            // ===================== PART 5: Mixed =====================
            // TODO: Task 5.1 ... 5.5

            Console.ReadKey();
        }
    }
}
```

---

## Part 1: The same query, two executions

For every task: `db.ResetCounters()` first, run the query, then `db.ShowCounters(...)`.

**Task 1.1. (`IEnumerable`)** Get the employees older than 30 with `db.GetAllRows().Where(...)`, then `ToList()`. Print the count and the counters.
*Expected:* `5` employees; **rows transferred = 8**, round trips = 1. The server printed `SELECT * FROM Employees`.

**Task 1.2. (`IQueryable`)** Do the same with `db.Employees.Where(...)`.
*Expected:* `5` employees; **rows transferred = 5**, round trips = 1. The server printed `Employees.Where(e => (e.Age > 30))`.

**Task 1.3.** Complete the table by running both versions for each filter:

| Filter | Rows transferred with `IEnumerable` | Rows transferred with `IQueryable` |
|---|---|---|
| `Age > 30` | ? | ? |
| `Department == "IT"` | ? | ? |
| `Salary > 60000` | ? | ? |

*Expected:* `8` / `5`, `8` / `3`, `8` / `4`.

**Task 1.4. (`Count`)** Count the employees older than 30 with `GetAllRows().Count(...)` and with `Employees.Count(...)`.
*Expected:* `5` both times; rows transferred `8` vs `1`.

**Task 1.5. (`Any`)** Check if there is an employee older than 40 with both versions.
*Expected:* `True` both times; rows transferred `5` vs `1`.
Explain why the `IEnumerable` version transferred **5** rows and not 8. (Answer in a comment. Hint: where is Omar Khaled in the list, and when does `Any` stop?)

**Task 1.6. (`Sum`)** Calculate the total salary with both versions.
*Expected:* `510000` both times; rows transferred `8` vs `1`.

---

## Part 2: Seeing the query tree

**Task 2.1.** Build this query **without** running it:

```csharp
var q = db.Employees.Where(e => e.Age > 30).OrderBy(e => e.Name).Select(e => e.Name);
```

1. Show the counters **before** running it.
2. Print `q.Expression`.
3. Run it with `ToList()` and show the counters again.

*Expected:* before: rows `0`, trips `0`. The expression prints as `Employees.Where(e => (e.Age > 30)).OrderBy(e => e.Name).Select(e => e.Name)`. After: rows `5`, trips `1`; names `Mona Fathy, Nour Ibrahim, Omar Khaled, Salma Youssef, Sam Adel`.

**Task 2.2.** For the query `q` of Task 2.1 print `ElementType`, and the **type name** of `q.Provider`. Then print the results of:
- `db.Employees is IQueryable`,
- `db.GetAllRows() is IQueryable`,
- `db.Employees is IEnumerable<Employee>`.

*Expected:* `System.String`, `FakeQueryProvider`; `True`, `False`, `True`. What does the last line tell you about the relationship between the two interfaces? (Comment.)

**Task 2.3. (running the query again and again)**

```csharp
var itQuery = db.Employees.Where(e => e.Department == "IT");
```

1. Call `itQuery.Count()`, then `itQuery.ToList()` twice. Show the counters.
2. Reset and call `ToList()` **once**, then use the list three times (`Count`, loop, `First`). Show the counters.

*Expected:* first case: round trips `3`, rows `7` (1 + 3 + 3); second case: round trips `1`, rows `3`.

**Task 2.4. (composing at the source)** Chain **two** `Where` calls (`Age > 30`, then `Department == "IT"`). How many round trips? Print the query the server received.
*Expected:* round trips `1`, rows `3` (`Sam Adel, Omar Khaled, Mona Fathy`). The printed query contains **both** `Where` calls.

**Task 2.5. (`IEnumerable` is lazy too)** Call `db.GetAllRows()` and keep the result in a variable. Show the counters. Then loop over it and `break` after the **second** employee. Show the counters again.
*Expected:* first `0` rows, `0` trips (nothing ran yet); then rows `2`, round trips `1`.

---

## Part 3: The traps

**Task 3.1. (a `Func` instead of an `Expression`)**

```csharp
Func<Employee, bool> f = e => e.Age > 30;
Expression<Func<Employee, bool>> ex = e => e.Age > 30;
```

Run `db.Employees.Where(f).ToList()` and `db.Employees.Where(ex).ToList()`. Compare the printed query and the counters.
*Expected:* with `f` the server prints just `Employees` and **8** rows are transferred; with `ex` the server prints the `Where` and **5** rows are transferred. The result is `5` employees both times. Explain which `Where` method was used with `f` (comment).

**Task 3.2. (`ToList` too early)** Compare:
1. `db.Employees.ToList().Where(e => e.Age > 30).ToList()`
2. `db.Employees.Where(e => e.Age > 30).ToList()`

*Expected:* rows transferred `8` vs `5`.

**Task 3.3. (your own method inside the query)** Use `IsGoodName` (names longer than 8 letters):
1. `db.Employees.Where(e => IsGoodName(e.Name)).ToList()` and look at what the server received.
2. Filter `Age > 30` **at the source**, then `AsEnumerable()`, then apply `IsGoodName`.

*Expected:* in (1) the printed query contains `IsGoodName(e.Name)`, and `7` rows are transferred. In (2) `5` rows are transferred and the result is `4` employees (`Salma Youssef, Omar Khaled, Mona Fathy, Nour Ibrahim`).
In a comment, write what **Entity Framework Core** would do in case (1) (hint: it cannot translate your method to SQL).

**Task 3.4. (return types)** Write two methods:

```csharp
static IEnumerable<Employee> GetEmployeesEnumerable(FakeDatabase db) => db.Employees;
static IQueryable<Employee>  GetEmployeesQueryable(FakeDatabase db)  => db.Employees;
```

Call each, add `.Where(e => e.Age > 30).ToList()`, and compare the counters. Both methods return the same object.
*Expected:* rows transferred `8` vs `5`. Explain why the **declared return type** changes the result (comment).

**Task 3.5. (`AsQueryable` on a list)** Take the in-memory `employees` list and call `.AsQueryable().Where(e => e.Age > 30)`. Print the type name of its `Provider` and its `Expression`.
*Expected:* provider `EnumerableQuery`1`; the expression starts with `System.Collections.Generic.List`1[...Employee].Where(...)`. No `[DB]` line is printed. Explain in a comment: is the filter running "at the source" here?

---

## Part 4: Real queries at the source

**Task 4.1.** Get the **names of the IT employees**, sorted alphabetically.
*Expected:* `Mona Fathy, Omar Khaled, Sam Adel`; rows `3`, trips `1`.

**Task 4.2.** Get the **3 highest-paid employees** (names only).
*Expected:* `Omar Khaled, Sam Adel, Salma Youssef`; rows `3`.

**Task 4.3. (paging)** Write

```csharp
static IQueryable<Employee> GetPage(IQueryable<Employee> source, int page, int size)
```

that sorts by salary (highest first) and returns the requested page with `Skip` and `Take`. Test it with page 2 / size 3, then page 3 / size 3, then page 4 / size 3.
*Expected:*
- page 2: `Nour Ibrahim, Mona Fathy, Sara Hassan` (rows `3`),
- page 3: `Hany Samir, Ali Mahmoud` (rows `2`),
- page 4: empty (rows `0`).

**Task 4.4.** Calculate the **average salary** of all employees and the **total salary of the IT department**.
*Expected:* `63750` and `265000`; round trips `2`, rows transferred `2` (one value each).

**Task 4.5.** Count the employees **per department** (group at the source and project to `{ Department, Count }`).
*Expected:* `HR 2`, `IT 3`, `Finance 1`, `Sales 2`; rows transferred `4`.

**Task 4.6.** Get the employees whose name **starts with "S"**.
*Expected:* `Sara Hassan, Sam Adel, Salma Youssef`; rows `3`.

---

## Part 5: Mixed

**Task 5.1. (optional filters)** Write

```csharp
static IQueryable<Employee> Search(IQueryable<Employee> source, string department, int? minAge)
```

It must add the department condition **only if** `department` is not null, and the age condition (`Age >= minAge`) **only if** `minAge` has a value. Test with:

| `department` | `minAge` | Expected employees | Rows |
|---|---|---|---|
| `null` | `null` | all 8 | 8 |
| `"IT"` | `null` | Sam Adel, Omar Khaled, Mona Fathy | 3 |
| `"IT"` | `33` | Sam Adel, Omar Khaled | 2 |
| `null` | `33` | Sam Adel, Salma Youssef, Omar Khaled, Nour Ibrahim | 4 |

Each search must use **one** round trip, and only the matching rows must be transferred.

**Task 5.2.** Write the same `Search` method but with `IEnumerable<Employee>` as the parameter and return type. Call it with `db.GetAllRows()` for `("IT", 33)` and compare it with Task 5.1.
*Expected:* same `2` employees, but rows transferred `8` instead of `2`.

**Task 5.3.** What is wrong with this code? Count the rows transferred, then fix it so only **2** rows are transferred.

```csharp
var result = db.Employees.ToList()
                .Where(e => e.Department == "IT")
                .OrderBy(e => e.Salary)
                .Take(2);
```

*Expected:* the broken version transfers `8` rows; the fixed version (`Where`, `OrderBy`, `Take` **before** `ToList`) transfers `2` rows (`Mona Fathy`, `Sam Adel`).

**Task 5.4.** In a comment, choose `IEnumerable<T>`, `IQueryable<T>`, `Func<>`, `Expression<Func<>>` or `List<T>` for each case and say why:
1. A repository method whose callers may add more filters before the data is loaded.
2. A method that returns the final, complete list for a report.
3. A filter parameter that is sent to a database.
4. A filter parameter used on an array already in memory.
5. A method that only needs to loop once over some items.

**Task 5.5.** Put these operations in the right order for the **best performance** (all of them are needed): `ToList`, `Where`, `Select(e => e.Name)`, `OrderBy`, `Take(5)`. Explain your order.
*Expected:* `Where` → `OrderBy` → `Take(5)` → `Select(e => e.Name)` → `ToList` (the `ToList` is last).

---

## Challenge (optional)

Write an extension method

```csharp
public static IQueryable<T> Trace<T>(this IQueryable<T> query, string label)
```

that prints `label` and `query.Expression`, and **returns the same query**. Use it in the middle of a chain (for example after the `Where`) to see how the tree grows with each operator. Does calling `Trace` send anything to the database?
*Expected:* no. Printing the expression does not run the query.

---

## Submission checklist

- [ ] Every task prints the results and the counters
- [ ] You can explain where `Where` runs for `IEnumerable` and for `IQueryable`
- [ ] You can explain why a `Func` passed to an `IQueryable` silently loads everything
- [ ] You know why `ToList()` must come last
- [ ] You can explain why a repository method's return type matters
- [ ] You can explain why your own C# method cannot be used inside a database query
- [ ] You know when to use `AsEnumerable()`
