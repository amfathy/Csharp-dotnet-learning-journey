# LINQ Session 16: Expression Trees

An **expression tree** represents code **as data**. Instead of a compiled method you can run, you get an **object structure** that describes the code, which you can **read**, **change**, **build** and **translate** (for example into SQL).

```csharp
Func<int, bool> IsEven = num => num % 2 == 0;                    // code you can RUN
Expression<Func<int, bool>> IsEvenExpr = num => num % 2 == 0;    // code you can READ (a tree)
```

The **same lambda text** produces two very different things, depending on the type it is assigned to.

| | `Func<int, bool>` | `Expression<Func<int, bool>>` |
|---|---|---|
| What it is | A **delegate** (compiled code) | A **tree of objects** describing the code |
| Can be called directly | Yes: `IsEven(10)` | **No.** Call `.Compile()` first |
| Can be inspected | No | Yes: parameters, body, operators, constants |
| Can be translated (SQL, JSON...) | No | **Yes** (this is the whole point) |
| Namespace | `System` | `System.Linq.Expressions` |

---

## 1. Func vs Expression (example 1)

```csharp
Func<int, bool> IsEven = (num) => num % 2 == 0;
Console.WriteLine(IsEven(10));            // True
Console.WriteLine(IsEven.Invoke(10));     // True  (exactly the same thing)

Expression<Func<int, bool>> IsEvenExpression = (num) => num % 2 == 0;
Func<int, bool> IsEvenV2 = IsEvenExpression.Compile();   // tree → runnable delegate
Console.WriteLine(IsEvenV2(10));          // True
```

- `IsEven(10)` and `IsEven.Invoke(10)` are the same call.
- `IsEvenExpression(10)` does **not** compile. A tree is not callable.
- `.Compile()` turns the tree into a delegate. It is **slow** (it generates code), so compile **once** and reuse the delegate; do not compile inside a loop.

Printing the two shows the difference:

```csharp
Console.WriteLine(IsEven);              // System.Func`2[System.Int32,System.Boolean]   (just a type name)
Console.WriteLine(IsEvenExpression);    // num => ((num % 2) == 0)                       (the code itself!)
```

---

## 2. Reading a tree (example 2)

An expression tree is made of **nodes**. For `num => num < 0`:

```
LambdaExpression  (num => num < 0)
├── Parameters:  [ num ]                    ParameterExpression
└── Body:        LessThan                   BinaryExpression
                 ├── Left:   num            ParameterExpression
                 └── Right:  0              ConstantExpression
```

```csharp
Expression<Func<int, bool>> IsNegativeExpression = (num) => num < 0;

ParameterExpression numParam = IsNegativeExpression.Parameters[0];
BinaryExpression operation   = (BinaryExpression)IsNegativeExpression.Body;
ParameterExpression left     = (ParameterExpression)operation.Left;
ConstantExpression right     = (ConstantExpression)operation.Right;

Console.WriteLine($"{numParam.Name} => {left.Name} {operation.NodeType} {right.Value}");
// num => num LessThan 0
```

### The most useful properties

| Member | Meaning |
|---|---|
| `Parameters` | The lambda's parameters |
| `Body` | The expression after `=>` |
| `NodeType` | What kind of node it is (`LessThan`, `Add`, `Constant`, `Call`...) |
| `Type` | The .NET type the node produces |
| `Left` / `Right` | The two sides of a `BinaryExpression` |
| `Value` | The value of a `ConstantExpression` |

### Common node classes

| Class | Example in code | `NodeType` |
|---|---|---|
| `ParameterExpression` | `num` | `Parameter` |
| `ConstantExpression` | `0`, `"IT"` | `Constant` |
| `BinaryExpression` | `a + b`, `a < b`, `a && b` | `Add`, `LessThan`, `AndAlso`... |
| `UnaryExpression` | `-x`, `!x`, a type conversion | `Negate`, `Not`, `Convert` |
| `MemberExpression` | `emp.Age` | `MemberAccess` |
| `MethodCallExpression` | `name.StartsWith("S")` | `Call` |
| `ConditionalExpression` | `a > b ? a : b` | `Conditional` |

### Careful with casts

The casts in example 2 only work because the body is **exactly** `num < 0`. The tree for `num % 2 == 0` is deeper:

```
Equal
├── Left:  Modulo         ← a BinaryExpression, NOT a ParameterExpression
│          ├── num
│          └── 2
└── Right: 0
```

`(ParameterExpression)operation.Left` would throw `InvalidCastException` there. Use pattern matching instead:

```csharp
if (operation.Left is ParameterExpression p) { ... }
else if (operation.Left is BinaryExpression b) { ... }
```

---

## 3. Building a tree by hand (example 3)

You can create the same tree **without writing a lambda**, using the factory methods of the `Expression` class. Target: `num => num % 2 == 0`.

```csharp
ParameterExpression numParam = Expression.Parameter(typeof(int), "num");     // num
ConstantExpression  twoConst  = Expression.Constant(2, typeof(int));         // 2
ConstantExpression  zeroConst = Expression.Constant(0, typeof(int));         // 0

