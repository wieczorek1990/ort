#!/bin/bash
mkdir tmp
cd tmp
wget -r --no-parent --no-directories -A 'sjp-myspell-pl-*.zip' http://sjp.pl/slownik/ort/
unzip sjp-myspell-pl*.zip
unzip pl_PL.zip
mv pl_PL.dic ../data
cd ..
rm -rf tmp
cd data
iconv -f ISO-8859-2 -t UTF-8 pl_PL.dic > temp.dic
sed -i 's/\/.*//g' temp.dic
mv temp.dic pl_PL.dic
tail -n +2 pl_PL.dic > temp.dic
mv temp.dic pl_PL.dic
perl -pi -e 'chomp if eof' pl_PL.dic