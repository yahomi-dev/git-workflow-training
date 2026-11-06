// GitHub App を Manifest フローで作るための受け口。scripts/bootstrap.sh が呼ぶ。
//
// 1. 127.0.0.1:<port>/ を開くと、manifest を GitHub (settings/apps/new) へ POST するフォームが自動送信される
// 2. 人がブラウザで「Create GitHub App」を押すと、GitHub が /callback?code=... へ戻す
// 3. code を POST /app-manifests/{code}/conversions で交換し、App の id / slug / pem を標準出力に JSON で出す
//
// 使い方: node scripts/lib/app-manifest.mjs --manifest <manifest.json> --port <番号>
// 環境変数: GH_TOKEN (任意。交換の API に付ける)
// 依存: node 18 以上 (fetch)。外部パッケージは使わない。
import http from "node:http";
import { randomBytes } from "node:crypto";
import { readFileSync } from "node:fs";

const args = process.argv.slice(2);

const argValue = (name, fallback) => {
  const index = args.indexOf(name);

  return index >= 0 && index + 1 < args.length ? args[index + 1] : fallback;
};

const manifestPath = argValue("--manifest", "");
const port = Number(argValue("--port", "8787"));
const token = process.env.GH_TOKEN ?? "";

if (manifestPath === "") {
  console.error("app-manifest: --manifest <manifest.json> が必要です");
  process.exit(2);
}

const manifest = JSON.parse(readFileSync(manifestPath, "utf8"));
const state = randomBytes(16).toString("hex");
const redirectUrl = `http://127.0.0.1:${port}/callback`;
const manifestToSend = { ...manifest, redirect_url: redirectUrl };

const escapeHtml = (text) => {
  return text.replace(/[&<>"']/g, (c) => {
    return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c];
  });
};

const page = (body) => {
  return `<!DOCTYPE html><html lang="ja"><head><meta charset="utf-8"><title>NPC の GitHub App</title></head><body style="font-family: sans-serif; padding: 2rem; line-height: 1.7">${body}</body></html>`;
};

const formPage = () => {
  const action = `https://github.com/settings/apps/new?state=${state}`;
  const value = escapeHtml(JSON.stringify(manifestToSend));

  return page(
    `<p>GitHub に移動します。開いたページで <b>Create GitHub App</b> を押してください。</p>` +
      `<form id="manifest-form" method="post" action="${action}">` +
      `<input type="hidden" name="manifest" value="${value}">` +
      `<button type="submit">GitHub で App を作る</button></form>` +
      `<script>document.getElementById("manifest-form").submit();</script>`,
  );
};

const convert = async (code) => {
  const headers = {
    accept: "application/vnd.github+json",
    "user-agent": "git-workflow-training-bootstrap",
    ...(token !== "" ? { authorization: `Bearer ${token}` } : {}),
  };
  const response = await fetch(`https://api.github.com/app-manifests/${encodeURIComponent(code)}/conversions`, {
    method: "POST",
    headers,
  });

  if (!response.ok) {
    return { ok: false, status: response.status, body: await response.text() };
  }

  return { ok: true, app: await response.json() };
};

const server = http.createServer(async (request, response) => {
  const url = new URL(request.url ?? "/", `http://127.0.0.1:${port}`);

  if (url.pathname === "/") {
    response.writeHead(200, { "content-type": "text/html; charset=utf-8" });
    response.end(formPage());

    return;
  }

  if (url.pathname === "/callback") {
    const code = url.searchParams.get("code") ?? "";
    const returnedState = url.searchParams.get("state") ?? "";

    if (code === "" || returnedState !== state) {
      response.writeHead(400, { "content-type": "text/html; charset=utf-8" });
      response.end(page("<p>state が一致しません。ターミナルで bootstrap をやり直してください。</p>"));

      return;
    }

    const result = await convert(code);

    if (!result.ok) {
      response.writeHead(500, { "content-type": "text/html; charset=utf-8" });
      response.end(page("<p>App の情報を受け取れませんでした。ターミナルのエラーを見てください。</p>"));
      console.error(`app-manifest: conversions が ${result.status}: ${result.body}`);
      server.close();
      process.exitCode = 1;

      return;
    }

    const app = result.app;
    response.writeHead(200, { "content-type": "text/html; charset=utf-8" });
    response.end(page(`<p>App <b>${escapeHtml(String(app.slug))}</b> を作りました。ターミナルに戻ってください。このタブは閉じてよいです。</p>`));
    process.stdout.write(`${JSON.stringify({ id: app.id, slug: app.slug, html_url: app.html_url, pem: app.pem })}\n`);
    server.close();

    return;
  }

  response.writeHead(404);
  response.end();
});

server.listen(port, "127.0.0.1", () => {
  process.stderr.write(`app-manifest: http://127.0.0.1:${port}/ を待っています\n`);
});

const timeout = setTimeout(() => {
  console.error("app-manifest: 15 分待っても戻ってこなかったので止めます");
  server.close();
  process.exitCode = 1;
}, 15 * 60 * 1000);
timeout.unref();
