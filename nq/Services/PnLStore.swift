//
//  PnLStore.swift
//  nq
//
//  Created by Codex on 10/18/25.
//

import Combine
import Foundation

@MainActor
final class PnLStore: ObservableObject {
    @Published private(set) var entries: [PnLEntry] = []

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let storageURL: URL

    init(fileName: String = "pnl_entries.json") {
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

    func add(_ entry: PnLEntry) {
        entries.append(entry)
        sortEntries()
        persistEntries()
    }

    func delete(_ entry: PnLEntry) {
        entries.removeAll { $0.id == entry.id }
        persistEntries()
    }

    func update(_ entry: PnLEntry) {
        guard let index = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        entries[index] = entry
        sortEntries()
        persistEntries()
    }

    var runningTotal: Double {
        entries.reduce(0) { $0 + $1.amount }
    }

    private func loadEntries() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }
        do {
            let data = try Data(contentsOf: storageURL)
            let decoded = try decoder.decode([PnLEntry].self, from: data)
            entries = decoded.sorted(by: { $0.date > $1.date })
        } catch {
            print("🔴 Failed to load PnL entries: \(error)")
        }
    }

    private func persistEntries() {
        do {
            let data = try encoder.encode(entries)
            try data.write(to: storageURL, options: [.atomic])
        } catch {
            print("🔴 Failed to persist PnL entries: \(error)")
        }
    }

    private func sortEntries() {
        entries.sort(by: { $0.date > $1.date })
    }
}
