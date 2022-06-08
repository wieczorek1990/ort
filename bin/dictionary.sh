#!/bin/bash

# Needs wget, sponge, gsed
# On MacOS: brew install sponge

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

tmp=$(mktemp -d)
cd "$tmp" || exit 1
wget -qr --no-parent --no-directories --show-progress -A 'sjp-myspell-pl-*.zip' https://sjp.pl/sl/ort/
unzip -q sjp-myspell-pl*.zip
unzip -q pl_PL.zip
iconv -f ISO-8859-2 -t UTF-8 pl_PL.dic | sponge pl_PL.dic
gsed -i 's/\/.*//g' pl_PL.dic
tail -n +2 pl_PL.dic | sponge pl_PL.dic
perl -pi -e 'chomp if eof' pl_PL.dic
egrep -v '(^..*[A-Z]+.*$)|(^[A-Z]+$)' pl_PL.dic | sponge pl_PL.dic
mv pl_PL.dic "$DIR/../data/"
