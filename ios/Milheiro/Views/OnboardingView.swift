import SwiftUI

/// Primeiro acesso: bancos, programas de pontos e assinaturas em quatro passos.
struct OnboardingView: View {
    @Environment(AppStore.self) private var store
    @State private var step = 0
    @State private var name = ""
    @State private var banks: Set<String> = []
    @State private var programs: Set<String> = []
    @State private var services: [String: Payer] = [:]

    var body: some View {
        Group {
            if step == 0 {
                welcome
            } else {
                VStack(spacing: 0) {
                    header
                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            stepContent
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }
                    footer
                }
            }
        }
        .background(Theme.background)
        .animation(.easeInOut(duration: 0.25), value: step)
    }

    // MARK: Boas-vindas

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 18) {
            Spacer(minLength: 12)
            WelcomeArt()
                .frame(maxWidth: .infinity)
                .frame(height: 230)
            Spacer(minLength: 12)
            Text("Cada real, cada ponto, aproveitado.")
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .fixedSize(horizontal: false, vertical: true)
            Text("O Milheiro junta seus bancos, cartões, benefícios da empresa e assinaturas. Ele encontra o que está sobrando, avisa antes dos pontos vencerem e diz qual cartão usar em cada compra.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            VStack(spacing: 10) {
                Button {
                    step = 1
                } label: {
                    Text("Começar com meus dados").frame(maxWidth: .infinity).padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.ink)
                Button {
                    store.replace(with: SampleData.example())
                } label: {
                    Text("Ver com dados de exemplo").frame(maxWidth: .infinity).padding(.vertical, 6)
                }
                .buttonStyle(.bordered)
            }
            .controlSize(.large)
            Text("Leva 1 minuto. Seus dados ficam só no seu iPhone.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }

    // MARK: Passos

    private var header: some View {
        HStack {
            Button {
                step -= 1
            } label: {
                Image(systemName: "chevron.left").font(.body.weight(.semibold)).padding(10)
            }
            .accessibilityLabel("Voltar")
            Spacer()
            HStack(spacing: 6) {
                ForEach(1...3, id: \.self) { i in
                    Capsule()
                        .fill(i <= step ? Theme.accent : Color.secondary.opacity(0.25))
                        .frame(width: 24, height: 5)
                }
            }
            Spacer()
            Color.clear.frame(width: 40, height: 1)
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case 1:
            Text("Quais bancos e cartões você usa?").font(.title.weight(.bold))
            Text("Toque para selecionar. Você ajusta os detalhes depois.").foregroundStyle(.secondary)
            TextField("Como quer ser chamado?", text: $name)
                .textContentType(.givenName)
                .padding(12)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            grid {
                ForEach(Catalog.banks) { bank in
                    OnboardingChip(abbr: bank.abbr, color: bank.color, fg: bank.fg, title: bank.name,
                                   badge: nil, selected: banks.contains(bank.id), company: false) {
                        toggle(&banks, bank.id)
                    }
                }
            }
        case 2:
            Text("Em quais programas você tem pontos?").font(.title.weight(.bold))
            Text("Programas de banco e de companhias aéreas.").foregroundStyle(.secondary)
            grid {
                ForEach(Catalog.programs) { program in
                    OnboardingChip(abbr: program.abbr, color: program.color, fg: 0xFFFFFF, title: program.name,
                                   badge: nil, selected: programs.contains(program.id), company: false) {
                        toggle(&programs, program.id)
                    }
                }
            }
        default:
            Text("Assinaturas e benefícios").font(.title.weight(.bold))
            Text("Toque uma vez se **você paga**. Toque de novo se é **benefício da empresa**, como TotalPass ou Wellhub.")
                .foregroundStyle(.secondary)
            grid {
                ForEach(Catalog.services.filter { $0.id != "custom" }) { svc in
                    let payer = services[svc.id]
                    OnboardingChip(abbr: svc.abbr, color: svc.color, fg: svc.fg, title: svc.name,
                                   badge: payer == nil ? nil : (payer == .company ? "empresa" : "eu pago"),
                                   selected: payer != nil, company: payer == .company) {
                        cycle(svc.id)
                    }
                }
            }
        }
    }

    private var footer: some View {
        Button {
            if step < 3 { step += 1 } else { finish() }
        } label: {
            Text(step < 3 ? "Continuar" : "Ver minhas economias")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .tint(Theme.ink)
        .controlSize(.large)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.bar)
    }

    private func grid<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            content()
        }
        .padding(.top, 4)
    }

    private func toggle(_ set: inout Set<String>, _ id: String) {
        if set.contains(id) { set.remove(id) } else { set.insert(id) }
    }

    private func cycle(_ id: String) {
        switch services[id] {
        case .none: services[id] = .me
        case .some(.me): services[id] = .company
        case .some(.company): services[id] = nil
        }
    }

    private func finish() {
        let data = SampleData.fromOnboarding(name: name, banks: Catalog.banks.map { $0.id }.filter { banks.contains($0) },
                                             programs: Catalog.programs.map { $0.id }.filter { programs.contains($0) },
                                             services: services)
        store.replace(with: data)
        Toast.shared.show("Pronto! Ajuste preços e saldos para afinar as sugestões.")
    }
}

