#! /bin/bash

echo "Zipping project rb-micromamba files ..."

cwd=$(pwd)
cd $HOME/projects

find rb-micromamba -type f \
-not -path "*/.git/*" \
-not -path "*/.delete/*" \
-not -path "*/.cursor/*" \
-not -path "*/.pylintrc" \
-not -path "*/.envrc" \
-not -path "*/.DS_Store" \
-not -path "*/.notes/*" \
-not -path "*/.dockerignore" \
-not -path "*/.gitignore" \
-not -path "*/.sandbox/*" \
-not -path "*/__pycache__/*" \
-not -path "*/data/*" \
-not -path "*/logs/*" \
-not -path "*/venv/*" \
-print | zip "rb-micromamba-$(date +%y%m%d%H%M).zip" -@

echo "Done! Here's your zipfile: $(pwd)/rb-micromamba-$(date +%y%m%d%H%M).zip"
# cd $cwd
