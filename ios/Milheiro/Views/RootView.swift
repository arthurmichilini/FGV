import SwiftUI

struct RootView: View {
    @Environment(AppStore.self) private var store
    @Environment(Toast.self) private var toast

    var body: some View {
        Group {
            if store.data.onboarded {
                MainTabs()
            } else {
                OnboardingView()
            }
        }
        .overlay(alignment: .bottom) {
            if let text = toast.text {
                Text(text)
                    .font(.subheadline.weight(.medium))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .foregroundStyle(Color(uiColor: .systemBackground))
                    .background(Color.primary.opacity(0.92), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .padding(.horizontal, 24)
                    .padding(.bottom, 92)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .accessibilityAddTraits(.isStaticText)
            }
        }
        .animation(.spring(duration: 0.35), value: toast.text)
    }
}

struct MainTabs: View {
    @Environment(Router.self) private var router

    var body: some View {
        @Bindable var router = router
        TabView(selection: $router.tab) {
            HomeView()
                .tabItem { Label("Início", systemImage: "house.fill") }
                .tag(AppTab.inicio)
            SubscriptionsView()
                .tabItem { Label("Assinaturas", systemImage: "rectangle.stack.fill") }
                .tag(AppTab.assinaturas)
            MilesView()
                .tabItem { Label("Milhas", systemImage: "star.circle.fill") }
                .tag(AppTab.milhas)
            TripsView()
                .tabItem { Label("Viagens", systemImage: "airplane") }
                .tag(AppTab.viagens)
            BuyView()
                .tabItem { Label("Comprar", systemImage: "creditcard.fill") }
                .tag(AppTab.comprar)
        }
        .sensoryFeedback(.selection, trigger: router.tab)
    }
}
