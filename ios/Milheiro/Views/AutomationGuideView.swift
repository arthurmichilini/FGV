import SwiftUI
import AppIntents

/// Como medir o uso real dos apps de assinatura com uma automação do app Atalhos.
struct AutomationGuideView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private let steps: [String] = [
        "Abra o app Atalhos e toque em Automação.",
        "Toque em + (Nova Automação) e escolha App.",
        "Selecione o app de assinatura, por exemplo Netflix. Marque \u{201C}For Aberto\u{201D} e escolha \u{201C}Executar Imediatamente\u{201D}.",
        "Crie uma automação em branco, busque Milheiro e adicione a ação \u{201C}Registrar uso de app\u{201D}.",
        "Na ação, escolha o mesmo app (Netflix) e conclua.",
        "Aqui no Milheiro, abra a assinatura e ative \u{201C}Medir uso automaticamente\u{201D}.",
    ]

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: "hand.tap.fill")
                        .font(.largeTitle)
                        .foregroundStyle(Theme.accent)
                    Text("Descubra o que você realmente usa")
                        .font(.title3.weight(.bold))
                    Text("Cada vez que você abrir um app de assinatura, o iPhone avisa o Milheiro. Depois de 14 dias, ele mostra quantas vezes você abriu cada app e sugere cancelar o que ficou parado.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            }
            Section("Passo a passo") {
                ForEach(Array(steps.enumerated()), id: \.offset) { item in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(item.offset + 1)")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Theme.onInk)
                            .frame(width: 26, height: 26)
                            .background(Theme.ink, in: Circle())
                        Text(item.element).font(.subheadline)
                    }
                    .padding(.vertical, 2)
                }
            }
            Section {
                Button {
                    AppLauncher.open(urlString: "shortcuts://")
                } label: {
                    Label("Abrir o app Atalhos", systemImage: "square.2.layers.3d")
                }
                ShortcutsLink()
            }
            Section {
                let tracked = store.data.subs.filter { $0.autoTrack }
                if tracked.isEmpty {
                    Text("Nenhuma assinatura com medição ligada ainda.").foregroundStyle(.secondary)
                } else {
                    ForEach(tracked) { sub in
                        HStack {
                            Text(sub.name)
                            Spacer()
                            Text(statusText(sub)).foregroundStyle(.secondary).font(.subheadline)
                        }
                    }
                }
            } header: {
                Text("Medindo agora")
            } footer: {
                Text("A medição fica só no seu iPhone. O Milheiro não vê o que você assiste, só que o app foi aberto.")
            }
        }
        .navigationTitle("Medir uso dos apps")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func statusText(_ sub: Subscription) -> String {
        let opens = Engine.opens(store.usage, serviceId: sub.serviceId)
        let count = opens == 1 ? "1 abertura" : "\(opens) aberturas"
        if Engine.isTracking(sub) { return "\(count) em 30 dias" }
        let since = sub.autoTrackSince ?? Date()
        let remaining = max(0, 14 - Int(Date().timeIntervalSince(since) / Engine.day))
        return "\(count) · resultado em \(remaining) dias"
    }
}
