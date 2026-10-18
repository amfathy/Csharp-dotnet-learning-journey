# LINQ Session 14: Tasks (`Aggregate`, `Count`, `Sum`, `Average`, `Min`, `Max`)

## How to use

1. Create a new Console project using **.NET 6 or later** (`MaxBy` and `MinBy` need it).
2. Replace `Program.cs` with the **Starter Code** below. It already has the data, classes and helpers, so **no shared project is needed**.
3. Solve each task in its `// TODO` area and print the results with a clear label.
4. For tasks that should **throw**, wrap the call in `try/catch` and print the exception type.

## The data

- **Question bank of 12 questions.** Each question has `Title`, `Choices`, `CorrectAnswer` and **`Marks`** (1, 2 or 3).

| Marks | Questions | Count |
|---|---|---|
| 1 | Q #1, #2, #6, #7, #8 | 5 |
| 2 | Q #3, #4, #5, #9, #11 | 5 |
| 3 | Q #10, #12 | 2 |

  Number of choices: `Q #1` and `Q #7` have 2, `Q #6` and `Q #8` have 3, all the others have 4.
- **Products** (`Name`, `Price`, `Quantity`): Laptop, Phone, Tablet, Monitor, Mouse.
- Small lists of numbers and names.

---

## Starter Code (copy into `Program.cs`)

```csharp
using System;
using System.Collections.Generic;
using System.Linq;

namespace LinqSession14Tasks
{
    // ---------- Models ----------
    public class Choice
    {
        public int Order { get; set; }
        public string Description { get; set; }
    }

    public class Question
    {
        public string Title { get; set; }
        public List<Choice> Choices { get; set; } = new();
        public int CorrectAnswer { get; set; }
        public int Marks { get; set; }

        public override string ToString() => $"{Title}  [{Marks} mark(s), {Choices.Count} choices]";
    }

    public class Product
    {
        public string Name { get; set; }
        public decimal Price { get; set; }
        public int Quantity { get; set; }

        public override string ToString() => $"{Name} ({Price:N0} x {Quantity})";
    }

    // ---------- Data ----------
    public static class QuestionBank
    {
        private static Question Q(int n, string title, int marks, int correct, params string[] choices) =>
            new Question
            {
                Title = $"Q #{n}: {title}",
                Marks = marks,
                CorrectAnswer = correct,
                Choices = choices.Select((text, i) => new Choice { Order = i + 1, Description = text }).ToList()
            };

        public static readonly List<Question> All = new()
        {
            Q(1,  "Streaming stored audio/video is sometimes referred to as on-demand audio/video", 1, 1,
                  "True", "False"),
            Q(2,  "Quantization refers to", 1, 1,
                  "Sampling in the voltage dimension", "Sampling in the frequency dimension",
                  "Sampling in the time dimension", "Sampling in the bitrate dimension"),
            Q(3,  "Nyquist theorem states", 2, 1,
                  "If the highest frequency is f, sample 2f times per second",
                  "If the highest frequency is f, sample f times per second",
                  "If the highest frequency is f, sample 3f times per second",
                  "If the highest frequency is f, sample 4f times per second"),
            Q(4,  "Converting analog audio to compressed binary form (sampling, quantization, encoding) is known as", 2, 1,
                  "Pulse code modulation", "Polar quantization", "Pulse code quantization", "Polar code modulation"),
            Q(5,  "The 3 categories that MPEG divides its frames into are", 2, 1,
                  "I-frames, P-frames, and B-frames", "A-frames, B-frames, and C-frames",
                  "B-frames, P-frames, and R-frames", "T-frames, I-frames, and B-frames"),
            Q(6,  "___________ is an independent frame that is not related to any other frame", 1, 1,
                  "I-frames", "P-frames", "B-frames"),
            Q(7,  "Jitter is the variation of packet delay", 1, 1,
                  "True", "False"),
            Q(8,  "RTP port numbers must be", 1, 1,
                  "An even number", "An odd number", "A prime number"),
            Q(9,  "A peer in a swarm that has the complete content file is called a(n)", 2, 2,
                  "Swarm", "Seed", "Leech", "Tracker"),
            Q(10, "In the Kademlia protocol, the distance between nodes is determined by bitwise", 3, 1,
                  "XOR", "XAND", "OR", "AND"),
            Q(11, "___________ is a standard security technology for establishing an encrypted link between a server and a client", 2, 1,
                  "SSL", "RSA", "SHA-2", "TCP"),
            Q(12, "Which unstructured overlay algorithm increases the TTL value by a small amount if the query fails?", 3, 2,
                  "Flooding", "Expanding ring", "Dijkstra", "Pastry"),
        };

        // Returns the questions whose ZERO-BASED index is in the given range
        public static List<Question> GetQuestionRange(IEnumerable<int> range) =>
            All.Where((x, i) => range.Contains(i)).ToList();
    }

    // ---------- Helper ----------
    public static class Extensions
    {
        public static void Print<T>(this IEnumerable<T> source, string title)
        {
            Console.WriteLine();
            Console.WriteLine($"=== {title} ===");
            Console.WriteLine(string.Join(", ", source));
        }
    }

    internal class Program
    {
        static void Main(string[] args)
        {
            // ---------- Sample data ----------
            var quiz     = QuestionBank.All;
            var numbers  = new List<int> { 4, 8, 15, 16, 23, 42 };
            var names    = new[] { "Ali", "Salem", "Abeer", "Reem", "Jalal" };

            var products = new List<Product>
            {
                new Product { Name = "Laptop",  Price = 25000, Quantity = 2  },
                new Product { Name = "Phone",   Price = 15000, Quantity = 5  },
                new Product { Name = "Tablet",  Price = 9000,  Quantity = 3  },
                new Product { Name = "Monitor", Price = 6000,  Quantity = 4  },
                new Product { Name = "Mouse",   Price = 300,   Quantity = 20 },
            };

            // ===================== PART 1: Count, Sum, Average, Min, Max (numbers) =====================
            // TODO: Task 1.1 ... 1.8


            // ===================== PART 2: The question bank =====================
            // TODO: Task 2.1 ... 2.8


            // ===================== PART 3: Aggregate =====================
            // TODO: Task 3.1 ... 3.9


            // ===================== PART 4: Products =====================
            // TODO: Task 4.1 ... 4.7


            // ===================== PART 5: Mixed =====================
            // TODO: Task 5.1 ... 5.5

            Console.ReadKey();
        }
    }
}
```

