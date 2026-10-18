# LINQ Session 16: Tasks (Expression Trees)

## How to use

1. Create a new Console project (.NET 5 or later).
2. Replace `Program.cs` with the **Starter Code** below. It already has the data and helpers, so **no shared project is needed**.
3. Solve each task in its `// TODO` area and print the results with a clear label.
4. Some tasks ask you to try code that **does not compile** or **throws**. Write it, observe the error, record the message in a comment, then comment the code out (or wrap it in `try/catch`) so the program keeps running.

## The data

- A list of **8 employees** (`Name`, `Department`, `Age`, `Salary`, `YearsOfExperience`).

| Name | Department | Age | Salary | Years |
|---|---|---|---|---|
| Sara Hassan | HR | 29 | 45,000 | 3 |
| Sam Adel | IT | 34 | 90,000 | 7 |
| Ali Mahmoud | HR | 24 | 30,000 | 1 |
| Salma Youssef | Finance | 38 | 70,000 | 6 |
| Omar Khaled | IT | 45 | 120,000 | 10 |
| Mona Fathy | IT | 31 | 55,000 | 4 |
| Hany Samir | Sales | 27 | 38,000 | 2 |
| Nour Ibrahim | Sales | 33 | 62,000 | 5 |

- A few numbers to test small expressions.

---

## Starter Code (copy into `Program.cs`)

```csharp
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Linq.Expressions;

namespace LinqSession16Tasks
{
    // ---------- Model ----------
    public class Employee
    {
        public string Name { get; set; }
        public string Department { get; set; }
        public int Age { get; set; }
        public decimal Salary { get; set; }
        public int YearsOfExperience { get; set; }

        public override string ToString() =>
            $"{Name,-14} | {Department,-7} | {Age,2} | {Salary,8:N0} | {YearsOfExperience,2} yrs";
    }

    // ---------- Data ----------
    public static class Repository
    {
        public static List<Employee> LoadEmployees() => new()
        {
            new Employee { Name = "Sara Hassan",   Department = "HR",      Age = 29, Salary = 45_000,  YearsOfExperience = 3  },
            new Employee { Name = "Sam Adel",      Department = "IT",      Age = 34, Salary = 90_000,  YearsOfExperience = 7  },
            new Employee { Name = "Ali Mahmoud",   Department = "HR",      Age = 24, Salary = 30_000,  YearsOfExperience = 1  },
            new Employee { Name = "Salma Youssef", Department = "Finance", Age = 38, Salary = 70_000,  YearsOfExperience = 6  },
            new Employee { Name = "Omar Khaled",   Department = "IT",      Age = 45, Salary = 120_000, YearsOfExperience = 10 },
            new Employee { Name = "Mona Fathy",    Department = "IT",      Age = 31, Salary = 55_000,  YearsOfExperience = 4  },
            new Employee { Name = "Hany Samir",    Department = "Sales",   Age = 27, Salary = 38_000,  YearsOfExperience = 2  },
            new Employee { Name = "Nour Ibrahim",  Department = "Sales",   Age = 33, Salary = 62_000,  YearsOfExperience = 5  },
        };
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

    // ---------- TODO (Part 5): write your ExpressionVisitor classes here ----------


    internal class Program
    {
        static void Main(string[] args)
        {
            var employees = Repository.LoadEmployees();

            // ===================== PART 1: Func vs Expression =====================
            // TODO: Task 1.1 ... 1.7


            // ===================== PART 2: Reading (decomposing) a tree =====================
            // TODO: Task 2.1 ... 2.6


            // ===================== PART 3: Building a tree by hand =====================
            // TODO: Task 3.1 ... 3.8


            // ===================== PART 4: IEnumerable vs IQueryable =====================
            // TODO: Task 4.1 ... 4.4


            // ===================== PART 5: Mixed and visitors =====================
            // TODO: Task 5.1 ... 5.5

            Console.ReadKey();
        }
    }
}
```

---

## Part 1: `Func` vs `Expression`

**Task 1.1.** Create `Func<int, bool> IsEven = num => num % 2 == 0;`. Call it with `IsEven(10)` and with `IsEven.Invoke(10)`.
*Expected:* `True` and `True`.

**Task 1.2.** Create `Expression<Func<int, bool>> IsEvenExpression` with the same lambda. Compile it once and call it with `10` and `9`.
*Expected:* `True`, `False`.

