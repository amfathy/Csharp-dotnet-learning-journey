using System;
using System.Collections.Generic;
using System.Linq;

namespace LinqSession15Tasks
{
    // ---------- Models ----------
    public class Employee
    {
        public string EmployeeNo { get; set; }
        public string Name { get; set; }

        public override string ToString() => $"{EmployeeNo} - {Name}";

        // TODO (Task 4.5): override Equals and GetHashCode here
    }

    public class Meeting
    {
        public string Title { get; set; }
        public DateOnly Date { get; set; }
        public TimeOnly StartAt { get; set; }
        public TimeOnly EndAt { get; set; }
        public List<Employee> Participants { get; set; } = new();

        public override string ToString() =>
            $"{Title} | {Date:yyyy-MM-dd} {StartAt:HH:mm}-{EndAt:HH:mm} | " +
            $"{Participants.Count} participants: {string.Join(", ", Participants.Select(p => p.Name))}";

        public override bool Equals(object obj)
        {
            if(ReferenceEquals(null, obj))  return false;
            if(ReferenceEquals(obj , this)) return true;
            if(obj.GetType() != this.GetType()) return false;

            Meeting other = (Meeting)obj;

            return Title.Equals(other.Title) && Date == other.Date
                && StartAt.Equals(other.StartAt) && EndAt.Equals(other.EndAt) && Participants.SequenceEqual(other.Participants);

        }
        public override int GetHashCode() => HashCode.Combine(Title, Date, StartAt, EndAt);

        //public override bool Equals(object obj) =>
        //    obj is Meeting other
        //    && Title == other.Title
        //    && Date == other.Date
        //    && StartAt == other.StartAt
        //    && EndAt == other.EndAt
        //    && Participants.SequenceEqual(other.Participants);      // needs Employee equality

        //public override int GetHashCode() => HashCode.Combine(Title, Date, StartAt, EndAt);
    }

    // ---------- Data ----------
    public static class Repository
    {
        public static Meeting Meeting1 => new Meeting
        {
            Title = "Meeting - 1",
            Date = new DateOnly(2022, 03, 02),
            StartAt = new TimeOnly(08, 0, 0),
            EndAt = new TimeOnly(09, 0, 0),
            Participants =
            {
                new Employee { EmployeeNo = "a10", Name = "Ruba Ali" },
                new Employee { EmployeeNo = "a11", Name = "Sana Sayed" },
                new Employee { EmployeeNo = "a12", Name = "Abeer Omar" },
            }
        };

        public static Meeting Meeting2 => new Meeting
        {
            Title = "Meeting - 2",
            Date = new DateOnly(2022, 03, 02),
            StartAt = new TimeOnly(09, 0, 0),
            EndAt = new TimeOnly(10, 0, 0),
            Participants =
            {
                new Employee { EmployeeNo = "a11", Name = "Sana Sayed" },
                new Employee { EmployeeNo = "a13", Name = "Rashed Sameh" },
                new Employee { EmployeeNo = "a15", Name = "Omniya Sayed" },
            }
        };

        public static Meeting Meeting3 => new Meeting
        {
            Title = "Meeting - 3",
            Date = new DateOnly(2022, 03, 02),
            StartAt = new TimeOnly(10, 0, 0),
            EndAt = new TimeOnly(11, 0, 0),
            Participants =
            {
                new Employee { EmployeeNo = "a17", Name = "Peter Siri" },
                new Employee { EmployeeNo = "a18", Name = "Joe Harb" },
            }
        };

        public static Meeting Meeting4 => new Meeting
        {
            Title = "Meeting - 7",
            Date = new DateOnly(2022, 03, 03),
            StartAt = new TimeOnly(10, 0, 0),
            EndAt = new TimeOnly(11, 0, 0),
            Participants =
            {
                new Employee { EmployeeNo = "a14", Name = "Salah Sayed" },
                new Employee { EmployeeNo = "a15", Name = "Omniya Sayed" },
                new Employee { EmployeeNo = "a17", Name = "Peter Siri" },
            }
        };

