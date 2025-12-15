//
//  CalendarJournalView.swift
//  nq
//
//  Created by Codex on 10/18/25.
//

import SwiftUI

struct CalendarJournalView: View {
    @EnvironmentObject private var store: JournalStore
    @State private var selectedDate: Date = Date()
    @State private var editingEntry: JournalEntry?

    private var entriesForSelectedDate: [JournalEntry] {
        store.entries(on: selectedDate).sorted(by: { $0.createdAt > $1.createdAt })
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                DatePicker(
                    "Select Day",
                    selection: $selectedDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(.accentColor)
                .padding(.horizontal)
                .onAppear {
                    let adjusted = adjustedTradingDay(from: selectedDate)
                    if adjusted != selectedDate { selectedDate = adjusted }
                }
                .onChange(of: selectedDate) { _, newValue in
                    let adjusted = adjustedTradingDay(from: newValue)
                    if adjusted != newValue { selectedDate = adjusted }
                }

                VStack(spacing: 4) {
                    Text("Daily P&L")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(dayTotalFormatted)
                        .font(.title3.bold())
                        .foregroundColor(dayTotal >= 0 ? Theme.positive : Theme.negative)
                }

                if entriesForSelectedDate.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No entries yet")
                            .font(.headline)
                        Text("Record a trade on the Home tab to see it here.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    List(entriesForSelectedDate) { entry in
                        NavigationLink {
                            JournalEntryDetailView(entryID: entry.id)
                        } label: {
                            CalendarListRow(entry: entry)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                                editingEntry = entry
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.accentColor)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Theme.surface)
                    .listRowBackground(Theme.card)
                }
            }
            .navigationTitle("Journal Calendar")
            .padding(.bottom)
            .toolbar {
                Menu {
                    Button(role: .destructive) {
                        deleteAllEntries(for: selectedDate)
                    } label: {
                        Label("Delete entries for \(selectedDate.formatted(date: .abbreviated, time: .omitted))", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
            .sheet(item: $editingEntry) { entry in
                NavigationStack {
                    JournalEntryEditView(entry: entry)
                }
                .environmentObject(store)
            }
            .background(Theme.surface)
        }
        .background(Theme.surface)
    }

    private var dayTotal: Double {
        entriesForSelectedDate.reduce(0) { result, entry in
            result + parsedAmount(from: entry.profitLoss)
        }
    }

    private var dayTotalFormatted: String {
        dayTotal.formatted(.currency(code: "USD"))
    }

    private func deleteAllEntries(for date: Date) {
        let entries = store.entries(on: date)
        for entry in entries {
            store.delete(entry)
            if let path = entry.imagePath {
                deleteImage(named: path)
            }
        }
    }

    private func deleteImage(named fileName: String) {
        let url = documentsDirectory().appendingPathComponent(fileName)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try? FileManager.default.removeItem(at: url)
    }

    private func documentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ??
            URL(fileURLWithPath: NSTemporaryDirectory())
    }

    private func parsedAmount(from value: String) -> Double {
        let cleaned = value.replacingOccurrences(of: "[^0-9.-]", with: "", options: .regularExpression)
        return Double(cleaned) ?? 0
    }

    private func adjustedTradingDay(from date: Date) -> Date {
        let calendar = Calendar.current
        var candidate = calendar.startOfDay(for: date)
        while calendar.isDateInWeekend(candidate) {
            candidate = calendar.date(byAdding: .day, value: -1, to: candidate) ?? candidate
        }
        return candidate
    }
}

private struct CalendarListRow: View {
    let entry: JournalEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(entry.pair) \(entry.entryTimeframe.formatted)")
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                Text(entry.winLoss.rawValue)
                    .fontWeight(.semibold)
                    .foregroundColor(color(for: entry.winLoss))
            }

            Text("\(entry.bias.displayName) • \(entry.entryModel.displayName)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            let entryLabel = entry.entryPoints.isEmpty ? "Entry: —" : "Entry: \(entry.entryPoints) pts"
            let exitLabel = entry.exitPoints.isEmpty ? "Exit: —" : "Exit: \(entry.exitPoints) pts"
            Text("\(entryLabel) • \(exitLabel)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let amount = entryAmount,
               amount != 0 {
                Text(amount.formatted(.currency(code: "USD")))
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(amount >= 0 ? Theme.positive : Theme.negative)
            }

            if !entry.analysis.isEmpty {
                Text(entry.analysis)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 8)
    }

    private func color(for state: WinLossState) -> Color {
        switch state {
        case .win:
            return Theme.positive
        case .loss:
            return Theme.negative
        case .breakeven:
            return Theme.warning
        }
    }

    private var entryAmount: Double? {
        let cleaned = entry.profitLoss.replacingOccurrences(of: "[^0-9.-]", with: "", options: .regularExpression)
        return Double(cleaned)
    }
}

#Preview {
    CalendarJournalView()
        .environmentObject(JournalStore(fileName: "calendar_preview.json"))
}
