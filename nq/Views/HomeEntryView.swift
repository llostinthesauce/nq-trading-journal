//
//  HomeEntryView.swift
//  nq
//
//  Created by Codex on 10/18/25.
//

import PhotosUI
import SwiftUI
import UIKit

struct HomeEntryView: View {
    @EnvironmentObject private var store: JournalStore

    @State private var draft = JournalEntry.empty
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: Image?
    @State private var selectedImageData: Data?
    @State private var saveErrorAlert = false
    @State private var showSaveConfirmation = false
    @FocusState private var focusedField: FocusedField?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    tradeDetailsCard
                        .cardStyle()

                    riskAndPerformanceCard
                        .cardStyle()

                    analysisCard
                        .cardStyle()

                    psychologyCard
                        .cardStyle()

                    imageCard
                        .cardStyle()
                }
                .padding(.horizontal)
                .padding(.vertical, 16)
            }
            .background(Theme.surface)
            .navigationTitle("New Entry")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save Entry", action: saveEntry)
                        .disabled(!canSaveEntry)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                }
            }
            .alert("Entry Saved", isPresented: $showSaveConfirmation) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your trading journal entry has been added to the calendar.")
            }
            .alert("Could not save entry", isPresented: $saveErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Add some analysis notes before saving.")
            }
        }
        .background(Theme.surface)
    }

    private var tradeDetailsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trade Details")
                .font(.headline)

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
    }

    private var riskAndPerformanceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Risk & Performance")
                .font(.headline)

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

            VStack(spacing: 10) {
                numericField("P/L ($)", text: $draft.profitLoss, focus: .profitLoss)
                numericField("Points", text: $draft.points, focus: .points)
                numericField("Entry (MNQ pts)", text: $draft.entryPoints, focus: .entryPoints)
                numericField("Exit (MNQ pts)", text: $draft.exitPoints, focus: .exitPoints)
                textField("Risk/Reward (e.g., 3:1)", text: $draft.riskReward, focus: .riskReward)
            }

            Picker("Rating", selection: $draft.rating) {
                ForEach(TradeRating.allCases) { rating in
                    Text(rating.displayName).tag(rating)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var analysisCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Analysis / Confluences")
                .font(.headline)
            textField("Notes", text: $draft.analysis, focus: .analysis, axis: .vertical)
        }
    }

    private var psychologyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Psychology / Emotions")
                .font(.headline)
            textField("Reflections", text: $draft.psychology, focus: .psychology, axis: .vertical)
        }
    }

    private var imageCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Image")
                .font(.headline)

            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Label("Attach Screenshot", systemImage: "paperclip")
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        await MainActor.run {
                            selectedImageData = data
                            if let uiImage = UIImage(data: data) {
                                selectedImage = Image(uiImage: uiImage)
                            }
                        }
                    }
                }
            }

            if let selectedImage {
                selectedImage
                    .resizable()
                    .scaledToFill()
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .clipped()
            } else {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.primary.opacity(0.05))
                    .frame(height: 220)
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                            Text("No image selected")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
            }
        }
    }

    private func numericField(_ title: String, text: Binding<String>, focus: FocusedField) -> some View {
        TextField(title, text: text)
            .keyboardType(.decimalPad)
            .focused($focusedField, equals: focus)
            .textFieldStyle(.roundedBorder)
    }

    private func textField(_ title: String, text: Binding<String>, focus: FocusedField, axis: Axis = .horizontal) -> some View {
        TextField(title, text: text, axis: axis)
            .focused($focusedField, equals: focus)
            .textFieldStyle(.roundedBorder)
    }

    private var canSaveEntry: Bool {
        !draft.analysis.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func saveEntry() {
        guard canSaveEntry else {
            saveErrorAlert = true
            return
        }

        var entryToSave = draft

        if let data = selectedImageData,
           let storedPath = saveImageToDocuments(data: data, entryID: draft.id) {
            entryToSave.imagePath = storedPath
        }

        store.add(entryToSave)
        draft = JournalEntry.empty
        selectedImage = nil
        selectedImageData = nil
        selectedPhotoItem = nil
        focusedField = nil
        showSaveConfirmation = true
    }

    private func saveImageToDocuments(data: Data, entryID: UUID) -> String? {
        let filename = "\(entryID.uuidString).jpg"
        let url = documentsDirectory().appendingPathComponent(filename)
        do {
            try data.write(to: url, options: .atomic)
            return filename
        } catch {
            print("🔴 Failed to save image: \(error)")
            return nil
        }
    }

    private func documentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ??
            URL(fileURLWithPath: NSTemporaryDirectory())
    }
}

private enum FocusedField: Hashable {
    case profitLoss
    case points
    case entryPoints
    case exitPoints
    case riskReward
    case analysis
    case psychology
}

#Preview {
    let store = JournalStore(fileName: "home_preview.json")
    return HomeEntryView()
        .environmentObject(store)
}
