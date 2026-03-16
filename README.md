# GymFlow

GymFlow is a local-only SwiftUI iPhone app for workout planning, session tracking, and recovery check-ins. It is built as a polished prototype, but it is fully runnable in Xcode and supports persistent local state through `UserDefaults`.

This README is split into two audiences:
- users: how to use the app day to day
- developers: how to run, understand, and extend the project

## User Guide

### What the app does

GymFlow helps you:
- build a weekly workout plan from onboarding answers
- edit each day freely, including the session topic and exercises
- run multiple workout sessions in the same day
- track training time, set time, and break time per exercise
- rate effort on a `1-10` scale after a set
- log recovery check-ins and get a lighter recommendation when needed

Everything is stored locally on the device or simulator. There is no login, backend, or HealthKit integration.

### First launch

On first launch, GymFlow shows a short onboarding flow:
1. fitness goal
2. training frequency
3. workout location
4. experience level

After onboarding, the app generates a weekly plan and opens the main 4-tab interface:
- `Today`
- `Plan`
- `Progress`
- `Recovery`

### Today tab

The `Today` tab is the main screen.

You can:
- review today’s session
- edit the session topic and duration
- add, edit, swap, or remove exercises
- start a workout
- run multiple sessions in the same day

Current exercise flow:
1. tap `Start Set`
2. the training timer starts for that exercise
3. tap `Log Set` when the set is done
4. the break timer starts automatically if more sets remain
5. tap `Start Set` again to begin the next set

Each exercise card includes:
- exercise name
- sets and reps
- suggested weight
- inline timer state
- break target: `60s`, `90s`, `120s`, or `Custom`
- effort scale from `1` to `10`
- `Edit`

Effort scale meaning:
- lower numbers mean the set felt too hard
- middle numbers mean the set felt about right
- higher numbers mean the set felt too easy

GymFlow uses that score to adjust the next-set suggestion locally.

### Editing today’s topic

You can edit the session topic from Today or Plan.

Important behavior:
- if you change today’s topic, GymFlow clears the previous focus text and exercise list for that day
- this is intentional, so you can rebuild the session from scratch without being forced into the old plan

### Plan tab

The `Plan` tab shows the weekly overview.

You can:
- open any day
- change the day topic, focus text, and estimated time
- add your own exercises
- swap or remove exercises
- reset a customized day back to the generated plan

Topics are flexible. You can use labels like:
- `Push`
- `Legs`
- `Upper`
- `Conditioning`
- `Open Session`
- any custom topic you type yourself

### Progress tab

The `Progress` tab summarizes momentum without dense analytics.

It includes:
- weekly completion
- current streak
- total completed workouts
- lightweight PRs
- milestone badges
- recent wins

If no workouts have been logged yet, it shows an empty state instead of fake data.

### Recovery tab

The `Recovery` tab lets you save a daily check-in for:
- energy
- soreness
- sleep

Based on those inputs, the app recommends one of:
- train as planned
- go lighter today
- take a recovery day

## Developer Guide

### Tech stack

- SwiftUI
- iOS 17
- Swift 6
- local persistence with `UserDefaults`
- XcodeGen for project generation

### Project layout

- `project.yml`: XcodeGen source of truth
- `GymFlow.xcodeproj`: generated Xcode project
- `GymFlow/App`: app entry and root flow
- `GymFlow/Models`: Codable models for workouts, sessions, recovery, and user profile
- `GymFlow/Store`: `AppStore` persistence and `WorkoutPlanGenerator`
- `GymFlow/ViewModels`: screen-specific view models
- `GymFlow/Views/Components`: reusable UI pieces
- `GymFlow/Views/Onboarding`: onboarding flow
- `GymFlow/Views/Tabs`: Today, Plan, Progress, and Recovery screens
- `GymFlow/Theme`: colors and app-wide visual styling

### Important files

- [GymFlowApp.swift](/Users/rhine_e/Documents/26WN/497/A2/GymFlow/GymFlow/App/GymFlowApp.swift): app entry point and environment store injection
- [RootView.swift](/Users/rhine_e/Documents/26WN/497/A2/GymFlow/GymFlow/App/RootView.swift): onboarding-to-tabs root switch
- [AppStore.swift](/Users/rhine_e/Documents/26WN/497/A2/GymFlow/GymFlow/Store/AppStore.swift): local persistence, active workout logic, day overrides, multi-session support
- [WorkoutPlanGenerator.swift](/Users/rhine_e/Documents/26WN/497/A2/GymFlow/GymFlow/Store/WorkoutPlanGenerator.swift): generated starter plan content
- [TodayView.swift](/Users/rhine_e/Documents/26WN/497/A2/GymFlow/GymFlow/Views/Tabs/TodayView.swift): main workout flow
- [ExerciseCard.swift](/Users/rhine_e/Documents/26WN/497/A2/GymFlow/GymFlow/Views/Components/ExerciseCard.swift): per-exercise timers, break targets, effort scale
- [WorkoutCustomizationSheet.swift](/Users/rhine_e/Documents/26WN/497/A2/GymFlow/GymFlow/Views/Components/WorkoutCustomizationSheet.swift): day editing and exercise editing sheets

### Build and run

Generate the Xcode project from `project.yml`:

```bash
xcodegen generate
```

Open the project in Xcode:

```bash
open GymFlow.xcodeproj
```

Command-line build:

```bash
xcodebuild -project GymFlow.xcodeproj -scheme GymFlow -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

### Persistence model

`AppStore` stores the following locally:
- onboarding profile
- generated plan
- daily customized overrides
- active workout
- completed sessions
- recovery check-ins

There is no sync layer. If you delete the app from the simulator, its local data is removed.

### Current behavior worth knowing

- only one active workout session can run at a time
- multiple completed sessions can exist on the same day
- changing a day topic resets that day’s previous plan so the user can rebuild it freely
- logging a set automatically starts a break if the exercise is not finished
- effort feedback is numeric, but older saved `Too Easy` / `Too Hard` values are still decoded safely

### Safe extension points

If you want to extend the app, the cleanest places are:
- `AppStore` for new persistence or workout rules
- `WorkoutCustomizationSheet` for richer editing controls
- `ExerciseCard` for timer and logging UX
- `ProgressViewModel` for extra progress summaries
- `RecoveryViewModel` for additional recovery recommendations

### Resetting local state during development

The easiest reset path is to remove the app from the simulator, or clear the stored `UserDefaults` for the app bundle by reinstalling a clean build.

## Notes

GymFlow is intentionally local-first and prototype-friendly. The code is organized so the UI is easy to demo, while the workout state is still coherent enough to support:
- editable day topics
- custom exercise lists
- multiple sessions per day
- per-exercise timers
- local progress history
