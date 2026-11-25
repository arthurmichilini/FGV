import SwiftUI
import UIKit

// MARK: Cartões e títulos

struct CardStyle: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

extension View {
    func cardStyle(padding: CGFloat = 16) -> some View {
        modifier(CardStyle(padding: padding))
    }

    /// Botão "OK" acima do teclado numérico, que não tem tecla de retorno.
    func keyboardDoneButton() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("OK") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .fontWeight(.semibold)
            }
        }
    }
}

struct SectionTitle: View {
    let title: String
    var trailing: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(.title3.weight(.bold))
            Spacer()
            if let trailing = trailing, let action = action {
                Button(trailing, action: action).font(.subheadline.weight(.semibold))
            } else if let trailing = trailing {
                Text(trailing).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: Campos numéricos

/// Campo para valores em pt-BR ("1.234,56"). Atualiza o valor a cada tecla,
/// para o botão Salvar nunca perder o que foi digitado.
struct NumberField: View {
    let placeholder: String
    @Binding var value: Double
    var decimals: Int = 2
    var alignment: TextAlignment = .trailing

    @State private var text: String = ""

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(decimals > 0 ? .decimalPad : .numberPad)
            .multilineTextAlignment(alignment)
            .monospacedDigit()
            .onAppear {
                if text.isEmpty && value != 0 { text = Fmt.number(value, decimals: decimals) }
            }
            .onChange(of: text) { _, newText in
                value = Fmt.parse(newText)
            }
            .onChange(of: value) { _, newValue in
                if abs(Fmt.parse(text) - newValue) > 0.000_1 {
                    text = newValue == 0 ? "" : Fmt.number(newValue, decimals: decimals)
                }
            }
    }
}

/// Campo numérico com rótulo, em caixa, para as calculadoras.
struct BoxField: View {
    let label: String
    @Binding var value: Double
    var decimals: Int = 2

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            NumberField(placeholder: "0", value: $value, decimals: decimals, alignment: .leading)
                .font(.body.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 9)
                .background(Theme.background, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: Chips

struct Chip: View {
    let title: String
    var selected: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .foregroundStyle(selected ? Theme.onInk : Color.primary)
                .background(selected ? AnyShapeStyle(Theme.ink) : AnyShapeStyle(Theme.card), in: Capsule())
                .overlay(Capsule().strokeBorder(selected ? Color.clear : Color.secondary.opacity(0.25), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

/// Distribui itens em linhas que quebram, como palavras num parágrafo.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var widest: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            widest = max(widest, x - spacing)
        }
        return CGSize(width: proposal.width ?? widest, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: Anel de aproveitamento

struct ScoreRing: View {
    let score: Int
    var size: CGFloat = 124
    @State private var shown: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.14), lineWidth: 10)
            Circle()
                .trim(from: 0, to: shown / 100)
                .stroke(Theme.scoreColor(score), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 2) {
                Text("\(score)")
                    .font(.system(size: size * 0.31, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                Text("APROVEITAMENTO")
                    .font(.system(size: 8.5, weight: .semibold))
                    .tracking(0.8)
                    .opacity(0.75)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.spring(duration: 1.1, bounce: 0.15)) { shown = Double(score) }
        }
        .onChange(of: score) { _, newScore in
            withAnimation(.easeOut(duration: 0.5)) { shown = Double(newScore) }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Aproveitamento: \(score) de 100")
    }
}

// MARK: Medidor de resgate

struct VerdictView: View {
    let result: RedemptionResult

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(result.verdict)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Theme.tone(result.tone))
                Text("Cada milheiro vale \(Fmt.brl(result.cpm)) neste resgate")
                    .font(.subheadline)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.tone(result.tone).opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            GeometryReader { geo in
                let width = geo.size.width
                let position = min(1, max(0, result.ratio / 1.6)) * width
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(LinearGradient(colors: [Theme.bad, Theme.warn, Theme.good], startPoint: .leading, endPoint: .trailing))
                        .frame(height: 8)
                    Rectangle()
                        .fill(Color.primary.opacity(0.35))
                        .frame(width: 2, height: 16)
                        .offset(x: width / 1.6 - 1)
                    Circle()
                        .fill(Theme.card)
                        .overlay(Circle().stroke(Color.primary, lineWidth: 3))
                        .frame(width: 18, height: 18)
                        .offset(x: position - 9)
                }
                .frame(height: 18)
            }
            .frame(height: 18)
            .animation(.spring(duration: 0.4), value: result.ratio)

            HStack {
                Text("pior")
                Spacer()
                Text("referência \(Fmt.brl(result.ref))")
                Spacer()
                Text("melhor")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: Faixa de exemplo

struct ExampleBanner: View {
    let onUseMine: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Text("Você está vendo **dados de exemplo**.")
                .font(.subheadline)
            Spacer()
            Button("Usar meus dados", action: onUseMine)
                .font(.footnote.weight(.semibold))
                .buttonStyle(.borderedProminent)
                .tint(Theme.ink)
                .controlSize(.small)
        }
        .padding(.leading, 14)
        .padding(.trailing, 8)
        .padding(.vertical, 8)
        .background(Theme.warn.opacity(0.15), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
