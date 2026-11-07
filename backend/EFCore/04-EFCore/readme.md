# EF Core Configuration: Convention, Data Annotations, Fluent API and Grouped Configuration

In this lesson one small "Twitter-like" database (**Users**, **Tweets**, **Comments**) is mapped to C# classes in **five different ways**. The program is almost the same every time. Only **how EF Core is told about the table and column names** changes.

```
Table of contents
1. The goal of the lesson
2. The three ways to configure + who wins
3. What is the same in all five projects
4. Project 1: Configuration by Convention
5. Project 2: Override with Data Annotations
6. Project 3: Override with Fluent API
7. Project 4: Grouping the configuration (one class per entity)
8. Project 5: ApplyConfigurationsFromAssembly
9. All five projects side by side + which one to use
10. Things to notice in the lesson code
11. Common errors
12. Exercises
```

> **Honest note:** the lesson code you pasted shows the entities and the `DbContext` classes. Some files were not pasted (the entities of the Data Annotations and Fluent API projects, and the `UserConfiguration` / `TweetConfiguration` / `CommentConfiguration` classes). I wrote those parts based on what the code obviously needs. They are marked **(inferred)**. I could not run EF Core here, so the SQL shown is what EF Core normally generates.

---

# 1. The goal of the lesson

The database already has tables. The C# classes must **match** them. But names often do **not** match:

| In the database | In C# |
|---|---|
| Table `tblUsers` | Class `User` |
| Column `CommentId` | Property `Id` |
| Column `UserId` | Property `CommentBy` |

If EF Core guesses wrong, you get errors like `Invalid object name 'Users'`. So we must learn to **tell EF Core exactly how to map** classes to tables and properties to columns. This is called **configuration** (or *mapping*).

---

# 2. The three ways to configure, and who wins

| Level | Name | Where you write it | Example |
|---|---|---|---|
| 1 | **Conventions** | Nowhere: built-in default rules | A property named `Id` is the primary key |
| 2 | **Data Annotations** | **Attributes** on the entity class | `[Table("tblUsers")]` |
| 3 | **Fluent API** | **Code** in `OnModelCreating` | `modelBuilder.Entity<User>().ToTable("tblUsers")` |

```
          weakest                                   strongest
   Conventions   <   Data Annotations   <   Fluent API
  (default rules)     (attributes)          (code, always wins)
```

**Rule:** if two levels say different things, the **stronger** one wins. That is why the lesson folders are named *"Override ... "*: each one **overrides** the default.

The five projects of the lesson:

| # | Project name | What it shows |
|---|---|---|
| 1 | `ConfigurationByConvention` | No configuration at all: defaults |
| 2 | `OverrideConfigurationByDataAnnotations` | Attributes on the classes |
| 3 | `OverrideConfigurationUsingFluentAPI` | Code in `OnModelCreating` |
| 4 | `OverrideConfiguratiobByGroupingConfiguration` | One configuration class per entity, called one by one |
| 5 | `CallGroupingConfigurationUsingAssembly` | The same classes, applied **all at once** with `ApplyConfigurationsFromAssembly` |

---

# 3. What is the same in all five projects

## 3.1 The entities (project 1 version)

```csharp
public class User
{
    public int UserId { get; set; }
    public string Username { get; set; }
}

public class Tweet
{
    public int TweetId { get; set; }
    public int UserId { get; set; }
    public string TweetText { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class Comment
{
    public int CommentId { get; set; }
    public int TweetId { get; set; }
    public int UserId { get; set; }
    public string CommentText { get; set; }
    public DateTime CreatedAt { get; set; }
}
```

As a picture:

```
User (1) ──────< Tweet (many) ──────< Comment (many)
UserId           TweetId, UserId      CommentId, TweetId, UserId
Username         TweetText            CommentText
                 CreatedAt            CreatedAt
```

## 3.2 The `DbContext`

