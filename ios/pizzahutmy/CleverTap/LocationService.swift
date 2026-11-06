import CoreLocation
import CleverTapSDK
import CleverTapLocation

/// Location permission is requested from the Store Locator explainer, never at launch.
final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationService()

    @Published private(set) var status: CLAuthorizationStatus
    @Published private(set) var lastLocation: CLLocation?
    private let manager = CLLocationManager()
    private var awaitingResponse = false

    override init() {
        status = manager.authorizationStatus
        super.init()
        manager.delegate = self
    }

    var isAuthorized: Bool { status == .authorizedAlways || status == .authorizedWhenInUse }
    var isUndetermined: Bool { status == .notDetermined }

    /// Geofencing needs "Always" access (CleverTap Geofence doc, step 5).
    func requestPermission() {
        awaitingResponse = true
        manager.requestAlwaysAuthorization()
    }

    func refreshLocation() {
        guard isAuthorized else { return }
        manager.requestLocation()
        // CleverTapLocation: capture the location and pass it to CleverTap for the profile and events.
        CTLocationManager.getLocationWithSuccess({ coordinate in
            CleverTap.setLocation(coordinate)
        }, andError: { reason in
            #if DEBUG
            print("[Location] CleverTapLocation error: \(reason ?? "unknown")")
            #endif
        })
    }

    // MARK: CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let new = manager.authorizationStatus
        DispatchQueue.main.async { self.status = new }
        if awaitingResponse && new != .notDetermined {
            awaitingResponse = false
            Analytics.track(.locationPermissionResponse, ["Granted": new == .authorizedAlways || new == .authorizedWhenInUse])
        }
        if new == .authorizedAlways || new == .authorizedWhenInUse { refreshLocation() }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        DispatchQueue.main.async { self.lastLocation = locations.last }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        #if DEBUG
        print("[Location] \(error.localizedDescription)")
        #endif
    }
}
