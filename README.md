# Milheiro

App para celular que junta **bancos, cartões, programas de pontos, benefícios da empresa e assinaturas** em um só lugar. Ele mostra onde dá para economizar e como aproveitar melhor as suas milhas.

É um **PWA**: abre no navegador, instala na tela inicial como um app, funciona offline e não precisa de loja de aplicativos. Os dados ficam **só no seu aparelho** (localStorage). Nada é enviado para servidores.

## O que ele faz

| Tela | Para que serve |
|---|---|
| **Início** | Índice de aproveitamento (0–100), quanto você gasta e quanto pode economizar por mês, uma lista de ações para fazer agora e as renovações e vencimentos dos próximos 45 dias. |
| **Assinaturas** | Todas as assinaturas por categoria, com gasto por categoria. Marca quem paga (você ou a empresa), quanto você usa, o dia da renovação e o cartão usado. |
| **Milhas** | Carteira de pontos com valor estimado em R$ e vencimentos. Tem o **"Vale a pena esse resgate?"** (calcula quanto vale o milheiro), o **simulador de transferência com bônus** e a lista dos seus cartões com o retorno de cada um. |
| **Viagens** | Compara o preço em dinheiro com as opções em Smiles, LATAM Pass, Azul e TAP. Diz qual sai mais barato e **quantos pontos transferir** do banco para completar o que falta. Também lista os benefícios dos seus cartões (sala VIP, seguro). |
| **Comprar** | "Qual cartão usar?": ranking dos cartões para cada compra. Considera cashback, pontos, IOF em compras internacionais, desconto no Pix, shopping de pontos, quanto o dinheiro rende ao parcelar sem juros e os benefícios de Meli+ e Prime. |

### O que o otimizador detecta
- Pagar à parte por algo que **já vem em outro plano** (ex.: Disney+ avulso e Meli+ Total, Prime Video e Amazon Prime).
- **Sobreposição** em categorias em que um serviço basta: academia (TotalPass da empresa + Wellhub pago por você), música, delivery, nuvem.
- **Streamings demais**: sugere fazer rodízio.
- Assinaturas que você **quase não usa**.
- **Plano anual** mais barato para o que você usa toda semana.
- **Clubes de pontos** caros (custo do milheiro acima do valor de resgate).
- **Anuidade maior** que o retorno do cartão.
- Assinaturas cobradas no **cartão que rende menos**.
- **Pontos vencendo** em até 180 dias e saldos parados que deveriam **esperar uma campanha de bônus**.

## Integração com o celular
- **Abrir os apps**: cada assinatura, banco e programa tem um botão que abre o app nativo (Nubank, Itaú, Mercado Livre, Wellhub, Netflix, Spotify, Smiles…). No Android usa o App Link do site oficial direcionado ao pacote do app. No iPhone usa o esquema de URL do app. Se o app não estiver instalado, abre o site.
- **Receber compartilhamentos**: com o app instalado (Android), compartilhe um produto da Amazon ou do Mercado Livre e escolha **Milheiro**. Ele lê o preço e a loja e diz qual cartão usar.
- **Colar preço**: copie um preço em qualquer app e toque em "Colar preço".
- **Calendário**: exporta renovações (recorrentes), vencimentos de pontos e viagens como `.ics`, com alarmes, para o app de Calendário.
- **Notificações**: ao abrir o app, avisa sobre renovações nos próximos 3 dias e pontos que vencem em até 30 dias.
- **Atalhos no ícone**: pressione o ícone do app para ir direto a "Qual cartão usar?", "Vale a pena esse resgate?", "Nova assinatura" e "Viagens".
- **Compartilhar plano de viagem** pelo WhatsApp, **vibração** ao tocar e **backup/restauração** em `.json`.

## Como usar no celular

1. Publique o site (veja abaixo) e abra o endereço no celular.
2. **Android (Chrome):** toque em "Instalar" no topo do app, ou use o menu ⋮ e "Instalar app".
   **iPhone (Safari):** toque em Compartilhar e depois em "Adicionar à Tela de Início".
3. Na primeira tela, escolha **"Começar com meus dados"** e marque seus bancos, programas e assinaturas. Toque duas vezes numa assinatura para marcá-la como benefício da empresa.
4. Ajuste preços, saldos, vencimentos e o gasto mensal de cada cartão. Quanto mais completo, melhores as sugestões.

### Publicar no GitHub Pages
O workflow `.github/workflows/pages.yml` publica o app a cada push na `main`. Para ativar: **Settings → Pages → Source: GitHub Actions**. (Em repositório privado, o GitHub Pages depende do seu plano do GitHub. Outra opção é publicar a pasta em Netlify, Vercel ou Cloudflare Pages, que têm plano gratuito.)

### Rodar localmente
```bash
python3 -m http.server 8000
# abra http://localhost:8000
```
O service worker e a instalação só funcionam em `https://` ou `localhost`.

### Página única
`node tools/build-single.mjs` gera `dist/milheiro.html` com tudo embutido, útil para prévias.

## Estrutura
```
index.html              casca do app
css/app.css             visual (tema claro e escuro)
js/catalog.js           bancos, cartões, programas, assinaturas e lojas (preços e taxas de referência)
js/engine.js            regras de otimização, valor do milheiro, ranking de cartões, viagens
js/phone.js             integração com o celular (apps, calendário, compartilhar, notificações, instalar)
js/app.js               telas, formulários e onboarding
sw.js                   offline e cliques em notificações
manifest.webmanifest    instalação, atalhos e recebimento de compartilhamentos
```

## Observações importantes
- **Preços, taxas de acúmulo, parcerias de transferência e benefícios (ex.: o que o Meli+ inclui) são estimativas** e mudam com frequência. Tudo é editável no app, e os valores de referência do milheiro ficam em **Ajustes**.
- Nenhum banco ou app libera uma API pública para ler saldos e assinaturas automaticamente, então os dados são informados por você. O Open Finance Brasil exige registro como instituição autorizada.
- Os nomes de pacotes Android e os esquemas iOS usados para abrir apps são os públicos conhecidos. Se algum mudar, o botão abre o site.