```csharp
public class AppDbContext : DbContext
{
    public DbSet<User> Users { get; set; } = null!;
    public DbSet<Tweet> Tweets { get; set; } = null!;
    public DbSet<Comment> Comments { get; set; } = null!;

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        base.OnConfiguring(optionsBuilder);

        var config = new ConfigurationBuilder()
            .AddJsonFile("appsettings.json")
            .Build();

        var connectionString = config.GetSection("constr").Value;

        optionsBuilder.UseSqlServer(connectionString);
    }
}
```

Line by line:

| Code | Meaning |
|---|---|
| `DbSet<User> Users` | "There is a table of users." Reading `context.Users` reads that table. |
| `= null!` | Tells the compiler "EF Core will fill this in, do not warn me about null". |
| `OnConfiguring` | Called by EF Core to decide **which database** to connect to. |
| `new ConfigurationBuilder().AddJsonFile("appsettings.json").Build()` | Reads the settings file. |
| `config.GetSection("constr").Value` | Reads the value of the key `constr` (the connection string). |
| `UseSqlServer(connectionString)` | Use SQL Server with that connection string. |

## 3.3 `appsettings.json` (the connection string, inferred)

```json
{
  "constr": "Server=.;Database=TwitterDb;Trusted_Connection=True;TrustServerCertificate=True;"
}
```

For this to work:
- Install the packages: `Microsoft.EntityFrameworkCore.SqlServer`, `Microsoft.Extensions.Configuration.Json`.
- In Visual Studio, select `appsettings.json` and set **Copy to Output Directory = Copy if newer**. Otherwise the program cannot find the file.
- The key must be named `constr` (the code reads `GetSection("constr")`).

## 3.4 The `Program` (identical in all five)

```csharp
using (var context = new AppDbContext())
{
    Console.WriteLine("-------- Users -----------");
    foreach (var user in context.Users)
        Console.WriteLine(user.Username);

    Console.WriteLine("-------- Tweets -----------");
    foreach (var tweet in context.Tweets)
        Console.WriteLine(tweet.TweetText);

    Console.WriteLine("-------- Comments -----------");
    foreach (var comment in context.Comments)
        Console.WriteLine(comment.CommentText);
}
Console.ReadKey();
```

It just reads the three tables and prints one column from each. **If the mapping is wrong, this is where you get an error.** If it prints the data, the configuration is correct.

---

# 4. Project 1: Configuration by Convention

**No configuration code at all.** EF Core uses its built-in default rules ("conventions").

## 4.1 The default rules

| Question | Convention (default) |
|---|---|
| Table name? | The **name of the `DbSet` property** (`Users`, `Tweets`, `Comments`). With no `DbSet`, the class name. |
| Primary key? | A property named `Id` or `<ClassName>Id` (`UserId` in `User`, `TweetId` in `Tweet`, `CommentId` in `Comment`) |
| Key generated by the database? | Yes: an `int` key becomes an **identity** column (1, 2, 3...) |
| Column name? | Same as the property name |
| Column type? | `int` → `int`, `string` → `nvarchar(max)`, `DateTime` → `datetime2`, `bool` → `bit`, `decimal` → `decimal(18,2)` |
| Can it be NULL? | Value types (`int`, `DateTime`): **NOT NULL**. `string`: **NULL** (if nullable reference types are off) or **NOT NULL** (if on and the property is `string`, not `string?`) |
| Relationships? | Created from **navigation properties** or foreign keys that follow the naming rules (see below) |

## 4.2 What EF Core expects from this lesson's code

```
Users     (UserId int PK identity, Username nvarchar)
Tweets    (TweetId int PK identity, UserId int, TweetText nvarchar, CreatedAt datetime2)
Comments  (CommentId int PK identity, TweetId int, UserId int, CommentText nvarchar, CreatedAt datetime2)
```

If the **real** tables are called `Users`, `Tweets` and `Comments` with these column names, this project works with **zero configuration**.

