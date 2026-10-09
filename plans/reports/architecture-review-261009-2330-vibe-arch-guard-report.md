# Vibe Arch Guard アーキテクチャレビュー

- 日付: 2026-10-09
- 対象コミット: `e917c43`
- 対象: `.claude/rules/architecture-sync.md` / `.claude/commands/architecture-plan.md` / `templates/ARCHITECTURE_TEMPLATE.md` / `scripts/verify-sync.sh` / `README.md`（周辺: `scripts/install.sh`、`.github/workflows/arch-drift-check.yml`、Cursor/Agy 向け複製）
- 根拠の区分: **Confirmed** = 手元で再現・実測 / **Estimated** = 条件を置いた推定

## 総合評価

着想と梱包は良い。「27項目の SSOT ＋ 同ターン同期 ＋ 状態記号 ＋ Changelog」という設計自体は、Vibe Coding の劣化に対する正しい処方で、Claude Code の `.claude/rules` に置けば毎セッション自動で読まれる（この環境で実測）。

ただし **機械的な層は全部「警告どまり」** で、保証の実体はプロンプト順守だけ。さらに **同梱テンプレートとインストーラが初日から「100% 現物根拠」の約束を裏切る**（`✅ 確定済` の偽ヘッダーと `✅` 付き架空スタックを設計書として植え付け、設計先行ゲートを二度と発火させない）。README の一行インストールも動かない。

評価: **設計 B＋ / 実装 C−**。直すべき順は ①インストーラと テンプレート ②fail-closed 化 ③「構造変更」の定義を1か所に ④`file:line` と ハッシュの検証可能化。

---

## 1. 設計の強み・実効性

1. **ルールの配置が正しい**（Confirmed）。`.claude/rules/*.md` はこの環境で project instructions として自動注入されていた。約 3.9KB ≈ 1.5k トークンで常駐コストは妥当。
2. **状態記号 4 種（✅ ◼ ⚠️ 打消し）** は「未実装の設計」と「実装済み」を分ける最小の語彙で、AI に「推測で ✅ を書かない」を言語化できている。
3. **Changelog を §27 に集約**し、更新項目（§4, §9）を書かせる形は、レビュアーが差分の当たり先を追える。
4. **「現物根拠・`> Not Found` 明記」** を `/architecture-plan` に書いたのは正しい。リバースエンジニアリングの幻覚対策として有効（ただし検証手段が無い。§2-4 参照）。
5. **4 ツール対応の梱包**（Claude / Cursor / Agy / Codex）と GIF・動画入り README は配布物として完成度が高い。
6. **§6 例外規定** があるので「typo 修正にも設計書更新」という過剰儀式を避けられる（ただし抜け穴にもなる。§2-3 参照）。

---

## 2. 死角・エッジケース

### 2-1. インストーラが設計先行ゲートを自分で潰す（Confirmed）

- `install.sh:31-34` はテンプレートをそのまま `docs/02-ky-thuat/architecture.md` に置く。テンプレート冒頭は `ステータス: ✅ 確定済 (2026-10-09) · 同期コミット: a1b2c3d`、§2 技術スタック表は PostgreSQL / Redis / AWS が全行 `✅`（テンプレート内の `✅` は 8 個）。§7 の「JWT 15分 / Refresh 7日」、§13 の Stripe / SendGrid は記号すら無く事実として読める。
- ルール §1-1 の「設計書が存在しない場合に `/architecture-plan` を実行し人間の承認を得る」は、**インストール直後から「存在する」ので二度と発火しない**。次のセッションの AI は、架空のスタックを `✅ 確定済` の SSOT として継承する。「100% 現物根拠」の逆を初日にやる。

### 2-2. 機械的な層に強制力が無い（Confirmed）

| 層 | 挙動 | 結果 |
|---|---|---|
| `verify-sync.sh` | 乖離でも `exit 0` | 止まらない |
| CI `arch-drift-check.yml:31` | `::warning` のみ | マージ可能 |
| `install.sh` | `verify-sync.sh` も workflow も**コピーしない** | 「1分インストール」では CI が入らない |
| CI トリガ | `pull_request` のみ | **main 直 push（ソロの vibe coder の典型）では一度も走らない** |

`MANDATORY` と書いてあるが、守るかどうかはモデル次第。

### 2-3. AI の規則回避の経路（ユーザーが挙げた論点）

