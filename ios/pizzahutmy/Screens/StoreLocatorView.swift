import SwiftUI
import MapKit
import CoreLocation

struct StoreLocatorView: View {
    let source: String
    var dismissible = false
    @EnvironmentObject var cart: CartStore
    @EnvironmentObject var location: LocationService
    @Environment(\.dismiss) private var dismiss

    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 3.1170, longitude: 101.6500),
                                                   span: MKCoordinateSpan(latitudeDelta: 0.42, longitudeDelta: 0.42))
    @State private var showExplainer = false
    @State private var focused: Catalog.Store?

    private var stores: [Catalog.Store] {
        let all = Catalog.shared.stores
        guard let here = location.lastLocation else { return all }
        return all.sorted { distance($0, from: here) < distance($1, from: here) }
    }

    var body: some View {
        VStack(spacing: 0) {
            Map(coordinateRegion: $region, showsUserLocation: location.isAuthorized, annotationItems: stores) { store in
                MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: store.lat, longitude: store.lng)) {
                    Button { focus(store) } label: {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: focused == store ? 34 : 26))
                            .foregroundColor(cart.selectedStore == store ? Theme.redDeep : Theme.red)
                            .background(Circle().fill(Color.white).padding(4))
                    }
                }
            }
            .frame(height: 280)

            if !location.isAuthorized { locationBanner }

            List(stores) { store in
                Button { select(store) } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: cart.selectedStore == store ? "checkmark.circle.fill" : "building.2")
                            .foregroundColor(Theme.red).font(.system(size: 20)).frame(width: 26)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(store.name).font(Theme.body(15, .bold)).foregroundColor(Theme.ink)
                            Text(store.address).font(Theme.body(12)).foregroundColor(Theme.grey).lineLimit(2)
                            HStack(spacing: 6) { Tag(text: "Delivery"); Tag(text: "Takeaway") }
                        }
                        Spacer()
                        if let here = location.lastLocation {
                            Text(String(format: "%.1f km", distance(store, from: here) / 1000)).font(Theme.body(12, .semibold)).foregroundColor(Theme.grey)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(focused == store ? Theme.redTint.opacity(0.3) : Color.white)
            }
            .listStyle(.plain)
        }
        .navigationTitle("Find a Hut")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if dismissible { Button("Close") { dismiss() }.foregroundColor(Theme.ink) }
            }
        }
        .sheet(isPresented: $showExplainer) { LocationExplainer { showExplainer = false } }
        .onAppear {
            Analytics.track(.storeLocatorViewed, ["Stores Shown": stores.count])
            if location.isAuthorized { location.refreshLocation() }
            if location.isUndetermined { DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { showExplainer = true } }
        }
        .onChange(of: location.lastLocation) { loc in
            guard let loc else { return }
            withAnimation { region = MKCoordinateRegion(center: loc.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)) }
        }
    }

    private var locationBanner: some View {
        Button { showExplainer = true } label: {
            HStack {
                Image(systemName: "location.fill").foregroundColor(Theme.red)
                Text(location.isUndetermined ? "Use my location to find the nearest Hut" : "Location is off. Turn it on in Settings to see the nearest Hut.")
                    .font(Theme.body(13, .medium)).foregroundColor(Theme.text).multilineTextAlignment(.leading)
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(Theme.greyLight)
            }
            .padding(12).background(Theme.redTint.opacity(0.35))
        }
        .disabled(!location.isUndetermined)
    }

    private func focus(_ store: Catalog.Store) {
        focused = store
        withAnimation { region.center = CLLocationCoordinate2D(latitude: store.lat, longitude: store.lng) }
    }

    private func select(_ store: Catalog.Store) {
        focus(store)
        cart.selectedStore = store
        Analytics.track(.storeSelected, ["Store ID": store.id, "Store Name": store.name, "Source": source])
        Analytics.setProfile([.preferredStore: store.name])
        if dismissible { DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { dismiss() } }
    }

    private func distance(_ s: Catalog.Store, from here: CLLocation) -> CLLocationDistance {
        CLLocation(latitude: s.lat, longitude: s.lng).distance(from: here)
    }
}

/// Branded explainer shown before the system location prompt.
struct LocationExplainer: View {
    let onClose: () -> Void
    @EnvironmentObject var location: LocationService

    var body: some View {
        VStack(spacing: 18) {
            Capsule().fill(Theme.border).frame(width: 40, height: 5).padding(.top, 10)
            ZStack {
                Circle().fill(Theme.redTint.opacity(0.5)).frame(width: 110, height: 110)
                Image(systemName: "location.circle.fill").font(.system(size: 60)).foregroundColor(Theme.red)
            }
            Text("Find the nearest Hut").font(Theme.heading(24)).foregroundColor(Theme.ink)
            VStack(alignment: .leading, spacing: 12) {
                point("mappin.and.ellipse", "See the closest Huts for Delivery and Takeaway")
                point("bell.badge", "Get a heads up on deals when you are near a Hut")
                point("lock.shield", "Your location is only used to improve your Pizza Hut experience")
            }
            .padding(.horizontal, 8)
            Spacer()
            Button("Allow location") {
                location.requestPermission()
                onClose()
            }
            .buttonStyle(PrimaryButtonStyle())
            Button("Not now", action: onClose).font(Theme.body(15, .semibold)).foregroundColor(Theme.grey)
        }
        .padding(20)
    }

    private func point(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(Theme.red).frame(width: 26)
            Text(text).font(Theme.body(15)).foregroundColor(Theme.text)
        }
    }
}
