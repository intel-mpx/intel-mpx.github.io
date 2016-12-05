#!/usr/bin/env bash

# to set this file as a git hook, execute the following:
# cp update_images.sh .git/hooks/pre-commit

mkdir images_tmp
cd images_tmp
git init
git remote add -f origin git@github.com:OleksiiOleksenko/mpx_evaluation.git
git config core.sparseCheckout true
echo "publications/memory_protection_survey/figures" >> .git/info/sparse-checkout
git pull origin dev

rsync -r publications/memory_protection_survey/figures/ ../images/
cd ..
rm -rf images_tmp

git add images/*