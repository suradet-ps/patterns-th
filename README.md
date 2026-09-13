# patterns-th

```
██████╗  █████╗ ████████╗████████╗███████╗██████╗ ███╗   ██╗███████╗        ████████╗██╗  ██╗
██╔══██╗██╔══██╗╚══██╔══╝╚══██╔══╝██╔════╝██╔══██╗████╗  ██║██╔════╝        ╚══██╔══╝██║  ██║
██████╔╝███████║   ██║      ██║   █████╗  ██████╔╝██╔██╗ ██║███████╗ █████╗    ██║   ███████║
██╔═══╝ ██╔══██║   ██║      ██║   ██╔══╝  ██╔══██╗██║╚██╗██║╚════██║ ╚════╝    ██║   ██╔══██║
██║     ██║  ██║   ██║      ██║   ███████╗██║  ██║██║ ╚████║███████║          ██║   ██║  ██║
╚═╝     ╚═╝  ╚═╝   ╚═╝      ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝          ╚═╝   ╚═╝  ╚═╝
```

---

## ◆ PULSE

[![GitHub Pages](https://img.shields.io/badge/Pages-live-2ea44f)](https://suradet-ps.github.io/patterns-th/)
[![License](https://img.shields.io/badge/license-MPL--2.0-blue.svg)](#-anatomy)

A Rust design pattern has a name, a shape, and a trade-off - patterns-th
is the Thai bridge to that catalogue. This is the complete Thai
translation of the official Rust Design Patterns book: 50 pages built
with mdbook, terminology locked by a single glossary, and every code
block byte-identical to the original. The links are checked against the
built book (632 anchors), the structure mirrors the upstream repo
file-for-file, and the license travels with the text. Built for the
Thai-speaking Rustacean:
[suradet-ps.github.io/patterns-th](https://suradet-ps.github.io/patterns-th/).

| แปลครบ 50 หน้า ▣ | Glossary ▣ | ลิงก์ 632/632 ▣ | Build ผ่าน ▣ |
|---|---|---|---|

*v1.0.0 - translation, glossary, verification, and the static build
are all sealed.*

> Built with mdbook 0.5 + Markdown, translated from
> [rust-unofficial/patterns](https://github.com/rust-unofficial/patterns),
> verified by script and rendered as static HTML - a book with the
> pages on the page.
>
> **suradet-ps**, artifact keeper

---

## ◆ IGNITION

One runtime, three commands.

```
⟫ git clone https://github.com/suradet-ps/patterns-th.git
⟫ cd patterns-th
⟫ cargo install mdbook
⟫ mdbook serve --open
```

Open [http://localhost:3000](http://localhost:3000).

```
⟫ mdbook build                                  # static HTML into book/
⟫ powershell scripts/check-links.ps1           # all anchors in the built book (pwsh on Linux/macOS)
⟫ powershell scripts/verify-translation.ps1    # byte-exact check vs upstream
```

> On Linux or macOS, run the verification scripts using `pwsh scripts/<script>.ps1`.
> `verify-translation.ps1` checks against `rust-unofficial/patterns` in adjacent directories or via `-Orig <path>`.

<details>
<summary>Translating a chapter</summary>

A chapter is a file: `src/<chapter>.md`, listed in `src/SUMMARY.md`.
The glossary lives in `GLOSSARY.md` - a term is chosen once and reused
everywhere. Code blocks, commands, links, and filenames stay verbatim;
only prose and headings are translated. Heading anchors follow mdbook's
slug rules (Thai tone marks are stripped), so anchors are copied from
the built HTML, never guessed.

</details>

---

## ◆ ANATOMY

One stack, zero custom JS, several quiet helpers.

- **Translates** - the complete book: introduction, 17 idiom chapters
  with FFI idioms, 14 design pattern chapters, 3 anti-patterns, 3
  functional programming chapters, and the design principles - Thai
  prose over untouched code.
- **Glossaries** - `GLOSSARY.md` locks the vocabulary (design pattern =
  ดีไซน์แพตเทิร์น, ownership = ความเป็นเจ้าของ, borrow checker = borrow
  checker), so chapter nine agrees with chapter two.
- **Verifies** - `scripts/verify-translation.ps1` diffs every code
  block, heading level, and link target against upstream
  `rust-unofficial/patterns` - byte-exact or it does not pass.
- **Checks** - `scripts/check-links.ps1` walks the built book and
  resolves every anchor link against real heading ids - 632 of them,
  all reachable.
- **Builds** - mdbook renders static HTML into `book/`, zero server
  runtime, readable offline and searchable by built-in static index.
- **Licenses** - MPL-2.0, inherited from upstream, with the LICENSE
  file shipped beside the text.

---

## ◆ RITUALS

**The core ceremony** - the translation pass:

1. Open a chapter in `src/`. The upstream `rust-unofficial/patterns`
   repo sits beside it (clone
   `https://github.com/rust-unofficial/patterns` alongside
   `patterns-th`) - structure is a contract.
2. Translate the prose; keep every code block and command as the
   original wrote it.
3. Consult `GLOSSARY.md` for every term that already has a canon.
   New terms get proposed in the glossary first.
4. Build, verify, check. The book builds clean, the diff is
   byte-exact, and the anchors resolve.

**The ceremony of the anchor** - mdbook slugs strip Thai tone marks
(`ตัวอย่าง` becomes `ตัวอยาง`). Anchors are read from the built HTML,
written into the source, and re-verified - a guessed anchor is a broken
link waiting to happen.

**The ceremony of the code block** - a translated command that is not
byte-identical to the original is a regression, not a translation.
The verifier is the conscience of the repo.

---

## ◆ ECHOES

**Where this artifact is heading**

```
P1 ▸ SUMMARY + introduction, translations, section indexes ────────── ▸ sealed
P2 ▸ all 17 idiom chapters + FFI idioms ───────────────────────────── ▸ sealed
P3 ▸ all 14 design pattern chapters ───────────────────────────────── ▸ sealed
P4 ▸ anti-patterns, functional chapters, design principles ────────── ▸ sealed
P5 ▸ glossary, license, link verification, mdbook build ───────────── ▸ sealed
```

**Raising the artifact** - the honest path lives in `GLOSSARY.md`
(term canon), `scripts/` (the verification gate), and `book.toml`
(book config). New chapters follow the frontmatter-free contract of
the SUMMARY. Open an issue first to discuss a change.

**Status** - on every change: `mdbook build` must pass, the
translation verifier must report byte-exact code blocks across all 52
files (50 chapters + `SUMMARY.md` + `refactoring/index.md`), and the
link checker must report `ALL ANCHOR LINKS OK`.
[Watch the gates](scripts).

---

```
  ─────────────────────────────────────────
   ทุกแพตเทิร์นมีข้อแลกเปลี่ยนของมัน
   ทุกหนังสือมีหน้าแรกของมัน
  ─────────────────────────────────────────
```

Translated from the [Rust Design Patterns](https://github.com/rust-unofficial/patterns)
book, which is licensed under [MPL-2.0](LICENSE).
