#!/usr/bin/env bash
# =============================================================================
# CheerRING 新保作成ドキュメントを cheerlink-workspace に同期するスクリプト
#
# 配置先: docs/business/cheerring/shinbo-docs/
#
# 実行方法:
#   bash scripts/sync_to_cheerlink.sh
#
# オプション:
#   --dry-run     実際にコピー/push/PRを行わず、対象ファイルを表示するのみ
#   --no-pr       push まで行うが PR 作成はスキップ
# =============================================================================

set -e
set -u

log()  { printf "\033[1;36m[INFO]\033[0m %s\n" "$*"; }
ok()   { printf "\033[1;32m[ OK ]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }
err()  { printf "\033[1;31m[ERR ]\033[0m %s\n" "$*" >&2; }
sec()  { printf "\n\033[1;37m=== %s ===\033[0m\n" "$*"; }

# ----- オプション解析 -----
DRY_RUN=0
NO_PR=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --no-pr)   NO_PR=1 ;;
  esac
done

# ----- 設定 -----
CHEERLINK_DIR="$HOME/ForClaudeCode/CheerLink"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DEST_REL="docs/business/cheerring/shinbo-docs"
DATE_TAG=$(date +%Y%m%d)
BRANCH="feature/cheerring-mnb-docs-${DATE_TAG}"
PR_TITLE="docs(cheerring): 新保作成ドキュメント同期 ${DATE_TAG}"

# =============================================================================
sec "0. 事前確認"
# =============================================================================
if [ ! -d "$CHEERLINK_DIR/.git" ]; then
  err "$CHEERLINK_DIR に cheerlink-workspace が見つかりません。"
  echo "    先に setup_cheerring.sh を実行してください。"
  exit 1
fi
ok "cheerlink-workspace: $CHEERLINK_DIR"
ok "コピー元: $SRC_DIR"

if [ "$DRY_RUN" = "1" ]; then
  warn "=== DRY RUN モード：ファイル一覧を表示するのみ ==="
fi

# =============================================================================
sec "1. 同期対象ファイルの確認"
# =============================================================================

# rsync の代わりに cp -r を使うため、まず対象を列挙
echo ""
echo "【同期対象】"
echo "  ソース: $SRC_DIR/Document/"
echo "  配置先: $CHEERLINK_DIR/$DEST_REL/Document/"
echo ""

# Document/ 以下の全ファイル（.DS_Store を除く）
DOC_FILES=$(find "$SRC_DIR/Document" \
  -type f \
  ! -name ".DS_Store" \
  | sort)

echo "$DOC_FILES" | while read -r f; do
  rel="${f#$SRC_DIR/}"
  echo "  $rel"
done

# ルートレベルの追加ファイル（コピーライト等は Document/ 以下に存在するため不要）
echo ""
echo "【ルートレベル追加ファイル】"
ROOT_FILES=(
  "index.html"
  "INDEX.md"
)
for f in "${ROOT_FILES[@]}"; do
  if [ -f "$SRC_DIR/$f" ]; then
    echo "  $f → $DEST_REL/$f"
  else
    warn "  $f (見つかりません、スキップ)"
  fi
done

if [ "$DRY_RUN" = "1" ]; then
  echo ""
  warn "DRY RUN 完了。実際に同期するには --dry-run を外して実行してください。"
  exit 0
fi

# =============================================================================
sec "2. main ブランチを最新化"
# =============================================================================
cd "$CHEERLINK_DIR"
log "現在のブランチ: $(git rev-parse --abbrev-ref HEAD)"

# 未コミット変更があればstash
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
  warn "未コミットの変更があります。一旦stashします..."
  git stash push -m "auto-stash-by-sync-script-$(date +%s)"
  STASHED=1
else
  STASHED=0
fi

log "main に切り替え..."
git checkout main
log "git pull origin main..."
git pull origin main
ok "main 最新化完了"

# =============================================================================
sec "3. 新規ブランチ作成"
# =============================================================================

# 同日ブランチが既にある場合は枝番付与
FINAL_BRANCH="$BRANCH"
SUFFIX=0
while git rev-parse --verify "$FINAL_BRANCH" >/dev/null 2>&1; do
  SUFFIX=$((SUFFIX + 1))
  FINAL_BRANCH="${BRANCH}-${SUFFIX}"
done

if [ "$FINAL_BRANCH" != "$BRANCH" ]; then
  warn "ブランチ $BRANCH は既に存在するため $FINAL_BRANCH を使用します"
fi

