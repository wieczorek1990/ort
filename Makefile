# Pobierz słownik myspell ze strony: http://sjp.pl/slownik/ort/ do katalogu programu i odpal make w konsoli.
all:
	iconv -f ISO-8859-2 -t UTF-8 pl_PL.dic > temp.dic
	sed -i 's/\/.*//g' temp.dic
	rm pl_PL.dic
	mv temp.dic pl_PL.dic