検査が **「ファイルに触ったか」** であって **「中身が正しいか」** ではない（Confirmed: `verify-sync.sh:26` の porcelain grep と CI の `grep -qE` はどちらも 1 行の Changelog 追記で通る）。具体的な回避経路:

1. **Changelog 1 行だけ足して本文を直さない**（CI も verify-sync も緑）。
2. **§6-3「関数内部の改善」への自己分類**。「構造変更か」を AI 自身が判定する作りなので、新しい Job やエンドポイントを「ロジック改善」と呼べば同期義務が消える。
3. **全部 `◼ Planned` にする／スキャンしていない章を `> Not Found` にする**。DoD「27 項目漏れなく」は記号で満たせる。
4. **ヘッダーのハッシュ自己申告**。検証無し（§2-4）。
5. **設計意図の反転**: §1-3 で AI に設計書の常時書込権限を与え、§1-2 で「コードと同じターンに書け」と言う。つまり **設計書はコードの後を追う**。検証されるのは「同時に動いたか」で、「先に承認されたか」ではない。「設計先行」を謳う仕組みが、機構としては「設計追従」になっている。
6. **ヘッドレス実行**（`claude -p`、CI 内エージェント）には承認者がいない。「ユーザーの承認を得てから」に代替経路が無いので、AI は止まるか自己承認するかのどちらか。

### 2-4. `file:line` と 同期コミットは検証不能で腐る（Confirmed: 検証コードが無い）

- DoD は「`file:line` が正確に検証されていること」を要求するが、パスの実在も行範囲も誰も確かめない。引用行より上を 1 行編集するたびに全引用が黙ってずれる。
- 「同期コミット: `hash`」は **鶏と卵**。設計書更新を含むコミットは自分のハッシュを知れないので、常に親コミットか作り物になる。しかもルール・script・CI のどれもこの値を読まない。

### 2-5. 「構造変更」の定義が 3 つあって一致しない（Confirmed）

| 定義場所 | 範囲 |
|---|---|
| ルール §1-2（散文） | サービス追加・モジュール分割・DB・外部連携・エンドポイント・Job・環境変数 |
| `verify-sync.sh:25` | 拡張子 `ts/js/py/go/rs/prisma/sql/json` |
| CI `paths:` | `src/ apps/ packages/ prisma/ migrations/` |

実測: `package.json` だけ変えると警告（誤検知）、`src/a.tsx` を足しても合格（見逃し）、`.env.example`・`Dockerfile`・`*.toml`・`*.yaml`・`infra/`・`app/`（Next.js App Router がルート直下）・`cmd/`・`internal/` はどの機械検査にも掛からない。

### 2-6. モノレポ（ユーザーが挙げた論点）

- 設計書は **1 枚** 前提。CI の `paths:` に `apps/**` `packages/**` があるのに、確認先はルートの 1 ファイルだけ。変更パス → 担当設計書 の解決が無い。
- §27 Changelog は末尾追記の単一ファイルなので、**並行 PR が全部 Changelog の最終行で衝突**する。
- `docs/02-ky-thuat`（ベトナム語「kỹ thuật」）が「universal」の既定パスに焼き付いている。ルール §2 は `docs/ARCHITECTURE.md` も既定と書くが、`verify-sync.sh` はそのパスでは `exit 1`（`verify-sync.sh:7-14`）。

### 2-7. トークン上限（ユーザーが挙げた論点）

- 空のテンプレートで 11.5KB・266 行。**Estimated**: 中規模リポ（エンドポイント 30・テーブル 20）で全主張に `file:line` と Mermaid を付けると 60〜150KB ≈ 15k〜40k トークン（1 行 60 バイト・1 トークン 4 バイトで概算）。「同ターン同期」のたびに AI がこれを読む。この環境の `docs.maxLoc: 800` を大きく超える。
- 27 項目は **Q レベルに関係なく「漏れなく」**。§1 に Q1〜Q4 を書かせるのに、Q1 Prototype でも RPO/RTO・サーキットブレーカー・Alertmanager の章を `> Not Found` で埋める。
- `/architecture-plan` に **章単位・差分モードが無い**。`verify-sync.sh:30` の助言は「`/architecture-plan` を実行」なので、乖離 1 件ごとに全 27 章の再生成と全文 churn になる。
- Cursor は `.cursorrules` と `alwaysApply: true` の `.mdc` を**両方**入れるので、同じ規則が二重注入される。

