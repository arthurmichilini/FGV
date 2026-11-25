# Milheiro

Junta **bancos, cartões, programas de pontos, benefícios da empresa e assinaturas** em um só lugar. Mostra onde dá para economizar e como aproveitar melhor as milhas.

| Pasta | O que é |
|---|---|
| [`docs/`](docs) | **App para iPhone pelo Safari** (web app instalável). Grátis, sem Mac e sem App Store. É a versão em uso. |
| [`ios/`](ios) | App nativo em SwiftUI, com widget, Siri e extensão de compartilhamento. Para usar no futuro: precisa de um Mac ou da conta Apple Developer. |

---

## App para iPhone (web)

### Como instalar
1. Abra **https://arthurmichilini.github.io/FGV/** no **Safari** do iPhone (depois de publicar, veja abaixo).
2. Toque em **Compartilhar** (o quadrado com a seta para cima).
3. Toque em **Adicionar à Tela de Início** e depois em **Adicionar**.

O Milheiro aparece na tela inicial com ícone próprio, abre em tela cheia como um app e funciona sem internet. O próprio app mostra esse passo a passo na primeira vez.

### Telas

| Aba | Para que serve |
|---|---|
| **Início** | Índice de aproveitamento (0–100), quanto você paga e quanto pode economizar por mês, ações para fazer agora e renovações e vencimentos dos próximos 45 dias. |
| **Assinaturas** | Lista por categoria com gastos por categoria. Para cada uma: quem paga (você ou a empresa), quanto você usa, dia da renovação, cartão usado e o que o plano inclui. |
| **Milhas** | Carteira de pontos com valor em R$ e vencimentos, **"Vale a pena esse resgate?"** (quanto vale cada milheiro), **simulador de transferência com bônus** e seus cartões com o retorno de cada um. |
| **Viagens** | Compara dinheiro com Smiles, LATAM Pass, Azul e TAP. Diz qual sai mais barato e **quantos pontos transferir** do banco. Mostra sala VIP e seguro dos seus cartões. |
| **Comprar** | "Qual cartão usar?": ranking dos cartões com cashback, pontos, IOF, desconto no Pix, shopping de pontos, quanto rende parcelar sem juros e os benefícios de Meli+ e Prime. |

### O que o otimizador encontra
- Pagar à parte algo que **já vem em outro plano** (Disney+ avulso e Meli+ Total, Prime Video e Amazon Prime).
- **Sobreposição** em categorias em que um serviço basta: academia (TotalPass da empresa + Wellhub pago por você), música, delivery, nuvem.
- **Streamings demais** (sugere rodízio) e assinaturas **quase sem uso**.
- **Plano anual** mais barato, **clube de pontos** caro e **anuidade maior** que o retorno do cartão.
- Assinaturas no **cartão que rende menos**.
- **Pontos vencendo** e saldos que deveriam **esperar uma campanha de bônus**.

### Integração com o iPhone
- Visual de app do iOS: título grande, barra de abas flutuante, folhas que sobem de baixo, chaves de liga e desliga nativas, tema claro e escuro.
- **Abrir os apps** do Nubank, Mercado Livre, Netflix, Spotify, iFood, Uber e outros direto da assinatura ou do cartão. Se o app não estiver instalado, o aviso oferece abrir o site.
- **Calendário:** renovações (repetindo todo mês), vencimentos de pontos e viagens, com alarmes, pela tela "Adicionar ao Calendário" do iPhone.
- **Número de pendências no ícone** do app e notificações ao abrir (iOS 16.4 ou mais recente, com o app instalado e as notificações ativadas em Ajustes).
- **Colar preço** copiado de qualquer app, **compartilhar** o plano de viagem pelo WhatsApp e **backup** no iCloud Drive ou no Arquivos.

O que só o app nativo faz: widget, Siri e o "Compartilhar → Milheiro" a partir de outros apps. O Safari não oferece esses recursos para web apps.

### Seus dados
Ficam **só no iPhone**, dentro do app instalado. Nada é enviado para servidores. Se você apagar o ícone da tela inicial, os dados vão junto, por isso o app lembra de fazer backup uma vez por mês (Ajustes > Fazer backup).

### Publicar no GitHub Pages (grátis)
O repositório é público, então o GitHub Pages é gratuito:
1. No GitHub, abra **Settings > Pages**.
2. Em **Build and deployment**, escolha **Deploy from a branch**.
3. Selecione o branch com o código (hoje `claude/subscription-benefits-manager-4ddmqh`; depois de juntar na `main`, a `main`) e a pasta **/docs**. Salve.
4. Em um ou dois minutos o app fica em **https://arthurmichilini.github.io/FGV/**.

Para testar no computador: `cd docs && python3 -m http.server 8000` e abra `http://localhost:8000`.

---

## App nativo (para o futuro)

A pasta [`ios/`](ios) tem o Milheiro em SwiftUI (iOS 17 ou mais recente), com recursos que a versão web não alcança:
- **Medir o uso real dos apps** com uma automação do app Atalhos ("quando o Netflix for aberto → Registrar uso de app").
- **Siri, Spotlight e Botão de Ação:** "E aí Siri, qual cartão usar no Milheiro".
- **Widget** na tela inicial e na tela bloqueada.
- **Compartilhar → Milheiro** no Safari, na Amazon ou no Mercado Livre.
- Notificações agendadas, Calendário direto e atalhos no ícone.

Para instalar é preciso **um Mac com Xcode** (grátis; com Apple ID gratuito o app vale 7 dias) ou a **conta Apple Developer** (US$ 99 por ano), que permite compilar na nuvem e instalar pelo TestFlight sem Mac. O passo a passo está em [`ios/project.yml`](ios/project.yml) e no workflow [`.github/workflows/ios.yml`](.github/workflows/ios.yml), que compila o app num Mac do GitHub a cada mudança na pasta `ios/`.

O código nativo foi escrito sem acesso a um Mac e ainda não foi compilado. O primeiro build pode apontar pequenos ajustes.

---

## Observações importantes
- **Preços, taxas de acúmulo, parcerias de transferência e benefícios (ex.: o que o Meli+ inclui) são estimativas** e mudam com frequência. Tudo é editável no app, e os valores de referência do milheiro ficam em **Ajustes**.
- Nenhum banco ou app libera uma API pública para ler saldos e assinaturas, então os dados são informados por você. O Open Finance Brasil exige registro como instituição autorizada.
- Os esquemas de URL usados para abrir outros apps são os públicos conhecidos. Se algum mudar, o Milheiro oferece abrir o site oficial.
