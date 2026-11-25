/* Milheiro — catálogo de bancos, programas de pontos e assinaturas.
 * Preços, taxas de acúmulo e benefícios são ESTIMATIVAS de referência (nov/2026)
 * e mudam com frequência. Tudo pode ser ajustado dentro do app.
 *
 * link.android = nome do pacote (abre o app via intent:// no Android, com fallback web)
 * link.ios     = esquema de URL (tenta abrir o app no iPhone, com fallback web)
 * link.web     = página usada quando o app não está instalado
 */

const CATEGORIES = {
  video:    { label: 'Streaming de vídeo', exclusive: false, softLimit: 2 },
  music:    { label: 'Música', exclusive: true },
  gym:      { label: 'Academia e bem-estar', exclusive: true },
  shipping: { label: 'Compras e frete', exclusive: false },
  delivery: { label: 'Delivery', exclusive: true },
  mobility: { label: 'Mobilidade', exclusive: false },
  cloud:    { label: 'Armazenamento', exclusive: true },
  ai:       { label: 'Inteligência artificial', exclusive: false },
  club:     { label: 'Clube de pontos', exclusive: false },
  other:    { label: 'Outros', exclusive: false },
};

/* Programas de pontos e milhas.
 * ref = valor de referência em R$ por 1.000 pontos (milheiro) para resgates bons.
 * partners = para onde os pontos podem ser transferidos (proporção padrão 1:1). */
const PROGRAMS = [
  { id: 'livelo',  name: 'Livelo',          kind: 'bank',    color: '#E5007E', abbr: 'Lv', ref: 30, expiryMonths: 24,
    partners: ['smiles', 'latam', 'azul', 'tap'],
    link: { android: 'br.com.pontomais.livelo', web: 'https://www.livelo.com.br' } },
  { id: 'esfera',  name: 'Esfera',          kind: 'bank',    color: '#EC0000', abbr: 'Es', ref: 30, expiryMonths: 24,
    partners: ['smiles', 'latam', 'azul', 'tap'],
    link: { web: 'https://www.esfera.com.vc' } },
  { id: 'atomos',  name: 'Átomos C6',       kind: 'bank',    color: '#1F1F1F', abbr: 'C6', ref: 30, expiryMonths: 24,
    partners: ['smiles', 'latam', 'azul', 'tap', 'livelo', 'esfera'],
    link: { android: 'com.c6bank.app', web: 'https://www.c6bank.com.br' } },
  { id: 'itau',    name: 'Itaú Pontos',     kind: 'bank',    color: '#EC7000', abbr: 'It', ref: 28, expiryMonths: 24,
    partners: ['latam', 'smiles', 'azul'],
    link: { android: 'com.itau', web: 'https://www.itau.com.br' } },
  { id: 'nupontos',name: 'Nubank Rewards',  kind: 'bank',    color: '#820AD1', abbr: 'Nu', ref: 25, expiryMonths: 0,
    partners: ['smiles', 'latam', 'azul'],
    link: { android: 'com.nu.production', ios: 'nubank://', web: 'https://nubank.com.br' } },
  { id: 'interloop', name: 'Inter Loop',    kind: 'bank',    color: '#FF7A00', abbr: 'In', ref: 20, expiryMonths: 12,
    partners: ['smiles', 'latam'],
    link: { android: 'br.com.intermedium', web: 'https://inter.co' } },
  { id: 'smiles',  name: 'Smiles',          kind: 'airline', color: '#FF5A00', abbr: 'Sm', ref: 17, expiryMonths: 36,
    partners: [],
    link: { android: 'br.com.smiles.android', web: 'https://www.smiles.com.br' } },
  { id: 'latam',   name: 'LATAM Pass',      kind: 'airline', color: '#1B0088', abbr: 'LA', ref: 25, expiryMonths: 24,
    partners: [],
    link: { android: 'com.latam.android', web: 'https://latampass.latam.com' } },
  { id: 'azul',    name: 'Azul Fidelidade', kind: 'airline', color: '#0A3E8C', abbr: 'Az', ref: 15, expiryMonths: 24,
    partners: [],
    link: { android: 'br.com.voeazul', web: 'https://www.voeazul.com.br' } },
  { id: 'tap',     name: 'TAP Miles&Go',    kind: 'airline', color: '#00A651', abbr: 'TP', ref: 30, expiryMonths: 36,
    partners: [],
    link: { web: 'https://www.flytap.com/pt-br/miles-and-go' } },
];

