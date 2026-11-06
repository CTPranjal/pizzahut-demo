import SwiftUI

struct ProductDetailView: View {
    let product: Product
    /// Set when opened from a recommendation row.
    var recoSlot: RecoSlot?
    @EnvironmentObject var cart: CartStore
    @EnvironmentObject var router: DeepLinkRouter
    @EnvironmentObject var engine: RecoEngine
    @Environment(\.dismiss) private var dismiss

    @State private var size: Catalog.PizzaOptions.Option?
    @State private var crust: Catalog.PizzaOptions.Option?
    @State private var toppings: [Catalog.PizzaOptions.Option] = []
    @State private var quantity = 1

    private let options = Catalog.shared.pizzaOptions

    private var sizes: [Catalog.PizzaOptions.Option] { product.pizzaTier.flatMap { options.tiers[$0]?.sizes } ?? [] }
    private var crusts: [Catalog.PizzaOptions.Option] { size.flatMap { options.crusts[$0.id] } ?? [] }
    private var toppingChoices: [Catalog.PizzaOptions.Option] { size.flatMap { options.toppings[$0.id] } ?? [] }

    private var item: CartItem { CartItem(product: product, size: size, crust: crust, toppings: toppings, quantity: quantity) }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ZStack(alignment: .topTrailing) {
                        CatalogImageView(path: product.image, mode: .fit)
                            .frame(maxWidth: .infinity).frame(height: 260).background(Color.white)
                        Button { dismiss() } label: {
                            Image(systemName: "xmark").font(.system(size: 14, weight: .bold)).foregroundColor(Theme.ink)
                                .frame(width: 34, height: 34).background(Color.white).clipShape(Circle())
                                .shadow(color: .black.opacity(0.15), radius: 4)
                        }
                        .accessibilityLabel("Close")
                        .padding(14)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text(product.name).font(Theme.heading(24)).foregroundColor(Theme.ink)
                        if !product.description.isEmpty {
                            Text(product.description).font(Theme.body(14)).foregroundColor(Theme.grey)
                        }
                        Text((product.isPizza ? "From " : "") + product.price.rm).font(Theme.body(18, .bold)).foregroundColor(Theme.red)
                    }
                    .padding(.horizontal, 16)

