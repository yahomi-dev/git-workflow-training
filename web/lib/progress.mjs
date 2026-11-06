// 進捗の判定 (純粋関数)。GitHub の状態 (PR、レビュー、タグ、枝) とブラウザの保存から、各クエストの状態を決める。
import { isBot } from "./github.mjs";

export const QUEST_BRANCH = /^quest\/(\d{2})-/;

/** PR が無いので、ゲーム画面のチェックで済にするクエスト */
export const MANUAL_QUESTS = ["01", "02", "11", "12"];

/**
 * GitHub の状態から自動で「済」と分かるクエスト番号の集合。
 *  - quest/NN-* の PR がマージ -> NN
 *  - hotfix/* の PR がマージ + タグ v1.0.0 と v1.0.1 -> 10
 *  - NPC の PR に人が Request changes -> 08
 */
export const detectAutoDone = ({ pulls, npcReviews, tags }) => {
  const merged = pulls.filter((pull) => pull.merged_at);
  const fromQuestBranches = merged
    .map((pull) => pull.head.ref.match(QUEST_BRANCH))
    .filter((match) => match !== null)
    .map((match) => match[1]);
  const hotfixMerged = merged.some((pull) => pull.head.ref.startsWith("hotfix/"));
  const tagNames = new Set(tags.map((tag) => tag.name));
  const hotfixDone = hotfixMerged && tagNames.has("v1.0.0") && tagNames.has("v1.0.1");
  const npcReviewed = npcReviews.some((review) => review.state === "CHANGES_REQUESTED" && !isBot(review.user));

  return new Set([...fromQuestBranches, ...(hotfixDone ? ["10"] : []), ...(npcReviewed ? ["08"] : [])]);
};

/**
 * クエストごとの状態: done / active / todo。
 * active = 未完了で、quest/NN-* の枝か open の PR がある。
 */
export const questStatuses = ({ quests, autoDone, manualDone, pulls, branches }) => {
  const openHeads = pulls.filter((pull) => pull.state === "open").map((pull) => pull.head.ref);

  return quests.map((quest) => {
    const done = autoDone.has(quest.nn) || manualDone[quest.nn] === true;
    const touched = [...openHeads, ...branches].some((ref) => ref.startsWith(`quest/${quest.nn}-`));
    const status = done ? "done" : touched ? "active" : "todo";

    return { ...quest, status, auto: !MANUAL_QUESTS.includes(quest.nn) };
  });
};

export const currentQuest = (statuses) => {
  return statuses.find((quest) => quest.status !== "done") ?? statuses[statuses.length - 1];
};

/** 完了条件のチェックが全部付いたら、そのクエストは手動で済 */
export const manualDoneFromChecks = (checks, questCount) => {
  return Object.fromEntries(
    Object.entries(checks).map(([nn, flags]) => [nn, flags.length > 0 && flags.every(Boolean)]),
  );
};

/** NPC の動き (新しい順): main への commit、NPC の PR、NPC のレビュー */
export const npcActivity = ({ mainCommits, pulls, npcReviews }) => {
  const commits = mainCommits
    .filter((commit) => commit.author.endsWith("[bot]"))
    .map((commit) => ({ at: commit.date, text: `main に commit: ${firstLine(commit.message)}` }));
  const npcPulls = pulls
    .filter((pull) => isBot(pull.user))
    .map((pull) => ({ at: pull.created_at, text: `PR #${pull.number} を開いた: ${pull.title}` }));
  const reviews = npcReviews
    .filter((review) => isBot(review.user) && review.body)
    .map((review) => ({ at: review.submitted_at, text: `PR #${review.pullNumber} にレビュー: ${firstLine(review.body)}` }));

  return [...commits, ...npcPulls, ...reviews]
    .filter((item) => item.at)
    .toSorted((a, b) => (a.at < b.at ? 1 : -1))
    .slice(0, 8);
};

export const firstLine = (text) => {
  return String(text).split("\n")[0];
};
