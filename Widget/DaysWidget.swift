import WidgetKit
import SwiftUI

struct DaysEntry: TimelineEntry {
    let date: Date
    let title: String?
    let days: Int?
}

struct DaysProvider: TimelineProvider {
    func placeholder(in context: Context) -> DaysEntry {
        DaysEntry(date: Date(), title: "Событие", days: 42)
    }

    func getSnapshot(in context: Context, completion: @escaping (DaysEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DaysEntry>) -> Void) {
        let entry = currentEntry()
        let nextMidnight = Calendar.current.nextDate(
            after: Date(),
            matching: DateComponents(hour: 0, minute: 0, second: 5),
            matchingPolicy: .nextTime
        ) ?? Date().addingTimeInterval(3600)

        let timeline = Timeline(entries: [entry], policy: .after(nextMidnight))
        completion(timeline)
    }

    private func currentEntry() -> DaysEntry {
        let dates = SharedStorage.loadDates()
        let selectedId = SharedStorage.loadSelectedWidgetId()
        let target = dates.first(where: { $0.id == selectedId }) ?? dates.first

        guard let item = target else {
            return DaysEntry(date: Date(), title: nil, days: nil)
        }
        return DaysEntry(date: Date(), title: item.title, days: item.daysPassed())
    }
}

struct DaysWidgetView: View {
    var entry: DaysProvider.Entry

    var body: some View {
        if let title = entry.title, let days = entry.days {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text("\(days)")
                    .font(.system(size: 40, weight: .bold, design: .rounded).monospacedDigit())

                Text("дней прошло")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .containerBackground(.fill.tertiary, for: .widget)
        } else {
            VStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(.title2)
                Text("Выберите дату в приложении")
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

@main
struct DaysWidget: Widget {
    let kind: String = "DaysWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DaysProvider()) { entry in
            DaysWidgetView(entry: entry)
        }
        .configurationDisplayName("Дни с даты")
        .description("Показывает количество дней с выбранной даты.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}