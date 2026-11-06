// ゲーム画面のロジックを、ブラウザなしで本物のリポジトリに対して確かめる (保守用)。
//
// 使い方: node scripts/web-check.mjs [owner/repo]
// 出すもの: クエスト一覧とメタ、自動判定の済、状態、NPC の動き、Mermaid gitGraph のテキスト。
// 認証なしの API を 8〜12 回呼ぶ (rate limit は 60 回/時)。
import { createClient, loadRepoState } from "../web/lib/github.mjs";
import { buildGitGraph } from "../web/lib/gitgraph.mjs";
import { currentQuest, detectAutoDone, npcActivity, questStatuses } from "../web/lib/progress.mjs";
import { parsePlatform, prepareQuest } from "../web/lib/quests.mjs";
import { readFileSync } from "node:fs";

const [owner, repo] = (process.argv[2] ?? "yahomi-dev/git-workflow-training").split("/");
const client = createClient({ owner, repo });

const repoState = await loadRepoState(client);
const kitConf = await client.getText("kit.conf").catch(() => "PLATFORM=github");
const platform = parsePlatform(kitConf);
const terms = JSON.parse(readFileSync(new URL(`../web/terms/${platform}.json`, import.meta.url), "utf8"));
const markdowns = await Promise.all(repoState.exerciseFiles.map((name) => client.getText(`exercises/${name}`)));
const quests = repoState.exerciseFiles.map((fileName, index) =>
  prepareQuest({ fileName, markdown: markdowns[index], platform, terms, htmlUrl: client.htmlUrl }),
);

const autoDone = detectAutoDone(repoState);
const statuses = questStatuses({ quests, autoDone, manualDone: {}, pulls: repoState.pulls, branches: repoState.branches });

console.log(`platform: ${platform}`);
console.log("quests:");
statuses.forEach((quest) => {
  const leftover = (quest.quest.match(/\{\{[a-z_]+\}\}/g) ?? []).join(" ");
  console.log(`  ${quest.nn} ${quest.status.padEnd(6)} week=${quest.week} ${quest.title} (quest ${quest.quest.length} 字, notes ${quest.notes.length} 字)${leftover ? ` 未置換: ${leftover}` : ""}`);
});
console.log(`current: ${currentQuest(statuses).title}`);
console.log(`auto done: ${[...autoDone].join(", ") || "(none)"}`);
console.log(`branches: ${repoState.branches.join(", ") || "(none)"}`);
console.log(`open pulls: ${repoState.pulls.filter((pull) => pull.state === "open").map((pull) => `#${pull.number}`).join(", ") || "(none)"}`);
console.log("npc activity:");
npcActivity(repoState).forEach((item) => console.log(`  ${item.at} ${item.text}`));
console.log("gitGraph:");
console.log(buildGitGraph({ mainCommits: repoState.mainCommits, branches: repoState.compares, tags: repoState.tags }));
console.log(`rate remaining: ${client.rate.remaining}`);
