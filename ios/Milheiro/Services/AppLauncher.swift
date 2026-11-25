import UIKit

/// Abre outros apps do iPhone (Nubank, Netflix, Mercado Livre…).
/// Tenta o esquema de URL do app; se ele não estiver instalado, abre o site oficial,
/// que muitas vezes abre o app pelo link universal.
enum AppLauncher {
    @MainActor
    static func open(_ link: AppLink?) {
        guard let link = link else { return }
        let web = link.web.flatMap { URL(string: $0) }
        if let scheme = link.scheme, let url = URL(string: scheme) {
            UIApplication.shared.open(url, options: [:]) { opened in
                if !opened, let web = web { UIApplication.shared.open(web, options: [:], completionHandler: nil) }
            }
        } else if let web = web {
            UIApplication.shared.open(web, options: [:], completionHandler: nil)
        }
    }

    @MainActor
    static func open(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    static func canOpen(_ link: AppLink?) -> Bool {
        link?.scheme != nil || link?.web != nil
    }
}
