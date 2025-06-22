#! /bin/bash

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
-not -path "*/docs/*" \
-not -path "*/logs/*" \
-not -path "*/venv/*" \
-not -path "*/pending/*" \
-not -path "*/output/*" \
-print

# cd $cwd