**Task 1.3.** Print the `Func` and the `Expression` with `Console.WriteLine`. What is the difference?
*Expected:* `System.Func`2[System.Int32,System.Boolean]` and `num => ((num % 2) == 0)`.

**Task 1.4.** Try to call the expression directly: `IsEvenExpression(10)`. Write the compiler error in a comment, then comment the line out.
*Expected:* it does not compile (an expression tree is not a delegate).

**Task 1.5.** Try to assign each of these lambdas to an `Expression<Func<int, ...>>`. Write the **error code** of each in a comment, then comment them out:
1. a lambda with a **statement body**: `n => { return n > 0; }`,
2. a lambda with an **assignment**: `n => n++`.

*Expected:* `CS0834` for the statement body and `CS0832` for the assignment.

**Task 1.6.** Create `Expression<Func<int, int>>` for `x => x * x`. Print the tree and the compiled result for `5`.
*Expected:* `x => (x * x)` and `25`.

**Task 1.7.** Create an expression with **two parameters**: `(a, b) => a + b`. Print `Parameters.Count`, the expression text, and the compiled result for `(3, 4)`.
*Expected:* `2`, `(a, b) => (a + b)`, `7`.

---

## Part 2: Reading a tree

**Task 2.1.** For `Expression<Func<int, bool>> e = num => num < 0;` print (like the sample):
`num => num LessThan 0`.
Use `Parameters[0]`, `Body` (cast to `BinaryExpression`), `Left`, `NodeType` and `Right`.

**Task 2.2.** Do the same for `x => x > 10`.
*Expected:* `x => x GreaterThan 10`.

**Task 2.3.** Decompose `num => num % 2 == 0` step by step. Print:
- the `NodeType` of the body,
- the `NodeType` of its `Left`,
- the constant on the right of that `Left`,
- the constant on the right of the body.

*Expected:* `Equal`, `Modulo`, `2`, `0`.

**Task 2.4. (the cast trap)** Apply the casts from Task 2.1 to the tree of Task 2.3, i.e. `(ParameterExpression)operation.Left`. What happens? Then rewrite it safely with `is` pattern matching (`operation.Left is BinaryExpression ...`).
*Expected:* `InvalidCastException`, then correct output.

**Task 2.5. (a tree printer)** Write a method `static void Describe(Expression e, int indent = 0)` that prints the tree, one node per line, indented by depth. It must handle `BinaryExpression`, `ParameterExpression` and `ConstantExpression`. Test it with the **body** of `num => num % 2 == 0`.
*Expected output:*

```
Equal
  Modulo
    Parameter num
    Constant 2
  Constant 0
```

**Task 2.6. (properties)** Decompose `Expression<Func<Employee, bool>> e = emp => emp.Age > 30;`. The left side is a `MemberExpression`. Print the member name and the parameter name it belongs to.
*Expected:* `emp => emp.Age GreaterThan 30`.
*Hint:* `((MemberExpression)left).Member.Name` and `.Expression`.

---

## Part 3: Building a tree by hand

**Task 3.1.** Build `num => num % 2 == 0` using only `Expression.Parameter`, `Constant`, `Modulo`, `Equal` and `Lambda`. Compile it and test `10` and `9`. Print its text.
*Expected:* `True`, `False`, `num => ((num % 2) == 0)`.

**Task 3.2.** Build `x => x * x + 1`. Test it with `5`.
*Expected:* `26`.

**Task 3.3.** Build `(a, b) => a > b ? a : b` with `Expression.Condition`. Test with `(3, 7)` and `(9, 2)`.
*Expected:* `7` and `9`.

**Task 3.4.** Build `emp => emp.Age > 30` with `Expression.Property`. Compile it and filter `employees`.
*Expected:* `5` employees (`Sam Adel, Salma Youssef, Omar Khaled, Mona Fathy, Nour Ibrahim`).

**Task 3.5.** Build `emp => emp.Name.StartsWith("S")` with `Expression.Call`.
*Hint:* `typeof(string).GetMethod("StartsWith", new[] { typeof(string) })`.
*Expected:* `3` employees (`Sara Hassan, Sam Adel, Salma Youssef`).

**Task 3.6.** Build `emp => emp.Age > 30 && emp.Department == "IT"` using **one** parameter and `Expression.AndAlso`.
*Expected:* `3` employees (`Sam Adel, Omar Khaled, Mona Fathy`).

**Task 3.7. (dynamic filter)** Write:

```csharp
static Expression<Func<Employee, bool>> BuildFilter(string propertyName, int threshold)
```

It builds `emp => emp.<propertyName> > threshold`. Test it with `("Age", 30)` and `("YearsOfExperience", 5)`.
*Expected:* `5` employees, then `3` (`Sam Adel, Salma Youssef, Omar Khaled`).

**Task 3.8. (types must match)** Build `emp => emp.Salary > 60000`. First use `Expression.Constant(60000)` (an `int`): what happens? Then fix it two ways: `Expression.Constant(60000m)` and `Expression.Convert(...)`.
*Expected:* `InvalidOperationException` (the operator is not defined for `Decimal` and `Int32`), then `4` employees (`Sam Adel, Salma Youssef, Omar Khaled, Nour Ibrahim`).

---

## Part 4: `IEnumerable` vs `IQueryable`

**Task 4.1.** Create `IQueryable<Employee> q = employees.AsQueryable().Where(e => e.Age > 30);`. Print `q.Expression`. What do you see: the **result** or a **description**?
*Expected:* a description of the call (the query as a tree), not the employees.

**Task 4.2.** Create both:

```csharp
Func<Employee, bool> f = e => e.Age > 30;
Expression<Func<Employee, bool>> ex = e => e.Age > 30;
```

Use `f` with `employees.Where(f)` and `ex` with `employees.AsQueryable().Where(ex)`. Compare the counts.
*Expected:* `5` both times.

**Task 4.3. (the silent trap)** With `IQueryable<Employee> q = employees.AsQueryable();` call `q.Where(f)` (the `Func`) and `q.Where(ex)` (the `Expression`). Print `GetType().Name` of each result. Which `Where` was used each time (`Enumerable` or `Queryable`)? Explain in a comment why this matters with a database.
*Expected:* both give `5` employees, but with `ex` the result is an `EnumerableQuery`1`; with `f` it is a plain LINQ iterator, because `Enumerable.Where` ran **in memory** (with a database, the whole table would be loaded first).

