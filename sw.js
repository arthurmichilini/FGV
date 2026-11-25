/* Milheiro — service worker: funciona offline e abre o app ao tocar numa notificação. */
const CACHE = 'milheiro-v1';
const SHELL = ['./', 'index.html', 'css/app.css', 'js/catalog.js', 'js/engine.js', 'js/phone.js', 'js/app.js',
  'manifest.webmanifest', 'icons/icon.svg', 'icons/icon-192.png', 'icons/icon-512.png'];

self.addEventListener('install', (e) => {
  e.waitUntil(caches.open(CACHE).then((c) => c.addAll(SHELL)).then(() => self.skipWaiting()));
});

self.addEventListener('activate', (e) => {
  e.waitUntil(caches.keys().then((keys) => Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k))))
    .then(() => self.clients.claim()));
});

self.addEventListener('fetch', (e) => {
  const req = e.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  // Navegações (inclui links compartilhados com ?text=...): rede primeiro, cache se offline.
  if (req.mode === 'navigate') {
    e.respondWith(fetch(req).catch(() => caches.match('index.html')));
    return;
  }
  if (url.origin === location.origin) {
    // Arquivos do app: cache, atualizando em segundo plano.
    e.respondWith(caches.match(req).then((hit) => {
      const net = fetch(req).then((res) => { if (res.ok) caches.open(CACHE).then((c) => c.put(req, res.clone())); return res; }).catch(() => hit);
      return hit || net;
    }));
  } else if (url.host.includes('fonts.g')) {
    e.respondWith(caches.open(CACHE).then((c) => c.match(req).then((hit) => hit || fetch(req).then((res) => { c.put(req, res.clone()); return res; }))));
  }
});

self.addEventListener('notificationclick', (e) => {
  e.notification.close();
  e.waitUntil(self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then((list) => {
    const win = list.find((c) => 'focus' in c);
    if (win) return win.focus();
    return self.clients.openWindow('./#inicio');
  }));
});
