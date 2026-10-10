"""
Normalize the multi-select column LanguageHaveWorkedWith into a table with
one row per respondent per language.

Input : Stack Overflow Developer Survey 2025 results file
Output: respondent_languages.csv (columns: ResponseId, LanguageHaveWorkedWith)
"""
import pandas as pd

INPUT_FILE = 'results.csv'
OUTPUT_FILE = 'respondent_languages.csv'

# Load only the two columns needed
df = pd.read_csv(INPUT_FILE, usecols=['ResponseId', 'LanguageHaveWorkedWith'])

# Drop respondents who skipped the question
df = df.dropna(subset=['LanguageHaveWorkedWith'])

# "Python;SQL;Go" -> ['Python', 'SQL', 'Go'] -> one row per language
df['LanguageHaveWorkedWith'] = df['LanguageHaveWorkedWith'].str.split(';')
df_long = df.explode('LanguageHaveWorkedWith')
df_long['LanguageHaveWorkedWith'] = df_long['LanguageHaveWorkedWith'].str.strip()

df_long.to_csv(OUTPUT_FILE, index=False)
print(df_long.head(10))
print(len(df_long), 'rows,', df_long['ResponseId'].nunique(), 'respondents')
