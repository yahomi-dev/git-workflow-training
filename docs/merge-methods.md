# 4 つの動詞: squash / rebase / ff / merge commit

ブランチの変更を main に取り込むやり方は 4 つある。やり方ごとに main の履歴の見え方が変わる。
演習 07 で使う。この研修の既定は Squash and merge。現場に出たら方式を聞いて合わせる ([first-day-questions.md](first-day-questions.md))。

出発点はどれも同じ。main が C から D に進み、自分のブランチ quest は C から A、B と 2 コミット進んだ状態。

    main  : ... C - D
    quest :      \ A - B

## 1. squash: まとめる

A と B を 1 つのコミット S に潰して main の先頭に付ける。A と B そのものは main に入らない。

    main  : ... C - D - S

- 履歴の見え方: 1 PR (GitLab では MR) = 1 コミット。`git log --oneline` が PR の一覧のように読める
- 向く場面: 途中の試行錯誤 (typo 修正、`wip`) を main に残したくないとき。PR が小さいとき
- 注意: 元の A、B の SHA は消える。大きな変更を 1 コミットに潰すと、後で `git bisect` や `git blame` で追いにくい

## 2. rebase: 載せ替える

A、B を D の後ろに付け直す。中身は同じでも親が変わるので、SHA は A'、B' に変わる。

    main  : ... C - D - A' - B'

- 履歴の見え方: 一直線。コミットの粒度はそのまま残る
- 向く場面: コミットを意味のある単位に整えてあり、それを残したいとき
- 注意: SHA が変わる。push 済みのブランチを rebase したら `git push --force-with-lease` が要る。他人と共有しているブランチでは rebase しない

## 3. ff (fast-forward): 印を進めるだけ

main が C のまま進んでいなければ、新しいコミットを作らずに main の印 (ブランチの指す先) を B に動かすだけで済む。

    (D が無い場合)
    main  : ... C - A - B      <- main の印が C から B へ進んだだけ

- 履歴の見え方: 一直線。何も作らず、何も書き換えない
- 向く場面: main が進んでいないとき。rebase 済みのブランチを取り込むとき
- 注意: main が進んでいる (D がある) とできない。「ff できない」は「main が進んで自分のブランチが乖離した」の検知器になる

ff できるかはローカルで確かめられる。

    git fetch origin
    git merge-base --is-ancestor origin/main HEAD; echo $?

確かめ方: `0` なら ff できる (origin/main が自分の履歴の祖先にいる)。`1` なら main が進んでいる。`git rebase origin/main` してから再確認する。

ff そのものを体験するにはローカルで main に取り込む。

    git switch main && git merge --ff-only quest/07-xxx

確かめ方: `Fast-forward` と表示される。ff できないときは `fatal: Not possible to fast-forward, aborting.` で止まる (何も壊れない)。

## 4. merge commit: 合流点を作る

A、B はそのまま残し、D と B の両方を親に持つ合流コミット M を作る。

    main  : ... C - D ------- M
                   \ A - B --/

- 履歴の見え方: 分岐と合流が残る。`git log --graph` で「いつ枝分かれし、いつ戻ったか」が読める
- 向く場面: 枝分かれの事実を残したいとき (リリースブランチの統合など)。SHA を書き換えたくないとき
- 注意: PR が多いと `--graph` が読みにくい。`Merge pull request #NN` のコミットが PR の数だけ増える

## 似ているが別物: ローカルの `git rebase main` と「Rebase and merge」

| | ローカルの `git rebase main` | GitHub の Rebase and merge |
|---|---|---|
| 誰がやる | 自分。自分のブランチの上で | GitHub。PR をマージするボタンの 1 つ |
| 目的 | 衝突を解消し、自分のブランチを main の先端に付け直す | PR を main に取り込む方式の 1 つ |
| 結果 | 自分のブランチの SHA が変わる。`--force-with-lease` で push し直す | main に A'、B' が付く。ff できる状態でも SHA は書き換わる |

演習 07 では両方をやる。前者で衝突を直し、後者で取り込む。

## GitHub / GitLab の画面との対応

| 動詞 | GitHub (マージボタンの 3 択) | GitLab (プロジェクト設定 Merge method) |
|---|---|---|
| squash | Squash and merge | MR ごとの `Squash commits` チェックボックス。既定はプロジェクト設定 (Do not allow / Allow / Encourage / Require) |
| rebase | Rebase and merge | 方式としては無い。Fast-forward merge / semi-linear で ff できないとき、MR の `Rebase` ボタンで載せ替える |
| ff | ボタン無し。ローカルで `git merge --ff-only` | Fast-forward merge |
| merge commit | Create a merge commit | Merge commit。`Merge commit with semi-linear history` は「ff できる状態にしてから merge commit」 |

- GitHub の UI には純粋な ff のボタンは無い。Rebase and merge は ff できる状態でも新しい SHA を作る (committer 情報が変わる)
- GitLab の squash は「方式」ではなく MR ごとの選択。Fast-forward merge + Squash で「1 コミットを ff で入れる」もできる
- squash のコミットメッセージは既定で PR のタイトルと本文から作られる。PR 本文を丁寧に書く理由の 1 つ

## この研修での使い分け

- 既定は Squash and merge (演習 04、05、06、09、10)
- 演習 07: `git rebase main` で衝突を解消 -> ローカルで 1 コミットに squash (`git rebase -i origin/main`、または `git reset --soft origin/main` して commit し直す) -> `merge-base` で ff できることを確認 -> `--force-with-lease` で push -> Rebase and merge で取り込む
- 現場では方式を聞いて合わせる。squash が使えない現場ではローカルでコミットを整えてから push する。merge commit の現場では 1 コミットずつが読める粒度にする
