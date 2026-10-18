# LINQ Session 14: Aggregation (`Aggregate`, `Count`, `Sum`, `Average`, `Min`, `Max`)

Aggregation operators **reduce a whole sequence to a single value**: a total, a count, an average, the biggest item, a joined string...

| Operator | Returns | Example |
|---|---|---|
| `Count()` / `LongCount()` | Number of items (`int` / `long`) | How many questions? |
| `Sum(selector)` | Total | Total marks |
| `Average(selector)` | Mean | Average mark |
| `Min(selector)` / `Max(selector)` | Smallest / largest **value** | Highest mark |
| `MinBy(selector)` / `MaxBy(selector)` | The **item** with the smallest / largest value (.NET 6+) | The question with the highest mark |
| `Aggregate(...)` | Anything: you write the rule | Longest title, comma-joined text, factorial |

> All of these run **immediately** (they return a value, not a sequence).
> There is no query-syntax keyword for them. Wrap the query in parentheses: `(from q in quiz where q.Marks == 1 select q).Count()`.

---

## 1. `Count` and `LongCount`

```csharp
var quiz = QuestionBank.GetQuestionRange(Enumerable.Range(1, 200));

quiz.Count();                                  // all questions
quiz.Count(x => x.Marks == 1);                 // questions that match a rule
quiz.Where(x => x.Marks == 1).Count();         // same result
quiz.Where(x => x.Marks == 1).LongCount();     // same, but returns a long
```

- `Count(rule)` is shorter than `Where(rule).Count()` and gives the same result.
- `LongCount` is for sequences that may have more than 2,147,483,647 items. For everyday work use `Count`.
- Only need to know if something exists? Use `Any()` (Session 7), not `Count() > 0`.

---

## 2. `Sum` and `Average`

```csharp
var total   = quiz.Sum(x => x.Marks);          // total marks
var average = quiz.Average(x => x.Marks);      // average mark
Console.WriteLine($"average: {average:0.##}");
```

| Rule | Detail |
|---|---|
| `Sum` of an **empty** sequence | `0` (no exception) |
| `Average` of an **empty** sequence | Throws `InvalidOperationException` |
| `Average` of `int` values | Returns a `double` (so `{1, 2, 4}` gives `2.333...`, not `2`) |
| `Average` of `decimal` values | Returns a `decimal` |
| `Sum` of `int` values | Can **overflow** and throws `OverflowException`. Sum as `long`: `Sum(x => (long)x)` |
| Nullable values (`int?`) | `null` items are **ignored** |

### Formatting the average

`average.ToString("#.##")` drops the leading zero for values below 1 (`0.5` becomes `.5`), and a value of exactly `0` becomes an empty string. Prefer `"0.##"` or `"F2"`.

---

## 3. `Min`, `Max`, `MinBy`, `MaxBy`

```csharp
var highestMark = quiz.Max(x => x.Marks);        // a number, e.g. 3
var lowestMark  = quiz.Min(x => x.Marks);        // a number, e.g. 1

var hardest = quiz.MaxBy(x => x.Marks);          // the Question object itself
var easiest = quiz.MinBy(x => x.Marks);          // the Question object itself
```

### `Max` vs `MaxBy`

| | `Max(x => x.Marks)` | `MaxBy(x => x.Marks)` |
|---|---|---|
| Returns | The **value** (`3`) | The **item** (the whole question) |
| Use when | You only need the number | You need to know **which** item |
| .NET version | All | **.NET 6+** |

Without `MaxBy` you would write `quiz.OrderByDescending(x => x.Marks).First()`, which sorts the whole list just to find one item.

### Important rules
- **Ties:** if several items share the maximum, `MaxBy` and `MinBy` return the **first** one.
- **Empty sequence:** `Min`, `Max`, `Average` throw `InvalidOperationException` for **non-nullable** types (`int`, `double`...). For reference types (`MaxBy` on a class list) an empty sequence gives `null`.

```csharp
var none = quiz.Where(x => x.Choices.Count < 2);

// none.Max(x => x.Marks);                            // throws: Sequence contains no elements
none.Select(x => (int?)x.Marks).Max();                // null
none.Select(x => x.Marks).DefaultIfEmpty(0).Max();    // 0
```

- `Max` and `Min` also work on `string` (alphabetical order), `DateTime`, and anything comparable.

---

## 4. `Aggregate`: build your own rule

`Aggregate` walks through the sequence and keeps an **accumulator** (a running result). For each item you combine the accumulator with the item and return the new accumulator.

```csharp
(accumulator, next) => newAccumulator
```

### Overload 1: without a seed

The **first item** becomes the starting accumulator.

```csharp
var names = new[] { "Ali", "Salem", "Abeer", "Reem", "Jalal" };

var joined = names.Aggregate((a, b) => $"{a},{b}");
// Ali,Salem,Abeer,Reem,Jalal
```

Step by step:

| Step | `a` (accumulator) | `b` (next) | Returns |
|---|---|---|---|
| 1 | `Ali` | `Salem` | `Ali,Salem` |
| 2 | `Ali,Salem` | `Abeer` | `Ali,Salem,Abeer` |
| 3 | `Ali,Salem,Abeer` | `Reem` | `Ali,Salem,Abeer,Reem` |
| 4 | `Ali,Salem,Abeer,Reem` | `Jalal` | `Ali,Salem,Abeer,Reem,Jalal` |

