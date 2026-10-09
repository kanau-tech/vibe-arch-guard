# 🛡️ Vibe Arch Guard (日本語ドキュメント)

> **「3ヶ月後に全破棄・作り直し」を防ぐ。**  
> **Claude Code**、**Codex**、**Antigravity (Agy)**、**Cursor** 向けアーキテクチャ自動同期＆崩壊防止フレームワーク。

---

## ⚡ 課題：Vibe Coding の罠

AIコーディング支援ツールに機能を依頼すると、AIは**「とりあえず動く最短経路」**を自動選択します。その結果、モジュール境界や拡張性を考慮しないコードが積み上がり、3ヶ月後には修正不能なスパゲッティコードとなって**「最初から作り直し」**を余儀なくされます。

```text
従来のVibe Coding:
指示 ➔ AIが最短経路で乱雑実装 ➔ 結合度過多 ➔ 設計崩壊 ➔ 全面作り直し 💥

Vibe Arch Guard 適用時:
指示 ➔ /architecture-plan (27項目) ➔ 人間承認 ➔ 実装 & 自動同期 ➔ 乖離ゼロ ✅
```

---

## 🏛️ 3段階のアーキテクチャ制御

1. **第1段階：場当たりの質問 (Ad-hoc)**: 「アーキテクチャはどうなってる？」と聞くだけ。次セッションで忘れるためテスト目的のみ。
2. **第2段階：27項目の `ARCHITECTURE.md`（推奨・常用）**: 実コード行番号（`file:line`）に基づく完全同期ドキュメント。トークン消費を最小化しつつ設計ドリフトを完全抑止。
3. **第3段階：動的アーキテクチャシミュレータ**: 単一HTML（Vanilla JS）でデータ遷移とレイヤー点灯を可視化。顧客提案・ステークホルダー合意に絶大な効果。

---

## 🚀 クイックスタート (1分導入)

プロジェクトルートで以下を実行:

```bash
curl -fsSL https://raw.githubusercontent.com/kanau-tech/vibe-arch-guard/main/scripts/install.sh | bash
```

インストール後、Claude Code または Antigravity で `/architecture-plan` を実行するだけで、既存コードの100%逆解析または新規設計が完了します。

---

## 🛡️ 機械的検証とCIフェイルクローズド保証

プロンプト遵守の善意に頼るだけでなく、ローカルおよびCIでの物理的なブロック機構を提供します:

- **ローカル検証 (`./scripts/verify-sync.sh`)**:
  - `git status` / `git diff` を解析し、構造変更があるのに `ARCHITECTURE.md` が更新されていない場合は **`exit 1`** で即座に停止。
  - コミット前のステージング検査: `./scripts/verify-sync.sh --staged`
- **GitHub Actions CI (`.github/workflows/arch-drift-check.yml`)**:
  - PR作成時および `main` への直接Push時に自動検証。乖離がある場合はマージをブロック。
  - 例外回避（エスケープハッチ）: PRラベル `arch:no-structural-change` または コミットメッセージ `[skip-arch-drift]`

---

## 📜 ライセンス

MIT License © 2026 [Kanau Tech™](https://kanautech.jp).