```sql
SELECT [u].[UserId], [u].[Username]
FROM [Users] AS [u]
```

## 4.3 Good to know

- The entities have **no navigation properties** (no `User User` inside `Tweet`). So EF Core does **not** create relationships here. `UserId` is just an `int` column. That is enough to **read** data, but no foreign keys are created if EF Core creates the database.
- Convention is great when you control the database and follow the naming rules. It stops being enough when the database has its own naming style, and that is the rest of the lesson.

---

# 5. Project 2: Override with Data Annotations

**Data annotations** are **attributes** you put on the class or on a property. They live in `System.ComponentModel.DataAnnotations` and `System.ComponentModel.DataAnnotations.Schema`.

## 5.1 Example (inferred)

Suppose the real tables are named `tblUsers`, `tblTweets`, `tblComments`:

```csharp
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

[Table("tblUsers")]
public class User
{
    [Key]
    public int UserId { get; set; }

    [Required]
    [MaxLength(50)]
    public string Username { get; set; }
}

[Table("tblComments")]
public class Comment
{
    [Key]
    [Column("CommentId")]
    public int Id { get; set; }

    public int TweetId { get; set; }

    [Column("UserId")]
    public int CommentBy { get; set; }

    public string CommentText { get; set; }
    public DateTime CreatedAt { get; set; }
}
```

The `DbContext` has **no** `OnModelCreating`. EF Core reads the attributes by itself.

## 5.2 The most used attributes

| Attribute | What it does |
|---|---|
| `[Table("tblUsers")]` | Table name |
| `[Column("CommentId")]` | Column name (and optionally `TypeName = "varchar(100)"`) |
| `[Key]` | This property is the primary key |
| `[Required]` | Column is `NOT NULL` (also used for validation) |
| `[MaxLength(50)]` / `[StringLength(50)]` | Maximum text length |
| `[NotMapped]` | Do **not** create a column for this property |
| `[ForeignKey("UserId")]` | Marks a foreign key |
| `[DatabaseGenerated(DatabaseGeneratedOption.None)]` | The key is **not** generated by the database |

## 5.3 Pros and cons

| + | - |
|---|---|
| Very easy to read: the rule sits next to the property | The entity class now **knows about the database** (mixing concerns) |
| Some attributes are also used for validation (`[Required]`, `[MaxLength]`) in ASP.NET | Cannot express everything (composite keys, some relationships, indexes with options) |

---

# 6. Project 3: Override with Fluent API

The **Fluent API** is configuration **in code**, inside `OnModelCreating`. The calls are chained like a sentence (that is why it is called "fluent").

```csharp
protected override void OnModelCreating(ModelBuilder modelBuilder)
{
    base.OnModelCreating(modelBuilder);

    modelBuilder.Entity<User>().ToTable("tblUsers");
    modelBuilder.Entity<Tweet>().ToTable("tblTweets");
    modelBuilder.Entity<Comment>().ToTable("tblComments");

    modelBuilder.Entity<Comment>().Property(p => p.Id)
        .HasColumnName("CommentId");

    modelBuilder.Entity<Comment>().Property(p => p.CommentBy)
        .HasColumnName("UserId");
}
```

## 6.1 Line by line

| Code | Meaning |
|---|---|
| `base.OnModelCreating(modelBuilder)` | Run EF Core's own default setup first (good habit) |
| `modelBuilder.Entity<User>()` | "I want to configure the `User` entity" |
| `.ToTable("tblUsers")` | Its table is `tblUsers` |
| `.Property(p => p.Id)` | "I want to configure the `Id` property of `Comment`" |
| `.HasColumnName("CommentId")` | Its column is `CommentId` |

## 6.2 The entity in this project (inferred)

The Fluent API code uses `p.Id` and `p.CommentBy`, so in this project the `Comment` class is:

```csharp
public class Comment
{
    public int Id { get; set; }            // column: CommentId
    public int TweetId { get; set; }
    public int CommentBy { get; set; }     // column: UserId
    public string CommentText { get; set; }
    public DateTime CreatedAt { get; set; }
}
```

The C# names (`Id`, `CommentBy`) are different from the column names (`CommentId`, `UserId`). The Fluent API is the bridge.

The SQL that EF Core now sends for `context.Comments`:

```sql
SELECT [c].[CommentId], [c].[CommentText], [c].[CreatedAt], [c].[UserId], [c].[TweetId]
FROM [tblComments] AS [c]
```

(EF Core renames `Id` to `CommentId` and `CommentBy` to `UserId` for you.)

## 6.3 More things the Fluent API can do

```csharp
modelBuilder.Entity<User>(entity =>
{
    entity.ToTable("tblUsers");
    entity.HasKey(u => u.UserId);                              // primary key
    entity.Property(u => u.Username).IsRequired();            // NOT NULL
    entity.Property(u => u.Username).HasMaxLength(50);        // nvarchar(50)
    entity.Property(u => u.Username).HasColumnType("varchar(50)");
    entity.HasIndex(u => u.Username).IsUnique();               // unique index
    entity.Ignore(u => u.SomeCalculatedProperty);              // like [NotMapped]
});

// relationship: one user has many tweets
modelBuilder.Entity<Tweet>()
    .HasOne<User>()
    .WithMany()
    .HasForeignKey(t => t.UserId);
```

## 6.4 Pros and cons

| + | - |
|---|---|
| The **most powerful** way: can do everything | A bit longer to write |
| Entity classes stay **clean** (no attributes) | `OnModelCreating` can grow huge (solved in the next project) |
| **Wins** over data annotations and conventions | |

---

# 7. Project 4: Grouping the configuration (one class per entity)

## 7.1 The problem

With 3 entities `OnModelCreating` is short. With 50 entities it becomes a giant method that is hard to read and full of merge conflicts.

## 7.2 The solution: `IEntityTypeConfiguration<T>`

Move the configuration of **each entity** into **its own class**. These are the files in the `Data/Config` folder (**inferred**):

```csharp
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

public class UserConfiguration : IEntityTypeConfiguration<User>
{
    public void Configure(EntityTypeBuilder<User> builder)
    {
        builder.ToTable("tblUsers");
    }
}

public class TweetConfiguration : IEntityTypeConfiguration<Tweet>
{
    public void Configure(EntityTypeBuilder<Tweet> builder)
    {
        builder.ToTable("tblTweets");
    }
}

public class CommentConfiguration : IEntityTypeConfiguration<Comment>
{
    public void Configure(EntityTypeBuilder<Comment> builder)
    {
        builder.ToTable("tblComments");
        builder.Property(p => p.Id).HasColumnName("CommentId");
        builder.Property(p => p.CommentBy).HasColumnName("UserId");
    }
}
```

Compare with project 3: the **code inside is the same**. Only the **place** changed: `modelBuilder.Entity<Comment>()` became the `builder` parameter.

## 7.3 Calling them one by one (this project)

```csharp
protected override void OnModelCreating(ModelBuilder modelBuilder)
{
    base.OnModelCreating(modelBuilder);

    // individual call
    new UserConfiguration().Configure(modelBuilder.Entity<User>());
    new TweetConfiguration().Configure(modelBuilder.Entity<Tweet>());
    new CommentConfiguration().Configure(modelBuilder.Entity<Comment>());
}
```

Reading it: "create the configuration object, give it the builder of the entity, let it configure".

There is also a built-in shortcut that does the same thing for **one** class:

```csharp
modelBuilder.ApplyConfiguration(new UserConfiguration());
```

## 7.4 Pros and cons

| + | - |
|---|---|
| `OnModelCreating` stays short | You must **remember to add a line** for every new configuration class |
| Each entity's mapping is in a clear, separate file | Forget one and that entity silently uses the defaults |
| Easy to find and to test | |

---