### 2-8. 4 ツール間でルール本文が食い違う（Confirmed）

| 項目 | Claude ルール | Cursor `.mdc` | `.cursorrules` | `SKILL.md` |
|---|---|---|---|---|
| 人間の承認 | あり | **無し**（propose and generate） | 無し | 無し |
| 同ターン同期 | あり | あり | あり | **無し** |
| §6 例外 | あり | 無し | 無し | 無し |
| ヘッダー文言 | 日本語 | 英語 | 無し | 英語 |
| `⚠️` の意味 | Drift / Review | Drift/Review | **Needs Review** | 無し |

Claude と Cursor を併用するチームでは、ヘッダーの言語がツールごとに入れ替わり、将来ヘッダーを機械検査しようとした瞬間に壊れる。`skills/` と `.agents/skills/` は同一内容の二重保持で、インストーラは `skills/` からしか読まない。README の Codex 行は `skills/` と書くが実体は `.agents/skills/`（Codex がどちらを読むかは未検証）。

### 2-9. インストーラの壊れ方（Confirmed）

- **README の一行インストール（`curl | bash`）が動かない**。stdin 実行では `BASH_SOURCE[0]` が空 → `SCRIPT_DIR` が cwd の親 → `cp` 失敗で `rc=1`。`mkdir -p` が先に走るので `docs/02-ky-thuat/` 等の空ディレクトリだけ残る。コメント「clone repo if run via curl」に対応するコードは無い。
- **既存の `.cursorrules` を無条件に上書き**（`install.sh:26`）。ルール 4 ファイルも `-n` 無し・控え無しで上書き。再インストール＝利用者のカスタマイズ消失。
- `verify-sync.sh` は相対パス前提で、サブディレクトリから実行すると「設計書が無い」で `exit 1`。

### 2-10. 細かい乖離

- README に貼った CI 抜粋は `ARCHITECTURE\.md` しか見ず、実物の workflow（2 パス対応）と違う。乖離防止ツールの README が乖離している。
- `◼`（U+25FC）は手入力しにくく、`■`（U+25A0）と見分けがつかない。grep 検査を書くときに表記揺れの温床。
- `✅` の定義「テストまたは動作が確認されている」は、リバースエンジニアリング時に AI が確かめられない。実際は「コードがある」だけで `✅` が付く。

---

## 3. 堅牢化の具体提案（死角と 1 対 1）

### 3-1. インストーラとテンプレート（最優先）

1. `install.sh` で `BASH_SOURCE[0]` が空のときは tarball を一時ディレクトリへ取得してから `cp`（または「curl 経由は非対応」と README から消す）。
2. 既存ファイルは上書きせず `*.vag.new` を置いて差分を出す。`.cursorrules` は **append** に変える。
3. テンプレートの状態記号を全部 `◼`／空欄にし、ヘッダーを `ステータス: ◼ 未確定（/architecture-plan 未実行）` にする。§7・§13 の具体値（JWT 15 分・Stripe）はプレースホルダ `[ ]` に戻す。
4. ルール §1-1 の発火条件を「設計書が無い」から **「ヘッダーが `✅ 確定済` でない」** に変える。これで 3 が効く。
5. `install.sh` が `verify-sync.sh` と workflow もコピーする（README の「What gets installed」と一致させる）。

### 3-2. fail-closed にする

1. `verify-sync.sh`: 乖離で `exit 1`。`git rev-parse --show-toplevel` に `cd` してから動く。`--staged` で pre-commit に挟める形にする。
2. CI: `::error` + `exit 1`。逃がし道は **人間しか付けられないラベル**（例 `arch:no-structural-change`）だけ。`push` to main でも走らせる。
3. Claude Code には `Stop` フック（または `PreToolUse` の Bash/Write 監視）で「構造パターンに当たるファイルが変わり設計書が変わっていない」なら停止理由を返す。散文のルールは機構の控えにする。

### 3-3. 「構造変更」の定義を 1 か所に

- `.archguard.yml` にパターンを書き、ルール・`verify-sync.sh`・CI・フックの全部がそれを読む。例:

```yaml
structural:
  - "src/**/routes/**"
  - "**/migrations/**"
  - "**/schema.prisma"
  - ".env.example"
  - "docker-compose*.yml"
  - "infra/**"
docs:
  - path: "ARCHITECTURE.md"
    owns: ["**"]
```

