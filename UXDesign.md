# GymFlow UX Design Summary

## 1. Project Overview

GymFlow is a local-first iPhone workout planner, session tracker, and run tracker designed around one core UX goal: reduce the friction between deciding to work out and actually starting the workout.

The app does not try to be a full health platform. It avoids social feeds, login walls, heavy analytics, and complex setup. Instead, it focuses on a smaller but more coherent experience:

- generate a simple weekly training structure
- let the user customize any day freely
- make the workout execution flow obvious in the moment
- provide a dedicated run tracking experience integrated into the plan
- support recovery-aware decisions
- show progress in a low-pressure way

This makes GymFlow especially suitable for users who want structure, but do not want to feel trapped by a rigid training plan.

## 2. UX Problem Statement

Many fitness apps fail in one of two ways:

1. They are too rigid.
Users are forced into a predefined split, fixed exercise lists, or fixed workout times.

2. They are too open-ended.
Users face a blank page with no guidance, so every workout starts with decision fatigue.

GymFlow is designed to sit between those extremes. It gives the user a starting point, but preserves the ability to override nearly everything.

The UX problem GymFlow solves is:

"How can a workout app provide enough structure to help the user act quickly, while still allowing them to adapt the workout to real life, energy level, schedule changes, and personal preference?"

## 3. Target User

The implied target user is someone who:

- wants to train consistently but does not always follow a rigid program
- may train in a gym, at home, or in both contexts
- runs outdoors or on a treadmill as part of their routine
- wants quick editing of workouts before starting
- benefits from clear session timing during training
- wants a clean snapshot of progress without excessive metrics
- may need recovery guidance to avoid overtraining or skipping completely

The app is also particularly aligned with student or busy-lifestyle use cases, where training context changes often and plans must remain flexible.

## 4. High-Level UX Strategy

The UX strategy is built around five principles.

### 4.1 Keep the next action obvious

The app emphasizes immediate, practical actions:

- `Start Today's Workout`
- `Start Run`
- `Edit Session Details`
- `Add Exercise`
- `Start Set`
- `Log Set`
- `Finish Workout`

The interface tries to answer "What should I do next?" instead of showing large amounts of passive information.

### 4.2 Start with guidance, then allow override

Onboarding generates a weekly plan so the user is never dropped into a blank state. But nearly every piece of that plan can be changed:

- topic
- focus
- exercises
- sets
- reps
- weights
- reusable topic defaults
- switching a day to a run day

This is one of the most important UX decisions in the project.

### 4.3 Make workout execution lightweight

During a session, the UI avoids hiding timing and action controls under extra layers. Each exercise card carries:

- its current status
- its set progress
- its training timer
- its break timer
- its break target
- its effort feedback scale
- its edit action

This keeps the interaction local to the exercise the user is currently performing.

During a run, the same principle applies: the full-screen run interface shows live distance, pace, splits, and controls without requiring navigation.

### 4.4 Reduce pressure in progress and recovery

Progress is presented as momentum, not judgment. Recovery is presented as guidance, not punishment. This is reflected in copy, layout, and data density.

### 4.5 Support imperfect real-world behavior

The app allows:

- multiple workout sessions in the same day
- topic changes on the fly
- blank "Open Session" days
- custom topics
- reusable defaults from user-customized plans
- ad-hoc runs from the Run tab regardless of the day's plan
- completed runs appearing in Today's sessions

This design assumes users do not always follow a perfect weekly script.

## 5. Information Architecture

The app has a five-tab structure after onboarding:

- `Today`
- `Run`
- `Plan`
- `Progress`
- `Recovery`

This information architecture is deliberate.

### Today

The execution surface. This is where the user sees what to do now, edits today's session, starts a workout or a run, and reviews completed sessions.

### Run

The standalone run surface. This is where the user can start a run at any time, configure run modes and goals, and view their run history. Running is also accessible from the Today tab when the day is a run day, but the Run tab provides a dedicated entry point independent of the weekly plan.

### Plan

The weekly planning surface. This is where the user sees the week as a sequence, reviews day cards including run days, and customizes sessions beyond today.

### Progress

The reflection surface. This is where the app summarizes consistency and momentum without requiring the user to interpret dense charts.

### Recovery

The check-in surface. This is where the user gives quick self-assessment inputs and receives a recommendation.

This five-part split keeps each tab focused on a single mental job, while the Run tab's integration with the Plan and Today tabs prevents it from feeling disconnected.

## 6. Onboarding UX

The onboarding flow asks for four inputs:

- fitness goal
- training frequency
- workout location
- experience level

### Why this works

These questions are enough to generate a believable starter plan without overwhelming the user with setup.

