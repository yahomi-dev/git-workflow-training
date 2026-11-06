# WSL2 の 1 枚

Windows の上に Ubuntu を立て、その中で Git と GitHub を使えるようにする手順。演習 02 で使う。
上から順に進める。1 つの手順に 1 コマンド。直後の「確かめ方」どおりに表示されたら次へ進む。
GitHub を舞台に書く。GitLab の現場向けの差分は `>` で始まる囲みに書いた。

## 1. WSL2 と Ubuntu を入れる

スタートメニューで「PowerShell」を右クリックし「管理者として実行」で開く。

    wsl --install -d Ubuntu

確かめ方: インストールの表示が終わったら Windows を再起動する。再起動後に Ubuntu の窓が開き、`Enter new UNIX username:` と聞かれる。
Windows 10 で失敗したら Windows Update を当ててからやり直す。

ユーザ名は英小文字で短く (例: `taro`)。パスワードは `sudo` のたびに使う。入力中は画面に何も出ないが打てている。

確かめ方: プロンプトが `taro@<PC 名>:~$` の形になる。次からはスタートメニューの「Ubuntu」で同じ窓を開ける。

## 2. パッケージを最新にする

    sudo apt update && sudo apt upgrade -y

確かめ方: 数分かかる。エラーで止まらずにプロンプトへ戻れば OK。

## 3. 作業ディレクトリを Linux 側に作る

    mkdir -p ~/src && cd ~/src && pwd

確かめ方: `/home/<ユーザ名>/src` と表示される。

リポジトリは必ずこの `~/src/` の下に置く。`/mnt/c/...` (Windows の C ドライブ) に置かない。
理由は 3 つ: 遅い。改行コードが CRLF になって壊れる。パーミッションが全部 777 に見えて事故る。

## 4. git は Ubuntu 側のものを使う

    which git

確かめ方: `/usr/bin/git` と表示される。何も出なければ `sudo apt install -y git` で入れる。
`/mnt/c/...` が出たら Windows 側の Git for Windows を見ている。Ubuntu の窓で打っているか確かめる。
Windows 側の Git と混ぜない。資格情報と改行の設定が食い違い、9 節のつまずきになる。

## 5. git の名前とメールを設定する

名前は GitHub に表示される名前。メールは GitHub の noreply アドレス `<ID>+<ログイン名>@users.noreply.github.com`。
見つけ方は [platform/github.md](platform/github.md) の「アカウント」。所属組織のメールアドレスは使わない。

    git config --global user.name "<表示名>"
    git config --global user.email "<ID>+<ログイン名>@users.noreply.github.com"
    git config --global core.autocrlf input
    git config --global init.defaultBranch main

確かめ方:

    git config --global --list

`user.name=`、`user.email=`、`core.autocrlf=input`、`init.defaultbranch=main` の 4 行が出る。

> GitLab の場合: noreply アドレスは `<ID>-<ユーザ名>@users.noreply.<GitLab のホスト>`。
> プロフィール設定の Commit email で「Use a private email」を選ぶと表示される。

## 6. gh CLI を入れて GitHub にログインする

