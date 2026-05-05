#!/usr/bin/env bash
# =============================================================================
# CheerRING スプリント セットアップスクリプト
# 用途: GitHub認証 → リポジトリclone → ローカル起動 までを半自動化
#
# 実行方法（Macのターミナルで）:
#   bash scripts/setup_cheerring.sh
#
# このスクリプトは「再実行できる」ように作っています。
# 途中でEnter押し忘れて止まっても、もう一度走らせれば続きから進みます。
# =============================================================================

set -e  # コマンド失敗で即停止
set -u  # 未定義変数で停止

# --- 色つきlog ---
log()  { printf "\033[1;36m[INFO]\033[0m %s\n" "$*"; }
ok()   { printf "\033[1;32m[ OK ]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }
err()  { printf "\033[1;31m[ERR ]\033[0m %s\n" "$*" >&2; }
ask()  { printf "\033[1;35m[ASK ]\033[0m %s " "$*"; }
sec()  { printf "\n\033[1;37m=== %s ===\033[0m\n" "$*"; }

REPO_OWNER="fumi5150"
REPO_NAME="cheerlink-workspace"
LOCAL_DIR="$HOME/ForClaudeCode/CheerLink"
GIT_NAME_DEFAULT="新保"
GIT_EMAIL_DEFAULT="manabu619@gmail.com"

# =============================================================================
sec "0. 事前確認"
# =============================================================================
log "Mac OS: $(sw_vers -productVersion 2>/dev/null || echo 'unknown')"
log "ホームディレクトリ: $HOME"
log "予定clone先: $LOCAL_DIR"
echo ""

# =============================================================================
sec "1. Homebrew の確認"
# =============================================================================
if command -v brew >/dev/null 2>&1; then
  ok "Homebrew インストール済み: $(brew --version | head -1)"
else
  warn "Homebrew が未インストールです。"
  echo ""
  echo "    以下のコマンドをこのターミナルで貼り付けて実行してください："
  echo ""
  echo "      /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
  echo ""
  echo "    インストール完了後、もう一度このスクリプトを実行してください。"
  exit 1
fi

# =============================================================================
sec "2. GitHub CLI (gh) の確認・インストール"
# =============================================================================
if command -v gh >/dev/null 2>&1; then
  ok "gh インストール済み: $(gh --version | head -1)"
else
  log "gh をインストールします..."
  brew install gh
  ok "gh インストール完了"
fi

# =============================================================================
sec "3. Node.js / npm の確認"
# =============================================================================
if command -v node >/dev/null 2>&1; then
  ok "Node.js インストール済み: $(node --version)"
else
  log "Node.js をインストールします（LTS版）..."
  brew install node
  ok "Node.js インストール完了: $(node --version)"
fi

# =============================================================================
sec "4. git の基本設定"
# =============================================================================
CURRENT_NAME="$(git config --global user.name || echo '')"
CURRENT_EMAIL="$(git config --global user.email || echo '')"

if [ -z "$CURRENT_NAME" ]; then
  log "git user.name を設定します..."
  git config --global user.name "$GIT_NAME_DEFAULT"
  ok "git user.name = $GIT_NAME_DEFAULT"
else
  ok "git user.name 設定済み: $CURRENT_NAME"
fi

if [ -z "$CURRENT_EMAIL" ]; then
  log "git user.email を設定します..."
  git config --global user.email "$GIT_EMAIL_DEFAULT"
  ok "git user.email = $GIT_EMAIL_DEFAULT"
else
  ok "git user.email 設定済み: $CURRENT_EMAIL"
fi

# defaultBranch を main に
git config --global init.defaultBranch main
ok "init.defaultBranch = main"

# =============================================================================
sec "5. GitHub 認証 (gh auth login)"
# =============================================================================
if gh auth status >/dev/null 2>&1; then
  ok "GitHub 認証済み"
  gh auth status 2>&1 | sed 's/^/    /'
else
  warn "GitHub 認証が未完了です。"
  echo ""
  echo "    これから対話形式で gh auth login を実行します。"
  echo "    プロンプトに以下のように答えてください："
  echo ""
  echo "      ? What account do you want to log into?              → GitHub.com"
  echo "      ? What is your preferred protocol for Git operations? → HTTPS"
  echo "      ? Authenticate Git with your GitHub credentials?      → Yes"
  echo "      ? How would you like to authenticate?                 → Login with a web browser"
  echo ""
  echo "    その後ターミナルに表示される8桁コードをコピーして、"
  echo "    自動で開くブラウザで貼り付ければ認証完了です。"
  echo ""
  ask "準備できたらEnterを押してください..."
  read -r _
  gh auth login
  ok "GitHub 認証完了"
fi

# 認証アカウント名取得
GH_USER="$(gh api user --jq .login 2>/dev/null || echo '')"
if [ -n "$GH_USER" ]; then
  ok "GitHubユーザー: $GH_USER"
fi

# =============================================================================
sec "6. リポジトリ Collaborator 権限の確認"
# =============================================================================
if gh repo view "${REPO_OWNER}/${REPO_NAME}" >/dev/null 2>&1; then
  ok "${REPO_OWNER}/${REPO_NAME} にアクセスできます"
else
  err "${REPO_OWNER}/${REPO_NAME} にアクセスできません。"
  echo ""
  echo "    考えられる原因:"
  echo "    1) ふみのりさんからまだ Collaborator 招待が届いていない"
  echo "    2) 招待は届いたが、まだ accept していない"
  echo ""
  echo "    対処:"
  echo "    a) ふみのりさんに GitHub ユーザー名「${GH_USER:-不明}」を伝える"
  echo "    b) 届いたメール or https://github.com/notifications で招待を accept"
  echo "    c) 完了したらこのスクリプトをもう一度実行"
  exit 1
fi

# =============================================================================
sec "7. リポジトリ clone"
# =============================================================================
mkdir -p "$(dirname "$LOCAL_DIR")"

if [ -d "$LOCAL_DIR/.git" ]; then
  ok "既に clone 済み: $LOCAL_DIR"
  log "git pull origin main を実行..."
  ( cd "$LOCAL_DIR" && git pull origin main )
else
  log "clone 開始: ${REPO_OWNER}/${REPO_NAME} → $LOCAL_DIR"
  gh repo clone "${REPO_OWNER}/${REPO_NAME}" "$LOCAL_DIR"
  ok "clone 完了"
fi

# =============================================================================
sec "8. 依存パッケージのインストール"
# =============================================================================
cd "$LOCAL_DIR"
if [ -f package.json ]; then
  log "npm install を実行（数分かかる場合あり）..."
  npm install
  ok "依存パッケージのインストール完了"
else
  warn "package.json が見つかりません。リポ構成が想定と違う可能性。"
fi

# =============================================================================
sec "9. ブランチ切り替え（試運転PR用）"
# =============================================================================
BRANCH="feature/cheerring-260501-kickoff"
if git rev-parse --verify "$BRANCH" >/dev/null 2>&1; then
  ok "ブランチ $BRANCH は既に存在します"
  git checkout "$BRANCH"
else
  log "新規ブランチ作成: $BRANCH"
  git checkout -b "$BRANCH"
  ok "ブランチ作成完了"
fi

# =============================================================================
sec "10. 完了"
# =============================================================================
ok "セットアップが全て完了しました！"
echo ""
echo "  次のステップ:"
echo ""
echo "  1) このディレクトリでローカル開発サーバーを起動:"
echo "       cd $LOCAL_DIR"
echo "       npm run dev"
echo "     → http://localhost:3003/sports/prowrestling が表示されればOK"
echo ""
echo "  2) Claude Code を起動:"
echo "       cd $LOCAL_DIR"
echo "       claude"
echo "     起動後、最初の指示として Document/06_作業メモ/001_fumi_CheerRING_キックオフ統合資料_2026-04-30_v2.md"
echo "     の '11. 最初の Claude Code 指示（コピペ用）' をコピペしてください。"
echo ""
echo "  3) 試運転PRの作り方は docs/team/03_CheerRING_GitHub_Flow_と作業範囲.md を参照"
echo ""