/* Bancos e cartões. Os produtos são pontos de partida para o cadastro. */
const BANKS = [
  { id: 'nubank', name: 'Nubank', color: '#820AD1', abbr: 'Nu',
    link: { android: 'com.nu.production', ios: 'nubank://', web: 'https://nubank.com.br' },
    products: [
      { name: 'Nubank (básico)', earn: 'none', fee: 0 },
      { name: 'Ultravioleta', earn: 'cashback', cashbackPct: 1, fee: 0, lounge: true, insurance: true },
      { name: 'Nubank Rewards', earn: 'points', ptsPerUSD: 1, program: 'nupontos', fee: 190 },
    ] },
  { id: 'itau', name: 'Itaú', color: '#EC7000', abbr: 'It',
    link: { android: 'com.itau', web: 'https://www.itau.com.br' },
    products: [
      { name: 'Itaú Personnalité Infinite', earn: 'points', ptsPerUSD: 2.2, program: 'itau', fee: 1300, lounge: true, insurance: true },
      { name: 'Itaú Platinum', earn: 'points', ptsPerUSD: 1.5, program: 'itau', fee: 500 },
    ] },
  { id: 'santander', name: 'Santander', color: '#EC0000', abbr: 'Sa',
    link: { android: 'com.santander.app', web: 'https://www.santander.com.br' },
    products: [
      { name: 'Santander Unique', earn: 'points', ptsPerUSD: 2.2, program: 'esfera', fee: 1300, lounge: true, insurance: true },
      { name: 'Santander Unlimited', earn: 'points', ptsPerUSD: 2, program: 'esfera', fee: 900 },
    ] },
  { id: 'bradesco', name: 'Bradesco', color: '#CC092F', abbr: 'Br',
    link: { android: 'com.bradesco', web: 'https://banco.bradesco' },
    products: [
      { name: 'Bradesco Visa Infinite', earn: 'points', ptsPerUSD: 2.5, program: 'livelo', fee: 1200, lounge: true, insurance: true },
      { name: 'Bradesco Platinum', earn: 'points', ptsPerUSD: 1.6, program: 'livelo', fee: 600 },
    ] },
  { id: 'bb', name: 'Banco do Brasil', color: '#F9DD16', fg: '#0038A8', abbr: 'BB',
    link: { android: 'br.com.bb.android', web: 'https://www.bb.com.br' },
    products: [
      { name: 'Ourocard Visa Infinite', earn: 'points', ptsPerUSD: 2.2, program: 'livelo', fee: 1100, lounge: true, insurance: true },
      { name: 'Ourocard Platinum', earn: 'points', ptsPerUSD: 1.4, program: 'livelo', fee: 500 },
    ] },
  { id: 'c6', name: 'C6 Bank', color: '#1F1F1F', abbr: 'C6',
    link: { android: 'com.c6bank.app', web: 'https://www.c6bank.com.br' },
    products: [
      { name: 'C6 Carbon', earn: 'points', ptsPerUSD: 2.5, program: 'atomos', fee: 1020, lounge: true, insurance: true },
      { name: 'C6 Platinum', earn: 'points', ptsPerUSD: 1, program: 'atomos', fee: 0 },
    ] },
  { id: 'inter', name: 'Inter', color: '#FF7A00', abbr: 'In',
    link: { android: 'br.com.intermedium', web: 'https://inter.co' },
    products: [
      { name: 'Inter Black', earn: 'cashback', cashbackPct: 1, fee: 0, lounge: true },
      { name: 'Inter Gold', earn: 'cashback', cashbackPct: 0.25, fee: 0 },
    ] },
  { id: 'xp', name: 'XP', color: '#111111', abbr: 'XP',
    link: { web: 'https://www.xpi.com.br' },
    products: [
      { name: 'XP Visa Infinite', earn: 'cashback', cashbackPct: 1, fee: 0, lounge: true, insurance: true },
    ] },
  { id: 'btg', name: 'BTG Pactual', color: '#0B2A55', abbr: 'BT',
    link: { web: 'https://www.btgpactual.com' },
    products: [
      { name: 'BTG Black', earn: 'points', ptsPerUSD: 2.5, program: 'livelo', fee: 0, lounge: true, insurance: true },
    ] },
  { id: 'mercadopago', name: 'Mercado Pago', color: '#00B1EA', abbr: 'MP',
    link: { android: 'com.mercadopago.wallet', web: 'https://www.mercadopago.com.br' },
    products: [
      { name: 'Cartão Mercado Pago', earn: 'cashback', cashbackPct: 0, fee: 0, merchantBoost: { mercadolivre: 5 } },
    ] },
  { id: 'picpay', name: 'PicPay', color: '#11C76F', abbr: 'PP',
    link: { android: 'com.picpay', web: 'https://www.picpay.com' },
    products: [
      { name: 'PicPay Card', earn: 'cashback', cashbackPct: 0, fee: 0 },
    ] },
];

