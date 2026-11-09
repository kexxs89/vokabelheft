// Offline-Modus für die Webversion. Bei Änderungen an Dateien VERSION hochzählen.
const VERSION = "v2";
const CACHE = "vokabelheft-" + VERSION;
const FILES = [
  "./",
  "index.html",
  "runner.html",
  "manifest.webmanifest",
  "fonts/Andika-400.woff2",
  "fonts/Andika-700.woff2",
  "fonts/LilitaOne-400.woff2",
  "fonts/PatrickHand-400.woff2",
  "icons/icon-192.png",
  "icons/icon-512.png",
  "icons/apple-touch-icon.png"
];

self.addEventListener("install", e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(FILES)).then(() => self.skipWaiting()));
});

self.addEventListener("activate", e => {
  e.waitUntil(caches.keys()
    .then(keys => Promise.all(keys.filter(k => k.startsWith("vokabelheft-") && k !== CACHE).map(k => caches.delete(k))))
    .then(() => self.clients.claim()));
});

self.addEventListener("fetch", e => {
  const req = e.request;
  // Nur eigene Dateien; die Wörterliste (Gist) lädt die Seite selbst und merkt sie sich in localStorage
  if (req.method !== "GET" || new URL(req.url).origin !== location.origin) return;
  if (req.mode === "navigate") {
    // Seite: erst Internet (damit Updates ankommen), sonst gespeicherte Version
    e.respondWith(fetch(req).then(r => {
      if (r.ok) { const copy = r.clone(); caches.open(CACHE).then(c => c.put(req, copy)); }
      return r;
    }).catch(() => caches.match(req, {ignoreSearch: true}).then(hit => hit || caches.match("index.html"))));
    return;
  }
  // Schriften, Icons: aus dem Speicher
  e.respondWith(caches.match(req).then(hit => hit || fetch(req)));
});
