# アーキテクチャ

## 核となる設計判断：2層に分ける

iOSアプリは1枚岩で作らず、**プラットフォーム非依存のエンジン層**と **iOS専用のシェル層**に分割する。

```
┌─────────────────────────────────────────────┐
│ iOSシェル層   （macOS / クラウドMac でのみビルド可）   │
│  - キーボード拡張（UIInputViewController）         │
│  - 本体アプリ（ペルソナ管理UI / SwiftUI）          │
│  - App Group・Full Access・CloudKit            │
├─────────────────────────────────────────────┤
│ エンジン層    （Windows / Linux でビルド・テスト可）   │
│  - PersonaEngine：予測・学習・切替・export/import   │
│  - Foundation のみ（UIKit 禁止）                  │
└─────────────────────────────────────────────┘
        ↑ iOSシェルは engine を `import PersonaEngine` するだけ
```

### なぜこの分割か
- **Swift言語は Windows でビルドできる**が、**iOSアプリ（UIKit / iOS SDK / コード署名）は macOS が必須**。
- 重い頭脳部分（エンジン）を UIKit から切り離しておけば、**開発の大半を手元の Windows で完結**でき、クラウドMacの利用＝iOS統合の最終段だけ＝コスト最小。
- エンジンは iOS でも Windows でも**同一コード**。Windows で書いたものを無改造で iOS に載せる。

### 制約（厳守）
エンジン層は **Foundation の中でもクロスプラットフォーム対応API のみ**で書く。Apple独自APIに触ると Windows でコンパイルが通らなくなる＝この分割の利点が消える。現状は純粋なロジック＋`FileManager`/`JSONEncoder` のみで、Windows/Linux 両対応を確認済み。

---

## エンジン層のデータモデル

```
PersonaEngine
 ├ personas: [Persona]          全ペルソナ
 ├ activePersonaID: UUID?       いまアクティブな1つ
 └ （API）create / switch / delete / learn / complete / predictNext / export / import

Persona                          ← 「人格レイヤー」1枚
 ├ id, name（"zeta用" 等）, createdAt, updatedAt
 └ store: LearningStore

LearningStore                    ← そのペルソナの学習データ（= 持ち運ぶ実体）
 ├ completions: [reading: [surface: WordStat]]   よみ→表記（変換候補）
 └ transitions: [prev: [next: WordStat]]          直前語→次語（予測変換）

WordStat
 ├ count: Int        頻度
 └ lastUsed: Date    最終使用（新しさ）
```

### ランキング（決定的）
候補の並びは **頻度 desc → 新しさ desc → 文字列 asc**。決定的なのでテストで固定できる（`LearningStore.rank`）。
将来は recency 減衰（半減期）や n-gram 拡張に差し替え可能。

### 持ち運び（製品の核）
`Persona` は `Codable`。`exportPersona(id) -> Data`（JSON）で1ペルソナを書き出し、`importPersona(from:)` で別端末に取り込む。これが「名前付きセットにアップ／ダウンロードして使う」の最小実装。id衝突時は新idを採番して既存を壊さない。

---

## iOSシェル層の実装（M2、`ios/` に着手済み）

コードは `ios/` に実装済み（UIKit/SwiftUI のため Linux ではビルド不可、Mac/xtool で組む）。
- `ios/Shared/` … 本体・拡張で共有（`AppGroup`／`PersonaService`）
- `ios/HostApp/` … SwiftUI 本体アプリ（一覧・切替・作成・削除・プリセット入出力）
- `ios/Keyboard/` … `UIInputViewController` ＋候補バー＋ローマ字入力＋👤切替
ビルド手順・プレースホルダ・デモの撮り方は `ios/README.md`。

## iOSシェル層の統合計画（M2以降）

1. **App Group** を本体アプリとキーボード拡張で共有 → `PersonaStore(directory:)` をApp Groupコンテナに向ける。本体アプリで編集 → 拡張で即利用。
2. **キーボード拡張**：`UIInputViewController` 上で、入力確定時に `engine.learn(...)`、入力中に `engine.complete(...)` / `predictNext(...)` を呼び候補表示。
3. **ペルソナ切替UI**：まずは本体アプリ側（軽い）。慣れたらキーボード上にも切替ボタン。
4. **Full Access**：クラウド同期を使う段階で必要。最初のPoCは**端末内＋App Groupのみで完結**させ Full Access 不要にする（審査・心理ハードルを下げる）。
5. **クラウド同期**（後）：`CloudKit` が最有力（サーバー不要）。export/import が既にあるので、同期はその上に乗せるだけ。

### メモリ戦略
キーボード拡張は **約30〜60MB でクラッシュ**（端末依存）。
- 現状エンジンの辞書はプレーンな辞書構造（学習データのみ）で軽量。
- 大規模なかな漢字変換辞書を載せる段階で **LOUDS（簡潔データ構造）＋頭文字分割の遅延ロード**を導入（azooKey が ~20MB台 / 30万語で実証済みの手法）。
- かな漢字変換そのものは自作が重いので、**まず学習・予測・切替（＝製品の新規性）を完成**させ、本格変換は azooKey 参照 or 後段で。

---

## azooKey の位置づけ
- **参照実装**（Apache-2.0）。LOUDS辞書の持ち方、学習の保存方式、キーボード拡張UI の作り方を**学ぶ対象**。
- フォークして土台にするか、エンジンを自作してUIだけ参考にするかは未決（→ `docs/DECISIONS.md` / `docs/ROADMAP.md`）。現状は**エンジン自作**で進行中。
