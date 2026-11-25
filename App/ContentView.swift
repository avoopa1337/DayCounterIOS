import SwiftUI
import WidgetKit

struct ContentView: View {
    @State private var dates: [TrackedDate] = SharedStorage.loadDates()
    @State private var selectedWidgetId: UUID? = SharedStorage.loadSelectedWidgetId()
    @State private var showingAddSheet = false

    var body: some View {
        NavigationStack {
            List {
                if dates.isEmpty {
                    ContentUnavailableView(
                        "Нет сохранённых дат",
                        systemImage: "calendar.badge.plus",
                        description: Text("Нажмите «+», чтобы добавить дату и вести отсчёт дней.")
                    )
                } else {
                    ForEach(dates) { item in
                        let isSelectedForWidget = item.id == selectedWidgetId
                        HStack(spacing: 14) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.headline)
                                Text(item.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(item.daysPassed())")
                                    .font(.title2.bold().monospacedDigit())
                                Text("дней")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Button {
                                toggleWidgetSelection(for: item.id)
                            } label: {
                                Image(systemName: isSelectedForWidget ? "pin.circle.fill" : "pin.circle")
                                    .font(.title2)
                                    .foregroundStyle(isSelectedForWidget ? .blue : .gray)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete(perform: deleteDates)
                }
            }
            .navigationTitle("Счётчик дней")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddDateSheet { title, date in
                    let newItem = TrackedDate(title: title, date: date)
                    dates.append(newItem)
                    if selectedWidgetId == nil {
                        selectedWidgetId = newItem.id
                        SharedStorage.saveSelectedWidgetId(newItem.id)
                    }
                    SharedStorage.saveDates(dates)
                    WidgetCenter.shared.reloadAllTimelines()
                }
            }
        }
    }

    private func toggleWidgetSelection(for id: UUID) {
        selectedWidgetId = (selectedWidgetId == id) ? nil : id
        SharedStorage.saveSelectedWidgetId(selectedWidgetId)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func deleteDates(at offsets: IndexSet) {
        let removedIds = offsets.map { dates[$0].id }
        dates.remove(atOffsets: offsets)
        if let current = selectedWidgetId, removedIds.contains(current) {
            selectedWidgetId = dates.first?.id
            SharedStorage.saveSelectedWidgetId(selectedWidgetId)
        }
        SharedStorage.saveDates(dates)
        WidgetCenter.shared.reloadAllTimelines()
    }
}

struct AddDateSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var selectedDate: Date = Date()

    let onSave: (String, Date) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("Название события", text: $title)
                DatePicker(
                    "Дата начала",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
            }
            .navigationTitle("Новая дата")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        let cleaned = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        onSave(cleaned.isEmpty ? "Событие" : cleaned, selectedDate)
                        dismiss()
                    }
                }
            }
        }
    }
}