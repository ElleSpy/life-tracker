import SwiftUI
import SwiftData

/// "What you're making" — a weekly food plan. Shows the next seven days with a
/// breakfast/lunch/dinner slot each; tap a slot to assign a recipe or free text.
struct MealPlanView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var entries: [MealPlanEntry]

    @State private var editingSlot: MealSlot?

    private let mealsShown: [MealType] = [.breakfast, .lunch, .dinner]

    private var weekDays: [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: today) }
    }

    var body: some View {
        List {
            ForEach(weekDays, id: \.self) { day in
                Section(day.formatted(.dateTime.weekday(.wide).month().day())) {
                    ForEach(mealsShown) { meal in
                        mealRow(day: day, meal: meal)
                    }
                }
            }
        }
        .sheet(item: $editingSlot) { slot in
            AssignMealView(day: slot.day, meal: slot.meal, existing: entry(for: slot.day, meal: slot.meal))
        }
    }

    private func mealRow(day: Date, meal: MealType) -> some View {
        let existing = entry(for: day, meal: meal)
        return Button {
            editingSlot = MealSlot(day: day, meal: meal)
        } label: {
            HStack {
                Label(meal.label, systemImage: meal.systemImage)
                    .foregroundStyle(Theme.Palette.subtleText)
                    .frame(width: 120, alignment: .leading)
                if let existing, !existing.isEmpty {
                    Text(existing.displayTitle).foregroundStyle(.primary)
                } else {
                    Text("Add").foregroundStyle(Theme.Palette.accent)
                }
                Spacer()
            }
        }
    }

    private func entry(for day: Date, meal: MealType) -> MealPlanEntry? {
        let start = Calendar.current.startOfDay(for: day)
        return entries.first {
            $0.mealType == meal && Calendar.current.isDate($0.date, inSameDayAs: start)
        }
    }
}

/// A day + meal position in the plan grid.
struct MealSlot: Identifiable {
    let day: Date
    let meal: MealType
    var id: String { "\(day.timeIntervalSince1970)-\(meal.rawValue)" }
}

#Preview {
    NavigationStack { MealPlanView() }
        .modelContainer(SampleData.previewContainer)
}
