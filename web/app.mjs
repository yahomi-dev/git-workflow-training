// ゲーム画面の DOM まわり。データの取得は lib/github.mjs、判定は lib/progress.mjs、描画の材料は lib/*.mjs の純粋関数。
import { marked } from "https://cdn.jsdelivr.net/npm/marked@12.0.2/lib/marked.esm.js";
import mermaid from "https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs";
import { createClient, detectRepo, loadRepoState } from "./lib/github.mjs";
import { buildGitGraph } from "./lib/gitgraph.mjs";
import { currentQuest, detectAutoDone, manualDoneFromChecks, npcActivity, questStatuses } from "./lib/progress.mjs";
import { parsePlatform, prepareQuest } from "./lib/quests.mjs";
import { clearSave, emptySave, loadSave, withCheck, withChecksLength, withMemo, writeSave } from "./lib/save.mjs";

const DEFAULT_REPO = { owner: "yahomi-dev", repo: "git-workflow-training" };
const REFRESH_MS = 120_000;

const byId = (id) => document.getElementById(id);

const repo = detectRepo(window.location, DEFAULT_REPO);
const client = createClient(repo);
const storage = window.localStorage;

mermaid.initialize({ startOnLoad: false, theme: "neutral", gitGraph: { mainBranchName: "main", showCommitLabel: true } });

// 画面の状態 (読み取り専用の値として持ち、更新は関数で作り直す)
const state = {
  save: undefined,
  quests: [],
  statuses: [],
  repoState: undefined,
  selected: undefined,
};

const setState = (patch) => {
  Object.assign(state, patch);
};

const formatTime = (iso) => {
  const date = new Date(iso);

  return `${String(date.getMonth() + 1).padStart(2, "0")}/${String(date.getDate()).padStart(2, "0")} ${String(date.getHours()).padStart(2, "0")}:${String(date.getMinutes()).padStart(2, "0")}`;
};

// ---- データ -------------------------------------------------------------------------

const loadQuests = async (repoState) => {
  const [kitConf, ...markdowns] = await Promise.all([
    client.getText("kit.conf").catch(() => "PLATFORM=github"),
    ...repoState.exerciseFiles.map((name) => client.getText(`exercises/${name}`)),
  ]);
  const platform = parsePlatform(kitConf);
  const terms = await fetch(`./terms/${platform}.json`).then((response) => response.json());

  return repoState.exerciseFiles.map((fileName, index) =>
    prepareQuest({ fileName, markdown: markdowns[index], platform, terms, htmlUrl: client.htmlUrl }),
  );
};

const recompute = () => {
  const autoDone = detectAutoDone(state.repoState);
  const manualDone = manualDoneFromChecks(state.save.checks);
  const statuses = questStatuses({
    quests: state.quests,
    autoDone,
    manualDone,
    pulls: state.repoState.pulls,
    branches: state.repoState.branches,
  });
  setState({ statuses, selected: state.selected ?? currentQuest(statuses).nn });
};

const refresh = async () => {
  byId("refresh-button").disabled = true;

  try {
    const repoState = await loadRepoState(client);
    const quests = state.quests.length > 0 ? state.quests : await loadQuests(repoState);
    setState({ repoState, quests });
    recompute();
    render();
  } catch (error) {
    byId("progress-summary").textContent = `読み込みに失敗: ${error.message}`;
  } finally {
    byId("refresh-button").disabled = false;
  }
};

// ---- 描画 ---------------------------------------------------------------------------

const render = () => {
  renderSummary();
  renderQuestList();
  renderQuest();
  renderActivity();
  renderPulls();
  renderTree();
  renderRate();
};

const renderSummary = () => {
  const done = state.statuses.filter((quest) => quest.status === "done").length;
  const current = currentQuest(state.statuses);
  byId("progress-summary").textContent = `進行 ${done} / ${state.statuses.length}。いまここ: ${current.title}`;
};

const renderQuestList = () => {
  const list = byId("quest-list");
  const current = currentQuest(state.statuses);
  const marks = { done: "済", active: "作業中", todo: "" };
  list.replaceChildren(
    ...state.statuses.map((quest) => {
      const item = document.createElement("li");
      item.dataset.status = quest.status;
      item.dataset.current = String(quest.nn === current.nn);
      const mark = document.createElement("span");
      mark.className = "quest-mark";
      mark.textContent = quest.status === "done" ? "✓" : quest.nn === current.nn ? "▶" : "";
      const button = document.createElement("button");
      button.type = "button";
      button.textContent = `${quest.title}${marks[quest.status] ? ` (${marks[quest.status]})` : ""}`;
      button.addEventListener("click", () => {
        setState({ selected: quest.nn });
        render();
      });
      item.append(mark, button);

      return item;
    }),
  );
};

