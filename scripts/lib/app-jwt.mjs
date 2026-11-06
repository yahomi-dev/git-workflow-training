// GitHub App として API を呼ぶための JWT (RS256、有効 9 分) を標準出力に出す。scripts/bootstrap.sh が install の検知に使う。
//
// 使い方: node scripts/lib/app-jwt.mjs --app-id <App ID> --pem <秘密鍵のパス>
// 依存: node 18 以上。外部パッケージは使わない。
import { createSign } from "node:crypto";
import { readFileSync } from "node:fs";

const args = process.argv.slice(2);

const argValue = (name, fallback) => {
  const index = args.indexOf(name);

  return index >= 0 && index + 1 < args.length ? args[index + 1] : fallback;
};

const appId = argValue("--app-id", "");
const pemPath = argValue("--pem", "");

if (appId === "" || pemPath === "") {
  console.error("app-jwt: --app-id と --pem が必要です");
  process.exit(2);
}

const base64url = (text) => {
  return Buffer.from(text).toString("base64url");
};

const now = Math.floor(Date.now() / 1000);
const header = base64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
const payload = base64url(JSON.stringify({ iat: now - 60, exp: now + 540, iss: appId }));
const signature = createSign("RSA-SHA256").update(`${header}.${payload}`).sign(readFileSync(pemPath, "utf8"), "base64url");

process.stdout.write(`${header}.${payload}.${signature}\n`);