/* Assinaturas e benefícios. price = mensal sugerido (R$). */
const SERVICES = [
  { id: 'netflix', name: 'Netflix', cat: 'video', price: 44.90, color: '#E50914', abbr: 'N',
    link: { android: 'com.netflix.mediaclient', ios: 'nflx://', web: 'https://www.netflix.com/browse' } },
  { id: 'disney', name: 'Disney+', cat: 'video', price: 46.90, annual: 449.90, color: '#0E2A8A', abbr: 'D+',
    link: { android: 'com.disney.disneyplus', ios: 'disneyplus://', web: 'https://www.disneyplus.com' } },
  { id: 'max', name: 'HBO Max', cat: 'video', price: 39.90, annual: 359.90, color: '#002BE7', abbr: 'Mx',
    link: { android: 'com.wbd.stream', web: 'https://www.max.com' } },
  { id: 'primevideo', name: 'Prime Video', cat: 'video', price: 19.90, color: '#1A98FF', abbr: 'PV',
    link: { android: 'com.amazon.avod.thirdpartyclient', web: 'https://www.primevideo.com' } },
  { id: 'globoplay', name: 'Globoplay', cat: 'video', price: 29.90, annual: 269.90, color: '#FB0234', abbr: 'Gp',
    link: { android: 'com.globo.globotv', web: 'https://globoplay.globo.com' } },
  { id: 'appletv', name: 'Apple TV+', cat: 'video', price: 29.90, color: '#111111', abbr: 'tv',
    link: { ios: 'videos://', web: 'https://tv.apple.com' } },
  { id: 'paramount', name: 'Paramount+', cat: 'video', price: 24.90, color: '#0064FF', abbr: 'P+',
    link: { android: 'com.cbs.ca', web: 'https://www.paramountplus.com' } },
  { id: 'youtube', name: 'YouTube Premium', cat: 'video', also: ['music'], price: 26.90, color: '#FF0000', abbr: 'YT',
    link: { android: 'com.google.android.youtube', ios: 'youtube://', web: 'https://www.youtube.com/premium' } },
  { id: 'spotify', name: 'Spotify', cat: 'music', price: 23.90, color: '#1DB954', abbr: 'Sp',
    link: { android: 'com.spotify.music', ios: 'spotify://', web: 'https://open.spotify.com' } },
  { id: 'deezer', name: 'Deezer', cat: 'music', price: 26.90, color: '#A238FF', abbr: 'Dz',
    link: { android: 'deezer.android.app', ios: 'deezer://', web: 'https://www.deezer.com' } },
  { id: 'amazonmusic', name: 'Amazon Music', cat: 'music', price: 21.90, color: '#25D1DA', abbr: 'AM',
    link: { android: 'com.amazon.mp3', web: 'https://music.amazon.com.br' } },
  { id: 'amazonprime', name: 'Amazon Prime', cat: 'shipping', price: 19.90, annual: 166.80, color: '#00A8E1', abbr: 'a',
    includes: ['primevideo', 'amazonmusic'],
    link: { android: 'com.amazon.mShop.android.shopping', web: 'https://www.amazon.com.br/prime' } },
  { id: 'melimais', name: 'Meli+', cat: 'shipping', price: 24.90, color: '#FFE600', fg: '#2D3277', abbr: 'M+',
    plans: [
      { name: 'Essencial', price: 9.90, includes: [] },
      { name: 'Total', price: 24.90, includes: ['disney', 'deezer'] },
      { name: 'Mega', price: 49.90, includes: ['disney', 'max', 'deezer'] },
    ],
    note: 'Os benefícios do Meli+ mudam com frequência. Confira o que seu plano inclui no app do Mercado Livre e ajuste aqui.',
    link: { android: 'com.mercadolibre', ios: 'meli://', web: 'https://www.mercadolivre.com.br/assinaturas' } },
  { id: 'ifood', name: 'Clube iFood', cat: 'delivery', price: 12.90, color: '#EA1D2C', abbr: 'iF',
    link: { android: 'br.com.brainweb.ifood', ios: 'ifood://', web: 'https://www.ifood.com.br' } },
  { id: 'rappi', name: 'Rappi Pro', cat: 'delivery', price: 24.90, color: '#FF441F', abbr: 'Ra',
    link: { android: 'com.grability.rappi', web: 'https://www.rappi.com.br' } },
  { id: 'uberone', name: 'Uber One', cat: 'mobility', also: ['delivery'], price: 25.90, color: '#000000', abbr: 'U1',
    link: { android: 'com.ubercab', ios: 'uber://', web: 'https://www.uber.com/br/pt-br/u/uber-one/' } },
  { id: 'wellhub', name: 'Wellhub (Gympass)', cat: 'gym', price: 129.90, color: '#E5285D', abbr: 'Wh',
    link: { android: 'com.gympass', web: 'https://wellhub.com/pt-br/' } },
  { id: 'totalpass', name: 'TotalPass', cat: 'gym', price: 99.90, color: '#00C389', abbr: 'TP',
    link: { android: 'br.com.totalpass', web: 'https://www.totalpass.com/br/' } },
  { id: 'academia', name: 'Academia (mensalidade)', cat: 'gym', price: 119.90, color: '#475569', abbr: 'Ac',
    link: {} },
  { id: 'icloud', name: 'iCloud+', cat: 'cloud', price: 14.90, color: '#3693F3', abbr: 'iC',
    link: { web: 'https://www.icloud.com' } },
  { id: 'googleone', name: 'Google One', cat: 'cloud', price: 9.99, annual: 99.99, color: '#4285F4', abbr: 'G1',
    link: { android: 'com.google.android.apps.subscriptions.red', web: 'https://one.google.com' } },
  { id: 'chatgpt', name: 'ChatGPT Plus', cat: 'ai', price: 110.00, color: '#10A37F', abbr: 'GP',
    link: { web: 'https://chatgpt.com' } },
  { id: 'claude', name: 'Claude Pro', cat: 'ai', price: 110.00, color: '#D97757', abbr: 'Cl',
    link: { web: 'https://claude.ai' } },
  { id: 'clubesmiles', name: 'Clube Smiles', cat: 'club', price: 42.00, pointsPerMonth: 1000, program: 'smiles', color: '#FF5A00', abbr: 'CS',
    link: { android: 'br.com.smiles.android', web: 'https://www.smiles.com.br/clube-smiles' } },
  { id: 'clubelivelo', name: 'Clube Livelo', cat: 'club', price: 39.90, pointsPerMonth: 1000, program: 'livelo', color: '#E5007E', abbr: 'CL',
    link: { android: 'br.com.pontomais.livelo', web: 'https://www.livelo.com.br/clube' } },
  { id: 'clubelatam', name: 'Clube LATAM Pass', cat: 'club', price: 45.00, pointsPerMonth: 1000, program: 'latam', color: '#1B0088', abbr: 'CL',
    link: { android: 'com.latam.android', web: 'https://latampass.latam.com' } },
  { id: 'clubeazul', name: 'Clube Azul', cat: 'club', price: 38.00, pointsPerMonth: 1000, program: 'azul', color: '#0A3E8C', abbr: 'CA',
    link: { android: 'br.com.voeazul', web: 'https://www.voeazul.com.br' } },
  { id: 'custom', name: 'Outra assinatura', cat: 'other', price: 0, color: '#64748B', abbr: '+',
    link: {} },
];

