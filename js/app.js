/* Milheiro — interface. */

/* ---------- utilidades ---------- */
const $ = (sel, root = document) => root.querySelector(sel);
const h = (s) => String(s ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const uid = () => Math.random().toString(36).slice(2, 10);
const pad2 = (n) => String(n).padStart(2, '0');
const isoLocal = (d) => `${d.getFullYear()}-${pad2(d.getMonth() + 1)}-${pad2(d.getDate())}`;
const isoIn = (days) => { const d = new Date(); d.setDate(d.getDate() + days); return isoLocal(d); };
const numBR = (v) => {
  if (typeof v === 'number') return v;
  const s = String(v ?? '').trim().replace(/[^\d.,-]/g, '');
  if (!s) return 0;
  return s.includes(',') ? Number(s.replace(/\./g, '').replace(',', '.')) || 0 : Number(s) || 0;
};
const reduceMotion = () => window.matchMedia?.('(prefers-reduced-motion: reduce)').matches;

const UI_FMT = {
  brl: (v) => (Number(v) || 0).toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' }),
  brl0: (v) => (Number(v) || 0).toLocaleString('pt-BR', { style: 'currency', currency: 'BRL', maximumFractionDigits: 0 }),
  int: (v) => Math.round(Number(v) || 0).toLocaleString('pt-BR'),
  pct: (v, d = 2) => `${((Number(v) || 0) * 100).toLocaleString('pt-BR', { maximumFractionDigits: d })}%`,
  day: (d) => d.toLocaleDateString('pt-BR', { day: '2-digit' }),
  mon: (d) => d.toLocaleDateString('pt-BR', { month: 'short' }).replace('.', ''),
  date: (d) => d.toLocaleDateString('pt-BR', { day: '2-digit', month: 'short', year: 'numeric' }),
  rel: (d) => {
    const n = Engine.daysUntil(d);
    if (n < 0) return `há ${-n} dia${n === -1 ? '' : 's'}`;
    if (n === 0) return 'hoje';
    if (n === 1) return 'amanhã';
    return `em ${n} dias`;
  },
};
const F = UI_FMT;

const ICON = {
  home: '<path d="M3 10.5 12 3l9 7.5V20a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z"/>',
  subs: '<rect x="3" y="4" width="18" height="16" rx="3"/><path d="M3 9h18M7 14h5"/>',
  miles: '<path d="M12 3l2.6 5.6 6.1.7-4.5 4.2 1.2 6L12 16.5 6.6 19.5l1.2-6L3.3 9.3l6.1-.7z"/>',
  plane: '<path d="M21 15.5v-1.8l-7.5-4.6V4a1.5 1.5 0 0 0-3 0v5.1L3 13.7v1.8l7.5-2.2v4.6L8.6 19.3V21l3.4-1 3.4 1v-1.7l-1.9-1.4v-4.6z"/>',
  bag: '<path d="M5 8h14l-1 12H6z"/><path d="M9 8V7a3 3 0 0 1 6 0v1"/>',
  gear: '<path d="M4 7h9M17 7h3M4 12h3M11 12h9M4 17h11M19 17h1"/><circle cx="15" cy="7" r="2"/><circle cx="9" cy="12" r="2"/><circle cx="17" cy="17" r="2"/>',
  plus: '<path d="M12 5v14M5 12h14"/>',
  open: '<path d="M14 4h6v6M20 4l-8.5 8.5M18 14v5a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V7a1 1 0 0 1 1-1h5"/>',
  cal: '<rect x="3" y="5" width="18" height="16" rx="2"/><path d="M3 10h18M8 3v4M16 3v4"/>',
  share: '<path d="M12 15V3M7 8l5-5 5 5M5 13v6a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1v-6"/>',
  bell: '<path d="M6 16v-5a6 6 0 1 1 12 0v5l2 2H4z"/><path d="M10 21a2 2 0 0 0 4 0"/>',
  x: '<path d="M6 6l12 12M18 6 6 18"/>',
  clip: '<rect x="8" y="3" width="8" height="4" rx="1"/><path d="M8 5H6a1 1 0 0 0-1 1v14a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1V6a1 1 0 0 0-1-1h-2"/>',
  card: '<rect x="2.5" y="5" width="19" height="14" rx="2.5"/><path d="M2.5 10h19M6 15h4"/>',
  chev: '<path d="M9 6l6 6-6 6"/>',
  down: '<path d="M12 4v11M7 10l5 5 5-5M5 20h14"/>',
  swap: '<path d="M7 4 3 8l4 4M3 8h14M17 20l4-4-4-4M21 16H7"/>',
  search: '<circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/>',
  install: '<rect x="6" y="2.5" width="12" height="19" rx="2.5"/><path d="M12 7v7M9 11l3 3 3-3M10 18.5h4"/>',
  trash: '<path d="M4 7h16M9 7V4h6v3M6 7l1 13h10l1-13"/>',
  pause: '<path d="M9 5v14M15 5v14"/>',
  check: '<path d="M5 12.5 10 17l9-10"/>',
  spark: '<path d="M12 3v4M12 17v4M3 12h4M17 12h4M6 6l2.5 2.5M15.5 15.5 18 18M6 18l2.5-2.5M15.5 8.5 18 6"/>',
};
const icon = (n, cls = '') => `<svg class="i ${cls}" viewBox="0 0 24 24" aria-hidden="true">${ICON[n] || ''}</svg>`;

const logo = (item = {}, size = '') =>
  `<span class="logo ${size}" style="--lc:${h(item.color || '#64748B')};--lf:${h(item.fg || '#fff')}" aria-hidden="true">${h(item.abbr || (item.name || '?').slice(0, 2))}</span>`;

const USAGE = { daily: 'Todo dia', weekly: 'Toda semana', monthly: 'Às vezes', rarely: 'Quase nunca' };

/* ---------- estado ---------- */
const STORE_KEY = 'milheiro.v1';

function defaultState() {
  return {
    version: 1, onboarded: false, example: false, name: '',
    cards: [], wallet: [], subs: [], trips: [], dismissed: [],
    settings: { usd: 5.4, iof: 3.5, cdiMonthly: 1.0, ref: {}, lastNotified: '' },
  };
}

function exampleState() {
  const s = defaultState();
  s.onboarded = true; s.example = true; s.name = 'Arthur';
  const nu = { id: uid(), bankId: 'nubank', name: 'Nubank Ultravioleta', earn: 'cashback', cashbackPct: 1, fee: 0, monthlySpend: 3500, lounge: true, insurance: true };
  const it = { id: uid(), bankId: 'itau', name: 'Itaú Platinum', earn: 'points', ptsPerUSD: 1.5, program: 'itau', fee: 500, monthlySpend: 1200 };
  const mp = { id: uid(), bankId: 'mercadopago', name: 'Cartão Mercado Pago', earn: 'cashback', cashbackPct: 0, fee: 0, monthlySpend: 400, merchantBoost: { mercadolivre: 5 } };
  s.cards = [nu, it, mp];
  s.wallet = [
    { id: uid(), programId: 'livelo', balance: 48000, expiry: isoIn(74) },
    { id: uid(), programId: 'itau', balance: 15200, expiry: isoIn(400) },
    { id: uid(), programId: 'smiles', balance: 22500, expiry: isoIn(800) },
    { id: uid(), programId: 'latam', balance: 8300, expiry: isoIn(500) },
  ];
  const d = new Date().getDate();
  const day = (k) => ((d + k - 1) % 28) + 1;
  const sub = (serviceId, extra) => {
    const svc = findService(serviceId);
    return { id: uid(), serviceId, name: svc.name, price: svc.price, cycle: 'monthly', payer: 'me', usage: 'weekly', cardId: it.id, renewDay: day(5), ...extra };
  };
  s.subs = [
    sub('totalpass', { payer: 'company', usage: 'weekly', cardId: '' , renewDay: 1 }),
    sub('wellhub', { usage: 'weekly', cardId: nu.id, renewDay: day(3) }),
    sub('melimais', { plan: 'Total', price: 24.90, includes: ['disney', 'deezer'], usage: 'weekly', cardId: mp.id, renewDay: day(9) }),
    sub('disney', { usage: 'weekly', renewDay: day(2) }),
    sub('netflix', { usage: 'daily', renewDay: day(12) }),
    sub('max', { usage: 'rarely', renewDay: day(6) }),
    sub('globoplay', { usage: 'monthly', renewDay: day(17) }),
    sub('spotify', { usage: 'daily', cardId: nu.id, renewDay: day(20) }),
    sub('amazonprime', { usage: 'weekly', cycle: 'annual', price: 166.80, renewDay: 14, renewMonth: ((new Date().getMonth() + 3) % 12) + 1 }),
    sub('ifood', { usage: 'weekly', renewDay: day(8) }),
    sub('uberone', { usage: 'monthly', renewDay: day(22) }),
    sub('clubesmiles', { usage: 'monthly', pointsPerMonth: 1000, program: 'smiles', renewDay: day(25) }),
  ];
  s.trips = [{
    id: uid(), origin: 'GRU', dest: 'LIS', destName: 'Lisboa', date: isoIn(96), back: isoIn(110), pax: 1, bonusPct: 100,
    offers: [
      { id: uid(), type: 'cash', cash: 4890 },
      { id: uid(), type: 'miles', program: 'smiles', miles: 95000, taxes: 380 },
      { id: uid(), type: 'miles', program: 'latam', miles: 120000, taxes: 290 },
      { id: uid(), type: 'miles', program: 'tap', miles: 70000, taxes: 520 },
    ],
  }];
  return s;
}

let state = (() => {
  try { const raw = localStorage.getItem(STORE_KEY); if (raw) return { ...defaultState(), ...JSON.parse(raw) }; } catch (e) {}
  return defaultState();
})();
state.settings = { ...defaultState().settings, ...(state.settings || {}) };

function save() { try { localStorage.setItem(STORE_KEY, JSON.stringify(state)); } catch (e) {} }
function commit(fn) { fn(state); save(); render(); }

/* ---------- toast e sheet ---------- */
const UI = {
  toast(msg, ms = 3200) {
    const t = $('#toast');
    t.textContent = msg; t.classList.add('show');
    clearTimeout(UI._t); UI._t = setTimeout(() => t.classList.remove('show'), ms);
  },
};

const scopes = {};

const Sheet = {
  ctx: null,
  open(ctx) {
    this.ctx = ctx; scopes.sheet = ctx;
    const el = $('#sheet');
    $('#sheet-title').textContent = ctx.title;
    this.refresh();
    el.hidden = false;
    requestAnimationFrame(() => requestAnimationFrame(() => el.classList.add('open')));
    document.documentElement.classList.add('locked');
    Phone.haptic(6);
  },
  refresh() {
    if (!this.ctx) return;
    const body = $('#sheet-body');
    body.innerHTML = this.ctx.body(this.ctx.draft);
    this.ctx.onChange?.(this.ctx.draft);
  },
  close() {
    const el = $('#sheet');
    el.classList.remove('open');
    document.documentElement.classList.remove('locked');
    setTimeout(() => { if (!el.classList.contains('open')) { el.hidden = true; $('#sheet-body').innerHTML = ''; } }, 260);
    this.ctx = null; delete scopes.sheet;
  },
};

function setPath(obj, path, val) {
  const keys = path.split('.');
  let o = obj;
  for (let i = 0; i < keys.length - 1; i++) o = o[keys[i]] ??= {};
  o[keys[keys.length - 1]] = val;
}
function getPath(obj, path) { return path.split('.').reduce((o, k) => (o == null ? o : o[k]), obj); }

/* ---------- navegação ---------- */
const VIEWS = [
  { id: 'inicio', label: 'Início', icon: 'home' },
  { id: 'assinaturas', label: 'Assinaturas', icon: 'subs' },
  { id: 'milhas', label: 'Milhas', icon: 'miles' },
  { id: 'viagens', label: 'Viagens', icon: 'plane' },
  { id: 'comprar', label: 'Comprar', icon: 'bag' },
];
let current = 'inicio';
let subFilter = 'all';
let animated = false;

function route() {
  const hash = (location.hash || '').replace('#', '');
  if (hash === 'resgate') { current = 'milhas'; render(); setTimeout(() => $('#tool-redeem')?.scrollIntoView({ behavior: reduceMotion() ? 'auto' : 'smooth' }), 60); return; }
  if (hash === 'nova') { current = 'assinaturas'; render(); openAddSub(); return; }
  current = VIEWS.some((v) => v.id === hash) ? hash : 'inicio';
  render();
}
function go(id) {
  if (location.hash !== '#' + id) location.hash = id; else route();
  window.scrollTo({ top: 0 });
}

/* ---------- render ---------- */
function render() {
  const app = $('#app');
  if (!state.onboarded) { app.innerHTML = renderOnboarding(); return; }
  const v = VIEWS.find((x) => x.id === current);
  app.innerHTML = `
    <header class="top">
      <div class="brand">${brandMark()}<span>Milheiro</span></div>
      <div class="top-actions">
        <button class="chip-btn install-btn" data-act="install">${icon('install')}<span>Instalar</span></button>
        <button class="icon-btn" data-act="settings" aria-label="Ajustes">${icon('gear')}</button>
      </div>
    </header>
    ${state.example ? `<div class="example-bar"><span>Você está vendo <b>dados de exemplo</b>.</span><button data-act="start-real">Usar meus dados</button></div>` : ''}
    <main id="view" class="view view-${current}">${VIEW_RENDER[current]()}</main>
    <nav class="tabbar" aria-label="Seções">
      ${VIEWS.map((x) => `<a href="#${x.id}" class="tab ${x.id === current ? 'on' : ''}" ${x.id === current ? 'aria-current="page"' : ''}>${icon(x.icon)}<span>${x.label}</span></a>`).join('')}
    </nav>`;
  document.title = current === 'inicio' ? 'Milheiro' : `${v.label} · Milheiro`;
  afterRender();
}

function afterRender() {
  for (const k of Object.keys(scopes)) if (k !== 'sheet' && $(`[data-scope="${k}"]`)) scopes[k].onChange?.(scopes[k].draft);
  if (current === 'inicio') animateHome();
}

const brandMark = () => `<svg class="mark" viewBox="0 0 32 32" aria-hidden="true"><rect width="32" height="32" rx="9" style="fill:var(--ink)"/><path d="M7 21.5 16 8l9 13.5" fill="none" style="stroke:var(--gold)" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/><circle cx="16" cy="21.5" r="2.4" style="fill:var(--paper-on-ink)"/></svg>`;

/* ---------- Início ---------- */
function greeting() {
  const hr = new Date().getHours();
  return hr < 5 ? 'Boa madrugada' : hr < 12 ? 'Bom dia' : hr < 18 ? 'Boa tarde' : 'Boa noite';
}

function renderHome() {
  const a = Engine.analyze(state);
  const w = Engine.walletSummary(state);
  const ins = a.insights.filter((i) => !state.dismissed.includes(i.id));
  const ev = Engine.upcoming(state, 45).slice(0, 6);
  const tone = a.score >= 80 ? 'good' : a.score >= 55 ? 'warn' : 'bad';
  const C = 2 * Math.PI * 52;
  const setupTodo = !state.example && (state.wallet.some((x) => !Number(x.balance)) || state.cards.some((c) => !Number(c.monthlySpend)));

  return `
  <section class="hero">
    <p class="eyebrow">${greeting()}${state.name ? ', ' + h(state.name) : ''}</p>
    <div class="hero-grid">
      <div class="ring ring-${tone}" role="img" aria-label="Índice de aproveitamento ${a.score} de 100">
        <svg viewBox="0 0 120 120"><circle class="ring-track" cx="60" cy="60" r="52"/><circle class="ring-val" cx="60" cy="60" r="52" stroke-dasharray="${C.toFixed(1)}" stroke-dashoffset="${(C * (1 - a.score / 100)).toFixed(1)}" data-offset="${(C * (1 - a.score / 100)).toFixed(1)}" data-c="${C.toFixed(1)}"/></svg>
        <div class="ring-label"><b data-count="${a.score}" data-fmt="int">${a.score}</b><span>aproveitamento</span></div>
      </div>
      <div class="hero-stats">
        <div class="stat"><span>Você paga em assinaturas</span><b class="num" data-count="${a.monthlyTotal}" data-fmt="brl">${F.brl(a.monthlyTotal)}</b><small>por mês</small></div>
        <div class="stat stat-save"><span>Dá para economizar</span><b class="num" data-count="${a.savings}" data-fmt="brl">${F.brl(a.savings)}</b><small>${F.brl0(a.savings * 12)} por ano</small></div>
      </div>
    </div>
    <button class="wallet-strip" data-act="goto" data-to="milhas">
      ${icon('miles')}<span><b class="num">${F.int(w.points)}</b> pontos e milhas</span><span class="muted">≈ ${F.brl0(w.value)}</span>${icon('chev')}
    </button>
    ${a.companyValue ? `<p class="company-note">${icon('spark')}<span>Sua empresa paga <b>${F.brl(a.companyValue)}/mês</b> em benefícios. Use antes de pagar algo parecido.</span></p>` : ''}
  </section>

  <div class="quick" role="list">
    <button role="listitem" data-act="goto" data-to="comprar">${icon('card')}<span>Qual cartão usar?</span></button>
    <button role="listitem" data-act="goto-redeem">${icon('miles')}<span>Vale o resgate?</span></button>
    <button role="listitem" data-act="add-sub">${icon('plus')}<span>Nova assinatura</span></button>
    <button role="listitem" data-act="paste-buy">${icon('clip')}<span>Colar preço</span></button>
    <button role="listitem" data-act="ics-all">${icon('cal')}<span>Lembretes</span></button>
  </div>

  ${setupTodo ? `<div class="setup">${icon('spark')}<div><b>Complete seus dados</b><p>Informe saldos de pontos e quanto gasta por mês em cada cartão. As sugestões ficam bem mais precisas.</p></div><button class="btn btn-small" data-act="goto" data-to="milhas">Completar</button></div>` : ''}

  <section class="block">
    <div class="block-head"><h2>O que fazer agora</h2><span class="muted">${ins.filter((i) => i.saving > 0 || i.risk).length} ações</span></div>
    ${ins.length ? `<ol class="insights">${ins.map(insightCard).join('')}</ol>` : `<div class="empty">${icon('check')}<p>Tudo otimizado por aqui. Cadastre mais assinaturas e cartões para encontrar novas economias.</p></div>`}
    ${state.dismissed.length ? `<button class="link" data-act="undismiss">Mostrar ${state.dismissed.length} dispensada${state.dismissed.length > 1 ? 's' : ''}</button>` : ''}
  </section>

  <section class="block">
    <div class="block-head"><h2>Próximos 45 dias</h2><button class="link" data-act="ics-all">${icon('cal')} Pôr no calendário</button></div>
    ${ev.length ? `<ul class="timeline">${ev.map((e) => `
      <li class="tl tl-${e.kind}">
        <div class="tl-date"><b>${F.day(e.date)}</b><span>${F.mon(e.date)}</span></div>
        <div class="tl-main"><b>${h(e.title)}</b><span>${F.rel(e.date)}</span></div>
        ${e.amount ? `<span class="num">${F.brl(e.amount)}</span>` : ''}
      </li>`).join('')}</ul>` : `<div class="empty"><p>Nenhuma renovação ou vencimento à vista. Informe o dia de renovação nas assinaturas para acompanhar aqui.</p></div>`}
  </section>`;
}

function insightCard(i) {
  const pill = i.saving > 0 ? `<span class="pill pill-save">−${F.brl(i.saving)}/mês</span>` : i.risk ? `<span class="pill pill-risk">${F.brl0(i.risk)} em risco</span>` : '';
  return `<li class="insight sev-${i.severity}">
    <div class="insight-top"><span class="kind">${h(i.kind)}</span>${pill}<button class="icon-btn tiny" data-act="dismiss" data-id="${h(i.id)}" aria-label="Dispensar">${icon('x')}</button></div>
    <h3>${h(i.title)}</h3>
    <p>${h(i.body)}</p>
    ${i.actions?.length ? `<div class="insight-actions">${i.actions.map((a) => `<button class="btn btn-ghost btn-small" data-act="${h(a.act)}" data-id="${h(a.id || '')}" data-to="${h(a.to || '')}">${h(a.label)}</button>`).join('')}</div>` : ''}
  </li>`;
}

function animateHome() {
  if (animated || reduceMotion()) return;
  animated = true;
  const ring = $('.ring-val');
  if (ring) {
    ring.style.strokeDashoffset = ring.dataset.c;
    requestAnimationFrame(() => requestAnimationFrame(() => { ring.style.transition = 'stroke-dashoffset 1.1s cubic-bezier(.2,.8,.2,1)'; ring.style.strokeDashoffset = ring.dataset.offset; }));
  }
  document.querySelectorAll('[data-count]').forEach((el) => {
    const target = Number(el.dataset.count); const fmt = F[el.dataset.fmt] || F.int;
    const t0 = performance.now(); const dur = 900;
    const step = (t) => {
      const p = Math.min(1, (t - t0) / dur); const e = 1 - Math.pow(1 - p, 3);
      el.textContent = fmt(target * e);
      if (p < 1) requestAnimationFrame(step);
    };
    requestAnimationFrame(step);
  });
}

/* ---------- Assinaturas ---------- */
const CAT_ORDER = ['video', 'music', 'gym', 'shipping', 'delivery', 'mobility', 'cloud', 'ai', 'club', 'other'];

function renderSubs() {
  const total = state.subs.reduce((t, s) => t + Engine.monthly(s), 0);
  const byCat = {};
  for (const s of state.subs) { const c = s.cat || Engine.service(s).cat; byCat[c] = (byCat[c] || 0) + Engine.monthly(s); }
  const segs = CAT_ORDER.filter((c) => byCat[c] > 0);
  const filters = { all: 'Todas', me: 'Pago eu', company: 'Empresa paga', paused: 'Pausadas' };
  const list = state.subs.filter((s) => subFilter === 'all' ? !s.paused : subFilter === 'paused' ? s.paused : s.payer === subFilter && !s.paused);

  return `
  <section class="page-head">
    <h1>Assinaturas</h1>
    <div class="big-number"><b class="num">${F.brl(total)}</b><span>por mês · ${F.brl0(total * 12)} por ano</span></div>
    ${segs.length ? `<div class="catbar" role="img" aria-label="Gasto por categoria">${segs.map((c) => `<span class="cat-${c}" style="flex:${byCat[c]}"></span>`).join('')}</div>
    <ul class="legend">${segs.map((c) => `<li><i class="cat-${c}"></i>${CATEGORIES[c].label}<b class="num">${F.brl0(byCat[c])}</b></li>`).join('')}</ul>` : ''}
  </section>
  <div class="seg" role="tablist">${Object.entries(filters).map(([k, v]) => `<button role="tab" aria-selected="${subFilter === k}" class="${subFilter === k ? 'on' : ''}" data-act="sub-filter" data-id="${k}">${v}</button>`).join('')}</div>
  ${list.length ? CAT_ORDER.map((c) => {
    const items = list.filter((s) => (s.cat || Engine.service(s).cat) === c);
    if (!items.length) return '';
    return `<section class="group"><h2 class="group-title">${CATEGORIES[c].label}</h2><ul class="rows">${items.map(subRow).join('')}</ul></section>`;
  }).join('') : `<div class="empty">${icon('subs')}<p>${subFilter === 'paused' ? 'Nenhuma assinatura pausada.' : 'Nenhuma assinatura aqui ainda.'}</p><button class="btn" data-act="add-sub">Adicionar assinatura</button></div>`}
  <button class="fab" data-act="add-sub" aria-label="Adicionar assinatura">${icon('plus')}</button>`;
}

function subRow(s) {
  const svc = Engine.service(s);
  const renew = Engine.nextRenewal(s);
  const card = state.cards.find((c) => c.id === s.cardId);
  const meta = [renew ? `renova ${F.rel(renew)}` : null, card ? card.name : null].filter(Boolean).join(' · ');
  const price = s.payer === 'company'
    ? `<span class="pill pill-company">empresa</span>`
    : `<b class="num">${F.brl(s.price)}</b><small>${s.cycle === 'annual' ? '/ano' : '/mês'}</small>`;
  return `<li class="row ${s.paused ? 'paused' : ''}" data-act="edit-sub" data-id="${s.id}" tabindex="0">
    ${logo(svc)}
    <div class="row-main"><div class="row-title">${h(s.name)}${s.plan ? ` <span class="muted">${h(s.plan)}</span>` : ''}</div><div class="row-meta">${h(meta || USAGE[s.usage] || '')}</div></div>
    <div class="row-end">${price}<span class="usage u-${s.usage}">${USAGE[s.usage] || ''}</span></div>
    <button class="icon-btn" data-act="launch-sub" data-id="${s.id}" aria-label="Abrir app ${h(s.name)}">${icon('open')}</button>
  </li>`;
}

function openAddSub() {
  Sheet.open({
    title: 'Nova assinatura', draft: { q: '' },
    body: (d) => `
      <label class="search">${icon('search')}<input id="svc-q" data-bind="q" placeholder="Buscar Netflix, Wellhub, Meli+…" autocomplete="off"></label>
      <div class="svc-grid" id="live-out"></div>`,
    onChange: (d) => {
      const q = (d.q || '').toLowerCase();
      const items = SERVICES.filter((s) => !q || s.name.toLowerCase().includes(q) || CATEGORIES[s.cat].label.toLowerCase().includes(q));
      $('#live-out').innerHTML = items.map((s) => `<button class="svc" data-act="pick-svc" data-id="${s.id}">${logo(s)}<span>${h(s.name)}</span><small>${CATEGORIES[s.cat].label}</small></button>`).join('');
    },
  });
}

function openSubEditor(sub, isNew) {
  const svc = Engine.service(sub);
  const draft = JSON.parse(JSON.stringify(sub));
  if (!Array.isArray(draft.includes)) draft.includes = [...Engine.includesOf(sub)];
  const includable = SERVICES.filter((s) => ['video', 'music'].includes(s.cat) && s.id !== sub.serviceId);
  Sheet.open({
    title: isNew ? `Adicionar ${svc.name}` : sub.name, draft,
    body: (d) => `
      <div class="sheet-hero">${logo(svc, 'lg')}<div><b>${h(d.name)}</b><span>${CATEGORIES[svc.cat].label}</span></div>
        ${svc.link?.web || svc.link?.android || svc.link?.ios ? `<button class="btn btn-ghost btn-small" data-act="launch-svc" data-id="${svc.id}">${icon('open')} Abrir app</button>` : ''}</div>
      <div class="form">
        ${svc.id === 'custom' ? field('Nome', `<input id="f-name" data-bind="name" value="${h(d.name)}">`) : ''}
        ${svc.plans ? field('Plano', `<select id="f-plan" data-bind="plan" data-refresh>${svc.plans.map((p) => `<option ${d.plan === p.name ? 'selected' : ''}>${h(p.name)}</option>`).join('')}</select>`) : ''}
        <div class="two">
          ${field('Valor (R$)', `<input id="f-price" data-bind="price" data-num inputmode="decimal" value="${h(String(d.price ?? '').replace('.', ','))}">`)}
          ${field('Cobrança', segmented('cycle', d.cycle, { monthly: 'Mensal', annual: 'Anual' }))}
        </div>
        ${field('Quem paga', segmented('payer', d.payer, { me: 'Eu', company: 'Empresa' }))}
        ${field('Quanto você usa', segmented('usage', d.usage, USAGE))}
        <div class="two">
          ${field('Dia da renovação', `<input id="f-day" data-bind="renewDay" data-num inputmode="numeric" placeholder="ex.: 10" value="${h(d.renewDay || '')}">`)}
          ${d.cycle === 'annual' ? field('Mês', `<select id="f-month" data-bind="renewMonth">${Array.from({ length: 12 }, (_, i) => `<option value="${i + 1}" ${Number(d.renewMonth) === i + 1 ? 'selected' : ''}>${new Date(2026, i, 1).toLocaleDateString('pt-BR', { month: 'long' })}</option>`).join('')}</select>`) : field('Cartão', cardSelect(d.cardId))}
        </div>
        ${d.cycle === 'annual' ? field('Cartão', cardSelect(d.cardId)) : ''}
        ${svc.cat === 'club' ? `<div class="two">${field('Pontos por mês', `<input id="f-pts" data-bind="pointsPerMonth" data-num inputmode="numeric" value="${h(d.pointsPerMonth ?? svc.pointsPerMonth ?? '')}">`)}${field('Programa', programSelect('program', d.program || svc.program))}</div>` : ''}
        ${['shipping', 'mobility', 'other'].includes(svc.cat) || svc.includes || svc.plans ? field('Este plano inclui', `<div class="chips">${includable.map((x) => `<button type="button" class="chip ${d.includes.includes(x.id) ? 'on' : ''}" data-act="toggle-inc" data-id="${x.id}">${h(x.name)}</button>`).join('')}</div>`, 'O app avisa se você paga à parte por algo que já vem incluído.') : ''}
        ${svc.note ? `<p class="note">${h(svc.note)}</p>` : ''}
      </div>
      <div class="sheet-actions">
        ${!isNew ? `<button class="btn btn-ghost" data-act="sub-pause">${icon('pause')} ${d.paused ? 'Reativar' : 'Pausar'}</button><button class="btn btn-ghost danger" data-act="sub-delete">${icon('trash')} Excluir</button>` : ''}
        <button class="btn" data-act="sub-save">${isNew ? 'Adicionar' : 'Salvar'}</button>
      </div>`,
    onBind: (key, d) => {
      if (key === 'plan') { const p = svc.plans.find((x) => x.name === d.plan); if (p) { d.price = p.price; d.includes = [...p.includes]; } }
    },
    isNew,
  });
}

const field = (label, control, hint) => {
  const tag = /^<(input|select)/.test(control) ? 'label' : 'div';
  return `<${tag} class="field"><span class="field-label">${label}</span>${control}${hint ? `<small class="hint">${hint}</small>` : ''}</${tag}>`;
};
const segmented = (key, val, opts) => `<div class="seg seg-sm" role="radiogroup">${Object.entries(opts).map(([k, v]) => `<button type="button" role="radio" aria-checked="${val === k}" class="${val === k ? 'on' : ''}" data-act="set" data-bind="${key}" data-val="${k}">${v}</button>`).join('')}</div>`;
const cardSelect = (val) => `<select id="f-card" data-bind="cardId"><option value="">Não sei / outro</option>${state.cards.map((c) => `<option value="${c.id}" ${val === c.id ? 'selected' : ''}>${h(c.name)}</option>`).join('')}</select>`;
const programSelect = (key, val, filter = () => true) => `<select id="f-${key}" data-bind="${key}" data-refresh>${PROGRAMS.filter(filter).map((p) => `<option value="${p.id}" ${val === p.id ? 'selected' : ''}>${h(p.name)}</option>`).join('')}</select>`;

/* ---------- Milhas ---------- */
scopes.redeem = { draft: { programId: 'smiles', cash: 2400, miles: 60000, taxes: 180 }, onChange: (d) => {
  const out = $('#redeem-out'); if (!out) return;
  const r = Engine.redemption(state, d);
  if (!r) { out.innerHTML = `<p class="muted">Informe o preço em dinheiro e as milhas pedidas.</p>`; return; }
  const pos = Math.max(0, Math.min(100, (r.ratio / 1.6) * 100));
  out.innerHTML = `
    <div class="verdict v-${r.tone}"><b>${r.verdict}</b><span>Cada milheiro vale <b class="num">${F.brl(r.cpm)}</b> nesse resgate</span></div>
    <div class="meter"><span style="left:${pos}%"></span><i style="left:${(1 / 1.6) * 100}%"></i></div>
    <div class="meter-legend"><span>pior</span><span>referência ${F.brl(r.ref)}</span><span>melhor</span></div>`;
} };

scopes.transfer = { draft: { from: 'livelo', to: 'smiles', points: 10000, bonus: 100 }, onBind: (k, d) => {
  const partners = findProgram(d.from)?.partners || [];
  if (k === 'from' && partners.length && !partners.includes(d.to)) d.to = partners[0];
}, onChange: (d) => {
  const out = $('#transfer-out'); if (!out) return;
  const r = Engine.transfer(state, d.from, d.to, Number(d.points) || 0, d.bonus);
  const ok = findProgram(d.from)?.partners.includes(d.to);
  out.innerHTML = `
    <div class="xfer"><div><span>${h(findProgram(d.from)?.name)}</span><b class="num">${F.int(d.points)}</b><small>≈ ${F.brl0(r.before)}</small></div>
    ${icon('swap')}
    <div><span>${h(findProgram(d.to)?.name)}</span><b class="num">${F.int(r.out)}</b><small>≈ ${F.brl0(r.after)}</small></div></div>
    ${ok ? '' : `<p class="note warn">Confira se ${h(findProgram(d.from)?.name)} transfere para ${h(findProgram(d.to)?.name)}. Parcerias mudam.</p>`}
    <p class="muted small">${r.after > r.before ? `Ganho estimado de ${F.brl0(r.after - r.before)} em valor de resgate.` : 'Sem bônus, a transferência costuma não valer a pena. Espere uma campanha.'}</p>`;
} };

function renderMiles() {
  const w = Engine.walletSummary(state);
  const bankProgs = PROGRAMS.filter((p) => p.kind === 'bank');
  const t = scopes.transfer.draft;
  const partners = (findProgram(t.from)?.partners || []).map(findProgram);
  return `
  <section class="page-head">
    <h1>Milhas e pontos</h1>
    <div class="big-number"><b class="num">${F.int(w.points)}</b><span>pontos · valem cerca de ${F.brl0(w.value)}</span></div>
  </section>

  <section class="block">
    <div class="block-head"><h2>Carteira</h2><button class="link" data-act="add-wallet">${icon('plus')} Programa</button></div>
    ${state.wallet.length ? `<div class="passes">${state.wallet.map(passCard).join('')}</div>` : `<div class="empty"><p>Adicione Livelo, Smiles, LATAM Pass e os outros programas em que você tem pontos.</p><button class="btn" data-act="add-wallet">Adicionar programa</button></div>`}
  </section>

  <section class="block tool" id="tool-redeem" data-scope="redeem">
    <div class="block-head"><h2>Vale a pena esse resgate?</h2></div>
    <p class="muted small">Compare o preço em dinheiro com as milhas pedidas pela mesma passagem.</p>
    <div class="form">
      ${field('Programa', programSelect('programId', scopes.redeem.draft.programId))}
      <div class="three">
        ${field('Preço em R$', `<input id="r-cash" data-bind="cash" data-num inputmode="decimal" value="${h(scopes.redeem.draft.cash)}">`)}
        ${field('Milhas', `<input id="r-miles" data-bind="miles" data-num inputmode="numeric" value="${h(scopes.redeem.draft.miles)}">`)}
        ${field('Taxas R$', `<input id="r-tax" data-bind="taxes" data-num inputmode="decimal" value="${h(scopes.redeem.draft.taxes)}">`)}
      </div>
    </div>
    <div id="redeem-out" class="out" aria-live="polite"></div>
  </section>

  <section class="block tool" data-scope="transfer">
    <div class="block-head"><h2>Simular transferência</h2></div>
    <div class="form">
      <div class="two">
        ${field('De', programSelect('from', t.from, (p) => p.kind === 'bank'))}
        ${field('Para', `<select id="f-to" data-bind="to">${(partners.length ? partners : PROGRAMS.filter((p) => p.kind === 'airline')).map((p) => `<option value="${p.id}" ${t.to === p.id ? 'selected' : ''}>${h(p.name)}</option>`).join('')}</select>`)}
      </div>
      ${field('Pontos', `<input id="t-pts" data-bind="points" data-num inputmode="numeric" value="${h(t.points)}">`)}
      ${field('Bônus da campanha', segmented('bonus', String(t.bonus), { 0: '0%', 50: '50%', 80: '80%', 100: '100%' }))}
    </div>
    <div id="transfer-out" class="out" aria-live="polite"></div>
  </section>

  <section class="block">
    <div class="block-head"><h2>Meus cartões</h2><button class="link" data-act="add-card">${icon('plus')} Cartão</button></div>
    ${state.cards.length ? `<ul class="rows">${state.cards.map(cardRow).join('')}</ul>` : `<div class="empty"><p>Cadastre seus cartões para saber qual usar em cada compra.</p><button class="btn" data-act="add-card">Adicionar cartão</button></div>`}
  </section>`;
}

function passCard(w) {
  const p = findProgram(w.programId) || { name: w.programId, color: '#64748B' };
  const d = Engine.parseDate(w.expiry);
  const days = d ? Engine.daysUntil(d) : null;
  const exp = d ? `<span class="pill ${days <= 90 ? 'pill-risk' : days <= 180 ? 'pill-warn' : 'pill-muted'}">vence ${F.rel(d)}</span>` : '';
  const val = (Number(w.balance) / 1000) * Engine.ref(state, w.programId);
  return `<button class="pass" style="--lc:${p.color};--lf:${p.fg || '#fff'}" data-act="edit-wallet" data-id="${w.id}">
    <span class="pass-top"><span class="pass-name">${h(p.name)}</span><span class="pass-kind">${p.kind === 'bank' ? 'banco' : 'cia. aérea'}</span></span>
    <b class="pass-bal num">${F.int(w.balance)}</b>
    <span class="pass-bottom"><span>≈ ${F.brl0(val)}</span>${exp}</span>
  </button>`;
}

function cardRow(c) {
  const b = findBank(c.bankId) || {};
  const rate = Engine.cardRate(state, c);
  const earn = c.earn === 'points' ? `${String(c.ptsPerUSD).replace('.', ',')} pts/US$ · ${findProgram(c.program)?.name || ''}` : c.earn === 'cashback' ? `${String(c.cashbackPct).replace('.', ',')}% de cashback` : 'Não acumula';
  return `<li class="row" data-act="edit-card" data-id="${c.id}" tabindex="0">
    ${logo(b)}
    <div class="row-main"><div class="row-title">${h(c.name)}</div><div class="row-meta">${h(earn)}${Number(c.fee) ? ` · anuidade ${F.brl0(c.fee)}` : ' · sem anuidade'}</div></div>
    <div class="row-end"><b class="num">${F.pct(rate)}</b><small>de retorno</small></div>
    <button class="icon-btn" data-act="launch-bank" data-id="${h(c.bankId)}" aria-label="Abrir app do banco">${icon('open')}</button>
  </li>`;
}

function openWalletEditor(w, isNew) {
  Sheet.open({
    title: isNew ? 'Adicionar programa' : findProgram(w.programId)?.name || 'Programa', draft: { ...w },
    body: (d) => `
      <div class="form">
        ${field('Programa', programSelect('programId', d.programId))}
        <div class="two">
          ${field('Saldo', `<input id="w-bal" data-bind="balance" data-num inputmode="numeric" value="${h(d.balance || '')}" placeholder="0">`)}
          ${field('Vencimento mais próximo', `<input id="w-exp" type="date" data-bind="expiry" value="${h(d.expiry || '')}">`)}
        </div>
        <p class="note">Veja o saldo e as datas de vencimento no app do programa.</p>
      </div>
      <div class="sheet-actions">
        <button class="btn btn-ghost" data-act="launch-program" data-id="${h(d.programId)}">${icon('open')} Abrir ${h(findProgram(d.programId)?.name)}</button>
        ${!isNew ? `<button class="btn btn-ghost danger" data-act="wallet-delete">${icon('trash')}</button>` : ''}
        <button class="btn" data-act="wallet-save">Salvar</button>
      </div>`,
    isNew,
  });
}

function openCardEditor(c, isNew) {
  Sheet.open({
    title: isNew ? 'Adicionar cartão' : c.name, draft: { ...c },
    body: (d) => {
      const bank = findBank(d.bankId);
      return `
      <div class="form">
        ${field('Banco', `<div class="chips">${BANKS.map((b) => `<button type="button" class="chip ${d.bankId === b.id ? 'on' : ''}" data-act="pick-bank" data-id="${b.id}">${h(b.name)}</button>`).join('')}</div>`)}
        ${bank ? field('Produto', `<div class="chips">${bank.products.map((p, i) => `<button type="button" class="chip ${d.name === p.name ? 'on' : ''}" data-act="pick-product" data-id="${i}">${h(p.name)}</button>`).join('')}</div>`, 'Valores de acúmulo são estimativas. Ajuste conforme o seu contrato.') : ''}
        ${field('Nome no app', `<input id="c-name" data-bind="name" value="${h(d.name || '')}">`)}
        ${field('Como acumula', segmented('earn', d.earn, { points: 'Pontos', cashback: 'Cashback', none: 'Não acumula' }))}
        ${d.earn === 'points' ? `<div class="two">${field('Pontos por US$', `<input id="c-pts" data-bind="ptsPerUSD" data-num inputmode="decimal" value="${h(String(d.ptsPerUSD ?? '').replace('.', ','))}">`)}${field('Programa', programSelect('program', d.program, (p) => p.kind === 'bank' || p.id === 'smiles' || p.id === 'latam' || p.id === 'azul'))}</div>` : ''}
        ${d.earn === 'cashback' ? field('Cashback (%)', `<input id="c-cb" data-bind="cashbackPct" data-num inputmode="decimal" value="${h(String(d.cashbackPct ?? '').replace('.', ','))}">`) : ''}
        <div class="two">
          ${field('Anuidade por ano (R$)', `<input id="c-fee" data-bind="fee" data-num inputmode="decimal" value="${h(d.fee ?? 0)}">`)}
          ${field('Gasto médio por mês', `<input id="c-spend" data-bind="monthlySpend" data-num inputmode="decimal" value="${h(d.monthlySpend || '')}" placeholder="R$">`)}
        </div>
        <div class="checks">
          <label><input type="checkbox" id="c-lounge" data-bind="lounge" ${d.lounge ? 'checked' : ''}> Dá acesso a salas VIP</label>
          <label><input type="checkbox" id="c-ins" data-bind="insurance" ${d.insurance ? 'checked' : ''}> Tem seguro viagem</label>
        </div>
      </div>
      <div class="sheet-actions">
        ${!isNew ? `<button class="btn btn-ghost danger" data-act="card-delete">${icon('trash')} Excluir</button>` : ''}
        <button class="btn" data-act="card-save">Salvar</button>
      </div>`;
    },
    isNew,
  });
}

/* ---------- Viagens ---------- */
function renderTrips() {
  const lounge = state.cards.filter((c) => c.lounge);
  const insur = state.cards.filter((c) => c.insurance);
  return `
  <section class="page-head">
    <h1>Viagens</h1>
    <p class="lede">Compare dinheiro e milhas para cada viagem e descubra a melhor forma de emitir.</p>
  </section>
  ${state.trips.length ? `<div class="tickets">${state.trips.map(ticket).join('')}</div>` : `<div class="empty">${icon('plane')}<p>Planeje uma viagem e compare o preço em dinheiro com as opções em milhas.</p></div>`}
  <button class="btn btn-wide" data-act="add-trip">${icon('plus')} Planejar viagem</button>
  <section class="block">
    <div class="block-head"><h2>Benefícios dos seus cartões</h2></div>
    <ul class="perks">
      <li>${icon('check')}<div><b>Salas VIP</b><span>${lounge.length ? lounge.map((c) => h(c.name)).join(', ') : 'Nenhum cartão cadastrado dá acesso.'}</span></div></li>
      <li>${icon('check')}<div><b>Seguro viagem</b><span>${insur.length ? `Emita a passagem com ${h(insur[0].name)} para ativar o seguro do cartão.` : 'Nenhum cartão com seguro cadastrado. Considere contratar à parte.'}</span></div></li>
      <li>${icon('check')}<div><b>Compras no exterior</b><span>IOF de ${String(state.settings.iof).replace('.', ',')}% no cartão. Conta global com câmbio comercial costuma sair mais barata.</span></div></li>
    </ul>
  </section>`;
}

function ticket(t) {
  const r = Engine.tripOptions(state, t);
  const win = r.winner;
  const d = Engine.parseDate(t.date);
  const code = (s) => h((s || '—').slice(0, 3).toUpperCase());
  return `<button class="ticket" data-act="edit-trip" data-id="${t.id}">
    <span class="ticket-main">
      <span class="t-codes"><b>${code(t.origin)}</b>${icon('plane', 'rot')}<b>${code(t.dest)}</b></span>
      <span class="t-sub">${h(t.destName || t.dest)} · ${d ? F.date(d) : 'sem data'} · ${t.pax || 1} pessoa${(t.pax || 1) > 1 ? 's' : ''}</span>
    </span>
    <span class="ticket-stub">
      <span class="muted small">Melhor opção</span>
      <b>${win ? h(win.label) : '—'}</b>
      <span class="num small">${win ? F.brl0(win.cost) : ''}</span>
    </span>
  </button>`;
}

function openTripEditor(t, isNew) {
  const draft = JSON.parse(JSON.stringify(t));
  Sheet.open({
    title: isNew ? 'Nova viagem' : `${t.origin || ''} → ${t.dest}`, draft,
    body: (d) => `
      <div class="form">
        <div class="two">
          ${field('Origem', `<input id="tr-o" data-bind="origin" value="${h(d.origin || '')}" placeholder="GRU">`)}
          ${field('Destino', `<input id="tr-d" data-bind="dest" value="${h(d.dest || '')}" placeholder="LIS">`)}
        </div>
        <div class="three">
          ${field('Ida', `<input id="tr-date" type="date" data-bind="date" value="${h(d.date || '')}">`)}
          ${field('Volta', `<input id="tr-back" type="date" data-bind="back" value="${h(d.back || '')}">`)}
          ${field('Pessoas', `<input id="tr-pax" data-bind="pax" data-num inputmode="numeric" value="${h(d.pax || 1)}">`)}
        </div>
        <div class="search-links">
          <span class="field-label">Pesquisar preços</span>
          <div class="chips">
            <a class="chip" target="_blank" rel="noopener" href="${googleFlights(d)}">Google Voos ${icon('open')}</a>
            <button type="button" class="chip" data-act="launch-program" data-id="smiles">Smiles ${icon('open')}</button>
            <button type="button" class="chip" data-act="launch-program" data-id="latam">LATAM ${icon('open')}</button>
            <button type="button" class="chip" data-act="launch-program" data-id="azul">Azul ${icon('open')}</button>
          </div>
        </div>
        <span class="field-label">Opções encontradas</span>
        <ul class="offers">${(d.offers || []).map((o, i) => offerRow(o, i)).join('')}</ul>
        <div class="chips">
          <button type="button" class="chip" data-act="add-offer" data-id="cash">${icon('plus')} Em dinheiro</button>
          <button type="button" class="chip" data-act="add-offer" data-id="miles">${icon('plus')} Em milhas</button>
        </div>
        ${field('Bônus de transferência disponível', segmented('bonusPct', String(d.bonusPct ?? 0), { 0: '0%', 50: '50%', 80: '80%', 100: '100%' }), 'Usado para calcular quanto transferir dos pontos do banco.')}
      </div>
      <div id="live-out" class="out" aria-live="polite"></div>
      <div class="sheet-actions">
        ${!isNew ? `<button class="btn btn-ghost danger" data-act="trip-delete" aria-label="Excluir">${icon('trash')}</button>` : ''}
        <button class="btn btn-ghost" data-act="trip-share">${icon('share')} Enviar</button>
        <button class="btn btn-ghost" data-act="trip-ics">${icon('cal')}</button>
        <button class="btn" data-act="trip-save">Salvar</button>
      </div>`,
    onChange: (d) => {
      const out = $('#live-out'); if (!out) return;
      const r = Engine.tripOptions(state, d);
      if (!r.options.length) { out.innerHTML = `<p class="muted">Adicione as opções que encontrou para comparar.</p>`; return; }
      const sorted = [...r.options].sort((a, b) => a.cost - b.cost);
      out.innerHTML = `<ol class="ranking">${sorted.map((o) => {
        const win = o === r.winner;
        const extra = o.offer.type === 'miles'
          ? `${F.int(o.offer.miles)} milhas + ${F.brl(o.offer.taxes)}${o.redemption ? ` · milheiro a ${F.brl(o.redemption.cpm)}` : ''}`
          : o.detail;
        let plan = '';
        if (o.offer.type === 'miles') {
          if (o.have >= o.offer.miles) plan = `Você já tem ${F.int(o.have)} milhas.`;
          else if (o.plan?.from) plan = `Faltam ${F.int(o.plan.missing)}. Transfira ${F.int(o.plan.need)} pontos ${o.plan.from.name}${d.bonusPct ? ` com ${d.bonusPct}% de bônus` : ''}.`;
          else plan = `Faltam ${F.int(o.plan?.missing || o.offer.miles)} milhas e não há pontos suficientes para transferir.`;
        }
        return `<li class="${win ? 'win' : ''} ${o.feasible ? '' : 'nope'}">
          <div class="rk-top"><b>${h(o.label)}</b>${win ? '<span class="pill pill-save">melhor</span>' : ''}${o.redemption ? `<span class="pill v-${o.redemption.tone}">${h(o.redemption.verdict)}</span>` : ''}<span class="num rk-cost">${F.brl0(o.cost)}</span></div>
          <span class="small muted">${h(extra || '')}</span>
          ${plan ? `<span class="small">${h(plan)}</span>` : ''}
        </li>`;
      }).join('')}</ol>
      <p class="muted small">Custo das milhas calculado pelo valor de referência de cada programa, mais taxas. Ajuste esses valores em Ajustes.</p>`;
    },
    isNew,
  });
}

function offerRow(o, i) {
  if (o.type === 'cash') return `<li class="offer"><span class="offer-tag">R$</span>
    <input id="of-cash-${i}" data-bind="offers.${i}.cash" data-num inputmode="decimal" value="${h(o.cash || '')}" placeholder="Preço total" aria-label="Preço em dinheiro">
    <button type="button" class="icon-btn tiny" data-act="rm-offer" data-id="${i}" aria-label="Remover">${icon('x')}</button></li>`;
  return `<li class="offer offer-miles">
    <select id="of-p-${i}" data-bind="offers.${i}.program" aria-label="Programa">${PROGRAMS.filter((p) => p.kind === 'airline').map((p) => `<option value="${p.id}" ${o.program === p.id ? 'selected' : ''}>${h(p.name)}</option>`).join('')}</select>
    <input id="of-m-${i}" data-bind="offers.${i}.miles" data-num inputmode="numeric" value="${h(o.miles || '')}" placeholder="Milhas" aria-label="Milhas">
    <input id="of-t-${i}" data-bind="offers.${i}.taxes" data-num inputmode="decimal" value="${h(o.taxes || '')}" placeholder="Taxas" aria-label="Taxas em reais">
    <button type="button" class="icon-btn tiny" data-act="rm-offer" data-id="${i}" aria-label="Remover">${icon('x')}</button></li>`;
}

const googleFlights = (t) => `https://www.google.com/travel/flights?hl=pt-BR&curr=BRL&q=${encodeURIComponent(`voos de ${t.origin || ''} para ${t.dest || ''}${t.date ? ' em ' + t.date : ''}${t.back ? ' volta ' + t.back : ''}`)}`;

/* ---------- Comprar ---------- */
scopes.buy = { draft: { amount: 899.9, merchantId: 'mercadolivre', installments: 1, pixPct: 0, portalPts: 0, portalProgram: 'livelo' }, onChange: (d) => {
  const out = $('#buy-out'); if (!out) return;
  if (!state.cards.length) { out.innerHTML = `<div class="empty"><p>Cadastre seus cartões para ver qual rende mais.</p><button class="btn" data-act="add-card">Adicionar cartão</button></div>`; return; }
  const r = Engine.purchase(state, d);
  const [win, ...rest] = r.ranking;
  const amount = Number(d.amount) || 0;
  const pixWins = r.pix > 0 && r.pix > win.net;
  out.innerHTML = `
    <div class="winner">
      <span class="eyebrow">${pixWins ? 'Melhor forma de pagar' : 'Use este cartão'}</span>
      <div class="winner-main">${pixWins ? `<b>Pix com desconto</b>` : `${logo(findBank(win.card.bankId))}<b>${h(win.card.name)}</b>`}</div>
      <p>${pixWins
        ? `O desconto de ${F.brl(r.pix)} vale mais que os ${F.brl(win.net)} que o melhor cartão devolveria.`
        : win.net >= 0
          ? `Volta cerca de <b>${F.brl(win.net)}</b>${win.pts ? ` (${F.int(win.pts)} pontos)` : ''} nesta compra de ${F.brl(amount)}.`
          : `Rende ${F.brl(win.back)}${win.pts ? ` (${F.int(win.pts)} pontos)` : ''}, mas o IOF custa ${F.brl(win.iofCost)}. Saldo: <b>${F.brl(win.net)}</b>.`}</p>
      ${!pixWins ? `<button class="btn btn-ghost btn-small" data-act="launch-bank" data-id="${h(win.card.bankId)}">${icon('open')} Abrir app ${h(findBank(win.card.bankId)?.name || '')}</button>` : ''}
    </div>
    ${r.perk ? `<p class="note good">${icon('spark')}<span>${h(r.perk)}</span></p>` : ''}
    ${r.iof ? `<p class="note warn">Inclui IOF de ${F.pct(r.iof, 1)} (${F.brl(amount * r.iof)}). Uma conta global pode sair mais barata.</p>` : ''}
    ${r.portal ? `<p class="note good">Comprando pelo shopping de pontos, você ganha mais ${F.brl(r.portal)} em pontos, somados ao cartão.</p>` : ''}
    ${r.yieldGain > 0.5 ? `<p class="note">Parcelando em ${d.installments}× sem juros e deixando o dinheiro rendendo perto do CDI, você ganha cerca de ${F.brl(r.yieldGain)}.</p>` : ''}
    ${rest.length ? `<ol class="ranking compact">${rest.map((x) => `<li><div class="rk-top">${logo(findBank(x.card.bankId), 'sm')}<b>${h(x.card.name)}</b><span class="num rk-cost">${F.brl(x.net)}</span></div></li>`).join('')}</ol>` : ''}`;
} };

function renderBuy() {
  const d = scopes.buy.draft;
  return `
  <section class="page-head">
    <h1>Qual cartão usar?</h1>
    <p class="lede">Digite o valor da compra, ou compartilhe o link de um produto direto para o Milheiro.</p>
  </section>
  <section class="block tool" data-scope="buy">
    <div class="amount-in">
      <span>R$</span>
      <input id="b-amount" data-bind="amount" data-num inputmode="decimal" value="${h(String(d.amount).replace('.', ','))}" aria-label="Valor da compra">
      <button class="icon-btn" data-act="paste-buy" aria-label="Colar preço copiado">${icon('clip')}</button>
    </div>
    <div class="form">
      ${field('Onde', `<div class="chips">${MERCHANTS.map((m) => `<button type="button" class="chip ${d.merchantId === m.id ? 'on' : ''}" data-act="set" data-bind="merchantId" data-val="${m.id}">${h(m.name)}</button>`).join('')}</div>`)}
      <div class="three">
        ${field('Parcelas', `<select id="b-inst" data-bind="installments" data-num>${Array.from({ length: 12 }, (_, i) => `<option value="${i + 1}" ${Number(d.installments) === i + 1 ? 'selected' : ''}>${i + 1}×</option>`).join('')}</select>`)}
        ${field('Desconto Pix %', `<input id="b-pix" data-bind="pixPct" data-num inputmode="decimal" value="${h(d.pixPct || '')}" placeholder="0">`)}
        ${field('Shopping pts/R$', `<input id="b-portal" data-bind="portalPts" data-num inputmode="decimal" value="${h(d.portalPts || '')}" placeholder="0">`)}
      </div>
    </div>
    <div id="buy-out" class="out" aria-live="polite"></div>
  </section>`;
}

/* ---------- Ajustes ---------- */
function openSettings() {
  const draft = JSON.parse(JSON.stringify({ name: state.name, ...state.settings }));
  Sheet.open({
    title: 'Ajustes', draft,
    body: (d) => `
      <div class="form">
        ${field('Seu nome', `<input id="s-name" data-bind="name" value="${h(d.name || '')}">`)}
        <div class="three">
          ${field('Dólar (R$)', `<input id="s-usd" data-bind="usd" data-num inputmode="decimal" value="${h(String(d.usd).replace('.', ','))}">`)}
          ${field('IOF cartão %', `<input id="s-iof" data-bind="iof" data-num inputmode="decimal" value="${h(String(d.iof).replace('.', ','))}">`)}
          ${field('CDI ao mês %', `<input id="s-cdi" data-bind="cdiMonthly" data-num inputmode="decimal" value="${h(String(d.cdiMonthly).replace('.', ','))}">`)}
        </div>
        <span class="field-label">Quanto vale o milheiro (R$ por 1.000 pontos)</span>
        <div class="refs">${PROGRAMS.map((p) => `<label>${logo(p, 'sm')}<span>${h(p.name)}</span><input id="ref-${p.id}" data-bind="ref.${p.id}" data-num inputmode="decimal" placeholder="${p.ref}" value="${h(d.ref?.[p.id] ?? '')}"></label>`).join('')}</div>
        <p class="note">Esses valores definem quando um resgate é bom e quanto seus pontos valem. Os padrões são médias de mercado.</p>
      </div>
      <div class="settings-list">
        <button data-act="notify-on">${icon('bell')}<span><b>Ativar notificações</b><small>Avisos de renovações e pontos vencendo ao abrir o app</small></span></button>
        <button data-act="ics-all">${icon('cal')}<span><b>Exportar para o calendário</b><small>Renovações, vencimentos e viagens com alarmes</small></span></button>
        <button data-act="install">${icon('install')}<span><b>Instalar na tela inicial</b><small>Abre como app, funciona offline e recebe links compartilhados</small></span></button>
        <button data-act="backup">${icon('down')}<span><b>Fazer backup</b><small>Salva seus dados em um arquivo .json</small></span></button>
        <label class="as-btn">${icon('share')}<span><b>Restaurar backup</b><small>Carrega um arquivo .json salvo antes</small></span><input type="file" id="restore" accept="application/json,.json" hidden></label>
        <button data-act="reset" class="danger">${icon('trash')}<span><b>Apagar tudo e recomeçar</b><small>Remove os dados deste aparelho</small></span></button>
      </div>
      <div class="sheet-actions"><button class="btn" data-act="settings-save">Salvar</button></div>
      <p class="muted small center">Seus dados ficam só neste aparelho. Nada é enviado para servidores.</p>`,
  });
}

/* ---------- Onboarding ---------- */
const ob = { step: 0, name: '', banks: new Set(), programs: new Set(), services: {} };

function renderOnboarding() {
  const steps = ['Boas-vindas', 'Bancos', 'Pontos', 'Assinaturas'];
  const dots = `<div class="ob-dots">${steps.map((_, i) => `<i class="${i <= ob.step ? 'on' : ''}"></i>`).join('')}</div>`;
  if (ob.step === 0) return `
    <div class="ob ob-welcome">
      <div class="ob-art" aria-hidden="true">${welcomeArt()}</div>
      <div class="ob-copy">
        ${brandMark()}
        <h1>Cada real, cada ponto, aproveitado.</h1>
        <p>O Milheiro junta seus bancos, cartões, benefícios da empresa e assinaturas em um só lugar. Ele encontra o que está sobrando, avisa antes dos pontos vencerem e diz qual cartão usar em cada compra.</p>
        <div class="ob-actions">
          <button class="btn btn-wide" data-act="ob-next">Começar com meus dados</button>
          <button class="btn btn-ghost btn-wide" data-act="ob-example">Ver com dados de exemplo</button>
        </div>
        <p class="muted small">Leva 1 minuto. Seus dados ficam só no seu celular.</p>
      </div>
    </div>`;

  const chips = (items, sel, kind) => items.map((x) => {
    const st = kind === 'services' ? ob.services[x.id] : sel.has(x.id) ? 'me' : null;
    const lab = kind === 'services' && st ? `<em>${st === 'company' ? 'empresa' : 'eu pago'}</em>` : '';
    return `<button class="ob-chip ${st ? 'on' : ''} ${st === 'company' ? 'company' : ''}" data-act="ob-toggle" data-kind="${kind}" data-id="${x.id}" aria-pressed="${!!st}">${logo(x, 'sm')}<span>${h(x.name)}</span>${lab}</button>`;
  }).join('');

  let body = '';
  if (ob.step === 1) body = `
    <h2>Quais bancos e cartões você usa?</h2>
    <p>Toque para selecionar. Você ajusta os detalhes depois.</p>
    ${field('Como quer ser chamado?', `<input id="ob-name" data-ob="name" value="${h(ob.name)}" placeholder="Seu nome">`)}
    <div class="ob-grid">${chips(BANKS, ob.banks, 'banks')}</div>`;
  if (ob.step === 2) body = `
    <h2>Em quais programas você tem pontos?</h2>
    <p>Programas de banco e de companhias aéreas.</p>
    <div class="ob-grid">${chips(PROGRAMS, ob.programs, 'programs')}</div>`;
  if (ob.step === 3) body = `
    <h2>Assinaturas e benefícios</h2>
    <p>Toque uma vez se <b>você paga</b>. Toque de novo se é <b>benefício da empresa</b>, como TotalPass ou Wellhub.</p>
    <div class="ob-grid">${chips(SERVICES.filter((s) => s.id !== 'custom'), null, 'services')}</div>`;

  return `<div class="ob">
    <div class="ob-head"><button class="icon-btn" data-act="ob-back" aria-label="Voltar">${icon('chev', 'flip')}</button>${dots}<span></span></div>
    <div class="ob-body">${body}</div>
    <div class="ob-foot"><button class="btn btn-wide" data-act="${ob.step === 3 ? 'ob-finish' : 'ob-next'}">${ob.step === 3 ? 'Ver minhas economias' : 'Continuar'}</button></div>
  </div>`;
}

function welcomeArt() {
  // Cartões e um cartão de embarque empilhados. Cores vêm das classes em app.css.
  return `<svg viewBox="0 0 320 220" class="art">
    <g transform="rotate(-10 160 110)"><rect x="40" y="40" width="200" height="124" rx="16" fill="#820AD1"/><rect x="58" y="62" width="34" height="24" rx="5" fill="#ffffff" opacity=".35"/><text x="58" y="146" fill="#ffffff" class="a-mono" font-size="13">•••• 4021</text></g>
    <g transform="rotate(4 180 120)"><rect x="70" y="56" width="200" height="124" rx="16" class="a-ink"/><path d="M96 150 128 102l32 48" fill="none" class="a-gold-stroke" stroke-width="6" stroke-linecap="round" stroke-linejoin="round"/><text x="200" y="92" class="a-on-ink a-mono" font-size="14" text-anchor="middle">48.000</text><text x="200" y="108" class="a-on-ink a-mono" opacity=".6" font-size="9" text-anchor="middle">PONTOS LIVELO</text></g>
    <g transform="rotate(-3 200 160)"><rect x="120" y="120" width="180" height="78" rx="12" class="a-card"/><line x1="240" y1="126" x2="240" y2="192" class="a-line" stroke-dasharray="4 4"/><text x="136" y="160" class="a-fg a-display" font-weight="700" font-size="22">GRU</text><text x="200" y="160" class="a-accent" font-size="16">→</text><text x="136" y="182" class="a-muted a-mono" font-size="9">MILHAS · 1 PAX</text><text x="252" y="166" class="a-fg a-display" font-weight="700" font-size="18">LIS</text></g>
  </svg>`;
}

function finishOnboarding() {
  const s = defaultState();
  s.onboarded = true; s.name = ob.name.trim();
  for (const id of ob.banks) {
    const b = findBank(id); const p = b.products[0];
    s.cards.push({ id: uid(), bankId: id, name: p.name, earn: p.earn, cashbackPct: p.cashbackPct || 0, ptsPerUSD: p.ptsPerUSD || 0, program: p.program || '', fee: p.fee || 0, monthlySpend: 0, lounge: !!p.lounge, insurance: !!p.insurance, merchantBoost: p.merchantBoost });
  }
  for (const id of ob.programs) s.wallet.push({ id: uid(), programId: id, balance: 0, expiry: '' });
  for (const [id, payer] of Object.entries(ob.services)) {
    const svc = findService(id);
    const plan = svc.plans?.[1];
    s.subs.push({ id: uid(), serviceId: id, name: svc.name, price: plan?.price ?? svc.price, plan: plan?.name, includes: plan ? [...plan.includes] : undefined, cycle: 'monthly', payer, usage: 'weekly', cardId: s.cards[0]?.id || '', renewDay: '', pointsPerMonth: svc.pointsPerMonth, program: svc.program });
  }
  state = s; save(); current = 'inicio'; animated = false;
  location.hash = 'inicio'; render();
  UI.toast('Pronto! Ajuste preços e saldos para afinar as sugestões.');
}

/* ---------- calendário ---------- */
function calendarEvents() {
  const ev = [];
  for (const s of state.subs) {
    if (s.paused) continue;
    const d = Engine.nextRenewal(s); if (!d) continue;
    ev.push({ uid: 'sub-' + s.id, date: d, title: `Renova ${s.name}${s.payer === 'company' ? '' : ' · ' + F.brl(s.price)}`, rrule: s.cycle === 'annual' ? 'FREQ=YEARLY' : 'FREQ=MONTHLY', alarmDays: 2, description: 'Decida antes da cobrança: manter, pausar ou cancelar. Veja as sugestões no Milheiro.' });
  }
  for (const w of state.wallet) {
    const d = Engine.parseDate(w.expiry); if (!d) continue;
    ev.push({ uid: 'exp-' + w.id, date: d, title: `Vencem pontos ${findProgram(w.programId)?.name}`, alarmDays: 30, description: `Saldo: ${F.int(w.balance)}. Transfira com bônus ou emita antes do vencimento.` });
  }
  for (const t of state.trips) {
    const d = Engine.parseDate(t.date); if (!d) continue;
    ev.push({ uid: 'trip-' + t.id, date: d, title: `Viagem ${t.origin || ''} → ${t.dest}`, alarmDays: 7, description: 'Confira check-in, seguro do cartão e sala VIP.' });
  }
  return ev;
}

async function exportCalendar(events = calendarEvents(), name = 'milheiro-lembretes.ics') {
  if (!events.length) { UI.toast('Informe dias de renovação ou vencimentos para criar lembretes.'); return; }
  const ok = await Phone.addToCalendar(events, name);
  if (ok) UI.toast(`${events.length} lembrete${events.length > 1 ? 's' : ''} prontos. Abra o arquivo para adicionar ao calendário.`, 4500);
}

/* ---------- notificações ao abrir ---------- */
async function checkNotifications() {
  try {
    if (!('Notification' in window) || Notification.permission !== 'granted') return;
    const todayKey = isoLocal(new Date());
    if (state.settings.lastNotified === todayKey) return;
    const soon = Engine.upcoming(state, 3).filter((e) => e.kind === 'renew');
    const exp = state.wallet.filter((w) => { const d = Engine.parseDate(w.expiry); return d && Engine.daysUntil(d) <= 30 && Engine.daysUntil(d) >= 0; });
    if (soon.length) await Phone.notify('Renovações chegando', soon.map((e) => `${e.ref.name} ${F.rel(e.date)}`).join(' · '), 'renew');
    if (exp.length) await Phone.notify('Pontos vencendo', exp.map((w) => `${findProgram(w.programId)?.name}: ${F.int(w.balance)}`).join(' · '), 'expire');
    state.settings.lastNotified = todayKey; save();
  } catch (e) {}
}

/* ---------- ações ---------- */
const VIEW_RENDER = { inicio: renderHome, assinaturas: renderSubs, milhas: renderMiles, viagens: renderTrips, comprar: renderBuy };

const findSub = (id) => state.subs.find((s) => s.id === id);

const ACTIONS = {
  goto: (el) => go(el.dataset.to),
  'goto-redeem': () => { location.hash = 'resgate'; },
  install: () => Phone.install(),
  settings: () => openSettings(),
  'start-real': () => { state = defaultState(); save(); ob.step = 1; render(); },
  dismiss: (el) => commit((s) => s.dismissed.push(el.dataset.id)),
  undismiss: () => commit((s) => { s.dismissed = []; }),
  'sub-filter': (el) => { subFilter = el.dataset.id; render(); },
  'add-sub': () => { if (current !== 'assinaturas') go('assinaturas'); openAddSub(); },
  'pick-svc': (el) => {
    const svc = findService(el.dataset.id);
    const plan = svc.plans?.[1];
    openSubEditor({ id: uid(), serviceId: svc.id, name: svc.id === 'custom' ? '' : svc.name, price: plan?.price ?? svc.price, plan: plan?.name, includes: plan ? [...plan.includes] : svc.includes ? [...svc.includes] : [], cycle: 'monthly', payer: 'me', usage: 'weekly', cardId: Engine.bestCard(state)?.card.id || '', renewDay: '', pointsPerMonth: svc.pointsPerMonth, program: svc.program }, true);
  },
  'edit-sub': (el) => { const s = findSub(el.dataset.id); if (s) openSubEditor(s, false); },
  'open-sub': (el) => { const s = findSub(el.dataset.id); if (s) openSubEditor(s, false); },
  'launch-sub': (el) => { const s = findSub(el.dataset.id); if (s) Phone.openApp(Engine.service(s).link, s.name); },
  'launch-svc': (el) => { const s = findService(el.dataset.id); Phone.openApp(s?.link, s?.name); },
  'launch-bank': (el) => { const b = findBank(el.dataset.id); Phone.openApp(b?.link, b?.name); },
  'launch-program': (el) => { const p = findProgram(el.dataset.id); Phone.openApp(p?.link, p?.name); },
  set: (el) => {
    const sc = scopeOf(el); if (!sc) return;
    let v = el.dataset.val; if (/^\d+$/.test(v) && el.dataset.bind !== 'merchantId') v = Number(v);
    setPath(sc.draft, el.dataset.bind, v);
    sc.onBind?.(el.dataset.bind, sc.draft);
    Phone.haptic(5);
    if (sc === Sheet.ctx) Sheet.refresh(); else render();
  },
  'toggle-inc': (el) => {
    const d = Sheet.ctx.draft; const id = el.dataset.id;
    d.includes = d.includes.includes(id) ? d.includes.filter((x) => x !== id) : [...d.includes, id];
    el.classList.toggle('on'); Phone.haptic(5);
  },
  'sub-save': () => {
    const d = Sheet.ctx.draft; const isNew = Sheet.ctx.isNew;
    if (!d.name) { UI.toast('Dê um nome para a assinatura.'); return; }
    commit((s) => { const i = s.subs.findIndex((x) => x.id === d.id); if (i >= 0) s.subs[i] = d; else s.subs.push(d); });
    Sheet.close(); UI.toast(isNew ? `${d.name} adicionada.` : 'Alterações salvas.');
  },
  'sub-pause': () => { const d = Sheet.ctx.draft; commit((s) => { const x = s.subs.find((y) => y.id === d.id); if (x) x.paused = !x.paused; }); Sheet.close(); UI.toast(d.paused ? 'Assinatura reativada.' : 'Assinatura pausada. Ela não conta nos gastos.'); },
  'sub-delete': () => confirmInline('sub-delete-yes', 'Excluir esta assinatura?'),
  'sub-delete-yes': () => { const id = Sheet.ctx.draft.id; commit((s) => { s.subs = s.subs.filter((x) => x.id !== id); }); Sheet.close(); UI.toast('Assinatura excluída.'); },
  'add-wallet': () => openWalletEditor({ id: uid(), programId: PROGRAMS.find((p) => !state.wallet.some((w) => w.programId === p.id))?.id || 'livelo', balance: '', expiry: '' }, true),
  'edit-wallet': (el) => { const w = state.wallet.find((x) => x.id === el.dataset.id); if (w) openWalletEditor(w, false); },
  'wallet-save': () => { const d = Sheet.ctx.draft; commit((s) => { const i = s.wallet.findIndex((x) => x.id === d.id); if (i >= 0) s.wallet[i] = d; else s.wallet.push(d); }); Sheet.close(); UI.toast('Saldo atualizado.'); },
  'wallet-delete': () => { const id = Sheet.ctx.draft.id; commit((s) => { s.wallet = s.wallet.filter((x) => x.id !== id); }); Sheet.close(); },
  'add-card': () => openCardEditor({ id: uid(), bankId: '', name: '', earn: 'points', ptsPerUSD: 1, program: 'livelo', cashbackPct: 0, fee: 0, monthlySpend: '' }, true),
  'edit-card': (el) => { const c = state.cards.find((x) => x.id === el.dataset.id); if (c) openCardEditor(c, false); },
  'pick-bank': (el) => { const d = Sheet.ctx.draft; d.bankId = el.dataset.id; ACTIONS['pick-product']({ dataset: { id: 0 } }); },
  'pick-product': (el) => {
    const d = Sheet.ctx.draft; const p = findBank(d.bankId)?.products[Number(el.dataset.id)]; if (!p) return;
    Object.assign(d, { name: p.name, earn: p.earn, ptsPerUSD: p.ptsPerUSD || 0, cashbackPct: p.cashbackPct || 0, program: p.program || d.program, fee: p.fee || 0, lounge: !!p.lounge, insurance: !!p.insurance, merchantBoost: p.merchantBoost });
    Sheet.refresh();
  },
  'card-save': () => { const d = Sheet.ctx.draft; if (!d.name) { UI.toast('Escolha o banco e o produto, ou dê um nome.'); return; } commit((s) => { const i = s.cards.findIndex((x) => x.id === d.id); if (i >= 0) s.cards[i] = d; else s.cards.push(d); }); Sheet.close(); UI.toast('Cartão salvo.'); },
  'card-delete': () => { const id = Sheet.ctx.draft.id; commit((s) => { s.cards = s.cards.filter((x) => x.id !== id); }); Sheet.close(); },
  'add-trip': () => openTripEditor({ id: uid(), origin: '', dest: '', date: '', back: '', pax: 1, bonusPct: 0, offers: [{ id: uid(), type: 'cash', cash: '' }, { id: uid(), type: 'miles', program: 'smiles', miles: '', taxes: '' }] }, true),
  'edit-trip': (el) => { const t = state.trips.find((x) => x.id === el.dataset.id); if (t) openTripEditor(t, false); },
  'add-offer': (el) => { const d = Sheet.ctx.draft; d.offers.push(el.dataset.id === 'cash' ? { id: uid(), type: 'cash', cash: '' } : { id: uid(), type: 'miles', program: 'latam', miles: '', taxes: '' }); Sheet.refresh(); },
  'rm-offer': (el) => { const d = Sheet.ctx.draft; d.offers.splice(Number(el.dataset.id), 1); Sheet.refresh(); },
  'trip-save': () => { const d = Sheet.ctx.draft; if (!d.dest) { UI.toast('Informe o destino.'); return; } d.origin = (d.origin || '').toUpperCase(); d.dest = d.dest.toUpperCase(); commit((s) => { const i = s.trips.findIndex((x) => x.id === d.id); if (i >= 0) s.trips[i] = d; else s.trips.push(d); }); Sheet.close(); UI.toast('Viagem salva.'); },
  'trip-delete': () => { const id = Sheet.ctx.draft.id; commit((s) => { s.trips = s.trips.filter((x) => x.id !== id); }); Sheet.close(); },
  'trip-share': () => {
    const d = Sheet.ctx.draft; const r = Engine.tripOptions(state, d);
    const lines = [`✈️ ${d.origin || ''} → ${d.dest}${d.date ? ' · ' + F.date(Engine.parseDate(d.date)) : ''}`];
    [...r.options].sort((a, b) => a.cost - b.cost).forEach((o) => lines.push(`${o === r.winner ? '★ ' : '• '}${o.label}: ${o.offer.type === 'miles' ? `${F.int(o.offer.miles)} milhas + ${F.brl(o.offer.taxes)}` : F.brl(o.offer.cash)} (≈ ${F.brl0(o.cost)})`));
    lines.push('Calculado no Milheiro');
    Phone.share({ title: 'Plano de viagem', text: lines.join('\n') });
  },
  'trip-ics': () => {
    const d = Sheet.ctx.draft; const dt = Engine.parseDate(d.date);
    if (!dt) { UI.toast('Informe a data de ida.'); return; }
    const ev = [{ uid: 'trip-' + d.id, date: dt, title: `Viagem ${d.origin || ''} → ${d.dest}`, alarmDays: 7, description: 'Lembrete do Milheiro' }];
    const back = Engine.parseDate(d.back); if (back) ev.push({ uid: 'tripb-' + d.id, date: back, title: `Volta ${d.dest} → ${d.origin || ''}`, alarmDays: 1 });
    exportCalendar(ev, `viagem-${(d.dest || 'milheiro').toLowerCase()}.ics`);
  },
  'paste-buy': async () => {
    const txt = await Phone.readClipboard();
    if (current !== 'comprar') go('comprar');
    if (!txt) { setTimeout(() => { $('#b-amount')?.focus(); UI.toast('Cole o preço no campo de valor.'); }, 80); return; }
    const p = Phone.parseShared(txt);
    if (!p.amount) { UI.toast('Não achei um preço em R$ no texto copiado.'); return; }
    Object.assign(scopes.buy.draft, p); render(); UI.toast(`Preço colado: ${F.brl(p.amount)}`);
  },
  'ics-all': () => exportCalendar(),
  'ics-subs': () => exportCalendar(calendarEvents().filter((e) => e.uid.startsWith('sub-'))),
  'notify-on': () => Phone.enableNotifications(),
  'settings-save': () => {
    const d = Sheet.ctx.draft; const { name, ...settings } = d;
    for (const k of Object.keys(settings.ref || {})) if (!settings.ref[k]) delete settings.ref[k];
    commit((s) => { s.name = name; s.settings = { ...s.settings, ...settings }; });
    Sheet.close(); UI.toast('Ajustes salvos.');
  },
  backup: () => Phone.saveFile(`milheiro-backup-${isoLocal(new Date())}.json`, JSON.stringify(state, null, 2), 'application/json'),
  reset: () => confirmInline('reset-yes', 'Apagar todos os dados deste aparelho?'),
  'reset-yes': () => { state = defaultState(); save(); Sheet.close(); ob.step = 0; render(); },
  'confirm-no': (el) => el.closest('.confirm')?.remove(),
  'sheet-close': () => Sheet.close(),
  'ob-next': () => { ob.step = Math.min(3, ob.step + 1); render(); window.scrollTo(0, 0); },
  'ob-back': () => { ob.step = Math.max(0, ob.step - 1); render(); },
  'ob-example': () => { state = exampleState(); save(); animated = false; location.hash = 'inicio'; route(); },
  'ob-toggle': (el) => {
    const { kind, id } = el.dataset;
    if (kind === 'services') {
      const cur = ob.services[id];
      if (!cur) ob.services[id] = 'me'; else if (cur === 'me') ob.services[id] = 'company'; else delete ob.services[id];
    } else { const set = ob[kind]; set.has(id) ? set.delete(id) : set.add(id); }
    Phone.haptic(6); render();
  },
  'ob-finish': () => finishOnboarding(),
};

function confirmInline(yesAct, text) {
  const host = $('#sheet-body .sheet-actions'); if (!host || host.querySelector('.confirm')) return;
  host.insertAdjacentHTML('beforebegin', `<div class="confirm"><span>${h(text)}</span><button class="btn btn-ghost btn-small" data-act="confirm-no">Cancelar</button><button class="btn danger-fill btn-small" data-act="${yesAct}">Sim, excluir</button></div>`);
}

function scopeOf(el) {
  if (el.closest('#sheet')) return Sheet.ctx;
  const sc = el.closest('[data-scope]');
  return sc ? scopes[sc.dataset.scope] : null;
}

/* ---------- eventos ---------- */
document.addEventListener('click', (e) => {
  const el = e.target.closest('[data-act]');
  if (!el) return;
  const fn = ACTIONS[el.dataset.act];
  if (fn) { e.preventDefault(); e.stopPropagation(); fn(el, e); }
});
document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape' && Sheet.ctx) Sheet.close();
  if ((e.key === 'Enter' || e.key === ' ') && e.target.matches('li[data-act]')) { e.preventDefault(); e.target.click(); }
});