---

## Part 1: `Count`, `Sum`, `Average`, `Min`, `Max` on numbers

**Task 1.1.** For `numbers`, print the **count, sum, average, minimum and maximum**.
*Expected:* `6`, `108`, `18`, `4`, `42`.

**Task 1.2.** Count the **even** numbers in two ways: `Count(rule)` and `Where(rule).Count()`.
*Expected:* `4` both times (`4, 8, 16, 42`).

**Task 1.3.** Calculate the **sum of the squares** of `numbers`.
*Expected:* `2854`.

**Task 1.4. (integer division trap)** For `{ 1, 2, 4 }` print `Sum() / Count()` and `Average()`. Why are they different?
*Expected:* `2` and `2.3333...`.

**Task 1.5.** Use `LongCount` to count the multiples of 3 between 1 and 100. Print the **type** of the result.
*Expected:* `33` and `System.Int64`.

**Task 1.6.** For `names`, print the `Max()` and `Min()` (alphabetical), then the **longest** and **shortest name length**.
*Expected:* `Salem`, `Abeer`, `5`, `3`.

**Task 1.7. (empty sequences)** On an **empty** `List<int>`, call `Count()`, `Sum()`, `Max()`, `Min()` and `Average()`. Which ones throw? Fix the ones that throw in **two ways**: with `DefaultIfEmpty(0)` and with a nullable (`Select(x => (int?)x)`).
*Expected:* `Count` is `0`, `Sum` is `0`; `Max`, `Min`, `Average` throw `InvalidOperationException`. The nullable versions return `null`.

**Task 1.8. (overflow)** Calculate `new[] { int.MaxValue, 1 }.Sum()` inside `try/catch`, then fix it by summing as `long`.
*Expected:* `OverflowException`, then `2147483648`.

---

## Part 2: The question bank

**Task 2.1.** Print the total number of questions, and the number of questions worth 1, 2 and 3 marks.
*Expected:* `12`; `5`, `5`, `2`.

**Task 2.2.** Print the **highest** and **lowest** mark.
*Expected:* `3` and `1`.

**Task 2.3.** Use `MaxBy` and `MinBy` on `Marks`. Which questions do you get? Why that one, even though several questions tie?
*Expected:* `Q #10` and `Q #1`: on ties they return the **first** match.

**Task 2.4.** Print the **total marks** and the **average mark** (formatted with two decimals).
*Expected:* `21` and `1.75`.

**Task 2.5.** Print:
- the total marks of the questions with **fewer than 3 choices**,
- the average mark of the questions with **exactly 4 choices**.

*Expected:* `2` (`Q #1` and `Q #7`) and about `2.125`.

**Task 2.6. (empty result)** Try `quiz.Where(x => x.Choices.Count < 2).Max(x => x.Marks)` inside `try/catch`. Then fix it so it returns `0` instead of throwing.
*Expected:* `InvalidOperationException`, then `0`.

**Task 2.7.** Find (with `MaxBy`):
- the question with the **most choices** (several tie),
- the question with the **longest title**.

*Expected:* `Q #2` (first one with 4 choices) and `Q #11`.

**Task 2.8.** Group the questions by `Marks` and print, for each mark value, the **count** and the **sum of marks**.
*Expected:* `1 mark: 5 questions, 5 marks`; `2 marks: 5 questions, 10 marks`; `3 marks: 2 questions, 6 marks`.

