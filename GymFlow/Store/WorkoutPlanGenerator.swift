import Foundation

enum WorkoutPlanGenerator {
    private static let calendar = Calendar.current

    static func makePlan(for profile: UserProfile, referenceDate: Date = .now) -> WorkoutPlan {
        let startOfDay = calendar.startOfDay(for: referenceDate)
        let offsets = scheduledOffsets(for: profile.frequency.weeklySessions)
        let workoutKinds = workoutKinds(for: profile)

        var days: [WorkoutDay] = []

        for offset in 0..<7 {
            let date = calendar.date(byAdding: .day, value: offset, to: startOfDay) ?? startOfDay
            let weekday = calendar.component(.weekday, from: date)
            let isWorkoutDay = offsets.contains(offset)

            if isWorkoutDay {
                let kindIndex = offsets.firstIndex(of: offset) ?? 0
                let kind = workoutKinds[min(kindIndex, workoutKinds.count - 1)]
                days.append(makeWorkoutDay(kind: kind, weekday: weekday, profile: profile))
            } else {
                days.append(
                    WorkoutDay(
                        weekday: weekday,
                        kind: .recovery,
                        title: "Recovery",
                        focusArea: "Mobility, walking, light stretching",
                        estimatedMinutes: 20,
                        exercises: []
                    )
                )
            }
        }

        return WorkoutPlan(
            generatedAt: .now,
            summary: planSummary(for: profile),
            days: days.sorted { $0.weekday < $1.weekday }
        )
    }

    private static func scheduledOffsets(for sessions: Int) -> [Int] {
        switch sessions {
        case 2:
            return [0, 3]
        case 3:
            return [0, 2, 4]
        case 4:
            return [0, 1, 3, 5]
        default:
            return [0, 1, 2, 4, 5]
        }
    }

    private static func workoutKinds(for profile: UserProfile) -> [WorkoutDayKind] {
        switch profile.frequency {
        case .twoDays:
            if profile.goal == .chestFocus {
                return [.chestFocus, .fullBody]
            }
            return [.fullBody, .fullBody]
        case .threeDays:
            if profile.goal == .chestFocus {
                return [.chestFocus, .pull, .legs]
            }
            return [.push, .pull, .legs]
        case .fourDays:
            if profile.goal == .chestFocus {
                return [.chestFocus, .lower, .push, .pull]
            }
            return [.upper, .lower, .push, .fullBody]
        case .fivePlusDays:
            if profile.goal == .chestFocus {
                return [.chestFocus, .pull, .legs, .push, .conditioning]
            }
            return [.push, .pull, .legs, .upper, .conditioning]
        }
    }

    private static func planSummary(for profile: UserProfile) -> String {
        "\(profile.frequency.rawValue) focused around \(profile.goal.rawValue.lowercased()) with \(profile.location.rawValue.lowercased()) options."
    }

    private static func makeWorkoutDay(
        kind: WorkoutDayKind,
        weekday: Int,
        profile: UserProfile
    ) -> WorkoutDay {
        WorkoutDay(
            weekday: weekday,
            kind: kind,
            title: kind.rawValue,
            focusArea: focusArea(for: kind, goal: profile.goal),
            estimatedMinutes: estimatedMinutes(for: kind, experience: profile.experienceLevel),
            exercises: exercises(for: kind, profile: profile)
        )
    }

    private static func focusArea(for kind: WorkoutDayKind, goal: FitnessGoal) -> String {
        switch kind {
        case .custom:
            return "Flexible session you can shape any way you want"
        case .push:
            return goal == .chestFocus ? "Pressing strength and chest volume" : "Chest, shoulders, and triceps"
        case .pull:
            return "Back, posture, and upper-arm support"
        case .legs:
            return "Quads, glutes, and lower-body stability"
        case .fullBody:
            return "Fast full-body work with low decision fatigue"
        case .upper:
            return "Balanced upper-body strength"
        case .lower:
            return "Lower-body strength and support work"
        case .chestFocus:
            return "Chest bias with supporting push volume"
        case .conditioning:
            return "Short conditioning and core support"
        case .recovery:
            return "Recovery and light movement"
        }
    }

