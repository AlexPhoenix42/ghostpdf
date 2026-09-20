#!/usr/bin/env fish
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Your Name <you@example.com>
#
# ghostpdf — menu-driven Ghostscript helper

set -g __ghostpdf_version 1.0.0
set -g __ghostpdf_dry_run 0

# ---------- Help ----------
function __ghostpdf_help
    echo "ghostpdf — menu-driven Ghostscript helper"
    echo
    echo "Usage:"
    echo "  ghostpdf                  Show interactive menu"
    echo "  ghostpdf -h | --help      Show this help"
    echo "  ghostpdf -V | --version   Show version"
    echo "  ghostpdf -n | --dry-run   Menu mode, but only print the gs command"
    echo "  ghostpdf <args...>        Pass args straight to gs (non-interactive)"
    echo
    echo "Examples:"
    echo "  ghostpdf -sDEVICE=pdfwrite -o out.pdf in.ps"
    echo "  ghostpdf -sDEVICE=png16m -r150 -o page-%03d.png in.pdf"
    echo
    echo "Notes:"
    echo "  • Interactive mode shows the exact gs command and asks for confirmation."
    echo "  • Existing output files trigger an extra overwrite prompt."
    echo "  • Requires 'gs' (Ghostscript) on PATH."
end

# ---------- Helpers ----------

function __ghostpdf_confirm
    read -P "$argv[1]" -l reply; or return 1
    string match -qi -r '^(y|yes)$' -- $reply
end

function __ghostpdf_require_file
    if test -z "$argv[1]"
        echo "$argv[2]: no path given." >&2
        return 1
    end
    if not test -e "$argv[1]"
        echo "$argv[2]: '$argv[1]' does not exist." >&2
        return 1
    end
    return 0
end

function __ghostpdf_run
    set -l out $argv[1]
    set -l cmd $argv[2..-1]

    echo
    echo "Command:"
    echo "  "(string join ' ' -- (string escape -- $cmd))
    echo

    if test -n "$out"; and test -e "$out"
        if not __ghostpdf_confirm "Output '$out' exists. Overwrite? [y/N] "
            echo "Skipped."
            return 1
        end
    end

    if test $__ghostpdf_dry_run -eq 1
        echo "(dry-run: not executing)"
        return 0
    end

    if not __ghostpdf_confirm "Run this command? [y/N] "
        echo "Cancelled."
        return 1
    end

    $cmd
end

# ---------- Actions ----------

function __ghostpdf_act_png
    read -P "Input PDF: " -l in; or return 1
    __ghostpdf_require_file "$in" "Input PDF"; or return 1
    read -P "DPI [150]: " -l dpi; or return 1
    test -z "$dpi"; and set dpi 150
    read -P "Output prefix [page]: " -l pre; or return 1
    test -z "$pre"; and set pre page
    __ghostpdf_run "" gs -sDEVICE=png16m -r$dpi -o "$pre-%03d.png" "$in"
end

function __ghostpdf_act_jpeg
    read -P "Input PDF: " -l in; or return 1
    __ghostpdf_require_file "$in" "Input PDF"; or return 1
    read -P "DPI [150]: " -l dpi; or return 1
    test -z "$dpi"; and set dpi 150
    read -P "JPEG quality [85]: " -l q; or return 1
    test -z "$q"; and set q 85
    read -P "Output prefix [page]: " -l pre; or return 1
    test -z "$pre"; and set pre page
    __ghostpdf_run "" gs -sDEVICE=jpeg -r$dpi -dJPEGQ=$q -o "$pre-%03d.jpg" "$in"
end

function __ghostpdf_act_txt
    read -P "Input PDF: " -l in; or return 1
    __ghostpdf_require_file "$in" "Input PDF"; or return 1
    read -P "Output text file [output.txt]: " -l out; or return 1
    test -z "$out"; and set out output.txt
    __ghostpdf_run "$out" gs -sDEVICE=txtwrite -o "$out" "$in"
end

function __ghostpdf_act_compress
    read -P "Input PDF: " -l in; or return 1
    __ghostpdf_require_file "$in" "Input PDF"; or return 1
    read -P "Output PDF [compressed.pdf]: " -l out; or return 1
    test -z "$out"; and set out compressed.pdf
    __ghostpdf_run "$out" gs -sDEVICE=pdfwrite -dPDFSETTINGS=/ebook -o "$out" "$in"
end

function __ghostpdf_act_merge
    read -P "Output PDF [merged.pdf]: " -l out; or return 1
    test -z "$out"; and set out merged.pdf

    echo "Enter input PDFs one per line. Empty line to finish:"
    set -l files
    while read -l f; and test -n "$f"
        set -a files $f
    end

    if test (count $files) -eq 0
        echo "No inputs given." >&2
        return 1
    end
    for f in $files
        __ghostpdf_require_file "$f" "Input PDF"; or return 1
    end
    __ghostpdf_run "$out" gs -sDEVICE=pdfwrite -o "$out" $files
