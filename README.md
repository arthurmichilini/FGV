# Milheiro

Junta **bancos, cartões, programas de pontos, benefícios da empresa e assinaturas** em um só lugar. Mostra onde dá para economizar e como aproveitar melhor as milhas.

| Pasta | O que é |
|---|---|
| [`ios/`](ios) | **App nativo para iPhone** (SwiftUI, iOS 17 ou mais recente), com widget, Siri, Atalhos e extensão de compartilhamento. |
| [`web/`](web) | Versão web (PWA). Funciona hoje em qualquer celular pelo navegador, sem instalar nada. |

---

## App para iPhone

### Telas

| Aba | Para que serve |
|---|---|
| **Início** | Índice de aproveitamento (0–100), quanto você paga e quanto pode economizar por mês, ações para fazer agora e renovações e vencimentos dos próximos 45 dias. |
| **Assinaturas** | Lista por categoria com gráfico de gastos. Para cada uma: quem paga (você ou a empresa), quanto você usa, dia da renovação, cartão usado e o que o plano inclui. Deslize para abrir o app, pausar ou excluir. |
| **Milhas** | Carteira de pontos com valor em R$ e vencimentos, **"Vale a pena esse resgate?"** (quanto vale cada milheiro), **simulador de transferência com bônus** e seus cartões com o retorno de cada um. |
| **Viagens** | Compara dinheiro com Smiles, LATAM Pass, Azul e TAP. Diz qual sai mais barato e **quantos pontos transferir** do banco. Mostra sala VIP e seguro dos seus cartões. |
| **Comprar** | "Qual cartão usar?": ranking dos cartões com cashback, pontos, IOF, desconto no Pix, shopping de pontos, quanto rende parcelar sem juros e os benefícios de Meli+ e Prime. |

### O que o otimizador encontra
- Pagar à parte algo que **já vem em outro plano** (Disney+ avulso e Meli+ Total, Prime Video e Amazon Prime).
- **Sobreposição** em categorias em que um serviço basta: academia (TotalPass da empresa + Wellhub pago por você), música, delivery, nuvem.
- **Streamings demais**: sugere rodízio.
- Assinaturas **quase sem uso**, informadas por você ou **medidas automaticamente** (veja abaixo).
- **Plano anual** mais barato, **clube de pontos** caro e **anuidade maior** que o retorno do cartão.
- Assinaturas no **cartão que rende menos**.
- **Pontos vencendo** e saldos que deveriam **esperar uma campanha de bônus**.

### Integração com o iPhone
- **Medir o uso real dos apps.** Com uma automação do app Atalhos ("quando o Netflix for aberto → Registrar uso de app"), o Milheiro conta quantas vezes você abre cada app de assinatura. Depois de 14 dias, essa medição substitui o "quanto você usa" e aponta o que ficou parado. O passo a passo está no app.
- **Siri, Spotlight e Botão de Ação:** "E aí Siri, qual cartão usar no Milheiro", "Resumo do Milheiro", "Quanto posso economizar no Milheiro".
- **Widget** na tela inicial (pequeno e médio) e na tela bloqueada: aproveitamento, economia possível e próximas renovações.
- **Compartilhar → Milheiro:** no Safari, na Amazon ou no Mercado Livre, compartilhe o produto e veja qual cartão usar.
- **Notificações:** 2 dias antes de cada renovação, 30 e 7 dias antes de pontos vencerem e 7 dias antes das viagens.
- **Calendário:** adiciona renovações (recorrentes), vencimentos e viagens com alarmes.
- **Abrir os apps** do Nubank, Mercado Livre, Netflix, Spotify, iFood, Uber e outros direto da assinatura ou do cartão.
- **Atalhos no ícone** (toque longo): Qual cartão usar?, Vale o resgate?, Nova assinatura e Viagens.
- **Colar preço** sem o aviso de permissão (botão de colar do sistema) e links `milheiro://comprar?valor=199,90`.

