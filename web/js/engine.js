/* Milheiro — motor de otimização. Funções puras sobre o estado do usuário. */

const Engine = (() => {
  const DAY = 86400000;

  const today = () => { const d = new Date(); d.setHours(0, 0, 0, 0); return d; };
  const parseDate = (s) => { if (!s) return null; const [y, m, d] = s.split('-').map(Number); return new Date(y, m - 1, d); };
  const daysUntil = (date) => Math.round((date - today()) / DAY);

  const ref = (state, programId) =>
    Number(state.settings.ref?.[programId]) || findProgram(programId)?.ref || 20;

  const service = (sub) => findService(sub.serviceId) || findService('custom');

  const monthly = (sub) => {
    if (sub.payer === 'company' || sub.paused) return 0;
    const p = Number(sub.price) || 0;
    return sub.cycle === 'annual' ? p / 12 : p;
  };

  const cats = (sub) => {
    const s = service(sub);
    return [sub.cat || s.cat, ...(s.also || [])];
  };

  const includesOf = (sub) => {
    if (Array.isArray(sub.includes)) return sub.includes;
    const s = service(sub);
    if (s.plans && sub.plan) return s.plans.find((p) => p.name === sub.plan)?.includes || [];
    return s.includes || [];
  };

  /* Retorno por R$ 1 gasto no cartão (em R$). */
  const cardRate = (state, card, merchantId) => {
    let r = 0;
    if (card.earn === 'cashback') r = (Number(card.cashbackPct) || 0) / 100;
    if (card.earn === 'points') {
      const usd = Number(state.settings.usd) || 5.4;
      r = ((Number(card.ptsPerUSD) || 0) / usd) * (ref(state, card.program) / 1000);
    }
    const boost = card.merchantBoost?.[merchantId];
    if (boost) r = Math.max(r, boost / 100);
    return r;
  };

  const bestCard = (state, merchantId) => {
    let best = null;
    for (const c of state.cards) {
      const rate = cardRate(state, c, merchantId);
      if (!best || rate > best.rate) best = { card: c, rate };
    }
    return best;
  };

  const nextRenewal = (sub) => {
    const day = Number(sub.renewDay);
    if (!day) return null;
    const t = today();
    if (sub.cycle === 'annual' && sub.renewMonth) {
      let d = new Date(t.getFullYear(), Number(sub.renewMonth) - 1, day);
      if (d < t) d = new Date(t.getFullYear() + 1, Number(sub.renewMonth) - 1, day);
      return d;
    }
    const clamp = (y, m) => new Date(y, m, Math.min(day, new Date(y, m + 1, 0).getDate()));
    let d = clamp(t.getFullYear(), t.getMonth());
    if (d < t) d = clamp(t.getFullYear(), t.getMonth() + 1);
    return d;
  };

  /* ---------- Insights ---------- */
  function analyze(state) {
    const insights = [];
    const flagged = new Set();
    const subs = state.subs.filter((s) => !s.paused);
    const fmt = UI_FMT;

    // 1. Pagando algo que já está incluído em outro plano
    for (const a of subs) {
      const inc = includesOf(a);
      if (!inc.length) continue;
      for (const b of subs) {
        if (b === a || b.payer === 'company' || flagged.has(b.id)) continue;
        if (inc.includes(b.serviceId)) {
          flagged.add(b.id);
          insights.push({
            id: `bundle-${a.id}-${b.id}`, severity: 'high', kind: 'Duplicado',
            title: `${b.name} já vem no seu ${a.name}${a.plan ? ' ' + a.plan : ''}`,
            body: `Você paga ${fmt.brl(monthly(b))}/mês à parte. Ative o ${b.name} pelo ${a.name} e cancele a assinatura avulsa.` +
              (service(a).note ? ` ${service(a).note}` : ''),
            saving: monthly(b),
            actions: [{ label: `Abrir ${a.name}`, act: 'open-sub', id: a.id }, { label: `Cancelar ${b.name}`, act: 'open-sub', id: b.id }],
          });
        }
      }
    }

    // 2. Categorias exclusivas com mais de um serviço (academia, música, delivery, nuvem)
    const byCat = {};
    for (const s of subs) for (const c of cats(s)) (byCat[c] ||= []).push(s);
    for (const [cat, list] of Object.entries(byCat)) {
      const meta = CATEGORIES[cat];
      if (!meta?.exclusive || list.length < 2) continue;
      const pending = list.filter((s) => !flagged.has(s.id));
      if (pending.length < 1 || list.length < 2) continue;
      const company = list.find((s) => s.payer === 'company');
      let keep, extra;
      if (company) {
        keep = company;
        extra = list.filter((s) => s !== company && s.payer !== 'company' && !flagged.has(s.id));
      } else {
        const usageRank = { daily: 0, weekly: 1, monthly: 2, rarely: 3 };
        const sorted = [...list].sort((x, y) => (usageRank[x.usage] ?? 2) - (usageRank[y.usage] ?? 2) || monthly(x) - monthly(y));
        keep = sorted[0];
        extra = sorted.slice(1).filter((s) => !flagged.has(s.id) && s.payer !== 'company');
      }
      if (!extra.length) continue;
      const saving = extra.reduce((t, s) => t + monthly(s), 0);
      extra.forEach((s) => flagged.add(s.id));
      insights.push({
        id: `dup-${cat}`, severity: 'high', kind: 'Sobreposição',
        title: company
          ? `${keep.name} já é pago pela empresa`
          : `Você tem ${list.length} serviços de ${meta.label.toLowerCase()}`,
        body: company
          ? `Use o ${keep.name} do benefício corporativo e cancele ${extra.map((s) => s.name).join(' e ')}. Antes, confira se as academias que você frequenta estão no plano da empresa.`
          : `Fique com ${keep.name} (o que você mais usa) e cancele ${extra.map((s) => s.name).join(' e ')}.`,
        saving,
        actions: extra.map((s) => ({ label: `Ver ${s.name}`, act: 'open-sub', id: s.id })),
      });
    }

    // 3. Muitos streamings de vídeo: rodízio
    const video = (byCat.video || []).filter((s) => s.payer !== 'company' && !flagged.has(s.id) && monthly(s) > 0);
    const limit = CATEGORIES.video.softLimit;
    if (video.length > limit) {
      const usageRank = { daily: 0, weekly: 1, monthly: 2, rarely: 3 };
      const sorted = [...video].sort((x, y) => (usageRank[x.usage] ?? 2) - (usageRank[y.usage] ?? 2));
      const rest = sorted.slice(limit);
      const saving = rest.reduce((t, s) => t + monthly(s), 0);
      rest.forEach((s) => flagged.add(s.id));
      insights.push({
        id: 'video-rotation', severity: 'med', kind: 'Rodízio',
        title: `${video.length} streamings de vídeo ao mesmo tempo`,
        body: `Mantenha ${sorted.slice(0, limit).map((s) => s.name).join(' e ')} e faça rodízio com ${rest.map((s) => s.name).join(', ')}: assine um por mês, maratone e cancele.`,
        saving,
        actions: [{ label: 'Lembrar no calendário', act: 'ics-subs' }],
      });
    }

    // 4. Pouco uso
    for (const s of subs) {
      if (flagged.has(s.id) || s.payer === 'company' || s.usage !== 'rarely' || monthly(s) <= 0) continue;
      flagged.add(s.id);
      insights.push({
        id: `unused-${s.id}`, severity: monthly(s) >= 30 ? 'high' : 'med', kind: 'Pouco uso',
        title: `Você quase não usa ${s.name}`,
        body: `São ${fmt.brl(monthly(s) * 12)} por ano. Cancele ou pause e assine de novo só quando precisar.`,
        saving: monthly(s),
        actions: [{ label: `Abrir ${s.name}`, act: 'launch-sub', id: s.id }],
      });
    }

    // 5. Plano anual mais barato
    for (const s of subs) {
      const svc = service(s);
      if (flagged.has(s.id) || s.payer === 'company' || s.cycle === 'annual' || !svc.annual) continue;
      if (!['daily', 'weekly'].includes(s.usage)) continue;
      const diff = (Number(s.price) * 12 - svc.annual) / 12;
      if (diff > 1) insights.push({
        id: `annual-${s.id}`, severity: 'low', kind: 'Plano anual',
        title: `${s.name} sai mais barato no plano anual`,
        body: `Anual por cerca de ${fmt.brl(svc.annual)} contra ${fmt.brl(Number(s.price) * 12)} pagando mês a mês. Vale para o que você usa toda semana.`,
        saving: diff,
        actions: [{ label: 'Editar', act: 'open-sub', id: s.id }],
      });
    }

    // 6. Clubes de pontos: custo do milheiro
    for (const s of subs) {
      const svc = service(s);
      if (svc.cat !== 'club' || s.payer === 'company') continue;
      const pts = Number(s.pointsPerMonth ?? svc.pointsPerMonth) || 0;
      if (!pts) continue;
      const prog = s.program || svc.program;
      const cpm = (monthly(s) / pts) * 1000;
      const r = ref(state, prog);
      if (cpm > r * 0.9) {
        insights.push({
          id: `club-${s.id}`, severity: 'med', kind: 'Clube caro',
          title: `${s.name}: milheiro a ${fmt.brl(cpm)}`,
          body: `Você paga mais pelo milheiro do que ele costuma valer em resgates (cerca de ${fmt.brl(r)}). Só mantenha se o clube der bônus extras que você usa, como bônus em transferências.`,
          saving: monthly(s),
          actions: [{ label: 'Ver clube', act: 'open-sub', id: s.id }],
        });
      } else {
        insights.push({
          id: `club-ok-${s.id}`, severity: 'good', kind: 'Bom negócio',
          title: `${s.name} compensa`,
          body: `Seu milheiro sai a ${fmt.brl(cpm)}, abaixo do valor de referência (${fmt.brl(r)}).`,
          saving: 0, actions: [],
        });
      }
    }

    // 7. Anuidade maior que o retorno
    for (const c of state.cards) {
      const fee = Number(c.fee) || 0;
      const spend = Number(c.monthlySpend) || 0;
      if (!fee || !spend) continue;
      const yearly = spend * 12 * cardRate(state, c);
      if (yearly < fee) {
        insights.push({
          id: `fee-${c.id}`, severity: 'high', kind: 'Anuidade',
          title: `${c.name}: anuidade maior que o retorno`,
          body: `Você paga ${fmt.brl(fee)}/ano e recebe cerca de ${fmt.brl(yearly)} em pontos ou cashback. Peça isenção no app (muitos bancos isentam com gasto mínimo ou investimento) ou troque por um cartão sem anuidade.`,
          saving: (fee - yearly) / 12,
          actions: [{ label: `Abrir app ${findBank(c.bankId)?.name || ''}`, act: 'launch-bank', id: c.bankId }],
        });
      }
    }

    // 8. Assinaturas no cartão errado
    const best = bestCard(state);
    if (best && best.rate > 0) {
      let gain = 0; const moved = [];
      for (const s of subs) {
        if (s.payer === 'company' || !monthly(s)) continue;
        const card = state.cards.find((c) => c.id === s.cardId);
        const cur = card ? cardRate(state, card) : 0;
        if (best.rate - cur > 0.001) { gain += monthly(s) * (best.rate - cur); moved.push(s.name); }
      }
      if (gain >= 1) insights.push({
        id: 'move-subs', severity: 'low', kind: 'Pontos',
        title: `Passe ${moved.length} assinatura${moved.length > 1 ? 's' : ''} para o ${best.card.name}`,
        body: `${moved.slice(0, 4).join(', ')}${moved.length > 4 ? '…' : ''} estão em um cartão que rende menos. Trocando, você ganha cerca de ${fmt.brl(gain * 12)}/ano em pontos ou cashback.`,
        saving: gain,
        actions: [],
      });
    }

    // 9. Pontos vencendo
    for (const w of state.wallet) {
      const d = parseDate(w.expiry);
      if (!d || !Number(w.balance)) continue;
      const days = daysUntil(d);
      if (days > 180) continue;
      const p = findProgram(w.programId);
      const value = (Number(w.balance) / 1000) * ref(state, w.programId);
      insights.push({
        id: `exp-${w.id}`, severity: days <= 90 ? 'high' : 'med', kind: 'Vencendo',
        title: days < 0
          ? `Pontos ${p?.name} vencidos`
          : `${fmt.int(w.balance)} pontos ${p?.name} vencem em ${days} dias`,
        body: p?.kind === 'bank'
          ? `Cerca de ${fmt.brl(value)} em risco. Transfira para uma companhia aérea, de preferência em campanha com bônus. A validade lá costuma ser maior.`
          : `Cerca de ${fmt.brl(value)} em risco. Emita uma passagem, ou faça uma compra pequena no programa para renovar a validade, se ele permitir.`,
        saving: 0, risk: value,
        actions: [{ label: `Abrir ${p?.name}`, act: 'launch-program', id: w.programId }, { label: 'Simular transferência', act: 'goto', to: 'milhas' }],
      });
    }

    // 10. Pontos de banco parados: esperar bônus
    for (const w of state.wallet) {
      const p = findProgram(w.programId);
      if (p?.kind !== 'bank' || Number(w.balance) < 10000) continue;
      const d = parseDate(w.expiry);
      if (d && daysUntil(d) <= 90) continue;
      insights.push({
        id: `bonus-${w.id}`, severity: 'info', kind: 'Estratégia',
        title: `${fmt.int(w.balance)} pontos ${p.name}: espere o bônus`,
        body: `Campanhas de transferência com 80% a 100% de bônus aparecem várias vezes por ano. Com 100%, viram ${fmt.int(w.balance * 2)} milhas. Não transfira sem bônus, a menos que vá emitir já.`,
        saving: 0, actions: [{ label: 'Simular', act: 'goto', to: 'milhas' }],
      });
    }

    // Pontuação
    const weights = { high: 12, med: 6, low: 3 };
    let score = 100;
    for (const i of insights) score -= weights[i.severity] || 0;
    if (!state.cards.some((c) => c.earn !== 'none')) score -= 8;
    score = Math.max(5, Math.min(100, score));

    const order = { high: 0, med: 1, low: 2, info: 3, good: 4 };
    insights.sort((a, b) => order[a.severity] - order[b.severity] || (b.saving || 0) - (a.saving || 0));

    const monthlyTotal = state.subs.reduce((t, s) => t + monthly(s), 0);
    const companyValue = state.subs.filter((s) => s.payer === 'company').reduce((t, s) => t + (Number(s.price) || 0), 0);
    const savings = insights.reduce((t, i) => t + (i.saving || 0), 0);
    return { insights, score, monthlyTotal, savings, companyValue };
  }

  /* ---------- Carteira ---------- */
  function walletSummary(state) {
    let points = 0, value = 0;
    for (const w of state.wallet) {
      const b = Number(w.balance) || 0;
      points += b; value += (b / 1000) * ref(state, w.programId);
    }
    return { points, value };
  }

  function transfer(state, fromId, toId, points, bonusPct, ratio = 1) {
    const out = Math.floor(points * ratio * (1 + (Number(bonusPct) || 0) / 100));
    const before = (points / 1000) * ref(state, fromId);
    const after = (out / 1000) * ref(state, toId);
    return { out, before, after };
  }

  /* Valor obtido por milheiro em um resgate. */
  function redemption(state, { cash, miles, taxes, programId }) {
    cash = Number(cash) || 0; miles = Number(miles) || 0; taxes = Number(taxes) || 0;
    if (!miles || !cash) return null;
    const cpm = ((cash - taxes) / miles) * 1000;
    const r = ref(state, programId);
    let verdict, tone;
    if (cpm >= r * 1.2) { verdict = 'Excelente resgate'; tone = 'good'; }
    else if (cpm >= r) { verdict = 'Bom resgate'; tone = 'good'; }
    else if (cpm >= r * 0.7) { verdict = 'Razoável'; tone = 'warn'; }
    else { verdict = 'Pague em dinheiro'; tone = 'bad'; }
    return { cpm, ref: r, verdict, tone, ratio: cpm / r };
  }

  /* ---------- Compras ---------- */
  function purchase(state, { amount, merchantId, installments, pixPct, portalPts, portalProgram }) {
    amount = Number(amount) || 0;
    const merchant = findMerchant(merchantId) || findMerchant('outro');
    const iof = merchant.intl ? (Number(state.settings.iof) || 3.5) / 100 : 0;
    const ranking = state.cards.map((c) => {
      const rate = cardRate(state, c, merchant.id);
      const back = amount * rate;
      const iofCost = amount * iof;
      const pts = c.earn === 'points' ? Math.round((amount / (Number(state.settings.usd) || 5.4)) * (Number(c.ptsPerUSD) || 0)) : 0;
      return { card: c, rate, back, iofCost, net: back - iofCost, pts };
    }).sort((a, b) => b.net - a.net);

    const n = Math.max(1, Number(installments) || 1);
    const cdi = (Number(state.settings.cdiMonthly) || 1) / 100;
    let yieldGain = 0;
    for (let k = 1; k < n; k++) yieldGain += (amount / n) * k * cdi;
    yieldGain *= 0.8; // depois do IR aproximado

    const pix = amount * ((Number(pixPct) || 0) / 100);
    const portal = portalPts ? amount * Number(portalPts) * (ref(state, portalProgram || 'livelo') / 1000) : 0;
    const perkSub = merchant.perk ? state.subs.find((s) => s.serviceId === merchant.perk && !s.paused) : null;
    return { ranking, yieldGain, pix, portal, merchant, perk: perkSub ? merchant.perkText : null, iof };
  }

  /* ---------- Viagens ---------- */
  function tripOptions(state, trip) {
    const best = bestCard(state, 'aereo');
    const balances = {};
    for (const w of state.wallet) balances[w.programId] = (balances[w.programId] || 0) + (Number(w.balance) || 0);
    const bonus = Number(trip.bonusPct) || 0;

    const options = (trip.offers || []).map((o) => {
      if (o.type === 'cash') {
        const cash = Number(o.cash) || 0;
        const back = best ? cash * best.rate : 0;
        return { offer: o, cost: cash - back, label: 'Dinheiro', detail: best ? `Volta ~${UI_FMT.brl(back)} no ${best.card.name}` : '', feasible: true };
      }
      const miles = Number(o.miles) || 0;
      const taxes = Number(o.taxes) || 0;
      const p = findProgram(o.program);
      const cost = (miles / 1000) * ref(state, o.program) + taxes;
      const have = balances[o.program] || 0;
      let feasible = have >= miles, plan = null;
      if (!feasible) {
        const missing = miles - have;
        const sources = PROGRAMS.filter((x) => x.partners.includes(o.program) && balances[x.id]);
        for (const src of sources) {
          const need = Math.ceil(missing / (1 + bonus / 100));
          if (balances[src.id] >= need) { plan = { from: src, need, missing }; feasible = true; break; }
        }
        if (!plan) plan = { missing };
      }
      const cashRef = (trip.offers || []).find((x) => x.type === 'cash');
      const r = cashRef ? redemption(state, { cash: cashRef.cash, miles, taxes, programId: o.program }) : null;
      return { offer: o, cost, label: p?.name || 'Milhas', feasible, have, plan, redemption: r };
    });
    const feasible = options.filter((x) => x.feasible);
    const winner = (feasible.length ? feasible : options).reduce((a, b) => (!a || b.cost < a.cost ? b : a), null);
    return { options, winner };
  }

  /* ---------- Agenda ---------- */
  function upcoming(state, horizon = 45) {
    const ev = [];
    for (const s of state.subs) {
      if (s.paused) continue;
      const d = nextRenewal(s);
      if (d && daysUntil(d) <= horizon) ev.push({ date: d, kind: 'renew', title: `Renova ${s.name}`, amount: s.payer === 'company' ? 0 : Number(s.price), ref: s });
    }
    for (const w of state.wallet) {
      const d = parseDate(w.expiry);
      if (d && daysUntil(d) <= Math.max(horizon, 120)) ev.push({ date: d, kind: 'expire', title: `Vencem ${UI_FMT.int(w.balance)} pts ${findProgram(w.programId)?.name}`, ref: w });
    }
    for (const t of state.trips) {
      const d = parseDate(t.date);
      if (d && daysUntil(d) >= 0 && daysUntil(d) <= 120) ev.push({ date: d, kind: 'trip', title: `Viagem ${t.origin || ''} → ${t.dest}`, ref: t });
    }
    return ev.sort((a, b) => a.date - b.date);
  }

  return { ref, monthly, cats, includesOf, cardRate, bestCard, analyze, walletSummary, transfer, redemption, purchase, tripOptions, upcoming, nextRenewal, parseDate, daysUntil, service };
})();
