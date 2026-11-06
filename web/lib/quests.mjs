// 演習ファイル (exercises/NN-*.md) をゲーム画面向けに整える (純粋関数)。
// scripts/render.sh と同じ規則: メタ、セクション (quest / notes)、platform ブロック、{{用語}}、相対リンク。

/** 先頭の <!-- kit ... --> から title / week を読む */
export const parseMeta = (markdown) => {
  const match = markdown.match(/<!-- kit\n([\s\S]*?)\n-->/);
  const lines = match ? match[1].split("\n") : [];
  const entries = lines
    .map((line) => line.match(/^([a-z_]+):\s*(.*)$/))
    .filter((m) => m !== null)
    .map((m) => [m[1], m[2]]);

  return Object.fromEntries(entries);
};

/** <!-- name:start --> と <!-- name:end --> の間を返す (quest は旧名 issue も受ける) */
export const extractSection = (markdown, name) => {
  const names = name === "quest" ? ["quest", "issue"] : [name];
  const found = names
    .map((n) => markdown.match(new RegExp(`<!-- ${n}:start -->\\n?([\\s\\S]*?)<!-- ${n}:end -->`)))
    .find((m) => m !== null);

  return found ? found[1] : "";
};

/** 指定プラットフォームのブロックだけ残し、マーカー行を消す */
export const selectPlatform = (markdown, platform) => {
  return markdown
    .replace(/<!-- platform:([a-z]+) -->\n([\s\S]*?)<!-- \/platform -->\n?/g, (_, name, body) => (name === platform ? body : ""))
    .replace(/<!-- platform:[a-z]+ -->\n?|<!-- \/platform -->\n?/g, "");
};

/** {{key}} を terms の値で置き換える */
export const applyTerms = (markdown, terms) => {
  return markdown.replace(/\{\{([a-z_]+)\}\}/g, (whole, key) => (key in terms ? terms[key] : whole));
};

/** ../docs/x.md や docs/x.md のような相対リンクを GitHub の blob URL にする */
export const fixLinks = (markdown, htmlUrl) => {
  return markdown.replace(/\]\((?:\.\.\/)?((?:docs|site|npc|scripts|exercises|\.github)\/)/g, `](${htmlUrl}/blob/main/$1`);
};

/** 1 ファイルを { nn, slug, title, week, quest, notes } にする */
export const prepareQuest = ({ fileName, markdown, platform, terms, htmlUrl }) => {
  const nn = fileName.slice(0, 2);
  const slug = fileName.replace(/^\d{2}-/, "").replace(/\.md$/, "");
  const substituted = applyTerms(selectPlatform(markdown, platform), terms);
  const meta = parseMeta(substituted);

  return {
    nn,
    slug,
    title: meta.title ?? `quest-${nn}`,
    week: meta.week ?? "",
    quest: fixLinks(extractSection(substituted, "quest"), htmlUrl),
    notes: fixLinks(extractSection(substituted, "notes"), htmlUrl),
  };
};

/** kit.conf の PLATFORM= を読む (無ければ github) */
export const parsePlatform = (kitConf) => {
  const match = String(kitConf).match(/^PLATFORM=([a-z]+)/m);

  return match ? match[1] : "github";
};