const renderQuest = () => {
  const quest = state.statuses.find((q) => q.nn === state.selected) ?? currentQuest(state.statuses);
  byId("quest-week").textContent = quest.week ? `第 ${quest.week} 週` : "";
  byId("quest-title").textContent = quest.title;
  byId("quest-status").textContent =
    quest.status === "done"
      ? "済"
      : quest.auto
        ? "PR がマージされると自動で済になる (10 はタグまで、08 は Request changes で)"
        : "完了条件のチェックを全部付けると済になる";

  const body = byId("quest-body");
  body.innerHTML = marked.parse(quest.quest);
  wireChecks(body, quest.nn);
  byId("quest-notes").innerHTML = marked.parse(quest.notes);

  const memo = byId("memo-field");
  memo.value = state.save.memo[quest.nn] ?? "";
  memo.oninput = () => {
    setState({ save: writeSave(storage, withMemo(state.save, quest.nn, memo.value)) });
  };

  const index = state.statuses.findIndex((q) => q.nn === quest.nn);
  byId("prev-quest").disabled = index <= 0;
  byId("next-quest").disabled = index >= state.statuses.length - 1;
  byId("prev-quest").onclick = () => {
    setState({ selected: state.statuses[index - 1].nn });
    render();
  };
  byId("next-quest").onclick = () => {
    setState({ selected: state.statuses[index + 1].nn });
    render();
  };
};

// 完了条件の - [ ] を押せるチェックにして、保存する
const wireChecks = (body, nn) => {
  const boxes = [...body.querySelectorAll('input[type="checkbox"]')];
  const save = withChecksLength(state.save, nn, boxes.length);
  setState({ save: writeSave(storage, save) });
  boxes.forEach((box, index) => {
    box.disabled = false;
    box.checked = save.checks[nn][index] === true;
    box.addEventListener("change", () => {
      setState({ save: writeSave(storage, withCheck(state.save, nn, index, box.checked)) });
      recompute();
      renderSummary();
      renderQuestList();
      byId("quest-status").textContent = state.statuses.find((q) => q.nn === nn).status === "done" ? "済" : byId("quest-status").textContent;
    });
  });
};

const renderActivity = () => {
  const items = npcActivity(state.repoState);
  byId("activity-list").replaceChildren(
    ...(items.length === 0
      ? [textItem("まだ動いていない")]
      : items.map((item) => {
          const li = document.createElement("li");
          const time = document.createElement("span");
          time.className = "activity-time";
          time.textContent = formatTime(item.at);
          li.append(time, document.createTextNode(item.text));

          return li;
        })),
  );
};

const renderPulls = () => {
  const open = state.repoState.pulls.filter((pull) => pull.state === "open");
  byId("pr-list").replaceChildren(
    ...(open.length === 0
      ? [textItem("なし")]
      : open.map((pull) => {
          const li = document.createElement("li");
          const link = document.createElement("a");
          link.href = pull.html_url;
          link.target = "_blank";
          link.rel = "noopener";
          link.textContent = `#${pull.number} ${pull.title}`;
          li.append(link, document.createTextNode(` (${pull.head.ref})${pull.draft ? " 下書き" : ""}`));

          return li;
        })),
  );
};

const renderTree = async () => {
  const text = buildGitGraph({
    mainCommits: state.repoState.mainCommits,
    branches: state.repoState.compares,
    tags: state.repoState.tags,
  });

  try {
    const { svg } = await mermaid.render(`tree-${Date.now()}`, text);
    byId("tree").innerHTML = svg;
  } catch (error) {
    byId("tree").textContent = `木を描けませんでした: ${error.message}`;
  }

  byId("tree-foot").textContent = `main の直近 ${state.repoState.mainCommits.length} コミットと、枝 ${state.repoState.compares.length} 本`;
};

const renderRate = () => {
  const { remaining, reset } = client.rate;
  byId("rate-note").textContent =
    remaining === undefined
      ? ""
      : `GitHub API の残り回数 ${remaining} (${reset ? formatTime(reset.toISOString()) : ""} に回復)。2 分ごとに自動更新。`;
};

const textItem = (text) => {
  const li = document.createElement("li");
  li.textContent = text;

  return li;
};

// ---- 画面の切り替え (はじめから / 続きから) ------------------------------------------------

const showStart = () => {
  const existing = loadSave(storage);
  byId("start-continue").hidden = existing === undefined;
  byId("start-note").textContent = existing
    ? `前回の保存: ${formatTime(existing.startedAt)} に開始。「はじめから」はこのブラウザの保存 (チェックとメモ) を消します。GitHub 側の砂場を戻すのは進行役が scripts/reset.sh で行います。`
    : "保存はこのブラウザだけに残ります。";
  byId("start-screen").hidden = false;
  byId("game").hidden = true;
};

const startGame = (save) => {
  setState({ save: writeSave(storage, save), selected: undefined });
  byId("start-screen").hidden = true;
  byId("game").hidden = false;
  refresh();
};

const boot = () => {
  byId("repo-link").href = client.htmlUrl;
  byId("footer-repo-link").href = client.htmlUrl;
  byId("footer-repo-link").textContent = `${repo.owner}/${repo.repo}`;
  byId("start-new").addEventListener("click", () => {
    const existing = loadSave(storage);

    if (existing && !window.confirm("このブラウザの保存 (チェックとメモ) を消して、はじめから始めます。よいですか")) {
      return;
    }

    clearSave(storage);
    startGame(emptySave(new Date().toISOString()));
  });
  byId("start-continue").addEventListener("click", () => startGame(loadSave(storage)));
  byId("refresh-button").addEventListener("click", () => refresh());
  byId("restart-button").addEventListener("click", () => showStart());
  window.setInterval(() => {
    if (!byId("game").hidden) {
      refresh();
    }
  }, REFRESH_MS);
  showStart();
};

boot();