Each onboarding step uses:

- one main question
- a short subtitle
- a list of clear options
- one-tap selection
- a progress indicator at the top

The copy tone is supportive and realistic. For example, the frequency step asks what feels realistic, not ideal. This matters because it frames the app as a partner for sustainable behavior, not an aspirational judge.

### UX purpose of the summary step

Before entering the app, the user sees:

- their selected settings
- a preview of the first workout

This gives closure and reinforces that the app has built something tangible from the setup inputs.

## 7. Today Tab UX

The `Today` tab is the core of the product.

### 7.1 Primary role

The Today screen is designed to bridge planning and action. It answers:

- What is today's session?
- Can I change it quickly?
- Can I start now?
- What am I doing during the workout?

### 7.2 Header design

The top card uses a high-energy gradient and a conversational question:

"What should you do today?"

This does two things:

- it gives the app a more human, guiding tone
- it frames the screen around action, not reporting

When a workout is active, the header changes into a live session summary with:

- completion ring
- total workout timer
- session title
- encouragement text

This helps maintain context while the user scrolls the session.

### 7.3 Pre-workout state

If the user has a plan but no active session, Today shows:

- the current topic
- focus area
- exercise preview rows
- `Edit Session Details`
- `Add Exercise`
- `Start Today's Workout`

The screen allows editing before commitment. This is an important UX decision because many users want to adjust the workout based on how they feel that day.

### 7.4 Run day state

If today's plan is set to `Run`, the Today tab adapts to show a run-specific interface:

- a run day explanation card
- a horizontal run mode selector (Free Run, Distance Goal, Time Goal, Intervals)
- goal configuration controls when a goal mode is selected
- `Start Run` button
- `Edit Session Details` to change the day topic

Tapping `Start Run` opens a full-screen run tracking interface with countdown, live distance, pace, elevation, calories, and split notifications. The user can pause, resume, and stop the run. After completing, a summary screen shows the full run stats with the option to save or discard.

This design means running is a first-class citizen in the Today flow. The user does not need to switch tabs to start a planned run.

### 7.5 Empty or recovery state

If the day has no exercises, the screen does not become unusable. Instead, it shifts into a builder state:

- an empty-state explanation
- a path to edit session details
- a path to add exercises

If the day is recovery-oriented, the user is still allowed to train. This reinforces flexibility instead of forcing a prescribed day type.

### 7.6 Active workout state

Once the workout starts, the UX becomes exercise-centered.

Each exercise appears as its own card with:

- exercise name
- set and rep target
- current weight
- edit button
- completion count
- supportive hint or adjustment note
- status label
- live timer block
- break target controls
- effort scale
- primary action button

The user does not need to open a separate timer page or a separate logging sheet. This reduces context switching during training.

### 7.7 Timing model

The timing model is one of the strongest UX ideas in the app.

There are two time layers:

1. Workout-level timer
- starts when today's workout starts
- gives a sense of whole-session duration

2. Exercise-level timer
- tracks training time when a set is in progress
- tracks break time after a set is logged

This matches how people actually experience workouts: globally as a session, and locally as alternating effort and rest.

### 7.8 Set interaction model

The interaction is intentionally simple:

1. Tap `Start Set`
2. Status becomes `Training`
3. Training timer runs
4. Tap `Log Set`
5. Break begins automatically if more sets remain
6. Tap `Start Set` again when ready

Removing a separate `Break` button was a good UX simplification because break is usually a consequence of logging a set, not a separate user decision.

### 7.9 Effort capture

Instead of broad labels like "Too Easy" or "Too Hard", the app uses a `1-10` effort scale. This is better UX because:

- it gives more nuance
- it aligns with familiar training effort concepts
- it can support smarter recommendations later

### 7.10 Multiple sessions per day

After finishing a workout, the day does not lock. The completed session appears as a recap card, while the user can still edit today's setup and start another session.

### 7.11 Today's sessions section

The "Today's sessions" section at the bottom of the Today tab shows all activity completed today in one place:

- completed workout sessions with set counts, duration, and logged exercise details
- completed runs with distance, duration, and average pace

This unified view means a user who does a morning run and an evening lifting session sees both in one spot. It reinforces the idea that all training activity, regardless of type, belongs to the same day.

## 8. Run Tab UX

The `Run` tab provides a dedicated, always-accessible interface for running.

### 8.1 Primary role

The Run tab exists because running has fundamentally different interaction needs than weight training. A workout session is composed of discrete sets, reps, and exercises. A run is a continuous activity that demands real-time feedback on pace, distance, and effort.

The Run tab answers:

