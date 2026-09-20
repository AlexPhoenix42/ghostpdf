#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Alex Phoenix <alex-phoenix@example.com>
#
# ghostpdf — menu-driven Ghostscript helper

set -u

VERSION="1.0.0"
DRY_RUN=0

# ---------- Help ----------
ghostpdf_help() {
    cat <<'EOF'
ghostpdf — menu-driven Ghostscript helper

Usage:
  ghostpdf                  Show interactive menu
  ghostpdf -h | --help      Show this help
  ghostpdf -V | --version   Show version
  ghostpdf -n | --dry-run   Menu mode, but only print the gs command
  ghostpdf <args...>        Pass args straight to gs (non-interactive)

Examples:
  ghostpdf -sDEVICE=pdfwrite -o out.pdf in.ps
  ghostpdf -sDEVICE=png16m -r150 -o page-%03d.png in.pdf

Notes:
  • Interactive mode shows the exact gs command and asks for confirmation.
  • Existing output files trigger an extra overwrite prompt.
  • Requires 'gs' (Ghostscript) on PATH.
EOF
}

# ---------- Helpers ----------

confirm() {
    local reply
    read -r -p "$1" reply || return 1
    case "$reply" in
        y|Y|yes|YES|Yes) return 0 ;;
        *) return 1 ;;
    esac
}

require_file() {
    if [ -z "$1" ]; then
        echo "$2: no path given." >&2
        return 1
    fi
    if [ ! -e "$1" ]; then
        echo "$2: '$1' does not exist." >&2
        return 1
    fi
}

run_gs() {
    local out="$1"; shift
    local -a cmd=("$@")

    echo
    echo "Command:"
    printf '  '
    printf '%q ' "${cmd[@]}"
    printf '\n\n'

    if [ -n "$out" ] && [ -e "$out" ]; then
        if ! confirm "Output '$out' exists. Overwrite? [y/N] "; then
            echo "Skipped."
            return 1
        fi
    fi

    if [ "$DRY_RUN" -eq 1 ]; then
        echo "(dry-run: not executing)"
        return 0
    fi

    if ! confirm "Run this command? [y/N] "; then
        echo "Cancelled."
        return 1
    fi

    "${cmd[@]}"
}

# ---------- Actions ----------

act_png() {
    local in dpi pre
    read -r -p "Input PDF: " in || return 1
    require_file "$in" "Input PDF" || return 1
    read -r -p "DPI [150]: " dpi || return 1
    [ -z "$dpi" ] && dpi=150
    read -r -p "Output prefix [page]: " pre || return 1
    [ -z "$pre" ] && pre=page
    run_gs "" gs -sDEVICE=png16m -r"$dpi" -o "${pre}-%03d.png" "$in"
}

act_jpeg() {
    local in dpi q pre
    read -r -p "Input PDF: " in || return 1
    require_file "$in" "Input PDF" || return 1
    read -r -p "DPI [150]: " dpi || return 1
    [ -z "$dpi" ] && dpi=150
    read -r -p "JPEG quality [85]: " q || return 1
    [ -z "$q" ] && q=85
    read -r -p "Output prefix [page]: " pre || return 1
    [ -z "$pre" ] && pre=page
    run_gs "" gs -sDEVICE=jpeg -r"$dpi" -dJPEGQ="$q" -o "${pre}-%03d.jpg" "$in"
}

act_txt() {
    local in out
    read -r -p "Input PDF: " in || return 1
    require_file "$in" "Input PDF" || return 1
    read -r -p "Output text file [output.txt]: " out || return 1
    [ -z "$out" ] && out=output.txt
    run_gs "$out" gs -sDEVICE=txtwrite -o "$out" "$in"
}

act_compress() {
    local in out
    read -r -p "Input PDF: " in || return 1
    require_file "$in" "Input PDF" || return 1
    read -r -p "Output PDF [compressed.pdf]: " out || return 1
    [ -z "$out" ] && out=compressed.pdf
    run_gs "$out" gs -sDEVICE=pdfwrite -dPDFSETTINGS=/ebook -o "$out" "$in"
}

act_merge() {
    local out f
    local -a files=()

    read -r -p "Output PDF [merged.pdf]: " out || return 1
    [ -z "$out" ] && out=merged.pdf

    echo "Enter input PDFs one per line. Empty line to finish:"
    while IFS= read -r f && [ -n "$f" ]; do
        files+=("$f")
    done

    if [ "${#files[@]}" -eq 0 ]; then
        echo "No inputs given." >&2
        return 1
    fi
    for f in "${files[@]}"; do
        require_file "$f" "Input PDF" || return 1
    done
    run_gs "$out" gs -sDEVICE=pdfwrite -o "$out" "${files[@]}"
}

