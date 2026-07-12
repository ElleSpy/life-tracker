import SwiftUI

/// A horizontal strip of the current week for picking which day to view.
/// The week is aligned to the user's chosen first weekday (see `AppSettings`).
struct WeekStripView: View {
    @Environment(AppSettings.self) private var settings
    @Binding var selectedDay: Date

    private var days: [Date] {
        settings.weekDays()
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(days, id: \.self) { day in
                    let isSelected = settings.calendar.isDate(day, inSameDayAs: selectedDay)
                    Button {
                        selectedDay = day
                    } label: {
                        VStack(spacing: Theme.Spacing.xs) {
                            Text(day.formatted(.dateTime.weekday(.abbreviated)))
                                .font(.caption)
                            Text(day.formatted(.dateTime.day()))
                                .font(.headline)
                        }
                        .frame(width: 44, height: 60)
                        .background(isSelected ? Theme.Palette.accent : Theme.Palette.cardBackground)
                        .foregroundStyle(isSelected ? .white : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.sm)
        }
    }
}

/// A single to-do row with a completion toggle.
struct TodoRowView: View {
    @Environment(Services.self) private var services
    @Bindable var todo: TodoItem

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            Button {
                todo.toggle()
                services.notifications.sync(todo)
            } label: {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(todo.isCompleted ? Theme.Palette.accent : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(todo.title)
                    .strikethrough(todo.isCompleted)
                    .foregroundStyle(todo.isCompleted ? .secondary : .primary)
                if !todo.notes.isEmpty {
                    Text(todo.notes)
                        .font(.caption)
                        .foregroundStyle(Theme.Palette.subtleText)
                }
                HStack(spacing: Theme.Spacing.sm) {
                    if let due = todo.dueDate {
                        Label(due.formatted(.dateTime.month().day()),
                              systemImage: "calendar")
                            .font(.caption2)
                            .foregroundStyle(todo.isOverdue ? .red : Theme.Palette.subtleText)
                    }
                    if todo.source != .manual {
                        Pill(text: todo.source.label, systemImage: todo.source.systemImage)
                    }
                }
            }
            Spacer()
            if todo.priority == .high {
                Image(systemName: todo.priority.systemImage)
                    .foregroundStyle(.orange)
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
    }
}

/// A compact row for the "at a glance" summary at the top of the Plan tab.
struct SummaryRow: View {
    let systemImage: String
    let title: String
    var detail: String?

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: systemImage)
                .foregroundStyle(Theme.Palette.accent)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(title)
                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(Theme.Palette.subtleText)
                        .lineLimit(1)
                }
            }
        }
    }
}

/// A calendar event row (read-only, from EventKit).
struct CalendarEventRow: View {
    let event: CalendarEvent

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: event.calendarColorHex))
                .frame(width: 4, height: 36)
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(event.title)
                Text(event.timeText)
                    .font(.caption)
                    .foregroundStyle(Theme.Palette.subtleText)
            }
        }
    }
}