function onBindInput(e) {
  const el = e.target;
  if (el.dataset.ob) { ob[el.dataset.ob] = el.value; return; }
  if (el.id === 'restore' && e.type === 'change') return restoreBackup(el);
  if (!el.dataset.bind) return;
  const sc = scopeOf(el); if (!sc) return;
  let v = el.type === 'checkbox' ? el.checked : el.value;
  if (el.dataset.num !== undefined && el.type !== 'checkbox') v = numBR(v);
  setPath(sc.draft, el.dataset.bind, v);
  sc.onBind?.(el.dataset.bind, sc.draft);
  if (el.hasAttribute('data-refresh') && e.type === 'change') { if (sc === Sheet.ctx) Sheet.refresh(); else render(); return; }
  sc.onChange?.(sc.draft);
}
document.addEventListener('input', onBindInput);
document.addEventListener('change', (e) => { if (e.target.tagName === 'SELECT' || e.target.type === 'checkbox' || e.target.type === 'file' || e.target.type === 'date') onBindInput(e); });

function restoreBackup(input) {
  const f = input.files?.[0]; if (!f) return;
  const r = new FileReader();
  r.onload = () => {
    try {
      const data = JSON.parse(r.result);
      if (!data || !Array.isArray(data.subs) || !Array.isArray(data.cards)) throw new Error('formato');
      state = { ...defaultState(), ...data, settings: { ...defaultState().settings, ...(data.settings || {}) } };
      save(); Sheet.close(); render(); UI.toast('Backup restaurado.');
    } catch (err) { UI.toast('Arquivo inválido. Use um backup gerado pelo Milheiro.'); }
  };
  r.readAsText(f);
}