### Como instalar no seu iPhone

**Com um Mac (grátis):**
1. Instale o Xcode (App Store) e o [Homebrew](https://brew.sh), depois rode `brew install xcodegen`.
2. Baixe este repositório e entre na pasta `ios`.
3. Abra `Config/Milheiro.xcconfig` e troque `com.seunome` por um identificador só seu (ex.: `com.arthursilva`).
4. Rode `xcodegen generate` e abra o `Milheiro.xcodeproj` que foi criado.
5. Em **Signing & Capabilities**, escolha seu Apple ID como *Team* nos três alvos: Milheiro, MilheiroWidget e MilheiroShare.
6. Conecte o iPhone, ative o **Modo de Desenvolvedor** (Ajustes > Privacidade e Segurança), escolha o iPhone no Xcode e toque em ▶.

Com um Apple ID gratuito, o app instalado assim vale por 7 dias e depois precisa ser instalado de novo pelo Xcode. Com o **Apple Developer Program** (US$ 99 por ano), vale por um ano e você pode distribuir pelo **TestFlight**.

**Sem Mac:** o workflow `.github/workflows/ios.yml` compila o app num Mac do GitHub e gera `Milheiro-sem-assinatura.ipa` (aba **Actions**, artefato *Milheiro-ipa*). Esse arquivo pode ser instalado com o **Sideloadly** (Windows ou Mac) ou o **AltStore**, usando seu Apple ID. A validade também é de 7 dias com conta gratuita.

### Estrutura

```
ios/
  project.yml              projeto do Xcode (XcodeGen): app + widget + extensão
  Config/                  identificador, Info.plist e App Group
  Shared/                  núcleo sem interface: modelos, catálogo, motor, armazenamento
  UIShared/                cores e componentes usados pelo app, widget e extensão
  Milheiro/                app: telas, Siri/Atalhos, notificações, calendário
  MilheiroWidget/          widget da tela inicial e da tela bloqueada
  MilheiroShare/           extensão "Compartilhar → Milheiro"
  Tests/                   testes do motor (swift test)
  Package.swift            pacote só com o núcleo, para os testes
```

Os dados ficam **só no iPhone**, num App Group compartilhado entre o app, o widget e a extensão. Há backup e restauração em Ajustes.

### Status
O código do app iOS foi escrito sem acesso a um Mac e **ainda não foi compilado**. O primeiro build, no Xcode ou no GitHub Actions, pode apontar pequenos ajustes de compilação. A lógica de otimização é a mesma da versão web, que foi testada no navegador.

Para rodar os testes do motor num Mac: `cd ios && swift test`.

---

## Versão web (PWA)

A mesma ideia, no navegador. No iPhone, abra no Safari e toque em **Compartilhar > Adicionar à Tela de Início**. No Android, use **Instalar app** no Chrome.

- Rodar localmente: `cd web && python3 -m http.server 8000` e abra `http://localhost:8000`.
- Publicar: o workflow `.github/workflows/pages.yml` publica a pasta `web/` no GitHub Pages a cada push na `main` (ative em **Settings → Pages → Source: GitHub Actions**).
- Página única para prévias: `node web/tools/build-single.mjs` gera `web/dist/milheiro.html`.

---

## Observações importantes
- **Preços, taxas de acúmulo, parcerias de transferência e benefícios (ex.: o que o Meli+ inclui) são estimativas** e mudam com frequência. Tudo é editável no app, e os valores de referência do milheiro ficam em **Ajustes**.
- Nenhum banco ou app libera uma API pública para ler saldos e assinaturas, então os dados são informados por você. O Open Finance Brasil exige registro como instituição autorizada.
- Os esquemas de URL usados para abrir outros apps são os públicos conhecidos. Se algum mudar, o Milheiro abre o site oficial, que no iPhone costuma abrir o app pelo link universal.
