# predictive-personas（コードネーム）

> 予測変換を「人格レイヤー」として名前をつけ、切り替え・持ち運びできる iOS 日本語キーボード。

AIチャット（zeta 等）に吐いた本音や、日常では使わない語彙が、予測変換の履歴に残るのが嫌な人向け。
履歴を「消す」のではなく、**名前付きのセット（例：`zeta用` / `日常用` / `仕事用`）として着脱・退避・持ち運び**できるようにする。

> ⚠️ `predictive-personas` は仮のコードネーム。ブランド名は後で決める（→ `docs/DISTRIBUTION.md`）。

---

## いまの状態（2026-06）

| レイヤー | 状態 | どこで動く |
|---|---|---|
| **エンジン層**（予測・学習・ペルソナ切替・export/import） | ✅ 実装済み・テスト14本パス・デモ動作 | **Windows / Linux / macOS**（Foundationのみ） |
| iOSシェル層（キーボード拡張・本体アプリUI） | ⏳ 未着手 | macOS（クラウドMac可） |

エンジンは **Mac なしで、いま手元の Windows で開発・テストできる**。これが本プロジェクト最大の設計判断（→ `docs/ARCHITECTURE.md`）。

---

## リポジトリ構成

```
predictive-personas/
├── README.md              ← これ
├── docs/
│   ├── ARCHITECTURE.md    技術設計（2層分割・データモデル・iOS統合計画）
│   ├── SETUP-WINDOWS.md   WindowsでのSwift導入・ビルド・テスト手順
│   ├── ROADMAP.md         マイルストーン（受験スケジュールから逆算）
│   ├── DISTRIBUTION.md    配布・匿名性・Apple Developer・TestFlight
│   └── DECISIONS.md       技術調査と意思決定の記録（根拠つき）
└── engine/                ← クロスプラットフォーム Swift Package
    ├── Package.swift
    ├── Sources/PersonaEngine/   エンジン本体（iOSへ無改造で持ち込む）
    ├── Sources/persona-demo/    動作デモ（swift run persona-demo）
    └── Tests/                    ユニットテスト
```

---

## クイックスタート（Windows / Linux / macOS 共通）

Swift ツールチェーンを入れたら：

```bash
cd predictive-personas/engine
swift test          # 14 tests がパスする
swift run persona-demo   # ペルソナ切替・持ち運びのデモが流れる
```

Windows でのSwiftインストールからのStep-by-stepは → `docs/SETUP-WINDOWS.md`

---

## 次の一手

`docs/ROADMAP.md` の **M1**（エンジンの語彙強化）か **M2**（クラウドMacでiOSシェルに載せる）。
詳細は各docを参照。