/* Lojas para o "Qual cartão usar?". */
const MERCHANTS = [
  { id: 'mercadolivre', name: 'Mercado Livre', perk: 'melimais', perkText: 'Meli+: frete grátis a partir de valor mínimo menor. Confira antes de pagar o frete.' },
  { id: 'amazon', name: 'Amazon', perk: 'amazonprime', perkText: 'Prime: frete grátis e entregas rápidas em itens elegíveis.' },
  { id: 'magalu', name: 'Magalu' },
  { id: 'ifood', name: 'iFood', perk: 'ifood', perkText: 'Clube iFood: cupons de entrega grátis. Veja se ainda tem cupom no mês.' },
  { id: 'uber', name: 'Uber / Uber Eats', perk: 'uberone', perkText: 'Uber One: cashback em Uber Cash nas corridas e taxa zero no Eats.' },
  { id: 'mercado', name: 'Supermercado' },
  { id: 'posto', name: 'Combustível' },
  { id: 'aereo', name: 'Passagem aérea / hotel', travel: true },
  { id: 'internacional', name: 'Compra internacional', intl: true },
  { id: 'outro', name: 'Outra loja' },
];

const findProgram = (id) => PROGRAMS.find((p) => p.id === id);
const findBank = (id) => BANKS.find((b) => b.id === id);
const findService = (id) => SERVICES.find((s) => s.id === id);
const findMerchant = (id) => MERCHANTS.find((m) => m.id === id);
