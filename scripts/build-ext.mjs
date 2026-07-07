// devad.html を拡張のnewtab.htmlへ複製する(単一ソース維持のため手編集禁止)
import { copyFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
const root = join(dirname(fileURLToPath(import.meta.url)), '..');
copyFileSync(join(root, 'devad.html'), join(root, 'ext', 'newtab.html'));
console.log('ext/newtab.html updated from devad.html');
