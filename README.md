# ghostpdf

A menu-driven wrapper around [Ghostscript](https://www.ghostscript.com/) for common PDF and PostScript tasks — convert, merge, split, compress, encrypt — without memorizing `-sDEVICE=` flags.

```
Ghostscript helper
==================
   1) PDF → PNG images
   2) PDF → JPEG images
   3) PDF → plain text
   4) Compress PDF (ebook)
   5) Merge PDFs
   6) Split PDF into single pages
   7) Extract page range
   8) PS/EPS → PDF
   9) PDF → PostScript
  10) Add password to PDF
  11) Help
  12) Quit

Choose [1-12]:
```

<!-- Replace with an asciinema cast or GIF, or delete this line. -->
![demo](docs/demo.gif)

## Why

Ghostscript is powerful but its command-line interface is dense and easy to get wrong. A single typo can silently overwrite an output file. `ghostpdf` wraps the most common operations in a menu, **shows the exact `gs` command before running it**, and asks for confirmation — so you learn the flags as you go instead of memorizing them.

If you already know Ghostscript, you can skip the menu and pass flags straight through:

```bash
ghostpdf -sDEVICE=pdfwrite -o out.pdf in.ps
```

## Features

- **Interactive menu** for the most common PDF / PostScript tasks
- **Pass-through mode** — non-interactive, drop-in replacement for `gs`
- **Confirmation prompt** before every command runs
- **Overwrite protection** — refuses to clobber an existing output file without asking
- **Dry-run mode** (`-n`) — print the `gs` command without executing it, so you can copy it into a script
- **No dependencies** beyond your shell (bash 3.2+ or fish 3.1+) and `gs`

## Install

### Bash

```bash
mkdir -p ~/.local/bin
curl -fsSL https://raw.githubusercontent.com/YOURNAME/ghostpdf/main/ghostpdf \
  -o ~/.local/bin/ghostpdf
chmod +x ~/.local/bin/ghostpdf
```

Make sure `~/.local/bin` is on your `PATH`. In `~/.bashrc` or `~/.zshrc`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

### Fish

```fish
curl -fsSL https://raw.githubusercontent.com/YOURNAME/ghostpdf/main/ghostpdf.fish \
  -o ~/.config/fish/functions/ghostpdf.fish
```

Fish autoloads functions from `~/.config/fish/functions/`, so no `chmod` is needed.

### From a clone

```bash
git clone https://github.com/YOURNAME/ghostpdf.git
cd ghostpdf

# Bash
install -Dm755 ghostpdf ~/.local/bin/ghostpdf

# Fish
install -Dm644 ghostpdf.fish ~/.config/fish/functions/ghostpdf.fish
```

## Requirements

- **Bash** 3.2+ (for `ghostpdf`) — works on stock macOS
- **Fish** 3.1+ (for `ghostpdf.fish`)
- **Ghostscript** (`gs`) on `PATH` — check with `gs --version`
  - Debian/Ubuntu: `sudo apt install ghostscript`
  - Fedora/RHEL: `sudo dnf install ghostscript`
  - Arch: `sudo pacman -S ghostscript`
  - macOS: `brew install ghostscript`

## Usage

### Interactive

```bash
ghostpdf
```

Pick an item, answer the prompts, review the command, confirm with `y`.

### Non-interactive

Pass Ghostscript arguments directly. Everything after the flags is forwarded to `gs`:

```bash
ghostpdf -sDEVICE=pdfwrite -o out.pdf in.ps
```

### Flags

| Flag | Description |
|------|-------------|
| `-h`, `--help` | Show help |
| `-V`, `--version` | Show version |
| `-n`, `--dry-run` | Interactive mode, but only print the `gs` command |

## Examples

Convert a PDF to PNGs at 300 DPI:

```bash
ghostpdf -sDEVICE=png16m -r300 -o page-%03d.png input.pdf
```

Merge two PDFs:

```bash
ghostpdf -sDEVICE=pdfwrite -o merged.pdf a.pdf b.pdf
```

Compress a PDF:

```bash
ghostpdf -sDEVICE=pdfwrite -dPDFSETTINGS=/ebook -o small.pdf big.pdf
```

Or do any of these through the menu, which lets you preview the command first.

## Ports

The repo ships two feature-equivalent ports:

- `ghostpdf` — POSIX-ish bash (3.2+), works on stock macOS
- `ghostpdf.fish` — fish (3.1+)

Both are maintained in lockstep. If you find a bug in one, please check the other.

## Known limitations

- **Not a PDF editor.** It converts and processes pages; it won't edit text, forms, or annotations.
- **Complex PDFs may lose features** after round-tripping through Ghostscript (bookmarks, links, form fields).
- **Passwords are echoed** in the "Add password to PDF" menu item. Use pass-through mode with `-sOwnerPassword=` / `-sUserPassword=` if that matters to you.
- **Interactive prompts are not sanitized.** This is fine for personal use; don't expose it as a service.

## Contributing

Issues and pull requests are welcome.

- **Bash:** run `shellcheck ghostpdf` and `shfmt -d -i 4 ghostpdf` before submitting.
- **Fish:** run `fish -n ghostpdf.fish` to check syntax.
- Keep both ports compatible with **bash 3.2** and **fish 3.1** respectively — no associative arrays, no `${var,,}`, no `mapfile`, no `read -a`.

## Related tools

If `ghostpdf` isn't the right fit, these might be:

- [`qpdf`](https://qpdf.readthedocs.io/) — structural PDF transformations, encryption
- [`pdftk`](https://gitlab.com/pdftk-java/pdftk) — split, merge, rotate, forms
- [`ocrmypdf`](https://ocrmypdf.readthedocs.io/) — add a text layer via OCR
- [`mutool`](https://mupdf.com/) — MuPDF's command-line tool
- [`img2pdf`](https://gitlab.mister-muffin.de/josch/img2pdf) — lossless image-to-PDF

`ghostpdf` is deliberately a small, readable wrapper — not a competitor to these.

## License

**GPL-3.0-or-later.** See [LICENSE](LICENSE.md).

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but **without any warranty**; without even the implied warranty of merchantability or fitness for a particular purpose. See the GNU General Public License for more details.

The license choice mirrors Ghostscript itself, which is also GPL-3.0-or-later.

