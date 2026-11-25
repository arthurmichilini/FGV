import SwiftUI
import AppIntents
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var settings = AppSettings()
    @State private var loaded = false
    @State private var message: String?
    @State private var importing = false
    @State private var confirmReset = false
    @State private var backupURL: URL?

    var body: some View {
        NavigationStack {
            Form {
                Section("Perfil") {
                    TextField("Seu nome", text: $name)
                }
                Section {
                    LabeledContent("Dólar (R$)") { NumberField(placeholder: "5,40", value: $settings.usd) }
                    LabeledContent("IOF no cartão (%)") { NumberField(placeholder: "3,5", value: $settings.iof) }
                    LabeledContent("CDI ao mês (%)") { NumberField(placeholder: "1,0", value: $settings.cdiMonthly) }
                } header: {
                    Text("Mercado")
                } footer: {
                    Text("Usados para converter pontos por dólar, calcular o IOF e quanto rende parcelar sem juros.")
                }
                Section {
                    ForEach(Catalog.programs) { program in
                        LabeledContent {
                            NumberField(placeholder: Fmt.number(program.ref), value: refBinding(program.id))
                                .frame(maxWidth: 90)
                        } label: {
                            HStack(spacing: 10) {
                                LogoTile(abbr: program.abbr, color: program.color, size: 28)
                                Text(program.name)
                            }
                        }
                    }
                } header: {
                    Text("Quanto vale o milheiro (R$)")
                } footer: {
                    Text("Valor de 1.000 pontos em resgates bons. Define quanto seus pontos valem e quando um resgate compensa. Em branco, usa a média de mercado.")
                }
                Section {
                    Toggle("Notificações de renovações e vencimentos", isOn: notificationsBinding)
                    Button {
                        Task { @MainActor in message = await store.exportCalendar() }
                    } label: {
                        Label("Adicionar lembretes ao Calendário", systemImage: "calendar.badge.plus")
                    }
                } header: {
                    Text("Lembretes")
                } footer: {
                    Text("Avisos 2 dias antes de cada renovação, 30 e 7 dias antes de pontos vencerem e 7 dias antes das viagens.")
                }
                Section {
                    NavigationLink {
                        AutomationGuideView()
                    } label: {
                        Label("Medir o uso dos apps automaticamente", systemImage: "hand.tap")
                    }
                    ShortcutsLink()
                } header: {
                    Text("Siri e Atalhos")
                } footer: {
                    Text("Diga \u{201C}E aí Siri, qual cartão usar no Milheiro\u{201D} ou \u{201C}Resumo do Milheiro\u{201D}. Os mesmos atalhos funcionam no Botão de Ação e no Spotlight.")
                }
                Section {
                    if let url = backupURL {
                        ShareLink(item: url) {
                            Label("Fazer backup dos dados", systemImage: "square.and.arrow.up")
                        }
                    }
                    Button {
                        importing = true
                    } label: {
                        Label("Restaurar backup", systemImage: "square.and.arrow.down")
                    }
                    Button {
                        store.replace(with: SampleData.example())
                        dismiss()
                    } label: {
                        Label("Carregar dados de exemplo", systemImage: "sparkles")
                    }
                    Button(role: .destructive) {
                        confirmReset = true
                    } label: {
                        Label("Apagar tudo e recomeçar", systemImage: "trash")
                    }
                } header: {
                    Text("Dados")
                } footer: {
                    Text("Seus dados ficam só neste iPhone. Nada é enviado para servidores. Preços, taxas e benefícios sugeridos são estimativas: confira nos apps de cada empresa.")
                }
            }
            .navigationTitle("Ajustes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Salvar") { save() } }
            }
            .keyboardDoneButton()
            .onAppear(perform: load)
            .alert("Milheiro", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(message ?? "")
            }
            .confirmationDialog("Apagar todos os dados deste iPhone?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Apagar tudo", role: .destructive) {
                    store.replace(with: AppData())
                    dismiss()
                }
            }
            .fileImporter(isPresented: $importing, allowedContentTypes: [UTType.json]) { result in
                restore(result)
            }
        }
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        name = store.data.name
        settings = store.data.settings
        if let raw = SharedStore.encode(store.data) {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("milheiro-backup.json")
            if (try? raw.write(to: url, options: .atomic)) != nil { backupURL = url }
        }
    }

    private func save() {
        var cleaned = settings
        cleaned.ref = cleaned.ref.filter { $0.value > 0 }
        let newName = name.trimmingCharacters(in: .whitespaces)
        store.mutate { d in
            d.name = newName
            d.settings = cleaned
        }
        dismiss()
    }

    private func refBinding(_ id: String) -> Binding<Double> {
        Binding(get: { settings.ref[id] ?? 0 }, set: { settings.ref[id] = $0 })
    }

    private var notificationsBinding: Binding<Bool> {
        Binding(
            get: { settings.notificationsOn },
            set: { on in
                settings.notificationsOn = on
                guard on else { return }
                Task { @MainActor in
                    let granted = await Reminders.requestNotifications()
                    if !granted {
                        settings.notificationsOn = false
                        message = "Notificações bloqueadas. Libere em Ajustes > Notificações > Milheiro."
                    }
                }
            })
    }

    private func restore(_ result: Result<URL, Error>) {
        guard case .success(let url) = result else { return }
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        guard let raw = try? Data(contentsOf: url), let data = SharedStore.decode(raw) else {
            message = "Arquivo inválido. Use um backup gerado pelo Milheiro."
            return
        }
        store.replace(with: data)
        dismiss()
    }
}
