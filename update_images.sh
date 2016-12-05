#!/usr/bin/env bash
# depends on ImageMagic

# to set this file as a git hook, execute the following:
# cp update_images.sh .git/hooks/pre-commit

# download images
mkdir images_tmp
cd images_tmp
git init
git remote add -f origin git@github.com:OleksiiOleksenko/mpx_evaluation.git
git config core.sparseCheckout true
echo "publications/memory_protection_survey/figures" >> .git/info/sparse-checkout
git pull origin dev

# update images
rsync -r publications/memory_protection_survey/figures/ ../images/
cd ..
rm -rf images_tmp

# convert
cd images
for img in *.pdf; do
    convert           \
       -density 350   \
       -trim          \
        $img          \
       -quality 100   \
       -flatten       \
       -sharpen 0x1.0 \
        ${img%.*}.jpg
done;
cd -

# add to the next commit
git add images/*
