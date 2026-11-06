<!-- kit
title: quest-04: お知らせを 1 件追加する {{pr}} を出す
week: 1
-->
# quest-04: お知らせを 1 件追加する {{pr}} を出す

<!-- issue:start -->
## 状況

図書室の担当者から: 「お知らせの一番上に 1 件足してください。文言は『読み聞かせ会を毎月第 3 日曜 14:00 に開きます。』です。」

今回は {{pr}} の本文を 5 項目できちんと書き、同僚 (NPC) のレビューコメントに返すところまで通します。

## やること

1. **作業前に**、この Issue の完了条件を自分の言葉で 1 行にして、この Issue にコメントする
2. ブランチを切る

   ```bash
   git switch main
   git pull
   git switch -c quest/04-add-notice
   ```

3. `site/index.html` の `<ul class="news-list">` の **先頭** に 1 行足す

   ```html
   <li>読み聞かせ会を毎月第 3 日曜 14:00 に開きます。</li>
   ```

4. ブラウザで確認する。`explorer.exe .` で今のフォルダを Windows で開き、`site/index.html` をダブルクリック。お知らせが 3 件になっていれば OK
5. commit して push する

   ```bash
   git add site/index.html
   git commit -m "お知らせに読み聞かせ会の案内を追加する"
   git push -u origin quest/04-add-notice
   ```

6. {{pr_long}} を作る。{{pr_create}}
   - タイトル: `quest-04: お知らせに読み聞かせ会の案内を追加する`
   - 本文: テンプレートの 5 項目 (意図 / 変更内容 / 影響範囲 / 確認方法 / 相談したいこと) をすべて埋める。`Closes #<この Issue の番号>`
7. {{ci}} の `check` が緑になるのを待つ ({{ci_tab}})
8. 数分すると **同僚 (NPC) からコメントが 3 件** 付く。1 件ずつ読み、次のどれかで返す
   - 確認して合っていた -> その旨を返信し、{{resolve}}
   - 直した -> 修正を commit して push し、「直した」と返信して {{resolve}}
   - 直さない -> 理由を返信して {{resolve}}
   - 分からない -> `[Q]` を付けて質問する (進行役が答える)
9. 3 件とも片付いたら、進行役にレビューを依頼する
10. 進行役の {{approve}} が付いたら {{squash_merge}} でマージし、ローカルを掃除する

    ```bash
    git switch main
    git pull
    git branch -d quest/04-add-notice
    ```

## 完了条件

- [ ] 作業前に、完了条件を 1 行にしたコメントを Issue に書いた
- [ ] {{pr}} のタイトルが `quest-04:` で始まり、本文に 5 項目すべてと `Closes #` がある
- [ ] {{ci}} の `check` が緑
- [ ] NPC の 3 件すべてに返信し、{{resolve}} した
- [ ] 進行役の {{approve}} の後に {{squash_merge}} し、main のお知らせが 3 件になった
- [ ] ローカルの main を pull し、作業ブランチを消した

## 参考

- [{{platform}} での操作の 1 枚](../{{platform_doc}}) の「レビューの操作」
- [レビュー観点の ID](../docs/review-ids.md) (NPC のコメントに付いている `DESC-01` などの意味)

## 詰まったら

NPC のコメントの意味が分からないときは、そのスレッドに `[Q]` で質問を書く。進行役が返す。
<!-- issue:end -->

<!-- notes:start -->
## 進行役メモ

- NPC (b) は {{pr}} が開いた瞬間に 1 回だけ動く。`npc/quests/04/review/` の 3 件が、`site/index.html` へのファイル単位のレビューコメントとして付く (差分に無い場合は {{pr}} 全体へのコメント)
- 動かなかったとき: Actions の `npc-review` を見る。赤なら原因 (secret、App の install) を直す。間に合わなければ 3 件を進行役が手で貼る (文面は `npc/quests/04/review/*.md`)
- {{approve}} の前に見るもの: 返しが 3 分類 (直した / 直さない理由 / 質問) のどれかになっているか、{{resolve}} 済みか、本文の「変更内容」と diff が一致しているか、「確認方法」に何を見たか書いてあるか
- 進行役のコメントは ID 付きで 1〜2 件まで。ここでは差し戻さない (差し戻しは演習 05)
- 到達チェック **T-1 / T-2 / H-3**
<!-- notes:end -->