struct OnboardingChip: View {
    let abbr: String
    let color: UInt32
    let fg: UInt32
    let title: String
    let badge: String?
    let selected: Bool
    let company: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                LogoTile(abbr: abbr, color: color, fg: fg, size: 30)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                Spacer(minLength: 0)
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
            .background(selected ? Theme.accent.opacity(0.12) : Theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: selected ? 2 : 1)
            )
            .overlay(alignment: .topTrailing) {
                if let badge = badge {
                    Text(badge.uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .tracking(0.5)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .foregroundStyle(company ? Color.black : Theme.onInk)
                        .background(company ? Theme.gold : Theme.ink, in: Capsule())
                        .offset(x: -8, y: -8)
                }
            }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: selected)
        .sensoryFeedback(.selection, trigger: company)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityValue(badge ?? "")
    }

    private var borderColor: Color {
        if company { return Theme.gold }
        return selected ? Theme.ink : Color.secondary.opacity(0.25)
    }
}

/// Cartões e um cartão de embarque empilhados.
struct WelcomeArt: View {
    @State private var float = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(hex: 0x820AD1))
                .frame(width: 200, height: 124)
                .overlay(alignment: .bottomLeading) {
                    Text("•••• 4021").font(.system(size: 13, design: .monospaced)).foregroundStyle(.white).padding(16)
                }
                .rotationEffect(.degrees(-10))
                .offset(x: -40, y: -16)
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Theme.ink)
                .frame(width: 200, height: 124)
                .overlay {
                    VStack(spacing: 2) {
                        Text("48.000").font(.system(size: 16, weight: .semibold, design: .monospaced))
                        Text("PONTOS LIVELO").font(.system(size: 9, weight: .medium, design: .monospaced)).opacity(0.65)
                    }
                    .foregroundStyle(Theme.onInk)
                    .offset(x: 30, y: -14)
                }
                .overlay(alignment: .bottomLeading) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(Theme.gold)
                        .padding(18)
                }
                .rotationEffect(.degrees(4))
                .offset(x: 0, y: 4)
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("GRU").font(.system(size: 22, weight: .heavy, design: .rounded))
                        Image(systemName: "airplane").foregroundStyle(Theme.accent)
                    }
                    Text("MILHAS · 1 PAX").font(.system(size: 9, design: .monospaced)).foregroundStyle(.secondary)
                }
                .padding(.leading, 16)
                Spacer()
                Text("LIS").font(.system(size: 18, weight: .heavy, design: .rounded)).padding(.trailing, 16)
            }
            .frame(width: 190, height: 74)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
            .rotationEffect(.degrees(-3))
            .offset(x: 50, y: 62)
        }
        .offset(y: float ? -5 : 5)
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) { float = true }
        }
        .accessibilityHidden(true)
    }
}