- Can I start a run right now?
- What mode do I want to run in?
- How did my recent runs look?

### 8.2 Idle screen

When no run is in progress, the Run tab shows:

- a prominent circular `Start Run` button
- a horizontal mode selector: `Free Run`, `Distance Goal`, `Time Goal`, `Intervals`
- goal configuration controls (distance slider or time slider) when a goal mode is selected
- a recent runs history section

This layout gives the user a fast path to action at the top, configuration in the middle, and reflection at the bottom.

### 8.3 Run modes

The four run modes serve different user intentions:

- `Free Run`: no goal, just track what happens
- `Distance Goal`: the run auto-completes when the target distance is reached
- `Time Goal`: the run auto-completes when the target time is reached
- `Intervals`: structured effort and recovery segments

Mode selection uses capsule-style chips for quick one-tap switching.

### 8.4 Active run interface

Once a run starts, the tab transitions to a full-screen dark interface. This is a deliberate design choice:

- the dark background reduces visual distraction during outdoor use
- large distance numbers are readable at a glance while moving
- the layout prioritizes the most important real-time metric (distance) as a hero element

The active run screen shows:

- elapsed time at the top
- hero distance in large typography
- a grid of secondary metrics: current pace, calories, average pace, elevation
- split flash notifications when a new kilometer is reached
- a pause button, or resume and stop buttons when paused

### 8.5 Countdown

Before the run begins, a 3-second countdown overlay gives the user time to prepare. This avoids accidental premature starts and creates a moment of focus.

### 8.6 Split tracking

The app tracks per-kilometer splits using GPS. When a new split is reached:

- a flash notification appears with the split pace
- haptic feedback fires for awareness without visual attention

This gives the runner periodic performance checkpoints without requiring them to look at the screen constantly.

### 8.7 Run summary

After stopping a run, a summary screen appears with:

- a celebration header
- stats grid: distance, duration, average pace, calories, elevation
- a per-kilometer split table with the fastest split highlighted
- `Save Run` and `Discard` actions

This gives the runner a moment to review before committing the data.

### 8.8 Run history

Saved runs appear in the recent runs section on the idle screen. Each card shows:

- date
- distance
- duration
- average pace

Tapping a card expands it to reveal:

- calories
- elevation gain
- per-kilometer splits with pace and elevation change
- a delete option

### 8.9 Integration with AppStore

Run records are persisted through the same `AppStore` that manages workout data. This means:

- run history survives app restarts
- runs completed from either the Run tab or the Today tab appear in the same history
- today's runs are visible in the Today tab's sessions section

## 9. Session Customization UX

The workout customization experience is central to the flexibility of the app.

### 9.1 Daily customization model

Customization is date-specific. This means users can change today's session without destroying the entire weekly plan.

This is a strong UX decision because it separates:

- the baseline plan
- the actual plan for a specific day

### 9.2 Edit Session Details

The session details editor allows the user to change:

- topic
- focus
- reusable-topic behavior
- default-template behavior

The topic system supports:

- built-in topics like `Push`, `Pull`, `Upper`, `Lower`, `Run`
- `Open Session`
- custom topics typed by the user

### 9.3 Topic semantics

The app assigns different UX behaviors to different topic types.

#### Standard topics

Examples:

- Push
- Pull
- Legs
- Upper
- Lower

These can load a default or generated session template, so changing to one of these topics can instantly swap the exercise list to a useful example plan.

#### Run

The `Run` topic converts a day into a run day. This clears the exercise list and signals the Today tab to show run-specific controls instead of exercise cards. The WorkoutCustomizationSheet shows a run-specific empty state explaining that runs are started from Today or the Run tab.

This is an important UX decision: it allows running to live within the same plan structure as weight training without forcing it into an exercise-based model that does not fit.

#### Open Session

This is intentionally a blank state topic. It clears the exercise list so the user can build a session from scratch. This supports maximum flexibility.

#### Custom topics

The user can type a topic label freely, then optionally save that topic as a reusable option for the future. This supports personalization without forcing rigid taxonomy.

### 9.4 Topic guidance

The editor includes topic guidance:

- `Open Session` explicitly explains that it clears the exercise list
- `Run` explains that the day becomes a run day with no exercises
- built-in topics like `Upper` and `Lower` show example default plan content

This helps the user understand what will happen before saving the change.

### 9.5 Exercise editing

Each exercise can be edited individually with controls for:

- name
- sets
- reps
- weight
- hint

The design includes wheel-style selection for common structured values and text entry when custom values are needed. This balances speed and flexibility.

### 9.6 Per-exercise edit access

Editing is available from each exercise row/card, not only from a top-level customization entry point. This is better UX because it places editing where the user notices the need to edit.

