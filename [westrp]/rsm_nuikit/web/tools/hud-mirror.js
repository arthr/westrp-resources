// Só na prévia do navegador (vite dev): serve a interface já compilada do
// rsm_hud em <base>hud-mirror/, para o estúdio mostrar o HUD de verdade no
// modo espelho. No jogo nada disso é usado: o estúdio abre a página do próprio
// rsm_hud (https://cfx-nui-<resource>/...). Procura o rsm_hud dentro deste
// projeto ou ao lado dele, na pasta de resources.
import fs from "node:fs";
import path from "node:path";

const TYPES = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".json": "application/json",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".webp": "image/webp",
  ".svg": "image/svg+xml",
  ".woff2": "font/woff2",
  ".woff": "font/woff",
  ".ttf": "font/ttf",
};

export default function hudMirror({ mount = "hud-mirror/", candidates = ["../rsm_hud/web/dist", "../../rsm_hud/web/dist"] } = {}) {
  return {
    name: "rsm-hud-mirror",
    apply: "serve",
    configureServer(server) {
      const root = server.config.root;
      const dist = candidates.map((c) => path.resolve(root, c)).find((d) => fs.existsSync(path.join(d, "index.html")));
      if (!dist) return;
      const base = server.config.base || "/";
      server.middlewares.use((req, res, next) => {
        let url = (req.url || "").split("?")[0];
        if (url.startsWith(base)) url = `/${url.slice(base.length)}`;
        if (!url.startsWith(`/${mount}`)) return next();
        const rel = decodeURIComponent(url.slice(mount.length + 1)) || "index.html";
        const file = path.resolve(dist, rel);
        if (!file.startsWith(dist + path.sep) || !fs.existsSync(file) || !fs.statSync(file).isFile()) return next();
        res.setHeader("Content-Type", TYPES[path.extname(file).toLowerCase()] || "application/octet-stream");
        res.setHeader("Cache-Control", "no-store");
        fs.createReadStream(file).pipe(res);
      });
    },
  };
}
