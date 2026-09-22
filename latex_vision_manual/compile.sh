#!/bin/bash
set -e

cd "$(dirname "$0")"

echo "=== [1/3] First Pass XeLaTeX Compilation ==="
/Library/TeX/texbin/xelatex -interaction=nonstopmode main.tex

echo "=== [2/3] Second Pass XeLaTeX Compilation (TOC/LOF/LOT/References) ==="
/Library/TeX/texbin/xelatex -interaction=nonstopmode main.tex

echo "=== [3/3] Verifying Output PDF ==="
if [ -f "main.pdf" ]; then
    SIZE=$(ls -lh main.pdf | awk '{print $5}')
    PAGES=$(/Library/TeX/texbin/pdfinfo main.pdf 2>/dev/null | grep Pages | awk '{print $2}' || echo "N/A")
    echo "SUCCESS: main.pdf generated successfully!"
    echo "File Size: $SIZE"
    echo "Total Pages: $PAGES"
else
    echo "ERROR: main.pdf was not generated."
    exit 1
fi