    private static func estimatedMinutes(for kind: WorkoutDayKind, experience: ExperienceLevel) -> Int {
        let base: Int

        switch kind {
        case .conditioning:
            base = 30
        case .recovery:
            base = 20
        case .fullBody:
            base = 40
        default:
            base = 45
        }

        switch experience {
        case .beginner:
            return base
        case .returning:
            return base + 5
        case .intermediate:
            return base + 10
        }
    }

    private static func exercises(for kind: WorkoutDayKind, profile: UserProfile) -> [Exercise] {
        switch profile.location {
        case .gym:
            return gymExercises(for: kind, profile: profile)
        case .home:
            return homeExercises(for: kind, profile: profile)
        case .both:
            return mixedExercises(for: kind, profile: profile)
        }
    }

    private static func gymExercises(for kind: WorkoutDayKind, profile: UserProfile) -> [Exercise] {
        switch kind {
        case .push:
            return [
                exercise("Chest Press", sets: 3, reps: "8-10", weight: suggestedWeight(light: 45, medium: 75, profile: profile), hint: "Slow the lowering phase to keep chest tension."),
                exercise("Incline Dumbbell Press", sets: 3, reps: "10-12", weight: suggestedWeight(light: 20, medium: 35, profile: profile), hint: "Keep shoulders down and stable."),
                exercise("Seated Shoulder Press", sets: 3, reps: "8-10", weight: suggestedWeight(light: 20, medium: 30, profile: profile), hint: "Press straight up without rushing."),
                exercise("Cable Fly", sets: 2, reps: "12-15", weight: suggestedWeight(light: 15, medium: 25, profile: profile), hint: "Think squeeze, not swing."),
                exercise("Triceps Pressdown", sets: 2, reps: "12-15", weight: suggestedWeight(light: 20, medium: 35, profile: profile), hint: "Lock elbows near your sides.")
            ]
        case .pull:
            return [
                exercise("Lat Pulldown", sets: 3, reps: "8-10", weight: suggestedWeight(light: 55, medium: 85, profile: profile), hint: "Pull elbows toward your back pockets."),
                exercise("Seated Cable Row", sets: 3, reps: "10-12", weight: suggestedWeight(light: 50, medium: 80, profile: profile), hint: "Pause with the chest tall."),
                exercise("Chest-Supported Row", sets: 3, reps: "8-10", weight: suggestedWeight(light: 25, medium: 45, profile: profile), hint: "Keep the neck relaxed."),
                exercise("Face Pull", sets: 2, reps: "12-15", weight: suggestedWeight(light: 15, medium: 25, profile: profile), hint: "Lead with elbows and rotate open."),
                exercise("Hammer Curl", sets: 2, reps: "10-12", weight: suggestedWeight(light: 15, medium: 25, profile: profile), hint: "Stay smooth through the last reps.")
            ]
        case .legs:
            return [
                exercise("Leg Press", sets: 3, reps: "8-10", weight: suggestedWeight(light: 90, medium: 180, profile: profile), hint: "Drive through the full foot."),
                exercise("Romanian Deadlift", sets: 3, reps: "8-10", weight: suggestedWeight(light: 55, medium: 95, profile: profile), hint: "Push hips back before standing tall."),
                exercise("Walking Lunge", sets: 2, reps: "10-12", weight: suggestedWeight(light: 15, medium: 25, profile: profile), hint: "Take long, steady steps."),
                exercise("Leg Curl", sets: 2, reps: "12-15", weight: suggestedWeight(light: 35, medium: 55, profile: profile), hint: "Control both directions."),
                exercise("Standing Calf Raise", sets: 2, reps: "12-15", weight: suggestedWeight(light: 40, medium: 70, profile: profile), hint: "Pause at the top for one beat.")
            ]
        case .fullBody, .custom:
            return [
                exercise("Goblet Squat", sets: 3, reps: "8-10", weight: suggestedWeight(light: 20, medium: 40, profile: profile), hint: "Sit between the hips, not forward."),
                exercise("Dumbbell Bench Press", sets: 3, reps: "8-10", weight: suggestedWeight(light: 20, medium: 40, profile: profile), hint: "Own the bottom position."),
                exercise("Cable Row", sets: 3, reps: "10-12", weight: suggestedWeight(light: 50, medium: 75, profile: profile), hint: "Pull with your back, not your wrists."),
                exercise("Romanian Deadlift", sets: 2, reps: "8-10", weight: suggestedWeight(light: 55, medium: 95, profile: profile), hint: "Keep lats tight on the way down."),
                exercise("Plank Hold", sets: 2, reps: "30-45", weight: "Bodyweight", hint: "Breathe slowly and keep ribs tucked.")
            ]
        case .upper:
            return [
                exercise("Bench Press", sets: 3, reps: "6-8", weight: suggestedWeight(light: 45, medium: 95, profile: profile), hint: "Press through the whole hand."),
                exercise("Lat Pulldown", sets: 3, reps: "8-10", weight: suggestedWeight(light: 55, medium: 85, profile: profile), hint: "Keep the chest proud."),
                exercise("Seated Shoulder Press", sets: 3, reps: "8-10", weight: suggestedWeight(light: 20, medium: 30, profile: profile), hint: "Brace before each rep."),
                exercise("Chest-Supported Row", sets: 3, reps: "8-10", weight: suggestedWeight(light: 25, medium: 45, profile: profile), hint: "Use a full pull and full reach."),
                exercise("Cable Curl", sets: 2, reps: "12-15", weight: suggestedWeight(light: 15, medium: 25, profile: profile), hint: "Keep shoulders out of the movement.")
            ]
        case .lower:
            return [
                exercise("Hack Squat", sets: 3, reps: "8-10", weight: suggestedWeight(light: 45, medium: 90, profile: profile), hint: "Stay controlled through the bottom."),
                exercise("Romanian Deadlift", sets: 3, reps: "8-10", weight: suggestedWeight(light: 55, medium: 95, profile: profile), hint: "Think hinge, then stand."),
                exercise("Bulgarian Split Squat", sets: 2, reps: "10-12", weight: suggestedWeight(light: 15, medium: 25, profile: profile), hint: "Keep the front foot planted."),
                exercise("Seated Leg Curl", sets: 2, reps: "12-15", weight: suggestedWeight(light: 35, medium: 55, profile: profile), hint: "Do not rush the eccentric."),
                exercise("Standing Calf Raise", sets: 2, reps: "12-15", weight: suggestedWeight(light: 40, medium: 70, profile: profile), hint: "Use a full range each rep.")
            ]
        case .chestFocus:
            return [
                exercise("Bench Press", sets: 4, reps: "6-8", weight: suggestedWeight(light: 45, medium: 95, profile: profile), hint: "Use a steady touch point each set."),
                exercise("Incline Dumbbell Press", sets: 3, reps: "8-10", weight: suggestedWeight(light: 20, medium: 35, profile: profile), hint: "Keep wrists stacked over elbows."),
                exercise("Machine Chest Press", sets: 3, reps: "10-12", weight: suggestedWeight(light: 40, medium: 70, profile: profile), hint: "Stop one rep before form breaks."),
                exercise("Cable Fly", sets: 2, reps: "12-15", weight: suggestedWeight(light: 15, medium: 25, profile: profile), hint: "Finish with a soft squeeze."),
                exercise("Triceps Dips", sets: 2, reps: "8-10", weight: "Bodyweight", hint: "Use an assisted machine if shoulders feel sticky.")
            ]
        case .conditioning:
            return [
                exercise("Bike Intervals", sets: 5, reps: "45", weight: "Moderate", hint: "Push hard for 45 seconds, then recover."),
                exercise("Kettlebell Swing", sets: 3, reps: "15", weight: suggestedWeight(light: 20, medium: 35, profile: profile), hint: "Snap hips, keep shoulders quiet."),
                exercise("Step-Up", sets: 2, reps: "12-14", weight: suggestedWeight(light: 15, medium: 25, profile: profile), hint: "Drive through the front leg."),
                exercise("Dead Bug", sets: 2, reps: "10-12", weight: "Bodyweight", hint: "Keep the low back gently anchored."),
                exercise("Mobility Flow", sets: 1, reps: "8", weight: "Easy", hint: "Move slowly through each position.")
            ]
        case .recovery:
            return []
        }
    }