**Task 4.4. (compile cost)** Use `Stopwatch` to compare:
1. compiling `IsEvenExpression` **10,000 times** (once per call),
2. compiling it **once** and calling the delegate 10,000 times.

*Expected:* the first is **much** slower. Write the lesson in a comment.

---

## Part 5: Mixed and visitors

**Task 5.1. (captured variables)**

```csharp
string dept = "IT";
Expression<Func<Employee, bool>> e = x => x.Department == dept;
```

Look at the `Right` side of the body. What is its `NodeType`? Try casting it to `ConstantExpression`. Then get its value (hint: `Expression.Lambda(right).Compile().DynamicInvoke()`). Repeat with the literal `"IT"` instead of the variable.
*Expected:* `MemberAccess`, `InvalidCastException`, value `"IT"`; with the literal the node is `Constant`.

**Task 5.2. (a visitor)** Write a class `ConstantCollector : ExpressionVisitor` that overrides `VisitConstant` and stores every constant value in a list. Test it with:
1. `num => num % 2 == 0`,
2. `x => x * 3 + 7 > 20`.

*Expected:* `2, 0` and `3, 7, 20`.

**Task 5.3. (dynamic search)** Write

```csharp
static Expression<Func<Employee, bool>> BuildEqualsFilter(Dictionary<string, object> conditions)
```

that combines `emp.<property> == <value>` conditions with `AndAlso`. Test with:
1. `{ Department = "IT" }`,
2. `{ Department = "IT", Age = 45 }`.

*Expected:* `3` employees, then `Omar Khaled`.
*Hint:* `Expression.Constant(value, property.Type)`.

**Task 5.4. (harder)** Given two separate expressions:

```csharp
Expression<Func<Employee, bool>> a = emp => emp.Age > 30;
Expression<Func<Employee, bool>> b = emp => emp.Department == "IT";
```

combine them into one `a && b`. Their parameters are **different objects**, so you must make `b` use the parameter of `a`. Write a small `ParameterReplacer : ExpressionVisitor` (override `VisitParameter`) to do it.
*Expected:* `Sam Adel, Omar Khaled, Mona Fathy`.

**Task 5.5.** In a comment, decide if you would use `Func<>` or `Expression<Func<>>` and why:
1. A filter passed to Entity Framework Core.
2. A button-click callback that runs in memory.
3. A search screen where the user picks the column and the operator.
4. Showing the text of a validation rule in an error message.
5. A rule compiled once and run a million times on in-memory objects.

---

## Challenge (optional)

1. Write a visitor `AddToSubtract : ExpressionVisitor` that turns `x => x + 5` into `x => x - 5`. Compile and test with `10`.
   *Expected:* `5`.
2. Write `Expression<Func<T, bool>> Not<T>(Expression<Func<T, bool>> e)` that returns the opposite rule, and test it with `emp => emp.Age > 30`.
   *Expected:* the other `3` employees (`Sara Hassan, Ali Mahmoud, Hany Samir`).

---

## Submission checklist

- [ ] Every task prints a clear, labeled result
- [ ] You can explain the difference between `Func<>` and `Expression<Func<>>`
- [ ] You can explain why `Compile()` should be called once, not in a loop
- [ ] You can read a tree: parameters, body, node type, left, right
- [ ] You can build a simple tree with the `Expression` factory methods
- [ ] You can explain why `IQueryable.Where(Func)` is a silent performance trap
- [ ] You know why a captured variable is a `MemberAccess`, not a `Constant`
