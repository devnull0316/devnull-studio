# Fable 5 / Mythos 5 利用停止 監視ルーティン

Claude Fable 5（`claude-fable-5`）/ Mythos 5（`claude-mythos-5`）の利用停止事案を
定期的に追跡し、GitHub Issue で記録・通知するための監視ルーティン定義。

## 背景（2026-06-13 時点）

- 2026-06-09: Fable 5 / Mythos 5 一般提供開始。
- 2026-06-12 17:21 ET: 米政府の輸出管理指令を受け、Anthropic が両モデルへの
  アクセスを全世界・全顧客で停止（起点は商務長官 Lutnick → Amodei 書簡 6/1付）。
- 理由: 匿名の競合が報告した「ジェイルブレイク手法」を発端とする国家安全保障上の懸念。
  Anthropic は根拠に異議（同等能力は GPT-5.5 等でも可能と主張）を唱えつつ遵守し、復旧作業中。
- 復旧時期は未定。Opus 4.8 等の他モデルは影響なし。

## 設計のポイント

- **実行方式**: Claude Code の **Routines**（クラウド実行・永続・最小1時間間隔）。
  `/schedule` または https://claude.ai/code/routines から登録。トリガーは4時間おき推奨
  （cron `0 */4 * * *`、米東部日中に寄せるなら `0 0,12,16,20 * * *`）。落ち着いたら日次へ。
- **プロンプトはファイル参照ではなく、下記「監視プロンプト」を指示欄に直接貼る**。
  ルーチンは既定ブランチ起点で新しい作業ブランチを切るため、feature ブランチに置いた
  ファイルは参照できない。この .md はドキュメント（最新版の保管）用。
- **状態管理**: ルーチンの各実行は記憶を持たない。そこで GitHub Issue（ラベル `fable-watch`）を
  「通知先 ＋ 前回状態の記録」の二役に使う。実行のたびに最新 Issue を読み、変化時のみ新規 Issue を作る。
- **通知**: 変化があった時だけ Issue を作成し本人をメンション → GitHub モバイルアプリの
  プッシュ＋メールで届く。対象リポを Watch（Participating 以上）にしておくこと。
- **モデル**: Fable は停止中のため Opus 4.8 で実行。

## 仕上げ前の確認

1. 指示欄の `@devnull0316` を自分の GitHub ハンドルに（違う場合）。
2. GitHub モバイルアプリの通知を ON、対象リポを Watch。
3. Issue 作成権限が無い構成なら、指示内の draft PR フォールバックが働く。

---

## 監視プロンプト（ルーチンの指示欄に貼る）

```text
あなたは「Claude Fable 5 / Mythos 5 利用停止」事案の監視アナリストです。
2026-06-12に米政府の輸出管理指令を受け、Anthropicが両モデルへのアクセスを
全世界・全顧客で停止しました。Web検索/閲覧で一次情報を優先して最新状況を確認し、
GitHub Issue で記録・通知します。

# 1) 前回状態の取得（最初に実行）
リポジトリ devnull0316/devnull-studio の Issue を「fable-watch」ラベルで検索し、
最新の1件を「前回ステータス」の基準として読む。1件も無ければ下記の既知ステータスを基準にする。

# 既知ステータス（初回基準・2026-06-13時点）
- ステータス: 全世界で利用停止中（SUSPENDED）
- 起点: 商務長官Lutnick→Amodei書簡(6/1) / 指令受領 6/12 17:21 ET
- 理由: 輸出管理指令。匿名の競合が報告した「ジェイルブレイク手法」が発端
- Anthropicの立場: 根拠に異議（同等能力はGPT-5.5等でも可能と主張）、遵守しつつ復旧作業中
- 影響範囲: Claude API / AWS / Bedrock / Vertex / Microsoft Foundry の全配信
- 非影響: Opus 4.8 等の他モデル

# 2) 確認順（一次情報優先）
A. Anthropic: 公式声明 https://www.anthropic.com/news/fable-mythos-access ／ ニュース https://www.anthropic.com/news ／ ステータス https://status.anthropic.com ／ モデル廃止 https://platform.claude.com/docs/en/about-claude/model-deprecations
B. 政府: 米商務省/BIS の発表
C. クラウド配信元: AWS Bedrock・Google Vertex AI・Microsoft Foundry の告知
D. 競合・他社AI: OpenAI / Google DeepMind / Meta の公式言及（あれば）
E. 裏取りのみ: Axios / Reuters / CNBC / TechCrunch

# 3) 回答すべき問い
- 利用停止は解除されたか（全員/一部/米国内のみ/依然全停止）
- 公式の復旧見通し・タイムライン
- 政府指令の内容・対象・撤回/変更（BIS一次情報で確認）
- 各クラウドで可用性に差は出たか
- 競合各社や業界団体の公式言及
- 推奨代替・移行（例: Opus 4.8）の更新

# 4) 周辺・波及情報（関連が薄くても拾う／各項目に 関連度: 高/中/低）
規制の他社・他国への波及や前例化、議会・訴訟・規制当局、データ保持(30日)・Covered Model・
Project Glasswing、復旧に向けた非公式観測（憶測と明示）、事業影響、Hacker News等の新論点。

# 5) 品質ルール
- 一次情報＞報道。全事実に「出典URL+公開/更新日」。
- 事実/推測/未確認をラベル分け。確認不能は「不明」。
- 「声明が無い」ことも明記。周辺情報は別セクション＋関連度ラベルで本筋と分離。

# 6) 報告と通知（GitHub）
今回のステータスを判定し、前回基準と比較する。
- 【変化あり、または fable-watch ラベルのIssueが1件も無い】:
  新規 Issue を作成。
   - タイトル: "[Fable監視] <YYYY-MM-DD HH:MM UTC> — <STATUS>"
   - ラベル: fable-watch（無ければ作成）
   - 本文: 下記フォーマット全文。末尾に @devnull0316 をメンションし、可能ならアサイン
- 【変化なし】: 新規Issueは作らない（通知を出さない）。最新の fable-watch Issue に
  「<時刻>: 変化なし（<STATUS>）」と短くコメントするに留める。
- ※Issue作成ができない場合のみ、claude/fable-watch ブランチに routines/logs/<日付>.md を
  コミットして draft PR を開く方法で代替する。

# 出力フォーマット（Issue本文・この順・簡潔に）
1. 【ステータス】SUSPENDED/PARTIALLY_RESTORED/RESTORED/UNKNOWN ＋確認時刻
2. 【前回基準からの変化】（なければ「変化なし」）
3. 【事実】Anthropic/政府/クラウド/他社 で小見出し分け・出典付き
4. 【周辺・参考情報】関連度ラベル付き
5. 【推奨アクション】
6. 【次回の着目点】
```

## 主要ソース

- Anthropic 公式声明: https://www.anthropic.com/news/fable-mythos-access
- Axios: https://www.axios.com/2026/06/12/anthropic-trump-mythos-fable-national-security
- CNBC: https://www.cnbc.com/2026/06/12/anthropic-disables-access-to-fable-5-and-mythos-5-to-comply-with-government-directive.html
- TechCrunch: https://techcrunch.com/2026/06/12/anthropics-safety-warnings-may-have-just-backfired-the-government-has-pulled-the-plug-on-its-most-powerful-ai/
- Claude Code Routines（実行機能）: https://code.claude.com/docs/en/routines.md
