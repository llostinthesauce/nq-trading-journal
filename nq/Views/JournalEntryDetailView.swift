//
//  JournalEntryDetailView.swift
//  nq
//
//  Created by Codex on 10/18/25.
//

import SwiftUI
import UIKit

struct JournalEntryDetailView: View {
    let entryID: UUID

    @EnvironmentObject private var store: JournalStore
    @State private var showingEditor = false

    private var entry: JournalEntry? {
        store.entries.first(where: { $0.id == entryID })
    }

    var body: some View {
        Group {
            if let entry {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        header(for: entry)
                        detailGrid(for: entry)
                        journalSection(title: "Analysis / Confluences", value: entry.analysis)
                        journalSection(title: "Psychology / Emotions", value: entry.psychology)
                        imageSection(for: entry)
                    }
                    .padding()
                    .background(Theme.surface)
                }
                .navigationTitle(title(for: entry))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Edit") {
                            showingEditor = true
                        }
                    }
                }
                .sheet(isPresented: $showingEditor) {
                    NavigationStack {
                        JournalEntryEditView(entry: entry)
                    }
                    .environmentObject(store)
                }
            } else {
                ContentUnavailableView(
                    "Entry Not Found",
                    systemImage: "exclamationmark.triangle",
                    description: Text("This trade may have been deleted.")
                )
            }
        }
        .background(Theme.surface)
    }

    private func header(for entry: JournalEntry) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.date, format: Date.FormatStyle(date: .complete, time: .omitted))
                .font(.title3.weight(.semibold))
            Text("Logged \(entry.createdAt, style: .relative) ago")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func detailGrid(for entry: JournalEntry) -> some View {
        let columns: [(String, String)] = [
            ("Ticker", entry.pair),
            ("Bias", entry.bias.displayName),
            ("Entry Model", entry.entryModel.displayName),
            ("Entry TF", entry.entryTimeframe.formatted),
            ("Contracts", "\(entry.riskContracts)"),
            ("Win/Loss", entry.winLoss.rawValue),
            ("P/L ($)", entry.profitLoss),
            ("Entry (pts)", entry.entryPoints),
            ("Exit (pts)", entry.exitPoints),
            ("Points", entry.points),
            ("Risk/Reward", entry.riskReward),
            ("Rating", entry.rating == .notRated ? "" : entry.rating.displayName)
        ]

        return Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
            ForEach(columns, id: \.0) { column in
                GridRow {
                    Text(column.0 + ":")
                        .font(.subheadline.weight(.medium))
                    Text(column.1.isEmpty ? "—" : column.1)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }
                Divider()
            }
        }
    }

    private func journalSection(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
            Text(value.isEmpty ? "—" : value)
                .font(.body)
                .foregroundStyle(.primary)
        }
    }

    private func imageSection(for entry: JournalEntry) -> some View {
        Group {
            if let image = loadImage(for: entry) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Screenshot")
                        .font(.headline)
                    image
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private func title(for entry: JournalEntry) -> String {
        "\(entry.pair) Trade"
    }

    private func loadImage(for entry: JournalEntry) -> Image? {
        guard let imagePath = entry.imagePath else { return nil }
        let url = documentsDirectory().appendingPathComponent(imagePath)
        guard let data = try? Data(contentsOf: url),
              let uiImage = UIImage(data: data) else { return nil }
        return Image(uiImage: uiImage)
    }

    private func documentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ??
            URL(fileURLWithPath: NSTemporaryDirectory())
    }
}

#Preview {
    let store = JournalStore(fileName: "detail_preview.json")
    let sample = JournalEntry(analysis: "Sample trade notes go here.", psychology: "Felt composed.")
    store.add(sample)

    return NavigationStack {
        JournalEntryDetailView(entryID: sample.id)
            .environmentObject(store)
    }
}
