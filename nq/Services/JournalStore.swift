//
//  JournalStore.swift
//  nq
//
//  Created by Codex on 10/18/25.
//

import Combine
import Foundation

@MainActor
final class JournalStore: ObservableObject {
    @Published private(set) var entries: [JournalEntry] = []

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let storageURL: URL

    init(fileName: String = "journal_entries.json") {
        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        storageURL = documentsURL?.appendingPathComponent(fileName) ??
            URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)

        loadEntries()
    }

    func add(_ entry: JournalEntry) {
        entries.append(entry)
        sortEntriesInPlace()
        persistEntries()
    }

    func update(_ entry: JournalEntry) {
        guard let index = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        entries[index] = entry
        sortEntriesInPlace()
        persistEntries()
    }

    func delete(_ entry: JournalEntry) {
        entries.removeAll { $0.id == entry.id }
        sortEntriesInPlace()
        persistEntries()
    }

    func entries(on day: Date) -> [JournalEntry] {
        let calendar = Calendar.current
        return entries.filter { calendar.isDate($0.date, inSameDayAs: day) }
    }

    func entriesGroupedByDay() -> [Date: [JournalEntry]] {
        let calendar = Calendar.current
        return Dictionary(grouping: entries) { calendar.startOfDay(for: $0.date) }
    }

    private func loadEntries() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }
        do {
            let data = try Data(contentsOf: storageURL)
            let decoded = try decoder.decode([JournalEntry].self, from: data)
            entries = decoded.sorted(by: { $0.date > $1.date })
        } catch {
            print("🔴 Failed to load journal entries: \(error)")
        }
    }

    private func persistEntries() {
        do {
            let data = try encoder.encode(entries)
            try data.write(to: storageURL, options: [.atomic])
        } catch {
            print("🔴 Failed to persist journal entries: \(error)")
        }
    }

    private func sortEntriesInPlace() {
        entries.sort(by: { $0.date > $1.date })
    }
}
