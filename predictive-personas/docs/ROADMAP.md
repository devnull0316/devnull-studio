# ロードマップ

ゴールは2つ：**(A) 実際に人に使わせて行動・心理データを取る**、**(B) 総合型選抜で見せられる実物にする**。
市場制覇ではなく、この2つに全振りする（→ `docs/DECISIONS.md`）。

時間軸（目安）：いま 2026-06 → 受験は 2026 秋ごろ → 法人登録は 2027-04 予定。
**受験までに必要なのは「動くプロトタイプ＋デモ＋数人の実ユーザー＋考察」**であって、App Store 公開でも法人化でもない。

---

## M0 — エンジン層 ✅ 完了
- [x] `PersonaEngine`：create / switch / delete / learn / complete / predictNext
- [x] 学習データのペルソナ単位の分離（isolation テスト済み）
- [x] export / import（持ち運びの最小実装）
- [x] ディスク永続化 `PersonaStore`（iOSではApp Groupに向ける）
- [x] ユニットテスト14本パス・`persona-demo` 動作
- [x] Windows/Linux ビルド確認

## M1 — エンジンを「使える」レベルへ（Windowsで完結）✅ 完了
- [x] かな入力の扱い：`RomajiConverter`（greedy最長一致、nn→ん、double consonant→っ）
- [x] 候補ランキングに recency 減衰（半減期）を導入：`halfLife` パラメータ、score = count × 0.5^(elapsed/halfLife)
- [x] 基本辞書バンドル：`DefaultLexicon`（約100語）、`seedDefaultLexicon()` で `distantPast` シード
- [x] 学習データのサイズ上限：`prune(keepPerReading:maxReadings:)` / `pruneActivePersona()`
- [x] 共有プリセット：`PersonaPackage`、`exportPackage()` / `importPackage()`（versioned・常に新ID）
- [x] テスト44本パス（ローマ字・decay・辞書・pruning・package round-trip 等）

## M2 — iOSシェルに載せる（xtool ルートを優先、TestFlight は クラウドMac）
- [ ] Apple Developer 登録（$99）— App Groups / プロビジョニングに必要
- [ ] **xtool セットアップ**（Linux/WSL）：`xtool build` でキーボード拡張を実機サイドロード
- [ ] Xcode プロジェクト作成（xtool または クラウドMac）：本体アプリ＋キーボード拡張
- [ ] `engine` をローカルSwift Package として参照
- [ ] App Group 設定、`PersonaStore` をコンテナに接続
- [ ] キーボード拡張で `learn` / `complete` を配線、候補バー表示
- [ ] **実機で初動作**（メモリを計測：30〜60MB以内）
- [ ] アップロード・ダウンロード・プリセット切替UI（`exportPackage` / `importPackage` を画面から）

## M3 — プロダクト体験（受験で効く部分）
- [ ] ペルソナ切替UI（本体アプリ）
- [ ] export/import を画面から（ファイル共有 or QR/リンク）
- [ ] 「消す」ではなく「退避して戻せる」体験の作り込み
- [ ] デモ動画を撮る（受験提出物）

## M4 — 実ユーザーテスト（TestFlight クローズド）
- [ ] プライバシーポリシー用意、初回ベータ審査を通す
- [ ] 友達5〜10人に TestFlight 配布（公開リスティングなし＝名前バレ回避）
- [ ] 観察設計：「消す vs 隠して戻す、どちらが安心か」等の行動・反応
- [ ] フィードバックと考察をまとめる（受験の質的データ）

## M5 — 受験後の分岐（いま決めない）
- [ ] 法人登録（D-U-N-S → 屋号でApp Store、本名非公開）2027-04
- [ ] オープンコア（キーボードOSS＋クラウド/パックで収益）か、閉じたままか判断
- [ ] クラウド同期（CloudKit）

---

## いま着手すべき次の1つ
**M2 の開始（xtool セットアップ）**。$99 Developer アカウントを取得し、xtool を Linux/WSL に入れれば実機でキーボード拡張が動く。クラウドMac を待たずに前進できる。  
TestFlight 提出のためだけにクラウドMac（Codemagic 等）を使う構成が最も効率的。
