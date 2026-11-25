import SwiftUI
import UIKit
import UserNotifications

@main
struct MilheiroApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var store = AppStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(Router.shared)
                .environment(Toast.shared)
                .tint(Theme.accent)
                .onOpenURL { url in Router.shared.handle(url) }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { store.refreshFromDisk() }
        }
    }
}

// MARK: Navegação e atalhos

enum AppTab: String, Hashable {
    case inicio, assinaturas, milhas, viagens, comprar
}

/// Guarda a aba atual e recebe links milheiro://, atalhos do ícone e toques em notificações.
@Observable
final class Router {
    static let shared = Router()

    var tab: AppTab = .inicio
    var showRedeem = false
    var showNewSub = false
    var pendingAmount: Double? = nil

    func handle(_ url: URL) {
        guard url.scheme == "milheiro" else { return }
        let route = url.host ?? ""
        switch route {
        case "comprar":
            tab = .comprar
            if let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let value = comps.queryItems?.first(where: { $0.name == "valor" })?.value {
                pendingAmount = Fmt.parse(value)
            }
        case "resgate":
            tab = .milhas
            showRedeem = true
        case "nova":
            tab = .assinaturas
            showNewSub = true
        case "assinaturas":
            tab = .assinaturas
        case "milhas":
            tab = .milhas
        case "viagens":
            tab = .viagens
        default:
            tab = .inicio
        }
    }

    func handle(route: String) {
        if let url = URL(string: "milheiro://\(route)") { handle(url) }
    }
}

/// Aviso rápido no rodapé da tela.
@Observable
final class Toast {
    static let shared = Toast()

    var text: String? = nil

    func show(_ message: String) {
        text = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) { [weak self] in
            if self?.text == message { self?.text = nil }
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // App aberto por um atalho do ícone (toque longo).
        if let item = options.shortcutItem { Router.shared.handle(route: item.type) }
        let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        return config
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        if let route = response.notification.request.content.userInfo["route"] as? String {
            DispatchQueue.main.async { Router.shared.handle(route: route) }
        }
        completionHandler()
    }
}

final class SceneDelegate: NSObject, UIWindowSceneDelegate {
    // Atalho do ícone com o app já aberto.
    func windowScene(_ windowScene: UIWindowScene,
                     performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void) {
        Router.shared.handle(route: shortcutItem.type)
        completionHandler(true)
    }
}
