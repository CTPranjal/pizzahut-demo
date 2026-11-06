import SwiftUI

struct AccountView: View {
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var orders: OrderStore
    @EnvironmentObject var cart: CartStore
    @State private var showPersonas = false

    var body: some View {
        NavigationView {
            Group {
                if let user = session.user {
                    List {
                        Section {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle().fill(Theme.red).frame(width: 56, height: 56)
                                    Text(String(user.name.prefix(1))).font(Theme.heading(24)).foregroundColor(.white)
                                }
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(user.name).font(Theme.body(18, .bold))
                                    Text(user.email).font(Theme.body(13)).foregroundColor(Theme.grey)
                                    Text(user.phone).font(Theme.body(13)).foregroundColor(Theme.grey)
                                }
                            }
                            .padding(.vertical, 6)
                            HStack {
                                Label("\(session.tier) member", systemImage: "crown.fill").foregroundColor(Theme.red)
                                Spacer()
                                Text("\(session.totalOrders) orders").foregroundColor(Theme.grey)
                            }
                            .font(Theme.body(14, .semibold))
                        }
                        Section("Notification preferences") {
                            Toggle("Push notifications", isOn: $session.preferences.push)
                            Toggle("Email", isOn: $session.preferences.email)
                            Toggle("SMS", isOn: $session.preferences.sms)
                            Toggle("WhatsApp", isOn: $session.preferences.whatsapp)
                        }
                        .tint(Theme.red)
                        .onChange(of: session.preferences) { _ in session.pushPreferences() }
                        ordersSection
                        Section {
                            NavigationLink("Find a Hut") { StoreLocatorView(source: "Account") }
                            Button("Log out") { session.logout() }.foregroundColor(Theme.red)
                        }
                    }
                    .listStyle(.insetGrouped)
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            LoginView(onDone: nil)
                            VStack(spacing: 0) {
                                ForEach(orders.orders) { o in
                                    NavigationLink { OrderTrackingView(orderId: o.id) } label: { linkRow("Order \(o.id)", "\(o.mode.rawValue) · \(o.amount.rm)") }
                                    Divider()
                                }
                                NavigationLink { StoreLocatorView(source: "Account") } label: { linkRow("Find a Hut", "Delivery and Takeaway outlets") }
                            }
                            .background(Color.white).clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 16).padding(.bottom, 20)
                        }
                    }
                    .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
                }
            }
            .navigationTitle(session.isLoggedIn ? "Profile" : "Log in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { InboxManager.shared.present() } label: { Image(systemName: "bell").foregroundColor(Theme.ink) }
                }
            }
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showPersonas) { DemoPersonasView() }
    }

    private func linkRow(_ title: String, _ subtitle: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Theme.body(15, .semibold)).foregroundColor(Theme.ink)
                Text(subtitle).font(Theme.body(12)).foregroundColor(Theme.grey)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundColor(Theme.greyLight)
        }
        .padding(14)
    }

    @ViewBuilder private var ordersSection: some View {
        if !orders.orders.isEmpty {
            Section("My orders") {
                ForEach(orders.orders) { o in
                    NavigationLink { OrderTrackingView(orderId: o.id) } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(o.id).font(Theme.body(14, .semibold))
                            Text("\(o.mode.rawValue) · \(o.amount.rm)").font(Theme.body(12)).foregroundColor(Theme.grey)
                        }
                    }
                }
            }
        }
    }
}

/// Login with the single demo user. Never mandatory: browsing, cart and checkout work anonymously.
struct LoginView: View {
    var onDone: (() -> Void)?
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var cart: CartStore
    @EnvironmentObject var pe: ProductExperience
    @State private var showPersonas = false

    private var persona: Persona { Persona.all[0] }

    var body: some View {
        VStack(spacing: 18) {
            CatalogImageView(path: Catalog.shared.brand.logo)
                .frame(width: 76, height: 76).clipShape(RoundedRectangle(cornerRadius: 16))
                .onLongPressGesture(minimumDuration: 0.8) { showPersonas = true }
                .padding(.top, 12)
            Text(pe.loginHeadline).font(Theme.body(17, .bold)).foregroundColor(Theme.ink)
                .multilineTextAlignment(.center)

            if !pe.loginTeaser.isEmpty {
                Label(pe.loginTeaser, systemImage: "star.circle.fill")
                    .font(Theme.body(14, .semibold)).foregroundColor(Theme.red)
                    .multilineTextAlignment(.leading)
                    .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.redTint.opacity(0.35)).clipShape(RoundedRectangle(cornerRadius: 12))
            }

            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Theme.red).frame(width: 52, height: 52)
                    Text(String(persona.profile.name.prefix(1))).font(Theme.heading(22)).foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(persona.profile.name).font(Theme.body(17, .bold)).foregroundColor(Theme.ink)
                    Text(persona.profile.email).font(Theme.body(13)).foregroundColor(Theme.grey)
                    Text(persona.profile.phone).font(Theme.body(13)).foregroundColor(Theme.grey)
                }
                Spacer()
            }
            .padding(14).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border))

            Button("\(pe.loginCtaPrefix) \(persona.profile.name.components(separatedBy: " ").first ?? persona.profile.name)") {
                session.login(persona: persona, cart: cart)
                onDone?()
            }
            .buttonStyle(PrimaryButtonStyle())

            Text("Logging in is optional. You can browse and order without an account.")
                .font(Theme.body(12)).foregroundColor(Theme.greyLight).multilineTextAlignment(.center)
        }
        .padding(16)
        .navigationTitle("Log in")
        .onAppear { Analytics.track(.loginScreenViewed, ["Headline": pe.loginHeadline, "Has Teaser": !pe.loginTeaser.isEmpty]) }
        .sheet(isPresented: $showPersonas) { DemoPersonasView(onDone: onDone) }
    }
}

/// Hidden demo panel (long press the logo): one-tap persona logins with distinct properties.
struct DemoPersonasView: View {
    var onDone: (() -> Void)?
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var cart: CartStore
    @EnvironmentObject var engine: RecoEngine
    @State private var resetDone = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                Section(footer: Text("Logs in with onUserLogin as the master demo profile and sets its PizzaHut profile properties.")) {
                    ForEach(Persona.all) { p in
                        Button {
                            session.login(persona: p, cart: cart)
                            dismiss()
                            onDone?()
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle().fill(Theme.red).frame(width: 44, height: 44)
                                    Text(String(p.profile.name.prefix(1))).font(Theme.body(18, .bold)).foregroundColor(.white)
                                }
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(p.title).font(Theme.body(16, .bold)).foregroundColor(Theme.ink)
                                    Text("\(p.profile.name) · \(p.profile.identity) · \(p.profile.phone)").font(Theme.body(12)).foregroundColor(Theme.grey)
                                    Text(p.summary).font(Theme.body(12, .medium)).foregroundColor(Theme.red)
                                }
                                Spacer()
                                if session.personaId == p.id { Image(systemName: "checkmark.circle.fill").foregroundColor(Theme.red) }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                Section(header: Text("Rehearsal tools"), footer: Text("Recommendations are computed on this device from this user's own activity.")) {
                    Button(resetDone ? "Recommendations reset" : "Reset recommendations") {
                        engine.reset()
                        resetDone = true
                    }
                    .foregroundColor(resetDone ? Theme.grey : Theme.red)
                    Toggle("Why this?", isOn: $engine.showWhy).tint(Theme.red)
                }
                if session.isLoggedIn {
                    Section { Button("Log out current user") { session.logout(); dismiss() }.foregroundColor(Theme.red) }
                }
            }
            .navigationTitle("Demo profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { dismiss() } } }
        }
    }
}
