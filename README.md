# GymFlow

GymFlow is a local-only SwiftUI iPhone app for workout planning, session tracking, run tracking, and recovery check-ins. It is built as a polished prototype, but it is fully runnable in Xcode and supports persistent local state through `UserDefaults`.

This README is split into two audiences:
- users: how to use the app day to day
- developers: how to run, understand, and extend the project

## User Guide

### What the app does

GymFlow helps you:
- build a weekly workout plan from onboarding answers
- edit each day freely, including the session topic and exercises
- set any day as a run day within the plan
- run multiple workout sessions in the same day
- track training time, set time, and break time per exercise
- rate effort on a `1-10` scale after a set
- start a GPS-tracked run with real-time pace, distance, and split tracking
- save completed runs and view them alongside workout sessions
- log recovery check-ins and get a lighter recommendation when needed

Everything is stored locally on the device or simulator. There is no login, backend, or HealthKit integration.

### First launch

On first launch, GymFlow shows a short onboarding flow:
1. fitness goal
2. training frequency
3. workout location
4. experience level

After onboarding, the app generates a weekly plan and opens the main 5-tab interface:
- `Today`
- `Run`
- `Plan`
- `Progress`
- `Recovery`

### Today tab

The `Today` tab is the main screen.

You can:
- review today's session
- edit the session topic and duration
- add, edit, swap, or remove exercises
- start a workout
- start a run (when the day is set to a run day)
- run multiple sessions in the same day
- see all completed workouts and runs for the day

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

#### Run days on the Today tab

When today's plan is set to `Run`:
- the Today tab shows a run mode selector and a `Start Run` button instead of exercises
- tapping `Start Run` opens a full-screen run tracking interface
- after completing, the run appears in Today's sessions alongside any workout sessions

### Run tab

The `Run` tab provides a standalone interface for running at any time, regardless of the day's plan.

You can:
- choose a run mode: `Free Run`, `Distance Goal`, `Time Goal`, or `Intervals`
- set distance or time goals with a slider
- start a run with a 3-second countdown
- view live metrics: distance, current pace, average pace, calories, elevation
- pause, resume, and stop the run
- see per-kilometer split notifications during the run
- save or discard the completed run
- browse run history with expandable split details

The active run interface is a full-screen dark layout optimized for glanceability during movement.

### Editing today's topic

You can edit the session topic from Today or Plan.

Important behavior:
- if you change today's topic, GymFlow clears the previous focus text and exercise list for that day
- setting the topic to `Run` converts the day into a run day with no exercises
- setting the topic to `Open Session` creates a blank slate for building a session from scratch

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
- `Run`
- `Open Session`
- any custom topic you type yourself

Run days appear in the weekly plan with a distinct icon and the label "Run session" instead of an exercise count. For users with five or more training days, the generated plan includes a run day by default.

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
- CoreLocation for GPS-based run tracking
- XcodeGen for project generation

### Project layout

- `project.yml`: XcodeGen source of truth
- `GymFlow.xcodeproj`: generated Xcode project
- `GymFlow/App`: app entry and root flow
- `GymFlow/Models`: Codable models for workouts, sessions, recovery, user profile, and run records
- `GymFlow/Store`: `AppStore` persistence, `WorkoutPlanGenerator`, and `LocationTracker`
- `GymFlow/ViewModels`: screen-specific view models including `RunViewModel`
- `GymFlow/Views/Components`: reusable UI pieces including run tracking views
- `GymFlow/Views/Onboarding`: onboarding flow
- `GymFlow/Views/Tabs`: Today, Run, Plan, Progress, and Recovery screens
- `GymFlow/Theme`: colors and app-wide visual styling

### Important files