# 8. Project 5: `ApplyConfigurationsFromAssembly`

To stop writing one line per class, let EF Core **find all the configuration classes by itself**:

```csharp
protected override void OnModelCreating(ModelBuilder modelBuilder)
{
    base.OnModelCreating(modelBuilder);
    modelBuilder.ApplyConfigurationsFromAssembly(typeof(UserConfiguration).Assembly);
}
```

## 8.1 What it does

1. `typeof(UserConfiguration).Assembly` = "the assembly (the compiled project, `.dll`) that contains `UserConfiguration`".
2. EF Core **scans** that assembly for every class that implements `IEntityTypeConfiguration<T>`.
3. It creates each one and calls its `Configure` method.

```
         your .dll
   ┌─────────────────────────┐
   │ UserConfiguration       │──┐
   │ TweetConfiguration      │──┼──►  EF Core finds all of them and applies them
   │ CommentConfiguration    │──┘
   │ (any new config class)  │──►  also found automatically, no code change
   └─────────────────────────┘
```

`UserConfiguration` is only used as a **pointer to the assembly**. You could use any type from the same assembly.

## 8.2 Pros and cons

| + | - |
|---|---|
| Add a new configuration class and it is applied **automatically** | A little "magic": nothing in `OnModelCreating` shows which classes are applied |
| `OnModelCreating` never grows | The classes must have a **public parameterless constructor** |
| This is the style used in most real projects | |

---

# 9. All five projects side by side

| | 1. Convention | 2. Data Annotations | 3. Fluent API | 4. Grouped (individual calls) | 5. Grouped (from assembly) |
|---|---|---|---|---|---|
| Where is the configuration? | Nowhere (defaults) | Attributes on entities | `OnModelCreating` | One class per entity | One class per entity |
| How is it applied? | Automatically | Automatically | Inside `OnModelCreating` | One line per class | **One line for all** |
| Can rename tables/columns? | No (uses the names it guesses) | Yes | Yes | Yes | Yes |
| Entity classes stay clean? | Yes | **No** (attributes) | Yes | Yes | Yes |
| Power | Lowest | Medium | **Highest** | Highest | Highest |
| Best for | Small apps with matching names | Simple mapping + validation | A few custom rules | Many entities | Many entities (most common) |

## Which one should I use?

A very common professional approach:

1. **Follow the conventions** wherever you can (less code).
2. Use **Data Annotations** only for simple things that also help validation (`[Required]`, `[MaxLength]`).
3. Use **Fluent API in `IEntityTypeConfiguration<T>` classes**, applied with **`ApplyConfigurationsFromAssembly`**, for everything else.

## Who wins when they disagree? (a quick experiment)

```csharp
[Table("Users")]                       // Data Annotation says: "Users"
public class User { ... }

modelBuilder.Entity<User>().ToTable("tblUsers");   // Fluent API says: "tblUsers"
```

The table used is **`tblUsers`**: Fluent API > Data Annotations > Conventions.

---

# 10. Things to notice in the lesson code

| What you see | Why it matters |
|---|---|
| The namespace `EF007.OverrideConfiguratiobByGroupingConfiguration` has a typo (**Configuratiob**) | Cosmetic, but it appears in several files. Easy to fix with *Rename* so names stay consistent. |
| Project 5's entities are in `EF007.CallGroupingConfigurationUsingAssembly.Entities`, but its `AppDbContext` is in `EF007.OverrideConfiguratiobByGroupingConfiguration.Data` | The project was copied from project 4 and the namespaces were not all renamed. It still compiles (namespaces are just labels), but it is confusing. |
| `AppDbContext` has the same name in all five projects | Fine: each project is separate. Never put two in the same project. |
| `config.GetSection("constr").Value` | Works, but the standard way is `"ConnectionStrings": { "Default": "..." }` and `config.GetConnectionString("Default")`. |
| The connection string is read **every time** a context is created | Fine for a lesson. In real apps, configure the context once with dependency injection (`AddDbContext`). |
| The entities have **no navigation properties** | So no relationships are configured. `UserId` in `Tweet` is just a number. See exercise 5 to add real relationships. |
| `foreach (var user in context.Users)` | The query runs when the loop starts. It must stay **inside** the `using` block. |
| The `DbSet` properties use `= null!` | Removes the "non-nullable property is null" warning; EF Core fills them. |
| No migrations are used | The lesson **maps to an existing database**. EF Core is not asked to create the tables. |

