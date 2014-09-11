all:
	mkdir tmp
	cd tmp && \
	wget -r --no-parent --no-directories -A 'sjp-myspell-pl-*.zip' http://sjp.pl/slownik/ort/ && \
	unzip sjp-myspell-pl*.zip && \
	unzip pl_PL.zip && \
	mv pl_PL.dic ..
	rm -rf tmp
	iconv -f ISO-8859-2 -t UTF-8 pl_PL.dic > temp.dic
	sed -i 's/\/.*//g' temp.dic
	mv temp.dic pl_PL.dic
