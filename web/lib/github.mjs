// GitHub REST API (認証なし、public リポジトリ) と raw.githubusercontent.com の薄いクライアント。
// ETag で条件付き取得にし、304 は rate limit を消費しないようにする。

const etagCache = new Map();

/**
 * リポジトリの owner / repo を決める。優先順: ?repo=owner/name -> GitHub Pages の URL -> 既定値。
 */
export const detectRepo = ({ hostname, pathname, search }, fallback) => {
  const params = new URLSearchParams(search);
  const fromQuery = params.get("repo");

  if (fromQuery && fromQuery.includes("/")) {
    const [owner, repo] = fromQuery.split("/");

    return { owner, repo };
  }

  if (hostname.endsWith(".github.io")) {
    const owner = hostname.split(".")[0];
    const repo = pathname.split("/").filter((part) => part !== "")[0];

    if (repo) {
      return { owner, repo };
    }
  }

  return fallback;
};

export const createClient = ({ owner, repo, fetchImpl = globalThis.fetch }) => {
  const apiBase = `https://api.github.com/repos/${owner}/${repo}`;
  const rawBase = `https://raw.githubusercontent.com/${owner}/${repo}/main`;
  const rate = { remaining: undefined, reset: undefined };

  const getJson = async (path) => {
    const url = `${apiBase}${path}`;
    const cached = etagCache.get(url);
    const headers = {
      accept: "application/vnd.github+json",
      ...(cached ? { "if-none-match": cached.etag } : {}),
    };
    const response = await fetchImpl(url, { headers });
    const remaining = response.headers.get("x-ratelimit-remaining");
    const reset = response.headers.get("x-ratelimit-reset");

    if (remaining !== null) {
      rate.remaining = Number(remaining);
    }

    if (reset !== null) {
      rate.reset = new Date(Number(reset) * 1000);
    }

    if (response.status === 304 && cached) {
      return cached.data;
    }

    if (!response.ok) {
      throw new Error(`GitHub API ${response.status}: ${path}`);
    }

    const data = await response.json();
    const etag = response.headers.get("etag");

    if (etag) {
      etagCache.set(url, { etag, data });
    }

    return data;
  };

  const getText = async (path) => {
    const response = await fetchImpl(`${rawBase}/${path}`, { cache: "no-store" });

    if (!response.ok) {
      throw new Error(`raw ${response.status}: ${path}`);
    }

    return response.text();
  };

  return { owner, repo, rate, getJson, getText, htmlUrl: `https://github.com/${owner}/${repo}` };
};

/**
 * ゲーム画面に要るデータをまとめて取る。
 * API 呼び出し: branches 1、tags 1、pulls 1、commits 1、compare (枝ごと 1)、reviews (NPC の PR ごと 1)、contents 1。
 */
export const loadRepoState = async (client) => {
  const [branches, tags, pulls, mainCommits, exerciseFiles] = await Promise.all([
    client.getJson("/branches?per_page=100"),
    client.getJson("/tags?per_page=100"),
    client.getJson("/pulls?state=all&per_page=100&sort=updated&direction=desc"),
    client.getJson("/commits?sha=main&per_page=12"),
    client.getJson("/contents/exercises"),
  ]);

  const sideBranches = branches.filter((branch) => branch.name !== "main");
  const compares = await Promise.all(
    sideBranches.map(async (branch) => {
      const compare = await client.getJson(`/compare/main...${encodeURIComponent(branch.name)}`);

      return {
        name: branch.name,
        mergeBaseSha: compare.merge_base_commit.sha,
        commits: compare.commits.map((commit) => ({ sha: commit.sha, message: commit.commit.message })),
      };
    }),
  );

  const npcPulls = pulls.filter((pull) => isBot(pull.user) || pull.labels.some((label) => label.name === "npc"));
  const reviewsByPull = await Promise.all(
    npcPulls.map(async (pull) => {
      const reviews = await client.getJson(`/pulls/${pull.number}/reviews?per_page=100`);

      return reviews.map((review) => ({ ...review, pullNumber: pull.number }));
    }),
  );

  return {
    branches: sideBranches.map((branch) => branch.name),
    tags: tags.map((tag) => ({ name: tag.name, sha: tag.commit.sha })),
    pulls,
    mainCommits: mainCommits
      .map((commit) => ({
        sha: commit.sha,
        message: commit.commit.message,
        author: commit.author?.login ?? commit.commit.author?.name ?? "",
        date: commit.commit.author?.date,
      }))
      .toReversed(),
    compares,
    npcReviews: reviewsByPull.flat(),
    exerciseFiles: exerciseFiles
      .filter((file) => /^\d{2}-.*\.md$/.test(file.name))
      .map((file) => file.name)
      .toSorted(),
  };
};

export const isBot = (user) => {
  return Boolean(user) && (user.type === "Bot" || String(user.login).endsWith("[bot]"));
};
