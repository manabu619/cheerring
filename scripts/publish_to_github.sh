#!/usr/bin/env bash
# =============================================================================
# CheerRING LP — GitHub 公開スクリプト
# 用途: manabu619 アカウントの GitHub に cheerring リポジトリを作成し、
#       LP（index.html）を GitHub Pages で公開する
#
# 実行方法（Macのターミナルで）:
#   bash scripts/publish_to_github.sh
#
# このスクリプトは「再実行できる」ように作っています。
# 途中で止まっても、もう一度走らせれば続きから進みます。
# =============================================================================

set -e
set -u

log()  { printf "\033[1;36m[INFO]\033[0m %s\n" "$*"; }
ok()   { printf "\033[1;32m[ OK ]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }
err()  { printf "\033[1;31m[ERR ]\033[0m %s\n" "$*" >&2; }
ask()  { printf "\033[1;35m[ASK ]\033[0m %s " "$*"; }
sec()  { printf "\n\033[1;37m=== %s ===\033[0m\n" "$*"; }

# ----- 設定 -----
REPO_NAME="cheerring"
REPO_DESC="CheerRING — プロレスファン向けデジタル会員証LP"
GH_OWNER_EXPECTED="manabu619"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# =============================================================================
sec "0. 事前確認"
# =============================================================================
log "プロジェクトディレクトリ: $PROJECT_DIR"
if [ ! -d "$PROJECT_DIR" ]; then
  err "プロジェクトディレクトリが見つかりません: $PROJECT_DIR"
  exit 1
fi

cd "$PROJECT_DIR"
log "カレント: $(pwd)"

# =============================================================================
sec "1. gh / git の確認"
# =============================================================================
if ! command -v gh >/dev/null 2>&1; then
  err "GitHub CLI (gh) が見つかりません。"
  echo "    インストール: brew install gh"
  exit 1
fi
ok "gh: $(gh --version | head -1)"

if ! command -v git >/dev/null 2>&1; then
  err "git が見つかりません。"
  exit 1
fi
ok "git: $(git --version)"

# =============================================================================
sec "2. GitHub 認証確認"
# =============================================================================
if gh auth status >/dev/null 2>&1; then
  GH_USER="$(gh api user --jq .login 2>/dev/null || echo '')"
  ok "GitHub 認証済み: $GH_USER"

  if [ "$GH_USER" != "$GH_OWNER_EXPECTED" ]; then
    warn "現在のアカウント($GH_USER)は想定($GH_OWNER_EXPECTED)と異なります。"
    ask "このまま $GH_USER のアカウントで進めますか？ [y/N]: "
    read -r ans
    if [ "$ans" != "y" ] && [ "$ans" != "Y" ]; then
      echo ""
      echo "  $GH_OWNER_EXPECTED でログインし直す場合:"
      echo "    gh auth logout"
      echo "    gh auth login"
      exit 1
    fi
  fi
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
  ask "準備できたらEnterを押してください..."
  read -r _
  gh auth login
  GH_USER="$(gh api user --jq .login 2>/dev/null || echo '')"
  ok "GitHub 認証完了: $GH_USER"
fi

# =============================================================================
sec "3. ローカル git リポジトリ初期化"
# =============================================================================
if [ -d ".git" ]; then
  ok "既に git 初期化済み"
else
  log "git init..."
  git init -b main
  ok "git init 完了"
fi

# user.name / user.email のチェック
CURRENT_NAME="$(git config --global user.name || echo '')"
CURRENT_EMAIL="$(git config --global user.email || echo '')"
if [ -z "$CURRENT_NAME" ]; then
  warn "git user.name が未設定です。"
  ask "user.name を入力してください: "
  read -r in_name
  git config --global user.name "$in_name"
  ok "user.name = $in_name"
fi
if [ -z "$CURRENT_EMAIL" ]; then
  warn "git user.email が未設定です。"
  ask "user.email を入力してください: "
  read -r in_email
  git config --global user.email "$in_email"
  ok "user.email = $in_email"
fi

# =============================================================================
sec "4. リモートリポジトリ作成（または既存確認）"
# =============================================================================
if gh repo view "${GH_USER}/${REPO_NAME}" >/dev/null 2>&1; then
  ok "リポジトリ ${GH_USER}/${REPO_NAME} は既に存在します"
else
  log "リポジトリ ${GH_USER}/${REPO_NAME} を作成します..."
  gh repo create "${GH_USER}/${REPO_NAME}" \
    --public \
    --description "$REPO_DESC" \
    --source . \
    --remote origin
  ok "リポジトリ作成完了"
fi

# remote 確認
if git remote get-url origin >/dev/null 2>&1; then
  ok "remote origin: $(git remote get-url origin)"
else
  log "remote origin を追加..."
  git remote add origin "https://github.com/${GH_USER}/${REPO_NAME}.git"
  ok "remote origin 追加完了"
fi

# =============================================================================
sec "5. ファイル add / commit"
# =============================================================================
git add .
if git diff --cached --quiet; then
  ok "コミット対象の変更はありません"
else
  log "commit を作成..."
  git commit -m "feat: initial publish — CheerRING LP

- index.html: コピーライト修正版を反映
- README.md: プロジェクト概要
- .gitignore: macOS/エディタ系除外"
  ok "commit 作成完了"
fi

# =============================================================================
sec "6. push"
# =============================================================================
log "main ブランチを push..."
git push -u origin main
ok "push 完了"

# =============================================================================
sec "7. GitHub Pages 有効化"
# =============================================================================
log "GitHub Pages を main ブランチ / root で有効化..."
# 既に有効化済みでもエラーにしない
gh api -X POST "repos/${GH_USER}/${REPO_NAME}/pages" \
  -f "source[branch]=main" \
  -f "source[path]=/" \
  >/dev/null 2>&1 \
  && ok "Pages 有効化完了" \
  || warn "Pages は既に有効化済みか、API応答待ちの可能性があります"

# =============================================================================
sec "8. 完了"
# =============================================================================
ok "公開作業が完了しました！"
echo ""
echo "  リポジトリ:"
echo "    https://github.com/${GH_USER}/${REPO_NAME}"
echo ""
echo "  公開URL（数十秒〜数分でアクセス可能になります）:"
echo "    https://${GH_USER}.github.io/${REPO_NAME}/"
echo ""
echo "  Pages のビルド状況確認:"
echo "    https://github.com/${GH_USER}/${REPO_NAME}/actions"
echo ""
