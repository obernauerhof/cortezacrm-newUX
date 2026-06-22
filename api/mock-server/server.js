#!/usr/bin/env node
'use strict';

/*
 * Abhängigkeitsfreier Mock-Server für die mobile App.
 * Implementiert `GET /me/modules` gemäß api/openapi.yaml, damit die iOS-App
 * mit useMockManifest=false gegen einen echten HTTP-Endpunkt laufen kann.
 *
 * Start:  node server.js   (oder: npm start)
 * Port:   PORT (Standard 4010)
 *
 * Hinweis: Für lokale Entwicklung wird jedes (oder kein) Bearer-Token
 * akzeptiert. Das ersetzt NICHT die echte serverseitige Autorisierung.
 */

const http = require('http');

const PORT = process.env.PORT ? Number(process.env.PORT) : 4010;

const manifest = {
  tenant: { id: 'demo', name: 'Demo GmbH' },
  modules: [
    { id: 'dashboard', type: 'native', title: 'Dashboard', icon: 'square.grid.2x2.fill', order: 10 },
    { id: 'crm', type: 'web', title: 'CRM', icon: 'person.2.fill', order: 20, url: 'https://demo.knoio.ai/crm', permissions: ['crm.read'] },
    { id: 'files', type: 'external', title: 'Dateien', icon: 'folder.fill', order: 30, url: 'https://seafile.demo.knoio.ai', provider: 'seafile' },
    { id: 'chat', type: 'external', title: 'Chat', icon: 'message.fill', order: 40, provider: 'matrix', homeserver: 'https://matrix.demo.knoio.ai', engine: 'native' },
  ],
};

function sendJSON(res, status, body) {
  const data = JSON.stringify(body);
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Content-Length': Buffer.byteLength(data),
  });
  res.end(data);
}

const server = http.createServer((req, res) => {
  const { method } = req;
  const path = (req.url || '').split('?')[0];

  console.log(`${method} ${path}`);

  if (method === 'GET' && path === '/healthz') {
    return sendJSON(res, 200, { status: 'ok' });
  }

  if (method === 'GET' && path === '/me/modules') {
    // Lokal: jedes/kein Token akzeptiert. In Produktion: echtes JWT prüfen.
    return sendJSON(res, 200, manifest);
  }

  sendJSON(res, 404, { error: 'not_found', message: `No handler for ${method} ${path}` });
});

server.listen(PORT, () => {
  console.log(`Knoio mock server läuft auf http://localhost:${PORT}`);
  console.log('  GET /me/modules   → Modul-Manifest');
  console.log('  GET /healthz      → Health-Check');
});
