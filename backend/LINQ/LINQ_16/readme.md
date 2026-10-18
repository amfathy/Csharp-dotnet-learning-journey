# LINQ Session 17: `IEnumerable<T>` vs `IQueryable<T>`

Both interfaces let you write the same LINQ code (`Where`, `Select`, `OrderBy`...). The difference is **where and how the query runs**.

| | `IEnumerable<T>` | `IQueryable<T>` |
|---|---|---|
| In one sentence | "Here are the items, **you** loop over them" | "Here is a **description of a query**, someone else will run it" |
| Where the query runs | **In your program's memory** | In the **data source** (database, web service) through a *provider* |
| Extension methods from | `System.Linq.Enumerable` | `System.Linq.Queryable` |
| `Where` takes | `Func<T, bool>` (a delegate: compiled code) | `Expression<Func<T, bool>>` (an expression tree: data, Session 16) |
| What is built while you chain operators | A chain of iterators | One growing **expression tree** |
| Who understands your lambda | The .NET runtime (any C# code works) | The **provider** (only what it can translate, e.g. to SQL) |
| Typical sources | `List<T>`, arrays, `Dictionary`, files | EF Core `DbSet<T>`, OData, other LINQ providers |
| Rows that travel from the database | **All** of them, then you filter | **Only** the matching ones |
| Best for | Collections already in memory | Large remote data |

> `IQueryable<T>` **inherits** from `IEnumerable<T>`. Every queryable *is* an enumerable, which is what makes some mistakes silent (see section 5).

```csharp
public interface IQueryable<T> : IEnumerable<T>, IQueryable
{
    // from IQueryable:
    Type ElementType { get; }          // typeof(T)
    Expression Expression { get; }     // the query so far, as a tree
    IQueryProvider Provider { get; }    // the thing that can run the tree
}
```

---

## 1. The same query, two very different executions

```csharp
// IEnumerable: filter in memory
var a = db.GetAllRows()                    // the "server" sends EVERY row
         .Where(e => e.Age > 30)           // your program filters them
         .ToList();

// IQueryable: filter at the source
var b = db.Employees                       // nothing is sent yet
         .Where(e => e.Age > 30)           // added to the query tree
         .ToList();                        // now the tree is sent; only matching rows return
```

With 8 employees in the table, 5 of them older than 30:

| | Rows transferred | What the server saw |
|---|---|---|
| `IEnumerable` version | **8** | `SELECT * FROM Employees` |
| `IQueryable` version | **5** | `Employees.Where(e => (e.Age > 30))` |

With a real database of 10 million rows, this is the difference between a fast query and a crash.

With EF Core, the second query becomes real SQL:

```sql
SELECT ... FROM Employees WHERE Age > 30
```

---

## 2. How `IQueryable` works inside

Each operator **does not run anything**. It takes the current expression tree, wraps it with one more call, and hands the new tree to the provider.

```csharp
var q = db.Employees                       // tree:  Employees
          .Where(e => e.Age > 30)          // tree:  Employees.Where(e => e.Age > 30)
          .OrderBy(e => e.Name)            // tree:  Employees.Where(...).OrderBy(e => e.Name)
          .Select(e => e.Name);            // tree:  ...Select(e => e.Name)
```

Only when you **enumerate** (`foreach`, `ToList()`, `ToArray()`) or ask for a **single value** (`Count()`, `First()`, `Any()`, `Sum()`...) does the provider read the tree, translate it, run it, and return the result.

```csharp
Console.WriteLine(q.Expression);           // prints the tree, no query has run yet
```

| Step | `IEnumerable` | `IQueryable` |
|---|---|---|
| `Where(...)` | Creates an iterator | Creates a **bigger tree** |
| Execution | When enumerated | When enumerated (or a single value is requested) |
| Translation | None | Tree → SQL (or other language) |

---

## 3. Deferred execution applies to both

Neither runs when you build the query. But watch out for **running it more than once**:

```csharp
var q = db.Employees.Where(e => e.Department == "IT");   // 0 round trips

var n = q.Count();     // round trip 1:  SELECT COUNT(*) ...
q.ToList();            // round trip 2
q.ToList();            // round trip 3
```

Each enumeration goes back to the source. If you need the data more than once, **materialize it once** with `ToList()` and reuse the list.

---

## 4. Single values are computed at the source

```csharp
db.Employees.Count(e => e.Age > 30);     // SELECT COUNT(*) ... : one number comes back
db.Employees.Any(e => e.Age > 50);       // one boolean comes back
db.Employees.Sum(e => e.Salary);         // one number comes back
```

On an `IEnumerable`, `Count()` would first bring **all the rows** and count them in memory.

---

## 5. The traps

### Trap 1: a `Func` instead of an `Expression`

```csharp
Func<Employee, bool> filter = e => e.Age > 30;     // a delegate, not a tree

var result = db.Employees.Where(filter).ToList();  // compiles and "works"
```

Because `IQueryable<T>` is also an `IEnumerable<T>`, `Where(filter)` binds to **`Enumerable.Where`**. The provider only receives the plain query `Employees`, sends **every row**, and your program filters them. No error, no warning, much slower.

Fix: declare the filter as `Expression<Func<Employee, bool>>`.

### Trap 2: calling `ToList()` too early

```csharp
db.Employees.ToList().Where(e => e.Age > 30);      // loads everything, then filters in memory
db.Employees.Where(e => e.Age > 30).ToList();      // filters at the source, then loads
```

Rule: put `ToList()`, `ToArray()`, `AsEnumerable()` **last**, after all filtering, sorting and projection that the source can do.

### Trap 3: a method the provider cannot translate

```csharp
db.Employees.Where(e => IsGoodName(e.Name)).ToList();   // your own C# method
```

SQL does not know `IsGoodName`. With EF Core this throws an `InvalidOperationException` ("could not be translated") at run time. Fix: use only operations the provider supports inside the query, or filter first and then switch to memory:

```csharp
db.Employees
  .Where(e => e.Age > 30)          // at the source
  .AsEnumerable()                  // switch to memory here, on purpose
  .Where(e => IsGoodName(e.Name))  // your C# method, on the 5 rows that arrived
  .ToList();
```

### Trap 4: returning `IEnumerable<T>` from a repository method

```csharp
IEnumerable<Employee> GetEmployees() => db.Employees;        // callers' Where runs in MEMORY
IQueryable<Employee>  GetEmployees() => db.Employees;        // callers can keep composing at the source
```

If a method returns `IEnumerable<T>`, any `Where` the caller adds becomes an in-memory filter over the whole table. Return `IQueryable<T>` when callers should add more conditions, or return a finished `List<T>` when the query is complete.

### Trap 5: `AsQueryable()` on a `List` is not a database

```csharp
var q = employees.AsQueryable().Where(e => e.Age > 30);   // still runs in memory
```

It gives you an `IQueryable` **API** (useful for tests and for demonstrating expression trees), but nothing is translated. The data never leaves your program.

---

## 6. `AsEnumerable()` and `AsQueryable()`

| Method | Does | Use when |
|---|---|---|
| `AsEnumerable()` | Treats the rest of the query as `IEnumerable`: **in memory** from this point on | You need C# code the provider cannot translate |
| `AsQueryable()` | Wraps an `IEnumerable` so it has the `IQueryable` API | Tests, or code that accepts `IQueryable` |
| `ToList()` | Runs the query **now** and keeps the results | You need the data more than once |

```csharp
db.Employees
  .Where(e => e.Age > 30)                 // at the source
  .AsEnumerable()                         // from here on: in memory
  .Select(e => e.Name.ToUpper())          // any C# is fine now
  .ToList();
```

---

## 7. When to use which

| Situation | Use |
|---|---|
| Data already in memory (`List`, array) | `IEnumerable<T>` |
| Data in a database, and you want filtering/sorting/paging done there | `IQueryable<T>` |
| Method parameter for a filter that goes to a database | `Expression<Func<T, bool>>` |
| Method parameter for an in-memory filter | `Func<T, bool>` |
| A repository method that callers may keep filtering | `IQueryable<T>` |
| A method that returns the final data | `List<T>` / `IReadOnlyList<T>` |
| Parameters of a public method that only reads items | `IEnumerable<T>` |

---

## Cheat sheet

| I want... | Do |
|---|---|
| Only matching rows from the database | Keep the query as `IQueryable`; use `Expression<Func>` filters |
| To see what the provider receives | `query.Expression` (or `ToQueryString()` in EF Core) |
| To use my own C# method in the query | Filter at the source, then `.AsEnumerable()`, then my method |
| To avoid running the query twice | `ToList()` once and reuse the list |
| To check existence | `Any(...)` (a single value comes back) |
| To page results at the source | `OrderBy(...).Skip(n).Take(m)` **before** `ToList()` |

## About the practice data

There is no real database in this session. The tasks file contains a **fake database** that counts **rows transferred** and **round trips**, and prints the query it receives, so you can *see* the difference without installing anything:

```
db.GetAllRows()   → IEnumerable<Employee>  (every row is sent to you)
db.Employees      → IQueryable<Employee>   (the query is sent to the "server")
```

Everything you learn carries over to Entity Framework Core, where `db.Employees` would be a `DbSet<Employee>`.
