<!-- kit
title: quest-02: WSL2 を入れて clone する
week: 1
-->
# quest-02: WSL2 を入れて clone する

<!-- issue:start -->
## 状況

作業環境を作ります。この演習は **対面 1** で進行役と一緒に進めます (1 時間)。
事前に [WSL2 の 1 枚](../docs/wsl2-setup.md) を読んでおくと速く終わります。

## やること

[WSL2 の 1 枚](../docs/wsl2-setup.md) の 1 から 8 までを、上から順に行う。
手順ごとに「こう表示されれば OK」が書いてあるので、1 つずつ確かめながら進める。

## 完了条件

Ubuntu のターミナルで次を打って、結果を確かめる。

- [ ] PowerShell で `wsl -l -v` を打つと、Ubuntu の VERSION が `2`
- [ ] `which git` が `/usr/bin/git` (Windows 側の git ではない)
- [ ] `git config --global --list` に `user.name`、`user.email` (noreply のアドレス)、`core.autocrlf=input`、`init.defaultbranch=main` の 4 行がある
- [ ] `{{cli}} auth status` が認証済みと言う
- [ ] リポジトリが `~/src/` の下にある (`pwd` が `/home/` で始まる。`/mnt/c` ではない)
- [ ] `git log --oneline | head -3` でコミットが 3 行出る
- [ ] VS Code でリポジトリを開くと、左下に `WSL: Ubuntu` と出る
- [ ] この Issue に `git log --oneline | head -3` の出力を貼った

## 詰まったら

[WSL2 の 1 枚](../docs/wsl2-setup.md) の末尾「つまずき」を見る。対面中なら進行役にその場で聞く。
<!-- issue:end -->

<!-- notes:start -->
## 進行役メモ

- **対面 1 (1 時間)** の流し方: 冒頭 10 分で演習 01 の説明と了承、残り 50 分でこの演習。終わらなければ残りは非同期で
- 事前に受講者の PC で WSL2 が有効化できるか (Windows のバージョン、仮想化の設定) を確認しておくと、当日の再起動待ちが減る
- よくある詰まり:
  - `wsl --install` の後の再起動を忘れる
  - `/mnt/c` (Windows のフォルダ) に clone してしまう。`pwd` で見つけたら `~/src/` に clone し直す
  - Windows 側の Git が先に見つかる (`which git` が `/mnt/c/...`)。Ubuntu 側で `sudo apt install git`
  - 資格情報の混線。`git config --global --list | grep credential` に Windows 側のパスがあれば `--unset-all credential.helper` してから `gh auth setup-git`
  - `git config` の `user.email` に通常のメールを入れてしまう。noreply に直す
- 到達チェック **W-1 / W-2 / W-3 / W-4**
<!-- notes:end -->