/* Arrastar a folha para baixo para fechar */
(() => {
  let y0 = null, dy = 0;
  document.addEventListener('touchstart', (e) => {
    const grip = e.target.closest('.sheet-grip, .sheet-head');
    if (!grip) return; y0 = e.touches[0].clientY; dy = 0;
  }, { passive: true });
  document.addEventListener('touchmove', (e) => {
    if (y0 == null) return; dy = Math.max(0, e.touches[0].clientY - y0);
    $('.sheet-panel').style.transform = `translateY(${dy}px)`;
  }, { passive: true });
  document.addEventListener('touchend', () => {
    if (y0 == null) return; const p = $('.sheet-panel'); p.style.transform = '';
    if (dy > 110) Sheet.close(); y0 = null;
  });
})();

/* ---------- inicialização ---------- */
function boot() {
  // Recebe conteúdo compartilhado por outros apps (Web Share Target)
  const q = new URLSearchParams(location.search);
  const shared = [q.get('title'), q.get('text'), q.get('url')].filter(Boolean).join(' ');
  if (shared && state.onboarded) {
    Object.assign(scopes.buy.draft, Phone.parseShared(shared));
    history.replaceState(null, '', location.pathname + '#comprar');
    setTimeout(() => UI.toast('Recebi o link. Veja qual cartão usar.'), 400);
  }
  if (Phone.isIOS && !Phone.standalone()) document.documentElement.classList.add('can-install');
  window.addEventListener('hashchange', route);
  route();
  checkNotifications();
  if ('serviceWorker' in navigator && /^https?:$/.test(location.protocol)) {
    navigator.serviceWorker.register('sw.js').catch(() => {});
  }
}
boot();
