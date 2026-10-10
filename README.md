# career-migration-sql-engine

A SQL pipeline that ingests and normalizes global developer survey data to compare pay and opportunity across three migration markets: **Germany, Canada and Ireland**.

## Business question

For a developer choosing between Germany, Canada and Ireland: where does pay run highest, which roles and languages are linked to higher pay, and how much does experience add in each country?

## Data

- **Source:** Stack Overflow Annual Developer Survey 2025 (survey.stackoverflow.co). See their site for licence terms.
- **Size:** about 49,000 responses, 170+ columns.
- **Salary column used:** `ConvertedCompYearly` (annual salary converted to USD by Stack Overflow, which makes countries comparable).

## Pipeline

1. **Ingest:** the raw survey CSV is imported into SQL Server (`CareerMigrationDB`, table `respondents`). Every column is loaded as text first, because the file contains values like `NA` in numeric columns.
2. **Normalize (Python):** `normalize_languages.py` splits the multi-select column `LanguageHaveWorkedWith` (values like `Python;SQL;Go` in one cell) into a second table, `respondent_languages`, with one row per person per language.
3. **Analyse (SQL):** `career_migration_analysis.sql` runs five queries using CTEs, `JOIN`, `RANK()`, `PERCENT_RANK()` and `NTILE()`.

## Schema

![ERD](erd.png)

`respondents` holds one row per person. `respondent_languages` holds one row per person per language and links back through `ResponseId`. The `respondents` table has 170+ columns in total. The diagram shows only the columns used in the analysis.

## Data cleaning decisions

- `TRY_CAST` converts text columns to numbers safely. Values like `NA` become `NULL` instead of crashing the query.
- Rows with a `NULL` salary are dropped.
- Salaries below **$10,000 per year** are excluded as unrealistic entries (for example, people who typed an hourly or monthly figure).
- Groups with fewer than **10 respondents** are excluded from the role and language rankings, so a handful of people cannot decide a result.

## Key findings

### 1. Average annual salary

| Country | Average salary (USD) |
|---|---|
| Ireland | 123,735 |
| Canada | 102,281 |
| Germany | 89,730 |

Ireland's average is about 38% higher than Germany's among survey respondents.

### 2. Highest-paying role per country (minimum 10 respondents)

| Country | Role | Average salary (USD) | Respondents |
|---|---|---|---|
| Germany | Senior executive (C-suite, VP, etc.) | 186,427 | 13 |
| Canada | Senior executive (C-suite, VP, etc.) | 140,876 | 11 |
| Ireland | Architect, software or solutions | 138,077 | 11 |

### 3. Does experience raise pay? (average salary by experience quartile)

Quartile 1 is the least experienced 25% in that country, quartile 4 the most experienced 25%.

| Country | Q1 | Q2 | Q3 | Q4 |
|---|---|---|---|---|
| Germany | 61,795 | 87,113 | 103,562 | 108,840 |
| Ireland | 84,120 | 134,239 | 135,267 | 142,559 |
| Canada | 74,931 | 113,088 | 116,712 | 108,612 |

- Germany rises in every quartile, about 76% from Q1 to Q4.
- Ireland rises about 69% from Q1 to Q4, with most of the gain between Q1 and Q2.
- Canada rises until Q3, then dips in Q4. It is the only country where the most experienced group earns less than the group before it.
- In all three countries the biggest jump happens early, between Q1 and Q2.

### 4. Top 5 languages by average salary (minimum 10 respondents)

| Country | Language | Average salary (USD) | Respondents |
|---|---|---|---|
| Canada | Scala | 133,149 | 22 |
| Canada | Perl | 130,602 | 34 |
| Canada | Ruby | 123,972 | 77 |
| Canada | Go | 121,458 | 152 |
| Canada | Lisp | 116,151 | 17 |
| Germany | Erlang | 119,402 | 30 |
| Germany | Lisp | 111,911 | 48 |
| Germany | Ada | 110,545 | 14 |
| Germany | Swift | 108,278 | 117 |
| Germany | Elixir | 103,895 | 66 |
| Ireland | Rust | 161,036 | 11 |
| Ireland | Java | 130,749 | 39 |
| Ireland | C++ | 130,365 | 25 |
| Ireland | Ruby | 128,882 | 11 |
| Ireland | Swift | 127,985 | 11 |

Go in Canada (152 respondents) and Swift in Germany (117 respondents) have the largest samples in this table.

## Limitations

- The survey is self-reported and voluntary, so respondents may not represent all developers in each country.
- Some groups are small (11 to 13 respondents for the top roles, 11 for several languages). Treat those rankings as indicative, not definitive.
- A person who uses several languages counts toward each of them.
- Language and salary are only associated here. The analysis does not control for seniority, role or company type.

## Files

| File | What it is |
|---|---|
| `career_migration_analysis.sql` | All five analysis queries, with comments |
| `normalize_languages.py` | Python script that builds the `respondent_languages` table |
| `erd.png` | Entity relationship diagram |

## How to reproduce

1. Download the 2025 survey CSV from survey.stackoverflow.co.
2. Import it into SQL Server as `dbo.respondents`, with all columns as text (`ResponseId` as `int`).
3. Run `normalize_languages.py` and import the output as `dbo.respondent_languages`.
4. Run `career_migration_analysis.sql`.

## Tools

SQL Server (SSMS), Python (pandas), dbdiagram.io
