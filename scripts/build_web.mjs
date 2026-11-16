import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';

const root = process.cwd();
const wwwDir = path.join(root, 'www');

const requiredFiles = [
  'index.html',
  'manifest.json',
  'sw.js',
  'privacy-policy.html',
  'assets/tailwind.min.css'
];

for (const rel of requiredFiles) {
  const fullPath = path.join(root, rel);
  assert(fs.existsSync(fullPath), `Archivo requerido faltante para webDir: ${rel}`);
}

fs.rmSync(wwwDir, { recursive: true, force: true });
fs.mkdirSync(wwwDir, { recursive: true });

for (const rel of ['index.html', 'manifest.json', 'sw.js', 'privacy-policy.html']) {
  fs.copyFileSync(path.join(root, rel), path.join(wwwDir, rel));
}

fs.cpSync(path.join(root, 'assets'), path.join(wwwDir, 'assets'), { recursive: true });

console.log('[build_web] www/ ensamblado correctamente para Capacitor y PWA.');