git checkout -b "$FINAL_BRANCH"
ok "ブランチ作成: $FINAL_BRANCH"

# =============================================================================
sec "4. ファイル配置"
# =============================================================================
DEST_FULL="$CHEERLINK_DIR/$DEST_REL"
mkdir -p "$DEST_FULL"
log "配置先: $DEST_FULL"

# Document/ フォルダを丸ごとコピー（.DS_Store 除外）
log "Document/ フォルダをコピー中..."
rsync -a \
  --exclude=".DS_Store" \
  --exclude="__pycache__" \
  "$SRC_DIR/Document/" \
  "$DEST_FULL/Document/"
ok "Document/ コピー完了"

# ルートレベルの追加ファイル
log "ルートレベルファイルをコピー中..."
for f in "${ROOT_FILES[@]}"; do
  if [ -f "$SRC_DIR/$f" ]; then
    cp "$SRC_DIR/$f" "$DEST_FULL/$f"
    ok "  コピー: $f"
  fi
done

# =============================================================================
sec "5. README 配置"
# =============================================================================
cat > "$DEST_FULL/README.md" <<EOF
# CheerRING — 新保作成ドキュメント

> 作成者: 新保 Manabu (mnb)
> 最終同期: $(date '+%Y-%m-%d')

このフォルダは、新保 Manabu が作成した CheerRING プロジェクトの
全成果物を同期・保管するためのディレクトリです。

## フォルダ構成