BinaryExpression modulo = Expression.Modulo(numParam, twoConst);             // num % 2
BinaryExpression isEven = Expression.Equal(modulo, zeroConst);               // (num % 2) == 0

Expression<Func<int, bool>> IsEvenExpression =
    Expression.Lambda<Func<int, bool>>(isEven, numParam);                    // num => ...

var compiled = IsEvenExpression.Compile();
Console.WriteLine(compiled(10));   // True
Console.WriteLine(compiled(9));    // False
```

**Read it inside-out**, from the smallest pieces to the whole lambda.

### Factory methods

| To build... | Use |
|---|---|
| a parameter | `Expression.Parameter(typeof(int), "num")` |
| a constant | `Expression.Constant(2)` |
| `a + b`, `a - b`, `a * b`, `a / b`, `a % b` | `Add`, `Subtract`, `Multiply`, `Divide`, `Modulo` |
| `a == b`, `a != b` | `Equal`, `NotEqual` |
| `a > b`, `a >= b`, `a < b`, `a <= b` | `GreaterThan`, `GreaterThanOrEqual`, `LessThan`, `LessThanOrEqual` |
| `a && b`, `a \|\| b`, `!a` | `AndAlso`, `OrElse`, `Not` |
| `x.Age` | `Expression.Property(x, "Age")` |
| `x.Name.StartsWith("S")` | `Expression.Call(instance, methodInfo, arguments)` |
| `cond ? a : b` | `Expression.Condition(cond, a, b)` |
| a type conversion | `Expression.Convert(expr, typeof(double))` |
| the lambda itself | `Expression.Lambda<Func<...>>(body, parameters)` |

### Types must match exactly

```csharp
// emp.Salary is decimal; 5000 is an int:
Expression.GreaterThan(salaryProperty, Expression.Constant(5000));
// InvalidOperationException: The binary operator GreaterThan is not defined for the types 'System.Decimal' and 'System.Int32'.

Expression.GreaterThan(salaryProperty, Expression.Constant(5000m));   // OK
// or convert: Expression.Convert(Expression.Constant(5000), typeof(decimal))
```

When you write a lambda, the **compiler** inserts these conversions. When you build by hand, **you** must.

### Why build by hand?

When the shape of the code is only known at **run time**: a filter chosen by the user ("Age greater than 30"), a column name stored in a string, a search screen with optional conditions.

```csharp
static Expression<Func<Employee, bool>> BuildFilter(string propertyName, int threshold)
{
    var emp  = Expression.Parameter(typeof(Employee), "emp");
    var prop = Expression.Property(emp, propertyName);                 // emp.<propertyName>
    var body = Expression.GreaterThan(prop, Expression.Constant(threshold));
    return Expression.Lambda<Func<Employee, bool>>(body, emp);
}

