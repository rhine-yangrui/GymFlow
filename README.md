# GymFlow
Build a polished iPhone app prototype in SwiftUI called “GymFlow”.

Goal:
Create a UX-focused fitness planning and workout tracking app for college students. This is a local-only prototype for Xcode, not a production app. The app should feel realistic, visually polished, and easy to demo in 5 minutes for a UX presentation.

Technical requirements:
- Use SwiftUI only
- Target iPhone
- No backend
- No login
- No HealthKit
- Use local mock data and local persistence only
- Use @AppStorage / UserDefaults or a simple local state store
- Make the project compile and run in Xcode
- Organize code cleanly into models, view models, views, and reusable components
- Add English comments only
- Use SF Symbols and native iOS design patterns
- Support dark mode
- Use accessible sizing and clear contrast
- Keep architecture simple and stable

App concept:
GymFlow helps students start working out quickly, follow a plan without overthinking, log workouts with minimal friction, see progress clearly, and avoid overtraining.

Primary UX principles:
- Reduce decision fatigue
- Frontload value
- Keep navigation shallow
- Make the main CTA obvious
- Design for quick scanning
- Use supportive, non-judgmental microcopy
- Show progress without creating pressure
- Include recovery and safety as part of the experience
- Use empty states well
- Make controls feel touch-friendly and accessible

Main structure:
Use a TabView with exactly 4 tabs:
1. Today
2. Plan
3. Progress
4. Recovery

App flow:
On first launch, show a 4-step onboarding flow before the tab interface appears.

Onboarding screens:
1. Goal selection
   - Build muscle
   - Lose fat
   - Stay consistent
   - Chest focus
   - General fitness

2. Training frequency
   - 2 days
   - 3 days
   - 4 days
   - 5+ days

3. Workout location
   - Gym
   - Dorm / home
   - Both

4. Experience level
   - Beginner
   - Intermediate
   - Returning after a break

Onboarding UX details:
- Show a progress indicator
- One primary action per screen
- Large tap targets
- Friendly microcopy
- Final summary screen that says the user’s plan is ready
- Generate a simple plan based on responses

Tab 1: Today
Purpose:
This is the home screen and most important page. It should answer: “What should I do today?”

UI content:
- Greeting/header
- Today’s workout title
- Estimated duration
- Progress ring or progress bar for today
- Exercise cards
- Each exercise card shows:
  - exercise name
  - target sets and reps
  - suggested weight
  - short hint line
  - log set button
  - too easy button
  - too hard button
- Rest timer card or simple timer section
- Primary CTA: Finish Workout
- If no workout has been started, show a clear CTA: Start Today’s Workout

Interaction:
- Logging a set updates progress
- Finish Workout marks the session complete
- Add subtle animations and haptic-style feedback placeholders if appropriate
- Include an empty state for first-time use

Microcopy examples:
- Start Today’s Workout
- Log First Set
- Too Easy
- Too Hard
- Finish Workout
- You’re halfway through today’s session

Tab 2: Plan
Purpose:
Show the user’s weekly structure and make the plan feel understandable and adjustable.

UI content:
- Weekly plan overview
- Cards for each day of the week
- Each day shows title like Push / Pull / Legs / Full Body / Recovery
- Show focus area and estimated time
- Highlight today
- Button: Adjust My Plan
- Button or sheet action: Swap Exercise

Interaction:
- Tapping a day shows a detail sheet
- Adjust My Plan opens a simple editable sheet
- Swap Exercise opens a sheet with 2–3 substitute options
- Keep this light and prototype-friendly

Tab 3: Progress
Purpose:
Make progress visible and motivating without overwhelming the user.

UI content:
- Weekly completion ring
- Current streak
- Total workouts completed
- Small personal records section
- Chest press trend or benchmark card
- Milestones / badges section
- Recent wins card

Include empty states:
- No workouts logged yet
- Complete today’s session to build your first streak

Visual style:
- Cards
- Simple charts or trend bars
- Clear hierarchy
- Focus on clarity more than data density

Tab 4: Recovery
Purpose:
Show that recovery and safety are part of fitness UX.

UI content:
- Daily recovery check-in
- 3 quick questions:
  - energy level
  - soreness
  - sleep quality
- Based on answers, show recommendation:
  - Train as planned
  - Go lighter today
  - Take a recovery day
- Recovery tips card
- Sleep / hydration / soreness guidance
- Beginner-safe reminders

Tone:
- Supportive, calm, not harsh
- Never shame the user
- Example text:
  - Recovery matters too
  - A lighter day can support long-term consistency
  - Rest is part of progress

Design system:
- Native iOS look using SwiftUI
- Use rounded cards, spacing, and clear hierarchy
- Use SF Symbols consistently
- Main accent color should feel energetic but calm
- Use semantic colors where possible
- Make all important controls large and finger-friendly
- Support Dynamic Type as much as practical
- Avoid relying only on color to show state
- Keep screens uncluttered

Reusable components to create:
- PrimaryButton
- SecondaryButton
- ProgressRing
- ExerciseCard
- StatCard
- EmptyStateView
- SectionHeader
- RecoveryRecommendationCard

Data model suggestions:
- UserProfile
- WorkoutPlan
- WorkoutDay
- Exercise
- LoggedSet
- ProgressStats
- RecoveryCheckIn
- Badge

State and persistence:
- Save onboarding completion
- Save generated plan
- Save logged workouts
- Save streak / stats
- Use local-only persistence

Demo polish:
- Add preview data
- Add smooth transitions between onboarding and main app
- Add light animations for progress updates
- Make the app feel complete enough for a class presentation
- Prioritize UI polish and UX clarity over technical complexity

Important:
- Do not overengineer
- Do not add backend or auth
- Do not add social features
- Do not add complex AI features
- Keep the code clean, modular, and runnable
- Include a short README explaining app structure and how the UX goals map to the screens

Please generate the full SwiftUI project structure and all necessary files.

## Implementation Notes

### Project structure
- `GymFlow.xcodeproj`: generated Xcode project for the iPhone SwiftUI app
- `project.yml`: XcodeGen source used to generate the project cleanly
- `GymFlow/App`: app entry point and onboarding-to-tabs root flow
- `GymFlow/Models`: Codable app models for profile, plan, workouts, progress, and recovery
- `GymFlow/Store`: local `UserDefaults` persistence and plan generation
- `GymFlow/ViewModels`: screen-focused view models for onboarding, today, plan, progress, and recovery
- `GymFlow/Views/Components`: reusable cards, buttons, progress ring, and empty states
- `GymFlow/Views/Onboarding`: 4-step onboarding plus summary screen
- `GymFlow/Views/Tabs`: Today, Plan, Progress, and Recovery tab screens

### UX mapping
- `Today`: keeps the next action obvious with a start CTA, clear workout card stack, rest timer, and fast set logging
- `Plan`: keeps navigation shallow with one weekly overview, quick day detail sheets, and simple adjust/swap flows
- `Progress`: shows momentum with a weekly completion ring, streak, records, badges, and recent wins without dense analytics
- `Recovery`: makes safety visible with a daily check-in, gentle recommendation logic, and calm recovery guidance
- Onboarding: reduces decision fatigue by asking one question per screen, showing progress, and generating the weekly plan automatically

### Local persistence
- `AppStore` saves onboarding state, generated plan, active workout, completed sessions, and recovery check-ins in `UserDefaults`
- No backend, auth, or external fitness integrations are used

### Build
- Generate the project with `xcodegen generate`
- Build from the command line with:

```bash
xcodebuild -project GymFlow.xcodeproj -scheme GymFlow -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```