- これで §6-3 の「AI 自身による分類」が消える。構造変更かどうかはパスで決まり、AI の自己申告ではなくなる。

### 3-4. 「触ったか」から「中身が合っているか」へ

1. 検査: 設計書の差分に **今回変わったソースのパス** か **今日の日付の Changelog 行** が含まれていなければ不合格。
2. `file:line` → **`path#symbol`**（関数名・クラス名）を一次の引用にし、行番号は任意にする。検査スクリプトはパス実在と `grep -n "symbol"` でシンボル実在を確かめる。行番号のズレで腐らない。
3. 同期コミットは「設計書が検証したコードの HEAD」と定義し直し、CI で `git merge-base --is-ancestor <hash> HEAD` と `git diff --stat <hash> HEAD -- <structural paths>` が空であることを確かめる。空でなければ `⚠️ 乖離` を機械で付ける。これで鶏と卵が解ける。

### 3-5. モノレポ

- `apps/<x>/ARCHITECTURE.md` ＋ ルートはインデックス（§3 と §12 だけ）。変更パスから最も近い祖先の設計書を担当とする（`.archguard.yml` の `owns`）。
- Changelog 衝突は `docs/arch-changes/<PR 番号>.md` の断片方式（towncrier 型）にし、リリース時に §27 へ畳む。

### 3-6. トークン

- Q レベルで章数を段階化: Q1 = §1〜6, 9, 10, 27 の 9 章 / Q2 = ＋§7, 8, 13, 14, 21 / Q3 以上 = 27 章。`/architecture-plan` が §1 の Q を読んで決める。
- `/architecture-plan --section 9` のような章単位モードと、`--since <hash>` の差分モードを足す。`verify-sync.sh` の助言もそれに変える。
- 設計書の上限を `verify-sync.sh` で検査（例 800 行）。超えたら章を `docs/architecture/NN-*.md` に分割し、ルートはインデックスにする。同ターン同期で読むのは触った章だけになる。
- Cursor は `.cursorrules` と `.mdc` のどちらか 1 つにする。

### 3-7. 4 ツールの単一ソース化

- `rules/architecture-sync.src.md` を正とし、Claude/Cursor/Agy 向けはビルドで生成する。CI に「4 変種の必須条項（承認・同ターン・例外・記号定義・ヘッダー書式）が全部入っているか」の parity テストを置く。
- ヘッダーは言語に依らない機械可読形式を 1 つ決める（例 `<!-- archguard: synced=<hash> status=confirmed date=YYYY-MM-DD -->`）。表示用の日本語・英語はその下に自由に書く。
- `.agents/skills/` の二重保持をやめる（`skills/` だけ残す）。

### 3-8. ヘッドレス実行

- 承認者がいないときは `◼ 未承認` のまま設計書だけ書いて **コードを書かずに終了**する、をルールとフックの両方に書く。自己承認を禁止する。

---

## 4. 評価サマリ

| 観点 | 評価 | 一言 |
|---|---|---|
| 着想・問題設定 | A | Vibe Coding 劣化への処方として正しい |
| ルール本文（Claude 版） | B＋ | 語彙と例外規定は良い。承認ゲートが機構化されていない |
| テンプレート | C | 架空の `✅` が幻覚の種。初日に SSOT を汚す |
| `verify-sync.sh` / CI | C− | 全部 advisory。定義が 3 つ。main 直 push は未検査 |
| インストーラ | D | 一行インストールが動かず、既存ファイルを壊す |
| 4 ツール整合 | C | 必須条項が変種ごとに欠ける |

---

## 実測ログ（再現手順）

```bash
# A. curl|bash 経路: rc=1、docs/ の空ディレクトリだけ残る
cat scripts/install.sh | bash -s -- .

# B. 既存 .cursorrules が上書きされる
echo "MY CUSTOM RULE" > .cursorrules && bash install.sh . && head -1 .cursorrules
# → "# Cursor / Windsurf Global Rules: Architecture Sync"

# C. verify-sync: package.json だけで警告 / src/a.tsx 追加で合格 / src/ から実行で exit 1
```

## 未解決の問い

- Codex CLI が `.agents/skills/` を自動で読むかは未検証（README の Codex 行の根拠）。
- Cursor `.mdc` の `globs: **/*` を Cursor の YAML パーサが受け付けるかは未検証（`*` 始まりは厳密な YAML ではエイリアス記号）。