act_split() {
    local in
    read -r -p "Input PDF: " in || return 1
    require_file "$in" "Input PDF" || return 1
    run_gs "" gs -sDEVICE=pdfwrite -o page-%d.pdf "$in"
}

act_extract() {
    local in first last out
    read -r -p "Input PDF: " in || return 1
    require_file "$in" "Input PDF" || return 1
    read -r -p "First page: " first || return 1
    read -r -p "Last page: " last || return 1
    read -r -p "Output PDF [extract.pdf]: " out || return 1
    [ -z "$out" ] && out=extract.pdf
    run_gs "$out" gs -sDEVICE=pdfwrite -dFirstPage="$first" -dLastPage="$last" -o "$out" "$in"
}

act_ps2pdf() {
    local in out
    read -r -p "Input PS/EPS: " in || return 1
    require_file "$in" "Input PS/EPS" || return 1
    read -r -p "Output PDF [output.pdf]: " out || return 1
    [ -z "$out" ] && out=output.pdf
    run_gs "$out" gs -sDEVICE=pdfwrite -o "$out" "$in"
}

act_pdf2ps() {
    local in out
    read -r -p "Input PDF: " in || return 1
    require_file "$in" "Input PDF" || return 1
    read -r -p "Output PS [output.ps]: " out || return 1
    [ -z "$out" ] && out=output.ps
    run_gs "$out" gs -sDEVICE=ps2write -o "$out" "$in"
}

act_encrypt() {
    local in out owner user
    read -r -p "Input PDF: " in || return 1
    require_file "$in" "Input PDF" || return 1
    read -r -p "Output PDF [encrypted.pdf]: " out || return 1
    [ -z "$out" ] && out=encrypted.pdf
    read -r -p "Owner password: " owner || return 1
    read -r -p "User password: " user || return 1
    run_gs "$out" gs -sDEVICE=pdfwrite -sOwnerPassword="$owner" -sUserPassword="$user" -o "$out" "$in"
}

# ---------- Main ----------

ghostpdf_main() {
    if ! command -v gs >/dev/null 2>&1; then
        echo "Error: ghostscript (gs) not found in PATH" >&2
        return 1
    fi

    local -a passthrough=()
    local arg
    for arg in "$@"; do
        case "$arg" in
            -h|--help)    ghostpdf_help; return 0 ;;
            -V|--version) echo "ghostpdf $VERSION"; return 0 ;;
            -n|--dry-run) DRY_RUN=1 ;;
            *)            passthrough+=("$arg") ;;
        esac
    done

    if [ "${#passthrough[@]}" -gt 0 ]; then
        if [ "$DRY_RUN" -eq 1 ]; then
            printf 'gs'
            printf ' %q' "${passthrough[@]}"
            printf '\n'
        else
            gs "${passthrough[@]}"
        fi
        return $?
    fi

    local -a choices=(
        "PDF → PNG images"
        "PDF → JPEG images"
        "PDF → plain text"
        "Compress PDF (ebook)"
        "Merge PDFs"
        "Split PDF into single pages"
        "Extract page range"
        "PS/EPS → PDF"
        "PDF → PostScript"
        "Add password to PDF"
        "Help"
        "Quit"
    )

    local choice i
    while true; do
        echo
        echo "Ghostscript helper"
        echo "=================="
        for i in "${!choices[@]}"; do
            printf "  %2d) %s\n" "$((i + 1))" "${choices[$i]}"
        done
        echo

        if ! read -r -p "Choose [1-${#choices[@]}]: " choice; then
            echo
            return 0
        fi

        if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
            echo "Invalid choice."
            continue
        fi
        if (( choice < 1 || choice > ${#choices[@]} )); then
            echo "Out of range."
            continue
        fi

        case "$choice" in
            1)  act_png ;;
            2)  act_jpeg ;;
            3)  act_txt ;;
            4)  act_compress ;;
            5)  act_merge ;;
            6)  act_split ;;
            7)  act_extract ;;
            8)  act_ps2pdf ;;
            9)  act_pdf2ps ;;
            10) act_encrypt ;;
            11) ghostpdf_help ;;
            12) return 0 ;;
        esac

        echo
        read -r -p "Press Enter to continue..." _ || return 0
    done
}

ghostpdf_main "$@"