### 9.7 Reusable defaults

One of the more advanced UX features is the ability to save a customized day as the new default for a topic. For example:

- customize a Push day
- save it as the default Push template
- later apply it instantly to future Push days

This turns one-time customization into reusable personalization. It is a strong design choice because it respects user preference accumulation over time.

## 10. Plan Tab UX

The Plan tab is intentionally lighter than Today.

### 10.1 Primary role

Its job is not to run the workout. Its job is to:

- show the structure of the week
- help the user understand where today fits
- provide a point of entry for editing other days

### 10.2 Weekly card system

Each day is shown as a card with:

- weekday and date
- icon by workout kind (including a distinct run icon for run days)
- topic title
- focus text
- exercise count, or "Run session" for run days
- special emphasis for today

This makes the week scannable without requiring calendar complexity.

### 10.3 Run days in the plan

Run days appear naturally within the weekly plan. For users with five or more training days, the generated plan includes a run day by default. Any other day can also be converted to a run day through the topic editor.

Run day cards are visually consistent with other day cards but display "Run session" instead of an exercise count. Tapping a run day card opens the customization sheet, which shows a run-specific empty state and allows changing the topic if the user decides to do a different type of session instead.

### 10.4 Adjust My Plan

The user can regenerate the weekly structure by changing:

- training frequency
- workout location

This is a good planning-layer interaction because it modifies the strategic plan without exposing unnecessary low-level settings.

## 11. Progress Tab UX

The Progress tab deliberately avoids heavy dashboards.

### 11.1 Core design philosophy

Progress is framed as clarity and momentum, not surveillance.

The tab shows enough to be meaningful, but not enough to become intimidating.

### 11.2 Two-ring weekly summary

The weekly summary now has two separate rings:

- `Days`: distinct active workout days this week
- `Minutes`: total workout minutes this week

This is a much better UX than counting sessions alone, because it reflects the difference between:

- training often in one day
- training consistently across a week

### 11.3 Supporting metrics

Below the rings, the app shows:

- current streak
- total completed workouts
- simple PRs
- milestone badges
- recent wins

These are chosen because they are easy to understand in seconds.

### 11.4 Simplified trend card

Instead of a dense data visualization, the app uses a lightweight trend card for pressing performance. This fits the prototype's UX direction:

- enough visual interest for a demo
- low interpretation cost for the user

## 12. Recovery Tab UX

The Recovery tab adds self-awareness without becoming clinical.

### 12.1 Inputs

The user rates:

- energy
- soreness
- sleep

These are practical variables users can usually answer quickly.

### 12.2 Output

The app produces a recommendation such as:

- train as planned
- go lighter
- prioritize recovery

### 12.3 UX value

This tab prevents the app from communicating that more training is always better. It creates a more balanced training experience and supports safer decision-making.

## 13. Visual Design System

The visual style supports the app's positioning as energetic but calm.

### 13.1 Color

The palette uses:

- a green-teal accent for readiness and action
- a warm orange accent for training intensity
- yellow for break/caution
- green for completion/success
- red for destructive actions

The hero gradient mixes deep green, lighter teal, and warm orange. This creates a more distinct identity than a generic white-and-blue productivity app.

### 13.2 Surfaces

The UI uses layered card surfaces:

- grouped system background as the shell
- rounded secondary cards for content blocks
- prominent hero cards for main state changes
- a full-screen dark surface for the active run interface

This helps users understand hierarchy through shape and elevation-like contrast.

### 13.3 Shape language

Rounded cards, capsules, and pill controls are used heavily. This produces:

- a touch-friendly feel
- approachable interaction targets
- a softer, less punishing emotional tone

### 13.4 Typography

Large rounded titles are used for emotional emphasis in key areas like Today and onboarding. The active run interface uses extra-large distance numbers for glanceable feedback during movement. Supporting copy is smaller and more muted. This creates a clear visual hierarchy:

- emotional headline
- practical explanation
- compact interaction controls

### 13.5 Motion and transition

The root flow and important actions use spring animation. The run interface uses state-driven transitions between idle, countdown, active, and summary screens. This gives the app a lightweight sense of continuity without turning it into a motion-heavy experience.

## 14. Interaction Design Patterns

The app repeatedly uses a few good interaction patterns.

### 14.1 Progressive disclosure

The user sees a simple weekly plan first, then can drill into a day, then into an exercise, then into per-set behavior. For run days, the flow goes from plan to run mode selection to the full-screen tracking experience.

### 14.2 Contextual editing

Edit controls are placed where the user notices the need to change something.

Examples:

- edit session details near the session
- edit button on each exercise
- per-exercise timer and break controls on each active card
- run mode and goal selection inline before starting

### 14.3 Friendly empty states

The app does not punish empty states. Instead, it explains what the user can do next. Run days show a clear explanation directing the user to start from Today or the Run tab.

### 14.4 One-active-session rule

Only one active workout can run at a time. From a UX perspective, this prevents confusion and maintains a clear mental model. Runs operate independently of the workout system, so a user could theoretically finish a workout and then do a run on the same day.

### 14.5 Full-screen focus for running

When a run is active, the interface goes full-screen with a dark background. This is a deliberate mode shift that communicates "you are now in a different kind of activity" and reduces distraction during outdoor movement.

## 15. Content and Tone

The copywriting style is one of the quieter strengths of the UX.

The tone is:

- supportive
- concise
- realistic
- non-judgmental

Examples of tone strategy:

- "Choose the schedule you can actually keep"
- "A lighter day can support long-term consistency"
- "Build the session your own way"
- "Pick a mode and tap Start. Pace, distance, and splits are tracked in real time."

This language reduces pressure while keeping the app action-oriented.

## 16. Data and State UX Implications

The product is local-only and uses persistent local storage. UX implications:

- fast startup
- no account barrier
- no dependency on internet connection
- more prototype simplicity
- less concern about privacy perception during a class demo

It also means the app feels personal and immediate rather than platform-heavy.

Run history and workout history share the same persistence layer, which means the user never has to think about where their data lives.

## 17. Key UX Strengths

- Clear information architecture with five distinct jobs
- Strong Today screen that connects planning and execution for both workouts and runs
- Running integrated into the plan without forcing it into an exercise-based model
- Standalone Run tab available anytime regardless of the day's plan
- High flexibility without collapsing into chaos
- Good per-exercise timing design
- Sensible support for multiple sessions per day
- Completed runs and workouts both appear in Today's sessions
- Reusable default templates are a strong personalization feature
- Progress and recovery are presented with low emotional pressure
- Visual design has more identity than a generic template app

## 18. Key UX Tradeoffs and Limitations

For an honest presentation, these tradeoffs are worth mentioning.

- The app is optimized for clarity, not for advanced athlete-level analytics.
- It currently depends on manual input rather than wearable or HealthKit integration.
- Timer interactions are embedded per exercise, which is powerful, but can make cards visually dense.
- Because the app prioritizes flexibility, users who want a fully locked-down program may find it too open.
- Run tracking depends on GPS, which may have limited accuracy indoors or in areas with poor signal.

These are acceptable tradeoffs for the app's intended direction.

## 19. Why This UX Is Coherent

The app works because all of its design choices support the same central idea:

"Give the user a plan, but never trap them inside it."

That principle appears in every layer:

- onboarding gives structure
- Today enables quick action for both workouts and runs
- session editing enables adaptation
- Run topic converts any day into a run day
- the Run tab lets users run anytime outside the plan
- Open Session supports full freedom
- reusable defaults support personalization
- progress avoids guilt-heavy metrics
- recovery encourages sustainable training

This is why the UX feels cohesive rather than like a random collection of features.

## 20. Suggested 5-Minute Presentation Structure

If you want ChatGPT to turn this into a short script, this is the clearest speaking structure:

### Part 1: Problem and concept

- Many workout apps are either too rigid or too open-ended.
- GymFlow is designed to balance guidance and flexibility.
- The goal is to reduce decision fatigue while preserving user control.

### Part 2: Core user flow

- Onboarding asks only four practical questions.
- The app then opens into five tabs: Today, Run, Plan, Progress, Recovery.
- Today is the main action surface where the user edits, starts, times, and logs workouts or runs.

### Part 3: Key UX innovations

- Daily sessions are flexible and can be rebuilt at any time.
- Running is integrated into the weekly plan as a first-class day type.
- The Run tab provides a dedicated interface with GPS-based pace, distance, and split tracking.
- Exercise cards contain their own training and break timing.
- Users can save customized topics as reusable defaults.
- Open Session supports completely blank training days.

### Part 4: Progress and recovery philosophy

- Progress emphasizes momentum, not pressure.
- Recovery makes the app safer and more realistic.
- The whole product encourages consistency over perfection.

### Part 5: Closing design statement

- GymFlow is not trying to be everything.
- It is designed to make the next workout or run easy to start, easy to adapt, and easy to understand.

## 21. One-Sentence Thesis

GymFlow's UX design is a flexible training system that gives users just enough structure to act quickly on workouts and runs, while preserving the freedom to adapt each day to their own goals, energy, and real-life schedule.