                    if product.isPizza {
                        optionGroup("Size", sizes, selected: size) { s in
                            size = s
                            if let c = crust, !(options.crusts[s.id] ?? []).contains(where: { $0.id == c.id }) { crust = options.crusts[s.id]?.first }
                            let allowed = Set((options.toppings[s.id] ?? []).map(\.id))
                            toppings = (options.toppings[s.id] ?? []).filter { t in toppings.contains { $0.id == t.id } && allowed.contains(t.id) }
                        }
                        optionGroup("Crust", crusts, selected: crust) { crust = $0 }
                        toppingGroup
                    }
                    quantityRow
                    RecoRowView(slot: .productDetail, context: product)
                }
                .padding(.bottom, 20)
            }
            Button {
                addToCart()
            } label: {
                Text("Add to Cart · " + item.lineTotal.rm)
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(16)
            .background(Color.white.shadow(color: .black.opacity(0.06), radius: 4, y: -2))
        }
        .background(Theme.surface.ignoresSafeArea())
        .onAppear {
            if product.isPizza, size == nil {
                size = sizes.first(where: { $0.id == "REG" }) ?? sizes.first
                crust = size.flatMap { options.crusts[$0.id]?.first }
            }
            var props: [String: Any] = [
                "Product ID": product.id, "Product Name": product.name, "Category": product.categoryName,
                "Price": product.price, "Image URL": product.imageUrl, "Source": source,
            ]
            if let recoSlot { props["Slot"] = recoSlot.rawValue }
            Analytics.track(.productViewed, props)
            engine.record(.viewed, product)
        }
    }

    private var source: String { recoSlot == nil ? "Browse" : "Recommendation" }

    private func addToCart() {
        var line = item
        line.source = source
        line.recoSlot = recoSlot
        if product.isPizza {
            engine.record(.customised, product, size: line.size?.name)
            Analytics.track(.productCustomised, [
                "Product ID": product.id,
                "Size": line.size?.name ?? "",
                "Crust": line.crust?.name ?? "",
                "Toppings": line.toppings.isEmpty ? "None" : line.toppings.map(\.name).joined(separator: ", "),
            ])
        }
        cart.add(line)
        engine.record(.addedToCart, product, units: line.quantity)
        var props: [String: Any] = [
            "Product ID": product.id, "Product Name": product.name, "Category": product.categoryName,
            "Price": line.unitPrice, "Quantity": line.quantity, "Cart Value": cart.subtotal, "Source": source,
        ]
        if let recoSlot { props["Slot"] = recoSlot.rawValue }
        Analytics.track(.addedToCart, props)
        dismiss()
        // First meaningful action: offer the branded push soft prompt.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { PushManager.shared.askAfterMeaningfulAction() }
    }

    private func optionGroup(_ title: String, _ items: [Catalog.PizzaOptions.Option], selected: Catalog.PizzaOptions.Option?,
                             onSelect: @escaping (Catalog.PizzaOptions.Option) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(Theme.body(16, .bold)).foregroundColor(Theme.ink)
            VStack(spacing: 10) {
                ForEach(Array(stride(from: 0, to: items.count, by: 2)), id: \.self) { i in
                    HStack(spacing: 10) {
                        optionButton(items[i], title: title, selected: selected, onSelect: onSelect)
                        if i + 1 < items.count {
                            optionButton(items[i + 1], title: title, selected: selected, onSelect: onSelect)
                        } else {
                            Color.clear.frame(maxWidth: .infinity, minHeight: 54)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private func optionButton(_ o: Catalog.PizzaOptions.Option, title: String, selected: Catalog.PizzaOptions.Option?,
                              onSelect: @escaping (Catalog.PizzaOptions.Option) -> Void) -> some View {
        let isOn = selected?.id == o.id
        return Button { onSelect(o) } label: {
            VStack(spacing: 2) {
                Text(o.name).font(Theme.body(14, isOn ? .bold : .medium)).multilineTextAlignment(.center)
                Text(o.add > 0 ? "+ " + o.add.rm : (title == "Size" ? "" : "Included")).font(Theme.body(12)).foregroundColor(Theme.grey)
            }
            .foregroundColor(isOn ? Theme.red : Theme.text)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(isOn ? Theme.redTint.opacity(0.45) : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(isOn ? Theme.red : Theme.border, lineWidth: isOn ? 1.5 : 1))
        }
        .buttonStyle(.plain)
    }

    private var toppingGroup: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Extra toppings").font(Theme.body(16, .bold)).foregroundColor(Theme.ink)
                Spacer()
                Text("Up to \(options.maxToppings)").font(Theme.body(12)).foregroundColor(Theme.grey)
            }
            ForEach(toppingChoices) { t in
                let isOn = toppings.contains { $0.id == t.id }
                Button {
                    if isOn { toppings.removeAll { $0.id == t.id } }
                    else if toppings.count < options.maxToppings { toppings.append(t) }
                } label: {
                    HStack {
                        Image(systemName: isOn ? "checkmark.square.fill" : "square").foregroundColor(isOn ? Theme.red : Theme.greyLight)
                        Text(t.name).font(Theme.body(14)).foregroundColor(Theme.text)
                        Spacer()
                        Text("+ " + t.add.rm).font(Theme.body(13)).foregroundColor(Theme.grey)
                    }
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                .disabled(!isOn && toppings.count >= options.maxToppings)
                .opacity(!isOn && toppings.count >= options.maxToppings ? 0.45 : 1)
            }
        }
        .padding(14).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
    }

    private var quantityRow: some View {
        HStack {
            Text("Quantity").font(Theme.body(16, .bold)).foregroundColor(Theme.ink)
            Spacer()
            QuantityStepper(value: $quantity, min: 1)
        }
        .padding(.horizontal, 16)
    }
}

struct QuantityStepper: View {
    @Binding var value: Int
    var min: Int = 0
    var onChange: ((Int) -> Void)?
    var body: some View {
        HStack(spacing: 0) {
            Button { set(value - 1) } label: { Image(systemName: "minus").frame(width: 34, height: 32) }
                .disabled(value <= min)
            Text("\(value)").font(Theme.body(15, .bold)).frame(minWidth: 28)
            Button { set(value + 1) } label: { Image(systemName: "plus").frame(width: 34, height: 32) }
        }
        .foregroundColor(Theme.red)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.red, lineWidth: 1.2))
    }
    private func set(_ v: Int) {
        guard v >= min else { return }
        value = v
        onChange?(v)
    }
}
