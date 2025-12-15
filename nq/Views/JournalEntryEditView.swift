//
//  JournalEntryEditView.swift
//  nq
//
//  Created by Codex on 10/18/25.
//

import PhotosUI
import SwiftUI
import UIKit

struct JournalEntryEditView: View {
    let entry: JournalEntry

    @EnvironmentObject private var store: JournalStore
    @Environment(\.dismiss) private var dismiss

    @State private var draft: JournalEntry
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: Image?
    @State private var selectedImageData: Data?
    @State private var showSaveError = false
    @State private var showRemoveImageConfirmation = false
    @FocusState private var focusedField: Field?

    init(entry: JournalEntry) {
        self.entry = entry
        _draft = State(initialValue: entry)
    }

    var body: some View {
        Form {
            tradeDetailsSection
            riskAndPerformanceSection
            analysisSection
            psychologySection
            imageSection
        }
        .navigationTitle("Edit Trade")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { saveChanges() }
                    .disabled(!canSave)
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
            }
        }
        .task {
            populateExistingImage()
        }
        .alert("Could not save entry", isPresented: $showSaveError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Add some analysis notes before saving.")
        }
        .confirmationDialog(
            "Remove attached image?",
            isPresented: $showRemoveImageConfirmation,
            titleVisibility: .visible
        ) {
            Button("Remove Image", role: .destructive) {
                removeExistingImage()
            }
            Button("Cancel", role: .cancel) { }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.surface)
        .formStyle(.grouped)
    }

    private var tradeDetailsSection: some View {
        Section("Trade Details") {
            DatePicker("Date", selection: $draft.date, displayedComponents: .date)
                .tint(.accentColor)
            LabeledContent("Ticker") {
                Text(draft.pair)
            }
            Picker("Bias", selection: $draft.bias) {
                ForEach(TradeBias.allCases) { bias in
                    Text(bias.displayName).tag(bias)
                }
            }
            .pickerStyle(.segmented)
            Picker("Entry Model", selection: $draft.entryModel) {
                ForEach(EntryModel.allCases) { model in
                    Text(model.displayName).tag(model)
                }
            }
            .pickerStyle(.segmented)
            Picker("Entry TF", selection: $draft.entryTimeframe) {
                ForEach(EntryTimeframe.allCases) { timeframe in
                    Text(timeframe.displayName).tag(timeframe)
                }
            }
            .pickerStyle(.segmented)
        }
        .listRowBackground(Theme.card)
    }

    private var riskAndPerformanceSection: some View {
        Section("Risk & Performance") {
            Picker("Contracts", selection: $draft.riskContracts) {
                ForEach(1...50, id: \.self) { count in
                    Text("\(count)").tag(count)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxHeight: 120)
            Picker("Win/Loss", selection: $draft.winLoss) {
                ForEach(WinLossState.allCases) { state in
                    Text(state.rawValue).tag(state)
                }
            }
            .pickerStyle(.segmented)
            TextField("P/L ($)", text: $draft.profitLoss)
                .keyboardType(.decimalPad)
                .focused($focusedField, equals: .profitLoss)
            TextField("Points", text: $draft.points)
                .keyboardType(.decimalPad)
                .focused($focusedField, equals: .points)
            TextField("Entry (MNQ pts)", text: $draft.entryPoints)
                .keyboardType(.decimalPad)
                .focused($focusedField, equals: .entryPoints)
            TextField("Exit (MNQ pts)", text: $draft.exitPoints)
                .keyboardType(.decimalPad)
                .focused($focusedField, equals: .exitPoints)
            TextField("Risk/Reward (e.g., 3:1)", text: $draft.riskReward)
                .focused($focusedField, equals: .riskReward)
            Picker("Rating", selection: $draft.rating) {
                ForEach(TradeRating.allCases) { rating in
                    Text(rating.displayName).tag(rating)
                }
            }
            .pickerStyle(.segmented)
        }
        .listRowBackground(Theme.card)
    }

    private var analysisSection: some View {
        Section("Analysis / Confluences") {
            TextField("Notes", text: $draft.analysis, axis: .vertical)
                .lineLimit(3, reservesSpace: true)
                .focused($focusedField, equals: .analysis)
        }
        .listRowBackground(Theme.card)
    }

    private var psychologySection: some View {
        Section("Psychology / Emotions") {
            TextField("Reflections", text: $draft.psychology, axis: .vertical)
                .lineLimit(3, reservesSpace: true)
                .focused($focusedField, equals: .psychology)
        }
        .listRowBackground(Theme.card)
    }

    private var imageSection: some View {
        Section("Image") {
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Label("Replace Screenshot", systemImage: "paperclip")
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        await MainActor.run {
                            selectedImageData = data
                            if let uiImage = UIImage(data: data) {
                                selectedImage = Image(uiImage: uiImage)
                                draft.imagePath = existingImageFileName()
                            }
                        }
                    }
                }
            }

            if let selectedImage {
                selectedImage
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
            } else if let image = existingStoredImage() {
                image
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
            } else {
                Text("No image attached")
                    .foregroundStyle(.secondary)
            }

            if draft.imagePath != nil || selectedImage != nil {
                Button(role: .destructive) {
                    showRemoveImageConfirmation = true
                } label: {
                    Label("Remove Image", systemImage: "trash")
                }
            }
        }
        .listRowBackground(Theme.card)
    }

    private var canSave: Bool {
        !draft.analysis.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func saveChanges() {
        guard canSave else {
            showSaveError = true
            return
        }

        var entryToSave = draft

        if let data = selectedImageData {
            let filename = existingImageFileName()
            let url = documentsDirectory().appendingPathComponent(filename)
            do {
                try data.write(to: url, options: .atomic)
                entryToSave.imagePath = filename
            } catch {
                print("🔴 Failed to save image: \(error)")
            }
        } else if draft.imagePath == nil, let existingPath = entry.imagePath {
            deleteImageFile(named: existingPath)
        }

        store.update(entryToSave)
        dismiss()
    }

    private func populateExistingImage() {
        guard selectedImage == nil,
              let image = existingStoredImage() else { return }
        selectedImage = image
    }

    private func existingStoredImage() -> Image? {
        guard let imagePath = draft.imagePath else { return nil }
        let url = documentsDirectory().appendingPathComponent(imagePath)
        guard let data = try? Data(contentsOf: url),
              let uiImage = UIImage(data: data) else { return nil }
        return Image(uiImage: uiImage)
    }

    private func removeExistingImage() {
        draft.imagePath = nil
        selectedImage = nil
        selectedPhotoItem = nil
        selectedImageData = nil
    }

    private func existingImageFileName() -> String {
        if let path = draft.imagePath ?? entry.imagePath {
            return path
        } else {
            return "\(entry.id.uuidString).jpg"
        }
    }

    private func deleteImageFile(named fileName: String) {
        let url = documentsDirectory().appendingPathComponent(fileName)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try? FileManager.default.removeItem(at: url)
    }

    private func documentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ??
            URL(fileURLWithPath: NSTemporaryDirectory())
    }
}

#Preview {
    let store = JournalStore(fileName: "edit_preview.json")
    let sample = JournalEntry(analysis: "Preview edit entry")
    store.add(sample)

    return NavigationStack {
        JournalEntryEditView(entry: sample)
            .environmentObject(store)
    }
}

private enum Field: Hashable {
    case profitLoss
    case points
    case entryPoints
    case exitPoints
    case riskReward
    case analysis
    case psychology
}
