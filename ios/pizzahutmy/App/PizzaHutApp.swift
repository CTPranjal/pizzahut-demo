import SwiftUI

@main
struct PizzaHutApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var router = DeepLinkRouter.shared
    @StateObject private var cart = CartStore()
    @StateObject private var session = SessionStore()
    @StateObject private var orders = OrderStore()
    @StateObject private var pe = ProductExperience.shared
    @StateObject private var display = NativeDisplayManager.shared
    @StateObject private var inbox = InboxManager.shared
    @StateObject private var location = LocationService.shared
    @StateObject private var reco = RecoEngine.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(router)
                .environmentObject(cart)
                .environmentObject(session)
                .environmentObject(orders)
                .environmentObject(pe)
                .environmentObject(display)
                .environmentObject(inbox)
                .environmentObject(location)
                .environmentObject(reco)
                .onOpenURL { router.handle($0) }
                .preferredColorScheme(.light)
        }
    }
}

struct RootView: View {
    @State private var showSplash = true
    @AppStorage("onboardingDone") private var onboardingDone = false

    var body: some View {
        ZStack {
            if showSplash {
                SplashView().transition(.opacity)
            } else if !onboardingDone {
                OnboardingView { onboardingDone = true }.transition(.opacity)
            } else {
                MainTabView().transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showSplash)
        .animation(.easeInOut(duration: 0.3), value: onboardingDone)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { showSplash = false }
        }
    }
}