        public static List<Employee> Employees => new()
        {
            new Employee { EmployeeNo = "a10", Name = "Ruba Ali" },
            new Employee { EmployeeNo = "a11", Name = "Sana Sayed" },
            new Employee { EmployeeNo = "a12", Name = "Abeer Omar" },
            new Employee { EmployeeNo = "a13", Name = "Rashed Sameh" },
            new Employee { EmployeeNo = "a14", Name = "Salah Sayed" },
            new Employee { EmployeeNo = "a15", Name = "Omniya Sayed" },
            new Employee { EmployeeNo = "a16", Name = "Rana Siri" },
            new Employee { EmployeeNo = "a17", Name = "Peter Siri" },
            new Employee { EmployeeNo = "a18", Name = "Joe Harb" },
            new Employee { EmployeeNo = "a19", Name = "Sara Madi" },
            new Employee { EmployeeNo = "a20", Name = "Ismail Saleh" },
            new Employee { EmployeeNo = "a21", Name = "Rama Ali" },
            new Employee { EmployeeNo = "a22", Name = "Sana Sayed" },
        };

        public static List<Meeting> Meetings => new() { Meeting1, Meeting2, Meeting3, Meeting4 };
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

    // ---------- TODO (Task 2.3): write your IEqualityComparer<Employee> here ----------


    internal class Program
    {
        static void Main(string[] args)
        {
            // ---------- Sample data (store the objects in variables!) ----------
            var m1 = Repository.Meeting1;
            var m2 = Repository.Meeting2;
            var m3 = Repository.Meeting3;
            var m4 = Repository.Meeting4;
            var meetings = new List<Meeting> { m1, m2, m3, m4 };
            var employees = Repository.Employees;

            var a = new[] { 1, 2, 3 };
            var b = new[] { 3, 4, 5 };

            // ===================== PART 1: Distinct on simple types =====================
            // TODO: Task 1.1 ... 1.7
            // Task 1.1
            new[] { 1, 2, 2, 3, 3, 3, 4 }
                .Distinct()
                .Print("1.1 Distinct numbers");

            // Task 1.2
            var letters = "mississippi".Distinct();
            letters.Print("1.2 Distinct letters");
            Console.WriteLine($"Count: {letters.Count()}");

            // Task 1.3
            var words = new[] { "a", "A", "b" };
            words.Distinct().Print("1.3 Case-sensitive");
            words.Distinct(StringComparer.OrdinalIgnoreCase)
                .Print("1.3 Ignore case");

            // ===================== PART 2: Distinct on objects (NO equality code yet) =====================
            // TODO: Task 2.1 ... 2.5
            var p12 = m1.Participants
               .Concat(m2.Participants)
               .ToList();

            p12.Print("2.1 Participants in Meeting 1 and 2");
            Console.WriteLine($"Count: {p12.Count}");

            // Task 2.2
            // Employee still uses default reference equality.
            // The two Sana objects are different instances.
            var plainDistinct = p12.Distinct().ToList();

            plainDistinct.Print("2.2 Plain Distinct");
            Console.WriteLine($"Count: {plainDistinct.Count}");

            // Task 2.3
            p12.DistinctBy(e => e.EmployeeNo)
                .Print("2.3 DistinctBy EmployeeNo");

            // Task 2.4
            employees.DistinctBy(e => e.EmployeeNo)
                .Print("2.4 DistinctBy EmployeeNo");

            employees.DistinctBy(e => e.Name)
                .Print("2.4 DistinctBy Name");

            Console.WriteLine(
                $"2.4 Count by number: " +
                $"{employees.DistinctBy(e => e.EmployeeNo).Count()}");

            Console.WriteLine(
                $"2.4 Count by name: " +
                $"{employees.DistinctBy(e => e.Name).Count()}");


            // ===================== PART 3: Union, Intersect, Except =====================
            // TODO: Task 3.1 ... 3.9
            // Task 3.1
            a.Union(b).Print("3.1 Union");
            a.Intersect(b).Print("3.1 Intersect");
            a.Except(b).Print("3.1 A except B");
            b.Except(a).Print("3.1 B except A");


            // ===================== PART 4: Meetings, and overriding equality =====================
            // TODO: Task 4.1 ... 4.5


            // ===================== PART 5: Mixed =====================
            // TODO: Task 5.1 ... 5.5

            Console.ReadKey();
        }
    }
}