\`\`\`
shinbo-docs/
├── Document/
│   ├── 01_事業計画/        ← 事業計画書（MD + PPTX）
│   ├── 02_提案資料/        ← 団体向け提案書・メールシーケンステンプレート等
│   ├── 03_市場調査/        ← NJPW収益推計・選手生涯年収モデル等（AI生成レポート）
│   ├── 04_実装計画/        ← LP改修・URL設計・スポーツ別仕様書
│   ├── 05_図解・画像/      ← 価値循環モデル図・ファン累計モデル等
│   ├── 06_作業メモ/        ← キックオフ統合資料・WBS・実行支援メモ
│   ├── コピーライト.md     ← 著作権表記（旧版）
│   └── コピーライト_修正版.md ← 著作権表記（最新版）
├── index.html              ← CheerRING LP（単一HTML）
└── INDEX.md                ← 全ファイル目次
\`\`\`

## 主要成果物

| ファイル | 内容 |
|---------|------|
| \`Document/02_提案資料/006_CheerRING_団体向け提案書.pptx\` | 団体・プロモーター向け導入提案書 |
| \`Document/01_事業計画/001_事業計画書.pptx\` | IP360スタートアップ支援向け事業計画書 |
| \`Document/02_提案資料/007_メールシーケンス_テンプレート.md\` | 早期登録者向けメールシーケンス（5通） |
| \`index.html\` | CheerRING ランディングページ |

## 公開版LP

- GitHub Pages: https://manabu619.github.io/cheerring/
- リポジトリ: https://github.com/manabu619/cheerring

## 同期スクリプト

このフォルダは以下のスクリプトで更新されます:
\`\`\`bash
bash scripts/sync_to_cheerlink.sh
\`\`\`
EOF
ok "README.md 作成"

# =============================================================================
sec "6. commit"
# =============================================================================
cd "$CHEERLINK_DIR"
git add "$DEST_REL"

# 変更差分サマリーを取得
ADDED=$(git diff --cached --name-status | grep "^A" | wc -l | tr -d ' ')
MODIFIED=$(git diff --cached --name-status | grep "^M" | wc -l | tr -d ' ')
DELETED=$(git diff --cached --name-status | grep "^D" | wc -l | tr -d ' ')

if git diff --cached --quiet; then
  warn "コミット対象の変更がありません（既に最新状態の可能性）"
  git checkout main
  if [ "$STASHED" = "1" ]; then
    warn "git stash pop で変更を復元してください。"
  fi
  exit 0
fi

COMMIT_MSG="docs(cheerring): 新保作成ドキュメント同期 $(date '+%Y-%m-%d')

## 同期内容
- 追加: ${ADDED} ファイル
- 更新: ${MODIFIED} ファイル
- 削除: ${DELETED} ファイル

## 主な成果物
- Document/01_事業計画/: 事業計画書（MD + PPTX）
- Document/02_提案資料/: 団体向け提案書・メールテンプレート等
- Document/03_市場調査/: AI生成調査レポート
- Document/04_実装計画/: LP改修・URL設計仕様書
- Document/05_図解・画像/: 価値循環モデル等図解
- Document/06_作業メモ/: WBS・実行支援メモ
- index.html: CheerRING LP（コンバージョン改善版）
- メールシーケンス_テンプレート.md: 早期登録者向け5通シーケンス

作成者: 新保 Manabu (mnb)"

git commit -m "$COMMIT_MSG"
ok "commit 作成"

# =============================================================================
sec "7. push"
# =============================================================================
if [ "$NO_PR" = "1" ] || true; then
  log "push 中..."
  git push -u origin "$FINAL_BRANCH"
  ok "push 完了"
fi

# =============================================================================
sec "8. PR 作成"
# =============================================================================
if [ "$NO_PR" = "1" ]; then
  warn "--no-pr オプションのため PR 作成をスキップします"
  echo ""
  echo "  手動でPRを作成する場合:"
  echo "  gh pr create --base main --head $FINAL_BRANCH --title \"$PR_TITLE\""
else
  PR_BODY=$(cat <<PREOF
## 概要

新保 Manabu (mnb) が作成した CheerRING プロジェクトの全成果物を
\`docs/business/cheerring/shinbo-docs/\` に同期します。

## 追加・更新されるドキュメント

### 事業計画（01_事業計画/）
- 事業計画書 MD・PPTX（IP360スタートアップ支援向け）

### 提案資料（02_提案資料/）
- 団体・プロモーター向け導入提案書（006）
- プロレス応援基盤 提案資料ドラフト（001〜005）
- 早期登録者向けメールシーケンス テンプレート（007）

### 市場調査（03_市場調査/）
- NJPW 2025年大会 チケット収入推計レポート
- プロレスラー生涯年収モデル
- プロレス産業収益構造調査

### 実装計画（04_実装計画/）
- LP改修計画（2026Q1）
- スポーツ別URL構造 実装計画
- サッカー向けランディング仕様書

### 図解・画像（05_図解・画像/）
- CheerRING価値循環モデル図
- プロレス選手ライフサイクル図
- ファン累計モデル図 等

### 作業メモ（06_作業メモ/）
- キックオフ統合資料（fumi作成）
- 実行支援メモ
- AI作業WBS（41タスク完了記録）

### LP・コアアセット
- \`index.html\` — CheerRING LP（コンバージョン改善版）
  - デジタル会員証 表記、500名限定プログレスバー、デスクトップ固定CTA
- \`メールシーケンス_テンプレート.md\` — 5通メールシーケンス

## 触っていない領域

- \`src/frontend/\` 配下は未変更
- \`supabase/\`・\`src/backend/\`・各種設定ファイルは未変更

## 次のアクション（このPRマージ後）

1. Fumiレビュー → 提案資料の方向性確認
2. 団体向けアウトリーチ開始（006_CheerRING_団体向け提案書.pptx を活用）
3. Formspree ID 設定 → LP のメール収集を実動化

---
*同期スクリプト: \`sync_to_cheerlink.sh\`*
PREOF
)

  if gh pr view "$FINAL_BRANCH" >/dev/null 2>&1; then
    warn "ブランチ $FINAL_BRANCH の PR は既に存在します"
    PR_URL=$(gh pr view "$FINAL_BRANCH" --json url --jq .url)
    ok "既存PR: $PR_URL"
  else
    log "PR を作成中..."
    gh pr create \
      --base main \
      --head "$FINAL_BRANCH" \
      --title "$PR_TITLE" \
      --body "$PR_BODY"
    PR_URL=$(gh pr view "$FINAL_BRANCH" --json url --jq .url)
    ok "PR 作成完了"
  fi
fi

# =============================================================================
sec "9. 完了"
# =============================================================================
echo ""
ok "fumi5150/cheerlink-workspace への同期が完了しました！"
echo ""
echo "  ブランチ: $FINAL_BRANCH"
if [ "$NO_PR" != "1" ]; then
  echo "  PR URL:  ${PR_URL:-（PR URL取得失敗）}"
fi
echo ""
echo "  同期された主なパス:"
echo "    $DEST_REL/Document/"
echo "    $DEST_REL/index.html"
echo "    $DEST_REL/メールシーケンス_テンプレート.md"
echo ""
echo "  次のアクション:"
echo "    1) PR URL を Google Chat でふみのりさんに共有"
echo "    2) レビュー → Approve → merge を依頼"
echo ""

# stashを戻す
if [ "$STASHED" = "1" ]; then
  warn "実行前にstashした変更があります。必要なら: cd $CHEERLINK_DIR && git stash pop"
fi