`gh` は GitHub 公式の apt リポジトリから入れる。手順は公式の [Installing gh on Linux](https://github.com/cli/cli/blob/trunk/docs/install_linux.md) の "Debian, Ubuntu Linux" の節をそのまま実行する。
Ubuntu 標準の `apt install gh` は古い版が入ることがあるので使わない。

    gh --version

確かめ方: `gh version 2.x.x` のように表示される。

    gh auth login

質問には次の順で答える: `GitHub.com` -> `HTTPS` -> `Authenticate Git with your GitHub credentials? Yes` -> `Login with a web browser`。
表示された 8 文字のコードを控えて Enter。ブラウザが開いたらコードを入れて承認する。開かなければ表示された URL を Windows 側のブラウザに貼る。

    gh auth status

確かめ方: `Logged in to github.com account <ログイン名>` と `Git operations protocol: https` が出る。

> GitLab の場合: `glab` (https://gitlab.com/gitlab-org/cli) を入れ、`glab auth login` でホストとトークンを登録する。確かめ方は `glab auth status`。

> SSH 鍵 (任意。HTTPS で困っていなければ飛ばしてよい):
> `ssh-keygen -t ed25519 -C "<noreply メール>"` で鍵を作る (質問はすべて Enter でよい)。
> `cat ~/.ssh/id_ed25519.pub` の 1 行を GitHub の Settings > SSH and GPG keys > New SSH key に貼る。
> `ssh -T git@github.com` で `Hi <ログイン名>! You've successfully authenticated` と出れば OK。

## 7. VS Code を WSL につなぐ

VS Code は Windows 側にインストールする (https://code.visualstudio.com/)。Ubuntu の中には入れない。
VS Code を開き、拡張機能 (Ctrl+Shift+X) で「WSL」(発行元 Microsoft) を検索してインストールする。

Ubuntu の窓で打つ:

    cd ~/src && code .

確かめ方: VS Code が開き、左下の緑の枠に `WSL: Ubuntu` と表示される。初回は接続の準備で 1 分ほどかかる。

VS Code のターミナル (Ctrl+`) は Ubuntu のシェルになっている。以後の git 操作はここで打ってもよい。

任意: `git commit` や `git revert` のメッセージ入力を VS Code で開くようにしておくと、演習 06、07、09 でエディタに戸惑わない。

    git config --global core.editor "code --wait"

確かめ方: `git config --global core.editor` が `code --wait` を返す。

任意: 枝の形を常に見ながら作業したいなら、VS Code の拡張機能「Git Graph」(発行元 mhutchie) を入れる。左下の `Git Graph` を押すと、main と自分の枝が図で出る。
ターミナルで同じものを見る短縮名も作っておくと便利。

    git config --global alias.tree "log --graph --oneline --decorate --all -20"

確かめ方: `git tree` でコミットの木が出る。GitHub 側の全体 (main と、まだマージされていない枝) はゲーム画面で見る。

## 8. リポジトリを clone する

    cd ~/src && gh repo clone <owner>/<repo>

確かめ方: `Cloning into '<repo>'...` と出て、`ls` に `<repo>` が増える。`gh` を使わないなら `git clone <URL>` でも同じ。

    cd <repo> && git log --oneline | head -5

確かめ方: `<7 桁の SHA> <コミットメッセージ>` の行が最大 5 行出る。ここまでで演習 02 の完了条件がそろう。

## 9. つまずいたら

| 症状 | 原因 | 直し方 |
|---|---|---|
| `$'\r': command not found` | ファイルの改行が CRLF (Windows 形式) | `/mnt/c` から持ってきたか、Windows のエディタで保存した。`sed -i 's/\r$//' <file>` で直す。以後は `~/src/` の中で編集する |
| `permission denied`。`ls -l` で全部 `-rwxrwxrwx` | `/mnt/c` の上で作業している | `pwd` で場所を見る。`~/src/` へ clone し直す |
| 今のフォルダを Windows のエクスプローラで見たい | - | `explorer.exe .` (末尾のドットまで打つ) |
| push のたびに Windows 側のアカウント選択が出る。別のアカウントで push される | Windows 側の資格情報マネージャと `gh` の認証が混ざっている | `git config --global --list \| grep credential` を見る。`/mnt/c/.../git-credential-manager` の行があれば `git config --global --unset-all credential.helper` で消し、`gh auth setup-git` をやり直す |
| `code .` が `command not found` | VS Code の PATH が WSL にまだ通っていない | Ubuntu の窓を閉じて開き直す。それでも出なければ VS Code を入れ直し「PATH への追加」にチェック |
| `sudo` のパスワードを忘れた | - | PowerShell で `wsl -u root` で入り `passwd <ユーザ名>` で付け直す |
