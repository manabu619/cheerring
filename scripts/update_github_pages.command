#!/bin/bash
DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"

echo "=== CheerRING GitHub Pages 更新 ==="
echo ""

# gitリポジトリの確認
if [ ! -d .git ]; then
  echo "git init します..."
  git init
  git remote add origin https://github.com/manabu619/cheerring.git
fi

# 変更をadd・commit・push
git add index.html hanxup.png hero_bg2.png manifest.json robots.txt sitemap.xml 404.html
git diff --cached --stat
echo ""

git commit -m "feat(lp): LP大幅強化・プロ品質へ全面改良

- hero_bg2.png, hanxup.png 追加 / quote-attr 修正
- アナウンスバー（残りスロット動的）・進捗バー
- EARLY VOICES・アーリーバード価格・ペルソナカード
- ロードマップ/タイムライン・カウントダウンタイマー
- スティッキーCTA・離脱防止ポップアップ
- skip-link / main / aria-label アクセシビリティ
- 利用規約・プライバシーポリシー モーダル
- LINE+Xシェアボタン
- FAQ 7問（個人情報・引退選手追加）
- manifest.json / sitemap.xml / robots.txt / 404.html
- meta description・Schema.org FAQPage改善" 2>/dev/null || echo "(変更なし or コミット済み)"

git push origin main 2>/dev/null || git push origin master 2>/dev/null || git push -u origin HEAD

echo ""
echo "=== 完了 ✅ ==="
echo "GitHub Pages: https://manabu619.github.io/cheerring/"
read -p "Enterで閉じます..."