---

# 11. Common errors

| Error message (short) | What it means | How to fix it |
|---|---|---|
| `Invalid object name 'Users'` | EF Core looked for a table named `Users` but the real table has another name (for example `tblUsers`) | Configure the table name: `[Table]`, `ToTable(...)`, or a configuration class |
| `Invalid column name 'CommentBy'` | The property name is not a real column | `HasColumnName("UserId")` or `[Column("UserId")]` |
| `The entity type 'X' requires a primary key to be defined` | EF Core found no key by convention | Name it `Id` / `XId`, or use `[Key]` / `HasKey(...)` |
| `FileNotFoundException: appsettings.json` | The file is not copied next to the `.exe` | Set **Copy to Output Directory** on the file |
| `The ConnectionString property has not been initialized` | `GetSection("constr").Value` returned `null` (wrong key name or empty file) | Check the key name is exactly `constr` |
| The configuration seems ignored | A **stronger** level overrides it, or `ApplyConfigurationsFromAssembly` is not called, or the config class is in another assembly | Check the priority and the call |
| `Cannot access a disposed context` | The query ran after the `using` block ended | Enumerate inside the block, or call `.ToList()` there |

---

# 12. Exercises

1. **Convention.** Create tables `Users`, `Tweets`, `Comments` with the columns of section 3.1 and run project 1. Then rename a table to `tblUsers` and see the error. Then fix it with **Data Annotations**.
2. **Fluent vs Annotations.** Put `[Table("Users")]` on `User` and `ToTable("tblUsers")` in the Fluent API. Which table is queried? Check with `query.ToQueryString()` or `optionsBuilder.LogTo(Console.WriteLine)`.
3. **More rules.** In `UserConfiguration` make `Username` required, with a maximum length of 50 and a **unique index**.
4. **Default value.** Make `Tweet.CreatedAt` use `GETDATE()` as the default value (`HasDefaultValueSql`).
5. **Relationships.** Add navigation properties (`Tweet.User`, `User.Tweets`, `Comment.Tweet`) and configure them with `HasOne` / `WithMany` / `HasForeignKey` in the configuration classes.
6. **Add an entity.** Add a `Like` entity with its own `LikeConfiguration`. In project 5 do you have to change `OnModelCreating`? In project 4?
7. **Connection string.** Change `appsettings.json` to use `"ConnectionStrings": { "Default": "..." }` and read it with `GetConnectionString("Default")`.
8. **Read the SQL.** Add `optionsBuilder.LogTo(Console.WriteLine)` and compare the SQL of the five projects. Which differences do you see in the table and column names?

---

# Summary

| Idea | One line |
|---|---|
| Configuration | Tells EF Core how classes map to tables and columns |
| Conventions | Built-in defaults: table = `DbSet` name, `Id` / `XId` = key |
| Data Annotations | Attributes on the entity: `[Table]`, `[Column]`, `[Key]`, `[Required]` |
| Fluent API | Code in `OnModelCreating`: `ToTable`, `HasColumnName`, `HasKey`... |
| Priority | **Fluent API > Data Annotations > Conventions** |
| `IEntityTypeConfiguration<T>` | One configuration class per entity, to keep `OnModelCreating` small |
| `ApplyConfigurationsFromAssembly` | Finds and applies **all** configuration classes automatically |
| Connection string | Read from `appsettings.json` (key `constr`) in `OnConfiguring` |