    private static func homeExercises(for kind: WorkoutDayKind, profile: UserProfile) -> [Exercise] {
        switch kind {
        case .push, .chestFocus:
            return [
                exercise("Push-Up", sets: 3, reps: "8-12", weight: "Bodyweight", hint: "Use a bench or desk incline if needed."),
                exercise("Backpack Floor Press", sets: 3, reps: "10-12", weight: suggestedWeight(light: 15, medium: 25, profile: profile), hint: "Pause lightly at the floor."),
                exercise("Pike Press", sets: 3, reps: "8-10", weight: "Bodyweight", hint: "Shift weight into the shoulders."),
                exercise("Band Fly", sets: 2, reps: "12-15", weight: "Light band", hint: "Stay smooth and keep ribs down."),
                exercise("Chair Dip", sets: 2, reps: "8-12", weight: "Bodyweight", hint: "Shorten range if shoulders feel pinchy.")
            ]
        case .pull:
            return [
                exercise("Backpack Row", sets: 3, reps: "10-12", weight: suggestedWeight(light: 15, medium: 30, profile: profile), hint: "Drive elbows back, not up."),
                exercise("Band Row", sets: 3, reps: "12-15", weight: "Medium band", hint: "Pause with your shoulder blades back."),
                exercise("Reverse Snow Angel", sets: 2, reps: "10-12", weight: "Bodyweight", hint: "Lift slowly with control."),
                exercise("Band Face Pull", sets: 2, reps: "12-15", weight: "Light band", hint: "Rotate thumbs behind you."),
                exercise("Backpack Curl", sets: 2, reps: "10-12", weight: suggestedWeight(light: 10, medium: 20, profile: profile), hint: "Slow down the lowering phase.")
            ]
        case .legs, .lower:
            return [
                exercise("Backpack Squat", sets: 3, reps: "10-12", weight: suggestedWeight(light: 20, medium: 35, profile: profile), hint: "Stay tall through the chest."),
                exercise("Single-Leg Romanian Deadlift", sets: 3, reps: "8-10", weight: "Bodyweight", hint: "Reach long with the back leg."),
                exercise("Split Squat", sets: 3, reps: "10-12", weight: "Bodyweight", hint: "Use a wall for balance if needed."),
                exercise("Glute Bridge", sets: 2, reps: "12-15", weight: "Bodyweight", hint: "Hold the top for a beat."),
                exercise("Calf Raise", sets: 2, reps: "15-20", weight: "Bodyweight", hint: "Pause at the top.")
            ]
        case .fullBody, .upper, .custom:
            return [
                exercise("Backpack Squat", sets: 3, reps: "10-12", weight: suggestedWeight(light: 20, medium: 35, profile: profile), hint: "Keep knees tracking over feet."),
                exercise("Push-Up", sets: 3, reps: "8-12", weight: "Bodyweight", hint: "Use an incline to keep reps clean."),
                exercise("Backpack Row", sets: 3, reps: "10-12", weight: suggestedWeight(light: 15, medium: 30, profile: profile), hint: "Pause at the top."),
                exercise("Hip Hinge", sets: 2, reps: "12-15", weight: "Bodyweight", hint: "Move from the hips, not the low back."),
                exercise("Dead Bug", sets: 2, reps: "10-12", weight: "Bodyweight", hint: "Move arms and legs slowly.")
            ]
        case .conditioning:
            return [
                exercise("Stair Sprint", sets: 5, reps: "30", weight: "Fast pace", hint: "Push for 30 seconds, then recover."),
                exercise("Jump Rope", sets: 3, reps: "45", weight: "Steady", hint: "Relax the shoulders."),
                exercise("Mountain Climber", sets: 2, reps: "30", weight: "Bodyweight", hint: "Keep your hips level."),
                exercise("Bodyweight Squat", sets: 2, reps: "15", weight: "Bodyweight", hint: "Move with a full range."),
                exercise("Mobility Flow", sets: 1, reps: "8", weight: "Easy", hint: "Finish with slow breathing.")
            ]
        case .recovery:
            return []
        }
    }

