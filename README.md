# Expense Tracker

A Flutter app for recording income and expenses, reviewing current totals, and
editing or deleting transactions.

## Features

- Dashboard totals for income, expenses, and balance
- Recent and complete transaction lists
- Filter transactions by income/expense type and inclusive date range
- Add, edit, and delete flows with required-field validation
- Drawer navigation with currency and income/expense category settings
- Persistent currency selection and separate income/expense categories
- On-device persistence with Sqflite in `expense_tracker.db`

## Run

Install Flutter, then run:

```shell
flutter pub get
flutter run
```

The Sqflite database is created locally on first launch. The Sqflite plugin
supports Android, iOS, and macOS; desktop and web targets need a compatible
database factory before they can use the persistence layer.
