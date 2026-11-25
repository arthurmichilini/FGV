// Gera dist/milheiro.html: uma página única com CSS e JS embutidos (para prévias e compartilhamento).
// Uso: node tools/build-single.mjs
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
const r = (p) => readFileSync(new URL('../' + p, import.meta.url), 'utf8'); // caminhos relativos a docs/
const css = r('css/app.css');
const js = ['js/catalog.js', 'js/engine.js', 'js/phone.js', 'js/app.js'].map(r).join('\n;\n');
const body = r('index.html').split('<body>')[1].split('<script')[0];
const html = `<title>Milheiro</title>
<meta name="claude:viewport-fit-sides" content="cover">
<style>${css}</style>
${body}
<script>document.documentElement.classList.add('in-artifact');
${js}</script>
`;
mkdirSync(new URL('../dist/', import.meta.url), { recursive: true });
writeFileSync(new URL('../dist/milheiro.html', import.meta.url), html);
console.log('dist/milheiro.html', html.length, 'bytes');
