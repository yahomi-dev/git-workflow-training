// main と未マージの枝から Mermaid の gitGraph テキストを作る (純粋関数)。
// 規則: main の直近コミットを本線に並べ、枝は merge-base の位置から出し、タグと main の先端に印を付ける。

const shortSha = (sha) => sha.slice(0, 7);

const safeLabel = (message) => {
  const line = String(message).split("\n")[0].replace(/["\\`]/g, "");

  return line.length > 24 ? `${line.slice(0, 24)}...` : line;
};

const safeBranchName = (name) => {
  return name.replace(/[^A-Za-z0-9_-]/g, "-");
};

/**
 * @param mainCommits 古い -> 新しい順
 * @param branches [{ name, mergeBaseSha, commits: [{ sha, message }] }]
 * @param tags [{ name, sha }]
 */
export const buildGitGraph = ({ mainCommits, branches, tags }) => {
  if (mainCommits.length === 0) {
    return "gitGraph\n    commit id: \"(コミットなし)\"";
  }

  const first = mainCommits[0].sha;
  const last = mainCommits[mainCommits.length - 1].sha;
  const shown = new Set(mainCommits.map((commit) => commit.sha));
  const tagBySha = Object.fromEntries(tags.map((tag) => [tag.sha, tag.name]));
  const attachSha = (branch) => (shown.has(branch.mergeBaseSha) ? branch.mergeBaseSha : first);

  const branchLines = (branch) => {
    const name = safeBranchName(branch.name);
    const commits = branch.commits.slice(0, 8).map((commit) => `    commit id: "${shortSha(commit.sha)} ${safeLabel(commit.message)}"`);

    return [`    branch ${name}`, `    checkout ${name}`, ...commits, "    checkout main"];
  };

  const lines = mainCommits.flatMap((commit) => {
    const tag = tagBySha[commit.sha] ? ` tag: "${tagBySha[commit.sha]}"` : "";
    const highlight = commit.sha === last ? " type: HIGHLIGHT" : "";
    const own = `    commit id: "${shortSha(commit.sha)} ${safeLabel(commit.message)}"${tag}${highlight}`;
    const attached = branches.filter((branch) => attachSha(branch) === commit.sha).flatMap(branchLines);

    return [own, ...attached];
  });

  return ["gitGraph", ...lines].join("\n");
};
