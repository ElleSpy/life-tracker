import SwiftUI
import SwiftData

@main
struct LifeTrackerApp: App {
    /// Service container. `Services()` uses the real EventKit calendar and mock
    /// implementations for the not-yet-wired integrations.
    @State private var services: Services
    @State private var session: Session

    /// The SwiftData stack holding every persisted model.
    let modelContainer: ModelContainer

    init() {
        let services = Services()
        _services = State(initialValue: services)
        _session = State(initialValue: Session(auth: services.auth))

        do {
            modelContainer = try ModelContainer(
                for: TodoItem.self, PantryItem.self, Recipe.self,
                RecipeIngredient.self, MealPlanEntry.self, Routine.self, RoutineStep.self,
                ShoppingItem.self
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(services)
                .environment(session)
        }
        .modelContainer(modelContainer)
    }
}
