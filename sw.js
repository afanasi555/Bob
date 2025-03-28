// sw.js
const CACHE_NAME = 'audio-mini-app-cache-v1';
const urlsToCache = [
    '/',
    '/index.html',
    '/separation.html',
    '/mixing.html',
    '/conversion.html',
    '/editing.html',
    '/styles.css',
    '/script.js',
    'https://cdn.jsdelivr.net/pyodide/v0.23.4/full/pyodide.js',
    'https://cdn.jsdelivr.net/pyodide/v0.23.4/full/pyodide.asm.js',
    'https://cdn.jsdelivr.net/pyodide/v0.23.4/full/pyodide.asm.wasm',
    'https://cdn.jsdelivr.net/pyodide/v0.23.4/full/python_stdlib.zip',
    'https://cdn.jsdelivr.net/npm/@zip.js/zip.js/dist/zip.min.js',
    'https://cdnjs.cloudflare.com/ajax/libs/jszip/3.10.1/jszip.min.js'
];

self.addEventListener('install', event => {
    event.waitUntil(
        caches.open(CACHE_NAME)
            .then(cache => {
                return cache.addAll(urlsToCache);
            })
    );
});

self.addEventListener('fetch', event => {
    event.respondWith(
        caches.match(event.request)
            .then(response => {
                return response || fetch(event.request).then(fetchResponse => {
                    if (!fetchResponse || fetchResponse.status !== 200) {
                        return fetchResponse;
                    }
                    return caches.open(CACHE_NAME).then(cache => {
                        cache.put(event.request, fetchResponse.clone());
                        return fetchResponse;
                    });
                });
            })
    );
});

self.addEventListener('activate', event => {
    const cacheWhitelist = [CACHE_NAME];
    event.waitUntil(
        caches.keys().then(cacheNames => {
            return Promise.all(
                cacheNames.map(cacheName => {
                    if (!cacheWhitelist.includes(cacheName)) {
                        return caches.delete(cacheName);
                    }
                })
            );
        })
    );
});