- [GymFlowApp.swift](/Users/rhine_e/Documents/26WN/497/A2/GymFlow/GymFlow/App/GymFlowApp.swift): app entry point and environment store injection
- [RootView.swift](/Users/rhine_e/Documents/26WN/497/A2/GymFlow/GymFlow/App/RootView.swift): onboarding-to-tabs root switch
- [AppStore.swift](/Users/rhine_e/Documents/26WN/497/A2/GymFlow/GymFlow/Store/AppStore.swift): local persistence, active workout logic, day overrides, multi-session support, run history
- [WorkoutPlanGenerator.swift](/Users/rhine_e/Documents/26WN/497/A2/GymFlow/GymFlow/Store/WorkoutPlanGenerator.swift): generated starter plan content including run days
- [TodayView.swift](/Users/rhine_e/Documents/26WN/497/A2/GymFlow/GymFlow/Views/Tabs/TodayView.swift): main workout flow, run day handling, full-screen run session cover
- [RunView.swift](/Users/rhine_e/Documents/26WN/497/A2/GymFlow/GymFlow/Views/Tabs/RunView.swift): standalone run tab with mode selection and run history
- [RunViewModel.swift](/Users/rhine_e/Documents/26WN/497/A2/GymFlow/GymFlow/ViewModels/RunViewModel.swift): run state machine, GPS ingestion, split tracking, timer management
- [ActiveRunView.swift](/Users/rhine_e/Documents/26WN/497/A2/GymFlow/GymFlow/Views/Components/ActiveRunView.swift): full-screen dark run tracking interface
- [RunSummaryView.swift](/Users/rhine_e/Documents/26WN/497/A2/GymFlow/GymFlow/Views/Components/RunSummaryView.swift): post-run stats and split review
- [LocationTracker.swift](/Users/rhine_e/Documents/26WN/497/A2/GymFlow/GymFlow/Store/LocationTracker.swift): CoreLocation wrapper for GPS updates during runs
- [ExerciseCard.swift](/Users/rhine_e/Documents/26WN/497/A2/GymFlow/GymFlow/Views/Components/ExerciseCard.swift): per-exercise timers, break targets, effort scale
- [WorkoutCustomizationSheet.swift](/Users/rhine_e/Documents/26WN/497/A2/GymFlow/GymFlow/Views/Components/WorkoutCustomizationSheet.swift): day editing and exercise editing sheets, including run day handling

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
- run history
- recovery check-ins
- default workout templates
- saved topic options

There is no sync layer. If you delete the app from the simulator, its local data is removed.

### Current behavior worth knowing

- only one active workout session can run at a time
- runs operate independently of the workout system and can be started at any time
- multiple completed sessions and runs can exist on the same day
- completed runs appear in the Today tab's "Today's sessions" section
- changing a day topic resets that day's previous plan so the user can rebuild it freely
- setting a day topic to `Run` clears its exercise list and enables run-specific UI on Today
- logging a set automatically starts a break if the exercise is not finished
- effort feedback is numeric, but older saved `Too Easy` / `Too Hard` values are still decoded safely
- run data is persisted through `AppStore` and shared between the Run tab and the Today tab
- GPS accuracy affects run tracking quality; the location tracker requests authorization on first use
- for five-or-more-day plans, the generator includes a run day by default

### Safe extension points

If you want to extend the app, the cleanest places are:
- `AppStore` for new persistence or workout rules
- `RunViewModel` for additional run metrics or training modes
- `WorkoutCustomizationSheet` for richer editing controls
- `ExerciseCard` for timer and logging UX
- `ProgressViewModel` for extra progress summaries (including run stats)
- `RecoveryViewModel` for additional recovery recommendations

### Resetting local state during development

The easiest reset path is to remove the app from the simulator, or clear the stored `UserDefaults` for the app bundle by reinstalling a clean build.

## Notes

GymFlow is intentionally local-first and prototype-friendly. The code is organized so the UI is easy to demo, while the workout and run state is still coherent enough to support:
- editable day topics including run days
- custom exercise lists
- GPS-based run tracking with splits
- multiple sessions and runs per day
- per-exercise timers
- local progress and run history
