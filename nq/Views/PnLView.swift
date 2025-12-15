//
//  PnLView.swift
//  nq
//
//  Created by Codex on 10/18/25.
//

import SwiftUI

struct PnLView: View {
    @EnvironmentObject private var pnlStore: PnLStore

    @State private var entryDate: Date = Date()
    @State private var amountText: String = ""
    @State private var noteText: String = ""
    @State private var showValidationError = false
    @State private var entryKind: PnLEntryKind = .payout
    @FocusState private var focusedField: Field?

    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.currencySymbol = "$"
        return formatter
    }()

    var body: some View {
        NavigationStack {
            List {
                Section("Add Entry") {
                    DatePicker("Date", selection: $entryDate, displayedComponents: .date)
                        .tint(.accentColor)
                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .amount)
                    TextField("Note (optional)", text: $noteText, axis: .vertical)
                        .lineLimit(2, reservesSpace: true)
                        .focused($focusedField, equals: .note)
                    Picker("Type", selection: $entryKind) {
                        Text("Payout").tag(PnLEntryKind.payout)
                        Text("Expense").tag(PnLEntryKind.expense)
                    }
                    .pickerStyle(.segmented)
                    Button(action: addEntry) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add P/L Entry")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor.opacity(0.12))
                        .foregroundColor(.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSubmit)
                }
                .listRowBackground(Theme.card)

                Section("Running Total") {
                    HStack {
                        Text("Total")
                        Spacer()
                        Text(currencyFormatter.string(from: pnlStore.runningTotal as NSNumber) ?? "$0.00")
                            .font(.title3.bold())
                            .foregroundColor(pnlStore.runningTotal >= 0 ? Theme.positive : Theme.negative)
                    }
                }
                .listRowBackground(Theme.card)

                if pnlStore.entries.isEmpty {
                    Section {
                        VStack(alignment: .center, spacing: 8) {
                            Image(systemName: "chart.bar.doc.horizontal")
                                .font(.title)
                                .foregroundStyle(.secondary)
                            Text("No P/L entries yet")
                                .font(.headline)
                            Text("Add expenses or payouts to build your running totals.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical)
                    }
                    .listRowBackground(Theme.card)
                } else {
                    Section("History") {
                        ForEach(pnlStore.entries) { entry in
                            PnLRow(entry: entry, formatter: currencyFormatter)
                        }
                        .onDelete(perform: deleteEntries)
                    }
                    .listRowBackground(Theme.card)
                }
            }
            .navigationTitle("P&L Ledger")
            .alert("Enter a valid amount", isPresented: $showValidationError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Use numbers like 250 or 125.50. We'll set the sign based on payout/expense.")
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Theme.surface)
        }
        .background(Theme.surface)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
            }
        }
    }

    private var canSubmit: Bool {
        !amountText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func addEntry() {
        let trimmed = amountText.trimmingCharacters(in: .whitespaces)
        guard let rawAmount = Double(trimmed) else {
            showValidationError = true
            return
        }

        let amount = entryKind == .expense ? -abs(rawAmount) : abs(rawAmount)

        let entry = PnLEntry(
            date: entryDate,
            amount: amount,
            note: noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        pnlStore.add(entry)

        entryDate = Date()
        amountText = ""
        noteText = ""
    }

    private func deleteEntries(at offsets: IndexSet) {
        for index in offsets {
            let entry = pnlStore.entries[index]
            pnlStore.delete(entry)
        }
    }
}

private enum PnLEntryKind: Hashable {
    case payout
    case expense
}

private enum Field: Hashable {
    case amount
    case note
}

private struct PnLRow: View {
    let entry: PnLEntry
    let formatter: NumberFormatter

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(entry.date, format: Date.FormatStyle(date: .abbreviated, time: .omitted))
                    .font(.headline)
                Spacer()
                Text(formattedAmount)
                    .font(.headline)
                    .foregroundColor(entry.amount >= 0 ? Theme.positive : Theme.negative)
            }

            if !entry.note.isEmpty {
                Text(entry.note)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var formattedAmount: String {
        formatter.string(from: entry.amount as NSNumber) ?? String(format: "$%.2f", entry.amount)
    }
}

#Preview {
    let store = PnLStore(fileName: "pnl_preview.json")
    store.add(PnLEntry(date: .now, amount: 250.0, note: "Week profit"))
    store.add(PnLEntry(date: .now.addingTimeInterval(-86400), amount: -55.75, note: "Platform fees"))
    return PnLView()
        .environmentObject(store)
}