    private static func mixedExercises(for kind: WorkoutDayKind, profile: UserProfile) -> [Exercise] {
        let base = gymExercises(for: kind, profile: profile)
        let homeOptions = homeExercises(for: kind, profile: profile)

        return zip(base, homeOptions).map { gymExercise, homeExercise in
            var updated = gymExercise
            updated.alternatives = [swapOption(from: homeExercise)] + gymExercise.alternatives
            return updated
        }
    }

    private static func exercise(
        _ name: String,
        sets: Int,
        reps: String,
        weight: String,
        hint: String
    ) -> Exercise {
        Exercise(
            name: name,
            targetSets: sets,
            targetReps: reps,
            suggestedWeight: weight,
            hint: hint,
            alternatives: defaultAlternatives(for: name, reps: reps, fallbackWeight: weight)
        )
    }

    private static func swapOption(from exercise: Exercise) -> ExerciseSwapOption {
        ExerciseSwapOption(
            name: exercise.name,
            targetReps: exercise.targetReps,
            suggestedWeight: exercise.suggestedWeight,
            hint: exercise.hint
        )
    }

    private static func suggestedWeight(light: Int, medium: Int, profile: UserProfile) -> String {
        switch profile.experienceLevel {
        case .beginner:
            return "\(light) lb"
        case .returning:
            return "\((light + medium) / 2) lb"
        case .intermediate:
            return "\(medium) lb"
        }
    }

