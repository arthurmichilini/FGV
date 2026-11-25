import UIKit
import SwiftUI
import UniformTypeIdentifiers

// Extensão "Compartilhar → Milheiro": no Safari, na Amazon ou no Mercado Livre,
// toque em Compartilhar e escolha Milheiro para ver qual cartão usar.

@Observable
final class ShareModel {
    var text = ""
    var amount: Double = 0
    var merchantId = "outro"

    func ingest(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        text = text.isEmpty ? trimmed : text + " " + trimmed
        let parsed = ShareParser.parse(text)
        if let found = parsed.amount { amount = found }
        if let merchant = parsed.merchantId { merchantId = merchant }
    }
}

final class ShareViewController: UIViewController {
    private let model = ShareModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        let root = ShareCardView(model: model) { [weak self] in
            self?.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        }
        let host = UIHostingController(rootView: root)
        addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        host.didMove(toParent: self)
        loadSharedItems()
    }

    private func loadSharedItems() {
        let items = (extensionContext?.inputItems as? [NSExtensionItem]) ?? []
        for item in items {
            if let text = item.attributedContentText?.string { model.ingest(text) }
            for provider in item.attachments ?? [] {
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] value, _ in
                        guard let url = value as? URL else { return }
                        DispatchQueue.main.async { self?.model.ingest(url.absoluteString) }
                    }
                } else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] value, _ in
                        guard let text = value as? String else { return }
                        DispatchQueue.main.async { self?.model.ingest(text) }
                    }
                }
            }
        }
    }
}

struct ShareCardView: View {
    @Bindable var model: ShareModel
    let onClose: () -> Void
    @State private var data = SharedStore.load()
    @State private var amountText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Compra") {
                    LabeledContent("Valor (R$)") {
                        TextField("0,00", text: $amountText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .monospacedDigit()
                    }
                    Picker("Loja", selection: $model.merchantId) {
                        ForEach(Catalog.merchants) { m in Text(m.name).tag(m.id) }
                    }
                }
                resultSection
            }
            .navigationTitle("Milheiro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Concluir", action: onClose)
                }
            }
            .onAppear { syncText(model.amount) }
            .onChange(of: amountText) { _, newText in model.amount = Fmt.parse(newText) }
            .onChange(of: model.amount) { _, newValue in syncText(newValue) }
        }
    }

    /// Mostra no campo o preço encontrado no link, sem atrapalhar o que a pessoa digita.
    private func syncText(_ value: Double) {
        if abs(Fmt.parse(amountText) - value) > 0.000_1 {
            amountText = value == 0 ? "" : Fmt.number(value, decimals: 2)
        }
    }

    @ViewBuilder
    private var resultSection: some View {
        if data.cards.isEmpty {
            Section {
                Text("Abra o Milheiro e cadastre seus cartões para ver qual rende mais.")
                    .foregroundStyle(.secondary)
            }
        } else if model.amount <= 0 {
            Section {
                Text("Digite o valor da compra.").foregroundStyle(.secondary)
            }
        } else {
            let result = Engine.purchase(data, amount: model.amount, merchantId: model.merchantId)
            Section("Use este cartão") {
                ForEach(Array(result.ranking.prefix(4))) { item in
                    HStack(spacing: 10) {
                        let bank = Catalog.bank(item.card.bankId)
                        LogoTile(abbr: bank?.abbr ?? "?", color: bank?.color ?? 0x64748B, fg: bank?.fg ?? 0xFFFFFF, size: 30)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.card.name).font(.subheadline.weight(.semibold))
                            if item.id == result.ranking.first?.id {
                                Text("Melhor opção").font(.caption).foregroundStyle(Theme.good)
                            }
                        }
                        Spacer()
                        Text(Fmt.brl(item.net)).monospacedDigit()
                    }
                }
            }
            if let perk = result.perk {
                Section { Text(perk).font(.footnote) }
            }
        }
    }
}