With 5 items the function is called **4 times**. On an **empty** sequence this overload throws `InvalidOperationException`.

### Overload 2: with a seed

You choose the **starting value**. The seed also sets the result type.

```csharp
var numbers = new[] { 1, 2, 3, 4, 5 };

var total = numbers.Aggregate(2, (a, b) => a + b);    // 2 + 1 + 2 + 3 + 4 + 5 = 17   (not 15!)
```

The seed is **part of the result**. Use `0` as the seed for a plain sum, `1` for a product.

```csharp
Enumerable.Range(1, 5).Aggregate(1, (a, b) => a * b);     // 120  (5 factorial)
"linq".Aggregate("", (acc, c) => c + acc);                // "qnil"  (reverse a string)
```

With a seed, the function runs once for **every** item (5 items: 5 calls), and an empty sequence simply returns the seed.

> **Overflow warning:** `Enumerable.Range(1, 13).Aggregate(1, (a, b) => a * b)` silently wraps around (a wrong number), because `int` overflows. Use a `long` seed: `Aggregate(1L, (a, b) => a * b)`.

### Overload 3: seed + result selector

The last parameter converts the final accumulator into the value you return.

```csharp
var quiz = QuestionBank.All;
var firstQuestion = quiz[0];

var longestQuestion = quiz.Aggregate(
    firstQuestion,                                                          // seed
    (longest, next) => longest.Title.Length < next.Title.Length ? next : longest,   // rule
    x => x);                                                                // result selector (here: unchanged)
```

Use a real result selector when the accumulator differs from what you want back:

```csharp
quiz.Aggregate(quiz[0],
               (longest, next) => longest.Title.Length < next.Title.Length ? next : longest,
               q => q.Title);          // returns only the longest TITLE (a string)
```

### The three overloads together

| Overload | Starts with | Empty sequence | Result type |
|---|---|---|---|
| `Aggregate(func)` | first item | throws | same as item |
| `Aggregate(seed, func)` | the seed | returns the seed | type of the seed |
| `Aggregate(seed, func, resultSelector)` | the seed | returns `resultSelector(seed)` | whatever the selector returns |

### Ties in the "longest" example

The rule uses `<` (strictly shorter). If two items have the same length, the **earlier one stays**. Use `<=` to prefer the later one.

### `Aggregate` is the general tool

Everything else in this session can be written with `Aggregate`:

```csharp
numbers.Aggregate(0, (acc, n) => acc + n);                   // Sum
numbers.Aggregate(0, (acc, n) => acc + 1);                   // Count
numbers.Aggregate(int.MinValue, (acc, n) => Math.Max(acc, n)); // Max
```

But the built-in operators are shorter and clearer, so use `Aggregate` only when nothing else fits. For joining text, `string.Join(",", names)` is better than `Aggregate`.

---

## Cheat sheet

| I want... | Use |
|---|---|
| How many items | `Count()` |
| How many match a rule | `Count(rule)` |
| Total | `Sum(x => x.Value)` |
| Average | `Average(x => x.Value)` |
| Biggest / smallest value | `Max(...)` / `Min(...)` |
| The item with the biggest / smallest value | `MaxBy(...)` / `MinBy(...)` |
| Join text with a separator | `string.Join(",", items)` |
| A custom running result | `Aggregate(seed, (acc, item) => ...)` |
| Safe max of a possibly empty list | `.DefaultIfEmpty(0).Max()` |

## Run the examples

```
LINQTut14.Aggregation      → RunMethod01 (comma-join), RunMethod02 (sum with seed), RunMethod03 (longest title)
LINQTut14.StandardMethod   → RunCount, RunMax, RunMaxBy, RunMin, RunMinBy, RunSum, RunAvg
```

## Things to notice in the sample code

- **`MaxBy` / `MinBy` need .NET 6.** If the project file still says `net5.0`, they will not compile. Change `<TargetFramework>` to `net6.0` or later.
- **`RunMethod02` prints `17`, not `15`**, because the seed `2` is included in the sum.
- **`RunMethod01` never prints `commaSeparatedNames`.** It only prints the `a = ..., b = ...` steps inside the lambda. Add a `Console.WriteLine` for the final result.
- **`x => x` in `RunMethod03` does nothing.** It is the identity. Use `q => q.Title` to see a useful result selector, or drop it and use the two-argument overload.
- **`QuestionBank.GetQuestionRange(Enumerable.Range(1, 200))`** uses `Range(start, count)` as zero-based **indexes**, so it skips index `0` (the first question) and returns Q #2 to Q #201. Use `Range(0, 200)` for the first 200.
- **`RunMin` stores the minimum in a variable called `maximumMark`.** The result is right, but the name is misleading.
- **`average.ToString("#.##")`** hides the leading zero for values below 1. Use `"0.##"`.
- **`Main` runs one method at a time** (`RunMethod03` and `RunAvg`). Uncomment or call the others to see them all.
