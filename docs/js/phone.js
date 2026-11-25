/* Milheiro — integração com o celular.
 * Tudo aqui degrada com elegância: se o recurso não existir, cai para uma alternativa. */

const Phone = (() => {
  const ua = navigator.userAgent || '';
  const isAndroid = /Android/i.test(ua);
  const isIOS = /iPhone|iPad|iPod/i.test(ua) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
  const standalone = () => window.matchMedia?.('(display-mode: standalone)').matches || navigator.standalone === true;

  /* Abre o app nativo. Android: intent:// com o pacote e fallback para a web.
   * iPhone: tenta o esquema de URL; se o app não abrir em 1,4 s, vai para a web. */
  function openApp(link = {}, label = 'app') {
    haptic(8);
    const web = link.web;
    try {
      if (isAndroid && link.android) {
        // Usa o App Link do site oficial direcionado ao pacote: o Chrome abre o app
        // se estiver instalado; senão vai para o site (ou para a Play Store).
        const store = `https://play.google.com/store/apps/details?id=${link.android}`;
        const fb = `;S.browser_fallback_url=${encodeURIComponent(web || store)}`;
        let target = '';
        if (web) { const u = new URL(web); target = `${u.host}${u.pathname}${u.search}`; }
        window.location.href = `intent://${target}#Intent;scheme=https;package=${link.android}${fb};end`;
        return true;
      }
      if (isIOS && link.ios) {
        // O iPhone pergunta "Abrir no app?". Se o app não estiver instalado, o aviso oferece o site.
        window.location.href = link.ios;
        if (web) UI.toast(`Abrindo ${label}…`, 6000, { label: 'Abrir site', href: web });
        return true;
      }
      if (web) { window.open(web, '_blank', 'noopener'); return true; }
    } catch (e) { /* segue para o aviso */ }
    UI.toast(`Não encontrei um link para abrir ${label}.`);
    return false;
  }

  function haptic(pattern = 10) {
    try { if (navigator.vibrate) navigator.vibrate(pattern); } catch (e) {}
  }

  /* ---------- Calendário (.ics) ---------- */
  const pad = (n) => String(n).padStart(2, '0');
  const icsDate = (d) => `${d.getFullYear()}${pad(d.getMonth() + 1)}${pad(d.getDate())}`;
  const esc = (s) => String(s || '').replace(/[\\;,]/g, (m) => '\\' + m).replace(/\n/g, '\\n');

  function buildICS(events) {
    const now = new Date();
    const stamp = `${icsDate(now)}T${pad(now.getHours())}${pad(now.getMinutes())}00`;
    const lines = ['BEGIN:VCALENDAR', 'VERSION:2.0', 'PRODID:-//Milheiro//PT-BR', 'CALSCALE:GREGORIAN', 'METHOD:PUBLISH', 'X-WR-CALNAME:Milheiro'];
    events.forEach((e, i) => {
      const end = new Date(e.date.getTime() + 86400000);
      lines.push('BEGIN:VEVENT',
        `UID:milheiro-${e.uid || i}-${icsDate(e.date)}@milheiro.app`,
        `DTSTAMP:${stamp}`,
        `DTSTART;VALUE=DATE:${icsDate(e.date)}`,
        `DTEND;VALUE=DATE:${icsDate(end)}`,
        `SUMMARY:${esc(e.title)}`,
        `DESCRIPTION:${esc(e.description || 'Lembrete criado pelo Milheiro')}`);
      if (e.rrule) lines.push(`RRULE:${e.rrule}`);
      lines.push('BEGIN:VALARM', 'ACTION:DISPLAY', `DESCRIPTION:${esc(e.title)}`, `TRIGGER:-P${e.alarmDays ?? 2}D`, 'END:VALARM', 'END:VEVENT');
    });
    lines.push('END:VCALENDAR');
    return lines.join('\r\n');
  }

  async function saveFile(name, content, type) {
    const blob = new Blob([content], { type });
    // No celular, compartilhar o arquivo abre direto no app de Calendário/Arquivos.
    try {
      const file = new File([blob], name, { type });
      if (navigator.canShare?.({ files: [file] })) {
        await navigator.share({ files: [file], title: name });
        return true;
      }
    } catch (e) { if (e?.name === 'AbortError') return false; }
    try {
      const url = URL.createObjectURL(blob);
      const a = Object.assign(document.createElement('a'), { href: url, download: name });
      document.body.appendChild(a); a.click(); a.remove();
      setTimeout(() => URL.revokeObjectURL(url), 4000);
      return true;
    } catch (e) {
      UI.toast('Este navegador não permite salvar arquivos aqui. Instale o app para usar esta função.');
      return false;
    }
  }

  async function addToCalendar(events, name = 'milheiro.ics') {
    const ics = buildICS(events);
    if (isIOS) {
      // No iPhone, abrir o .ics mostra a tela do Calendário com "Adicionar Tudo".
      try {
        const win = window.open('data:text/calendar;charset=utf-8,' + encodeURIComponent(ics), '_blank');
        if (win) return true;
      } catch (e) { /* tenta salvar o arquivo */ }
    }
    return saveFile(name, ics, 'text/calendar');
  }

  /* Número no ícone do app (iPhone com o app na tela inicial, Android e computador). */
  async function setBadge(n) {
    try {
      if (!('setAppBadge' in navigator)) return;
      if (n > 0) await navigator.setAppBadge(n); else await navigator.clearAppBadge();
    } catch (e) { /* sem permissão: ignora */ }
  }

  /* ---------- Compartilhar ---------- */
  async function share({ title, text, url }) {
    haptic(8);
    try {
      if (navigator.share) { await navigator.share({ title, text, url }); return true; }
    } catch (e) { if (e?.name === 'AbortError') return false; }
    return copy([text, url].filter(Boolean).join('\n'));
  }

  async function copy(text) {
    try { await navigator.clipboard.writeText(text); UI.toast('Copiado. Cole no WhatsApp ou onde quiser.'); return true; }
    catch (e) { UI.toast('Não consegui copiar automaticamente.'); return false; }
  }

  async function readClipboard() {
    try { return await navigator.clipboard.readText(); } catch (e) { return null; }
  }

  /* ---------- Notificações ---------- */
  async function enableNotifications() {
    if (!('Notification' in window)) {
      UI.toast(isIOS ? 'No iPhone, instale o Milheiro na tela inicial primeiro. Depois ative as notificações por aqui.' : 'Seu navegador não suporta notificações.', 5000);
      return false;
    }
    try {
      const res = await Notification.requestPermission();
      if (res !== 'granted') { UI.toast('Notificações bloqueadas. Libere nas configurações do navegador.'); return false; }
      await notify('Milheiro ativado', 'Vou avisar sobre renovações e pontos perto de vencer.');
      return true;
    } catch (e) { UI.toast('Não foi possível ativar notificações aqui.'); return false; }
  }

  async function notify(title, body, tag) {
    try {
      if (!('Notification' in window) || Notification.permission !== 'granted') return false;
      const reg = await navigator.serviceWorker?.getRegistration?.();
      const opts = { body, tag, icon: 'icons/icon-192.png', badge: 'icons/icon-192.png' };
      if (reg) await reg.showNotification(title, opts); else new Notification(title, opts);
      return true;
    } catch (e) { return false; }
  }

  /* ---------- Instalação (PWA) ---------- */
  let deferredPrompt = null;
  window.addEventListener('beforeinstallprompt', (e) => {
    e.preventDefault();
    deferredPrompt = e;
    window.dispatchEvent(new Event('milheiro:installable'));
  });
  const canPrompt = () => !!deferredPrompt;

  async function install() {
    if (deferredPrompt) {
      deferredPrompt.prompt();
      await deferredPrompt.userChoice.catch(() => null);
      deferredPrompt = null;
      window.dispatchEvent(new Event('milheiro:installable'));
      return;
    }
    if (isIOS) UI.toast('No iPhone: toque em Compartilhar e depois em “Adicionar à Tela de Início”.', 6000);
    else UI.toast('Abra o menu do navegador e escolha “Instalar app” ou “Adicionar à tela inicial”.', 6000);
  }

  /* Interpreta texto compartilhado por outro app (preço, loja, link). */
  function parseShared(text = '') {
    const out = {};
    const m = text.match(/R\$\s?([\d.]+,\d{2}|[\d.]+)/i);
    if (m) out.amount = Number(m[1].replace(/\./g, '').replace(',', '.'));
    const t = text.toLowerCase();
    if (/mercadolivre|mercado livre|meli/.test(t)) out.merchantId = 'mercadolivre';
    else if (/amazon/.test(t)) out.merchantId = 'amazon';
    else if (/magalu|magazine/.test(t)) out.merchantId = 'magalu';
    else if (/ifood/.test(t)) out.merchantId = 'ifood';
    else if (/uber/.test(t)) out.merchantId = 'uber';
    else if (/latam|gol|azul|voo|passage|booking|hotel|decolar/.test(t)) out.merchantId = 'aereo';
    else if (/aliexpress|shein|temu|usd|us\$/.test(t)) out.merchantId = 'internacional';
    return out;
  }

  return { isAndroid, isIOS, standalone, openApp, haptic, addToCalendar, buildICS, saveFile, share, copy, readClipboard, enableNotifications, notify, install, canPrompt, setBadge, parseShared };
})();