var filter = BuildFilter("Age", 30);       // emp => emp.Age > 30
```

---

## 4. Why expression trees matter: `IEnumerable` vs `IQueryable`

LINQ has **two** versions of `Where`, `Select`, `OrderBy`...

| | `IEnumerable<T>` (LINQ to Objects) | `IQueryable<T>` (LINQ providers: EF Core...) |
|---|---|---|
| Defined in | `System.Linq.Enumerable` | `System.Linq.Queryable` |
| `Where` takes | `Func<T, bool>` | `Expression<Func<T, bool>>` |
| Runs | In memory, in your program | The provider **reads the tree** and translates it (e.g. to SQL) |

```csharp
// EF Core: this lambda is an expression tree
var result = db.Employees.Where(e => e.Age > 30).ToList();
// the provider turns the tree into:  SELECT ... FROM Employees WHERE Age > 30
```

The database cannot run C# delegates, but it **can** understand a tree that says "Age greater than 30".

### The silent trap

```csharp
Func<Employee, bool> filter = e => e.Age > 30;      // a delegate, NOT a tree

var result = db.Employees.Where(filter).ToList();   // compiles!
```

Because `IQueryable<T>` is also an `IEnumerable<T>`, this binds to the **in-memory** `Enumerable.Where`. EF Core loads **the whole table** into memory and filters it in C#. Slow, but no error. When working with databases, keep predicates typed as `Expression<Func<...>>`.

You can also see an expression tree with in-memory data:

```csharp
IQueryable<Employee> q = employees.AsQueryable().Where(e => e.Age > 30);
Console.WriteLine(q.Expression);    // shows the query as a tree, not a result
```

---

## 5. Limits of expression trees

A lambda can become an expression tree only if it is a **single expression**:

```csharp
Expression<Func<int, bool>> ok  = n => n > 0;                      // OK
Expression<Func<int, bool>> bad = n => { return n > 0; };          // error: statement body
Expression<Func<int, int>>  bad2 = n => n++;                       // error: assignment/increment
```

Not allowed inside the lambda: statement bodies (`{ ... }`), assignments, `++`/`--`, the null-conditional `?.`, `await`, `dynamic`.

Trees are also **immutable**: you cannot change a node. To "modify" one you build a **new** tree, usually with an `ExpressionVisitor` (a class that walks a tree and can rebuild parts of it).

---

## 6. Variables captured by a lambda are not constants

```csharp
string dept = "IT";
Expression<Func<Employee, bool>> e = x => x.Department == dept;
```

The right side is **not** a `ConstantExpression`. It is a `MemberExpression` that reads the field of a compiler-generated "closure" object. Casting it to `ConstantExpression` throws. Providers such as EF Core evaluate it to get the value (here `"IT"`) and send it as a SQL parameter.

---

## Cheat sheet

| I want to... | Use |
|---|---|
| Run a lambda | `Func<...>` and call it |
| Keep a lambda as inspectable data | `Expression<Func<...>>` |
| Run an expression tree | `expr.Compile()` once, then call the delegate |
| See the code of a tree | `expr.ToString()` |
| Read the parts | `expr.Parameters`, `expr.Body`, `.NodeType`, `.Left`, `.Right` |
| Build one at run time | `Expression.Parameter`, `Constant`, `Property`, `GreaterThan`, `AndAlso`, `Lambda` |
| Walk or rewrite a tree | A class that derives from `ExpressionVisitor` |
| Make EF Core filter in the database | Pass `Expression<Func<T,bool>>`, not `Func<T,bool>` |

## Run the examples

```
LINQTut16.ExpressionTree01   → Func vs Expression, Compile()
LINQTut16.ExpressionTree02   → decomposing an expression
LINQTut16.ExpressionTree03   → building an expression by hand
LINQTut16.ExpressionTree04   → (empty placeholder)
```

## Things to notice in the sample code

- **Example 2 only works for `num < 0`.** The casts assume a very specific shape. Try it with `num % 2 == 0` and you get `InvalidCastException`, which is a good live demo.
- **In example 3 the variables `zeroParam` and `twoParam` are constants, not parameters.** Only `numParam` is a `ParameterExpression`. Names like `zeroConst` and `twoConst` are clearer.
- **Example 3 compiles the tree and calls it with `10` and `9`**, which proves the hand-built tree behaves like the lambda `num => num % 2 == 0`.
- **Example 4 is empty.** It is a good place for a demo such as `BuildFilter(...)` (a filter chosen at run time) or an `ExpressionVisitor`.
- **`Compile()` is called once and the delegate reused** in the samples, which is the right habit.
