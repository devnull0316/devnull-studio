# Fable 5 / Mythos 5 利用停止 監視ルーティン

Claude Fable 5（`claude-fable-5`）/ Mythos 5（`claude-mythos-5`）の利用停止事案を
定期的に追跡し、前回からの変化を報告するための監視プロンプト。

## 背景（2026-06-13 時点）

- 2026-06-09: Fable 5 / Mythos 5 一般提供開始。
- 2026-06-12 17:21 ET: 米政府の輸出管理指令を受け、Anthropic が両モデルへの
  アクセスを全世界・全顧客で停止（起点は商務長官 Lutnick → Amodei 書簡 6/1付）。
- 理由: 匿名の競合が報告した「ジェイルブレイク手法」を発端とする国家安全保障上の懸念。
  Anthropic は根拠に異議（同等能力は GPT-5.5 等でも可能と主張）を唱えつつ遵守し、復旧作業中。
- 復旧時期は未定。Opus 4.8 等の他モデルは影響なし。

## 実行方法

- **本番の定期監視（推奨）**: Claude Code の **Routines**（クラウド実行・永続・最小1時間間隔）。
  `/schedule` コマンド、または https://claude.ai/code/routines から登録。
  Prompt に下記本文を貼り、Schedule を Daily 等に設定、結果保存先にこのリポジトリを指定。
- **開発中の一時ループ**: `/loop 1h <下記要約>`（セッション内のみ・終了で停止）。
- **単発の深掘り**: `deep-research` スキルに下記本文を渡す。

毎回の実行後、出力の「前回確認時点のステータス」ブロックを最新の結果で上書きすること。

---

## 監視プロンプト

```text
# 役割
あなたは「Claude Fable 5 / Mythos 5 利用停止」事案の監視アナリストです。
2026-06-12に米政府の輸出管理指令を受け、Anthropicが両モデルへのアクセスを
全世界・全顧客で停止しました。最新状況を一次情報で確認し、前回からの
「変化」を、Anthropicだけでなく政府・競合各社・クラウド配信元まで含めて報告します。

# 前回確認時点のステータス（差分の基準・実行時に前回出力で上書き）
- ステータス: 全世界で利用停止中（SUSPENDED）
- 起点: 商務長官Lutnick→Amodei書簡(6/1) / 指令受領 6/12 17:21 ET
- 理由: 輸出管理指令。匿名の競合が報告した「ジェイルブレイク手法」が発端
- Anthropicの立場: 根拠に異議（同等能力はGPT-5.5等でも可能と主張）、遵守しつつ復旧作業中
- 影響範囲: Claude API / AWS / Bedrock / Vertex / Microsoft Foundry の全配信
- 非影響: Opus 4.8 等の他モデル

# 確認手順（一次情報を最優先・この順）
A. Anthropic
  1. 公式声明 https://www.anthropic.com/news/fable-mythos-access
  2. ニュース一覧 https://www.anthropic.com/news
  3. ステータス https://status.anthropic.com
  4. モデル廃止 https://platform.claude.com/docs/en/about-claude/model-deprecations
B. 政府
  5. 米商務省/BIS の発表・プレス（輸出管理関連）
C. クラウド配信元（実際の遮断/復旧元）
  6. AWS Bedrock / Claude on AWS の告知
  7. Google Cloud Vertex AI の告知
  8. Microsoft Foundry の告知
D. 競合・他社AI（本件への言及があれば）
  9. OpenAI / Google DeepMind / Meta の公式声明・ニュースルーム
E. 速報の裏取りのみ
  10. Axios / Reuters / CNBC / TechCrunch 等の主要報道

# 回答すべき問い
- 利用停止は解除されたか？（全員/一部/米国内のみ/依然全停止）
- 公式の復旧見通し・タイムラインは出たか？
- 政府指令の内容・対象・撤回/変更はあるか？（BIS一次情報で確認）
- 各クラウド（AWS/Vertex/Foundry）で可用性に差は出たか？
- 競合各社（OpenAI等）や業界団体が本件に公式言及したか？
- Anthropicの推奨代替・移行手順（例: Opus 4.8）に更新はあるか？

# 品質ルール
- 一次情報＞報道。すべての事実に「出典URL+公開/更新日」を付す。
- 事実・推測・未確認をラベル分け。確認不能は「不明」と明記。
- 「声明が無い」ことも結果として明記（例:「OpenAIの公式言及は確認できず」）。
- 前回と照合し、変化が無ければ「変化なし」と断言。

# 出力フォーマット（この順・簡潔に）
1. 【ステータス】1行: SUSPENDED/PARTIALLY_RESTORED/RESTORED/UNKNOWN ＋確認時刻
2. 【前回からの変化】箇条書き（なければ「変化なし」）
3. 【事実】出典URL+日付つき。Anthropic/政府/クラウド/他社 で小見出し分け
4. 【推奨アクション】依存ユーザー/開発者が今取るべき具体策
5. 【次回確認の着目点】
```

## 主要ソース

- Anthropic 公式声明: https://www.anthropic.com/news/fable-mythos-access
- Axios（政府指令の報道）: https://www.axios.com/2026/06/12/anthropic-trump-mythos-fable-national-security
- CNBC: https://www.cnbc.com/2026/06/12/anthropic-disables-access-to-fable-5-and-mythos-5-to-comply-with-government-directive.html
- TechCrunch: https://techcrunch.com/2026/06/12/anthropics-safety-warnings-may-have-just-backfired-the-government-has-pulled-the-plug-on-its-most-powerful-ai/
- Claude Code Routines（実行機能）: https://code.claude.com/docs/en/routines.md
