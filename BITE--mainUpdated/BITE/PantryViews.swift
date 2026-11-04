import SwiftUI

struct PantryView: View {
    @EnvironmentObject var app: AppState
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    Text("What’s in My\nPantry")
                        .font(.system(size: 28, weight: .bold))
                    Spacer()
                    AppleMascot(mood: .wink, size: 64)
                }
                .padding(.horizontal, 20)

                HStack {
                    Text("What I have:").font(.system(size: 16, weight: .bold))
                    Spacer()
                    Button { showAdd = true } label: {
                        Label("Add Food", systemImage: "plus")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color.biteGreen))
                    }
                }
                .padding(.horizontal, 20)

                // The list owns the remaining space and scrolls independently.
                List {
                    ForEach(app.pantry) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name).font(.system(size: 13))
                                if let expiry = item.expiry {
                                    Text("Expires \(expiry.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Text(status(item))
                                .font(.system(size: 12))
                                .foregroundStyle(item.amount >= 3 ? Color.secondary : Color.orange)
                        }
                    }
                    .onDelete { app.pantry.remove(atOffsets: $0) }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay {
                    if app.pantry.isEmpty {
                        Text("Your pantry is empty.\nTap “Add Food” to start.")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .allowsHitTesting(false)
                    }
                }

                // Ordinary layout siblings, NOT bottom overlays/safeAreaInsets.
                // They have guaranteed height ABOVE MainTabView's separate tab bar.
                VStack(spacing: 9) {
                    NavigationLink { PantryIdeasView() } label: {
                        Label("Cook with my pantry", systemImage: "fork.knife")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.biteGreen)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Capsule().stroke(Color.biteGreen, lineWidth: 1.5))
                    }
                    NavigationLink { ShoppingListView() } label: {
                        Label("Open Shopping List", systemImage: "cart")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Capsule().fill(Color.biteGreen))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showAdd) { AddFoodView() }
        }
    }

    private func status(_ item: PantryItem) -> String {
        if item.amount <= 0 { return "Out" }
        return item.amount >= 3 ? "Plenty - \(item.amount)" : "Low - \(item.amount) left"
    }
}

struct AddFoodView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var amount = 1
    @State private var hasExpiry = true
    @State private var expiry = Date()
    @State private var showScanner = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Button { showScanner = true } label: {
                        Label("Scan Receipt", systemImage: "doc.text.viewfinder")
                            .font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
                            .frame(maxWidth: .infinity).frame(height: 64)
                            .background(Capsule().fill(Color.biteGreen))
                    }
                    Text("Or add it manually:").font(.system(size: 15, weight: .bold))
                        .frame(maxWidth: .infinity)

                    field("Insert product name:") {
                        TextField("Name", text: $name)
                    }
                    field("Insert the amount:") {
                        Stepper("\(amount)", value: $amount, in: 1...99)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Insert the expiration date:", isOn: $hasExpiry)
                            .font(.system(size: 12, weight: .semibold)).tint(Color.biteGreen)
                        if hasExpiry {
                            DatePicker("", selection: $expiry, in: Date()..., displayedComponents: .date)
                                .datePickerStyle(.graphical).labelsHidden()
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        app.addPantry(name: name, amount: amount, expiry: hasExpiry ? expiry : nil)
                        dismiss()
                    } label: { Image(systemName: "plus.circle.fill").foregroundStyle(Color.biteGreen) }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .sheet(isPresented: $showScanner) { ReceiptScannerView() }
        }
    }

    private func field<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.system(size: 12, weight: .semibold))
            content().font(.system(size: 14))
            Divider()
        }
    }
}

struct ShoppingListView: View {
    @EnvironmentObject var app: AppState
    @State private var showAdd = false
    @State private var movedCount: Int?

    var body: some View {
        VStack(spacing: 12) {
            Button { showAdd = true } label: {
                Label("Add Items", systemImage: "plus")
                    .font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).frame(height: 40)
                    .background(Capsule().fill(Color.biteGreen))
            }
            .padding(.horizontal, 16)

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(Category.all, id: \.self) { category in
                        let items = app.shopping.filter { $0.category == category }
                        if !items.isEmpty {
                            Text(category).font(.system(size: 16, weight: .semibold))
                            VStack(spacing: 0) {
                                ForEach(items) { item in
                                    row(item)
                                    if item.id != items.last?.id { Divider().padding(.leading, 52) }
                                }
                            }
                            .background(CardBackground(radius: 14))
                        }
                    }
                    if app.shopping.isEmpty {
                        Text("Your shopping list is empty.").foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity).padding(.top, 40)
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 6)
            }

            PrimaryButton(title: "Finish Your Shopping", enabled: app.shopping.contains { $0.checked }) {
                movedCount = app.finishShopping()
            }
            .padding(.horizontal, 16)
        }
        .navigationTitle("My Shopping List")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAdd) { AddShoppingItemView() }
        .alert("Added to your pantry", isPresented: Binding(get: { movedCount != nil }, set: { if !$0 { movedCount = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("\(movedCount ?? 0) item(s) moved from your list to the pantry.")
        }
    }

    private func row(_ item: ShoppingItem) -> some View {
        HStack(spacing: 12) {
            Button { app.toggleShopping(item) } label: {
                Image(systemName: item.checked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 26))
                    .foregroundStyle(item.checked ? Color.biteGreen : Color.secondary)
            }
            Text(item.name).font(.system(size: 13))
                .strikethrough(item.checked)
            Spacer()
            if let amount = item.amount { Text(amount).font(.system(size: 12)).foregroundStyle(.secondary) }
            else if item.quantity > 1 { Text("×\(item.quantity)").font(.system(size: 12)).foregroundStyle(.secondary) }
            Button { app.shopping.removeAll { $0.id == item.id } } label: {
                Image(systemName: "xmark").font(.system(size: 11)).foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
    }
}

struct AddShoppingItemView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var category = Category.produce
    @State private var quantity = 1

    var body: some View {
        NavigationStack {
            Form {
                TextField("Item name", text: $name)
                Picker("Category", selection: $category) {
                    ForEach(Category.all, id: \.self) { Text($0).tag($0) }
                }
                Stepper("Quantity: \(quantity)", value: $quantity, in: 1...99)
            }
            .navigationTitle("Add Items")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        app.addShopping(name: name, category: category, quantity: quantity)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