    private static func defaultAlternatives(
        for name: String,
        reps: String,
        fallbackWeight: String
    ) -> [ExerciseSwapOption] {
        switch name {
        case "Bench Press", "Chest Press", "Machine Chest Press":
            return [
                ExerciseSwapOption(name: "Push-Up", targetReps: "8-12", suggestedWeight: "Bodyweight", hint: "Use an incline if you want smoother reps."),
                ExerciseSwapOption(name: "Dumbbell Floor Press", targetReps: reps, suggestedWeight: fallbackWeight, hint: "Great when you need a simpler setup."),
                ExerciseSwapOption(name: "Cable Press", targetReps: "10-12", suggestedWeight: fallbackWeight, hint: "Use this if the bench area is crowded.")
            ]
        case "Lat Pulldown", "Seated Cable Row", "Chest-Supported Row":
            return [
                ExerciseSwapOption(name: "Band Row", targetReps: "12-15", suggestedWeight: "Medium band", hint: "Easy to set up between classes."),
                ExerciseSwapOption(name: "Single-Arm Dumbbell Row", targetReps: reps, suggestedWeight: fallbackWeight, hint: "Brace against a bench or chair."),
                ExerciseSwapOption(name: "Inverted Row", targetReps: "8-10", suggestedWeight: "Bodyweight", hint: "Use a sturdy bar or Smith machine.")
            ]
        case "Leg Press", "Hack Squat", "Goblet Squat":
            return [
                ExerciseSwapOption(name: "Split Squat", targetReps: "10-12", suggestedWeight: "Bodyweight", hint: "A good swap when machines are taken."),
                ExerciseSwapOption(name: "Backpack Squat", targetReps: "10-12", suggestedWeight: "25 lb", hint: "Simple dorm-friendly substitute."),
                ExerciseSwapOption(name: "Step-Up", targetReps: "10-12", suggestedWeight: fallbackWeight, hint: "Drive through the working leg.")
            ]
        default:
            return [
                ExerciseSwapOption(name: "\(name) variation", targetReps: reps, suggestedWeight: fallbackWeight, hint: "Pick the nearby version that feels smooth today."),
                ExerciseSwapOption(name: "Band alternative", targetReps: "12-15", suggestedWeight: "Medium band", hint: "Helpful when equipment access is limited."),
                ExerciseSwapOption(name: "Bodyweight option", targetReps: "10-12", suggestedWeight: "Bodyweight", hint: "Keep the range controlled and repeatable.")
            ]
        }
    }
}
