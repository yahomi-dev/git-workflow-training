// セーブデータ (ブラウザの localStorage)。「はじめから」で作り直し、「続きから」で読む。
// 中身: 完了条件のチェック、クエストごとのメモ、開始日時。GitHub 側の状態は保存しない (毎回取り直す)。

export const SAVE_KEY = "hidamari-quest-save-v1";

export const emptySave = (now) => {
  return { version: 1, startedAt: now, checks: {}, memo: {} };
};

export const loadSave = (storage) => {
  const raw = storage.getItem(SAVE_KEY);

  if (raw === null) {
    return undefined;
  }

  try {
    const parsed = JSON.parse(raw);

    return parsed && parsed.version === 1 ? parsed : undefined;
  } catch {
    return undefined;
  }
};

export const writeSave = (storage, save) => {
  storage.setItem(SAVE_KEY, JSON.stringify(save));

  return save;
};

export const clearSave = (storage) => {
  storage.removeItem(SAVE_KEY);
};

export const withCheck = (save, nn, index, value) => {
  const current = save.checks[nn] ?? [];
  const padded = Array.from({ length: Math.max(current.length, index + 1) }, (_, i) => current[i] ?? false);
  const next = padded.with(index, value);

  return { ...save, checks: { ...save.checks, [nn]: next } };
};

export const withChecksLength = (save, nn, length) => {
  const current = save.checks[nn] ?? [];
  const next = Array.from({ length }, (_, i) => current[i] ?? false);

  return { ...save, checks: { ...save.checks, [nn]: next } };
};

export const withMemo = (save, nn, text) => {
  return { ...save, memo: { ...save.memo, [nn]: text } };
};