end

function __ghostpdf_act_split
    read -P "Input PDF: " -l in; or return 1
    __ghostpdf_require_file "$in" "Input PDF"; or return 1
    __ghostpdf_run "" gs -sDEVICE=pdfwrite -o page-%d.pdf "$in"
end

function __ghostpdf_act_extract
    read -P "Input PDF: " -l in; or return 1
    __ghostpdf_require_file "$in" "Input PDF"; or return 1
    read -P "First page: " -l first; or return 1
    read -P "Last page: " -l last; or return 1
    read -P "Output PDF [extract.pdf]: " -l out; or return 1
    test -z "$out"; and set out extract.pdf
    __ghostpdf_run "$out" gs -sDEVICE=pdfwrite -dFirstPage=$first -dLastPage=$last -o "$out" "$in"
end

function __ghostpdf_act_ps2pdf
    read -P "Input PS/EPS: " -l in; or return 1
    __ghostpdf_require_file "$in" "Input PS/EPS"; or return 1
    read -P "Output PDF [output.pdf]: " -l out; or return 1
    test -z "$out"; and set out output.pdf
    __ghostpdf_run "$out" gs -sDEVICE=pdfwrite -o "$out" "$in"
end

function __ghostpdf_act_pdf2ps
    read -P "Input PDF: " -l in; or return 1
    __ghostpdf_require_file "$in" "Input PDF"; or return 1
    read -P "Output PS [output.ps]: " -l out; or return 1
    test -z "$out"; and set out output.ps
    __ghostpdf_run "$out" gs -sDEVICE=ps2write -o "$out" "$in"
end

function __ghostpdf_act_encrypt
    read -P "Input PDF: " -l in; or return 1
    __ghostpdf_require_file "$in" "Input PDF"; or return 1
    read -P "Output PDF [encrypted.pdf]: " -l out; or return 1
    test -z "$out"; and set out encrypted.pdf
    read -P "Owner password: " -l owner; or return 1
    read -P "User password: " -l user; or return 1
    __ghostpdf_run "$out" gs -sDEVICE=pdfwrite -sOwnerPassword=$owner -sUserPassword=$user -o "$out" "$in"
end

# ---------- Main ----------

function ghostpdf --description "Menu-driven Ghostscript helper"
    if not command -sq gs
        echo "Error: ghostscript (gs) not found in PATH" >&2
        return 1
    end

    set -g __ghostpdf_dry_run 0

    set -l passthrough

    for a in $argv
        switch $a
            case -h --help
                __ghostpdf_help
                return 0
            case -V --version
                echo "ghostpdf $__ghostpdf_version"
                return 0
            case -n --dry-run
                set -g __ghostpdf_dry_run 1
            case '*'
                set -a passthrough $a
        end
    end

    if test (count $passthrough) -gt 0
        if test $__ghostpdf_dry_run -eq 1
            echo "gs "(string join ' ' -- (string escape -- $passthrough))
        else
            gs $passthrough
        end
        return $status
    end

    set -l choices \
        "PDF → PNG images" \
        "PDF → JPEG images" \
        "PDF → plain text" \
        "Compress PDF (ebook)" \
        "Merge PDFs" \
        "Split PDF into single pages" \
        "Extract page range" \
        "PS/EPS → PDF" \
        "PDF → PostScript" \
        "Add password to PDF" \
        "Help" \
        "Quit"

    while true
        echo
        echo "Ghostscript helper"
        echo "=================="
        for i in (seq (count $choices))
            printf "  %2d) %s\n" $i $choices[$i]
        end
        echo

        if not read -P "Choose [1-"(count $choices)"]: " -l choice
            echo
            return 0
        end

        if not string match -qr '^[0-9]+$' -- $choice
            echo "Invalid choice."
            continue
        end
        if test $choice -lt 1 -o $choice -gt (count $choices)
            echo "Out of range."
            continue
        end

        switch $choice
            case 1;  __ghostpdf_act_png
            case 2;  __ghostpdf_act_jpeg
            case 3;  __ghostpdf_act_txt
            case 4;  __ghostpdf_act_compress
            case 5;  __ghostpdf_act_merge
            case 6;  __ghostpdf_act_split
            case 7;  __ghostpdf_act_extract
            case 8;  __ghostpdf_act_ps2pdf
            case 9;  __ghostpdf_act_pdf2ps
            case 10; __ghostpdf_act_encrypt
            case 11; __ghostpdf_help
            case 12; return 0
        end

        echo
        read -P "Press Enter to continue..." -l _; or return 0
    end
end