---

## Part 3: `Aggregate`

**Task 3.1.** Join `names` into one text with `Aggregate` (no seed). Print `a` and `b` on each step like the sample. How many times is the lambda called?
*Expected:* `Ali,Salem,Abeer,Reem,Jalal`, and the lambda is called **4** times.

**Task 3.2.** Produce the same text with `string.Join` and with a `foreach` loop. Which version do you prefer, and why? (Answer in a comment.)

**Task 3.3. (the seed)** For `{ 1, 2, 3, 4, 5 }` calculate `Aggregate(2, (a, b) => a + b)`. Is the result `15`? Explain.
*Expected:* `17`, because the seed is part of the sum.

**Task 3.4. (factorial)** Calculate `5!` and `10!` with `Enumerable.Range` and `Aggregate`. Then calculate `13!` once with an `int` seed and once with a `long` seed (`1L`).
*Expected:* `120`, `3628800`; for `13!` the `int` version gives a **wrong number** (`1932053504`) and the `long` version gives `6227020800`.

**Task 3.5.** Find the **longest name** in `names` with `Aggregate`. Several names have 5 letters, which one do you get with `<`, and which with `<=`?
*Expected:* `Salem` with `<`; `Jalal` with `<=`.

**Task 3.6.** Find the question with the **longest title** using the **3-parameter** overload (seed, rule, result selector):
1. returning the **question** (`x => x`),
2. returning only the **title** (`q => q.Title`).

Then do it again with `MaxBy`.
*Expected:* `Q #11` every time.

**Task 3.7.** Reverse the string `"linq"` with `Aggregate`.
*Expected:* `qnil`.

**Task 3.8. (two results in one pass)** Find the **minimum and maximum** of `numbers` in a **single** `Aggregate` call, using a tuple as the seed: `(min: int.MaxValue, max: int.MinValue)`.
*Expected:* `(4, 42)`.

**Task 3.9.** Call `Aggregate` on an **empty** list: once without a seed (inside `try/catch`) and once with a seed of `0`.
*Expected:* `InvalidOperationException`, then `0`.

---

## Part 4: Products

**Task 4.1.** Calculate the **total value** of the stock (`Price * Quantity` for each product, then sum).
*Expected:* `182000`.

**Task 4.2.** Print the **average price**, the **most expensive** product and the **cheapest** product.
*Expected:* `11060`, `Laptop`, `Mouse`.

**Task 4.3.** Print the **total quantity** and the **number of products with a price above 10,000**.
*Expected:* `34` and `2`.

**Task 4.4.** Find the product with the **highest line value** (`Price * Quantity`).
*Expected:* `Phone` (`75000`).

**Task 4.5.** Build the text `"Laptop x2, Phone x5, Tablet x3, Monitor x4, Mouse x20"` with `Aggregate` (and again with `string.Join`).

**Task 4.6.** Print `products.Sum(p => p.Price)`. What is the type of the result?
*Expected:* `55300`, `decimal`.

**Task 4.7.** Print the **average quantity**.
*Expected:* `6.8`.

---

## Part 5: Mixed

**Task 5.1. (report)** Print a small statistics table for the **marks** of the question bank:

```
Questions : 12
Minimum   : 1
Maximum   : 3
Total     : 21
Average   : 1.75
```

**Task 5.2.** For each mark value, print the **share** of questions as a percentage (`count / total`).
*Expected:* `1 mark: 41.7%`, `2 marks: 41.7%`, `3 marks: 16.7%`.

**Task 5.3. (exam builder)** Take questions **in order** until adding the next one would push the **total marks above 10**. Use a running total (with `Aggregate` or `TakeWhile` plus a variable).
*Expected:* the first **7** questions (`Q #1` to `Q #7`), with a total of `10` marks.

**Task 5.4.** In a comment, explain which is better and why: `quiz.Count() > 0` or `quiz.Any()`.

**Task 5.5.** In a comment, choose the right operator for each case:
1. The total price of a shopping cart.
2. The name of the employee with the highest salary.
3. The highest salary only.
4. A comma-separated list of tags.
5. A running calculation that no built-in operator does.

---

## Challenge (optional)

Write a **`Median`** for the marks of the question bank (sort, then take the middle value, or the average of the two middle values when the count is even).
*Expected:* `2`.
Then write your own extension method `MyAggregate<T>(this IEnumerable<T> source, Func<T, T, T> func)` with a `foreach` loop, and check that it gives the same result as `Aggregate` for `names`.

---

## Submission checklist

- [ ] Every task prints a clear, labeled result
- [ ] Tasks that should throw are wrapped in `try/catch`
- [ ] You can explain `Max` vs `MaxBy`, and what happens on ties
- [ ] You can explain what the seed does in `Aggregate`
- [ ] You can explain which aggregation operators throw on an empty sequence
- [ ] You know when to use `string.Join` instead of `Aggregate`
