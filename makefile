
all : gahyph.tex dist ga.xml

#  upon a new release of tetex, need to redo the "installation instructs"
#  as given in usaid.html.
install :
	cp -f gahyph.tex /usr/share/texmf/tex/generic/hyphen
	chmod 444 /usr/share/texmf/tex/generic/hyphen/gahyph.tex
	(cd /usr/share/texmf/web2c; initex latex.ltx; chmod 444 latex.fmt)
	(cd /usr/share/texmf/pdftex/latex/config; pdfinitex pdflatex.ini; chmod 444 pdflatex.fmt; mv -f pdflatex.fmt /usr/share/texmf/web2c)
#	cp -f gahyph.tex /usr/share/texmf/source/generic/babel
#	chmod 444 /usr/share/texmf/source/generic/babel/gahyph.tex

dist : hyph_ga_IE.zip

gahyph.tex : ga.pat gahyphtemplate.tex
	rm -f gahyph.tex
	cat ga.pat | LC_ALL=C sed 's/�/^^e1/g; s/�/^^e9/g; s/�/^^ed/g; s/�/^^f3/g; s/�/^^fa/g;' > ga.pat.tmp
	sed '/\\patterns{/r ga.pat.tmp' gahyphtemplate.tex > gahyph.tex
	rm -f ga.pat.tmp
	chmod 400 gahyph.tex

hyph_ga_IE.zip : hyph_ga_IE.dic README_hyph_ga_IE.txt
	zip hyph_ga_IE.zip hyph_ga_IE.dic README_hyph_ga_IE.txt

# change to hyph_ga_IE.dic?
ga.xml : ambig.txt ga.pat
	sed '/^<patterns>/r ga.pat' foptemplate.xml > ga.xml
	sed -i '/^<exceptions>/r ambig.txt' ga.xml

# see "Converting the patterns" here:
# https://github.com/mnater/Hyphenator/blob/wiki/en_AddNewLanguage.md#what-we-have-now
# after this, take the result and paste into the conversion website
# and copy the result into ../Hyphenator/patterns/ga.js
# and submit a pull request; also occasionally sync to public_html/fleiscin
ga.js: gahyph.tex
	cat gahyph.tex | sed '1,/^\\patterns/d' | sed '/^}$$/,$$d' | LC_ALL=C sed 's/\^\^e1/�/g; s/\^\^e9/�/g; s/\^\^ed/�/g; s/\^\^f3/�/g; s/\^\^fa/�/g;' | tr "\n" " " | iconv -f iso-8859-1 -t utf8 > $@

# http://wiki.services.openoffice.org/wiki/Documentation/SL/Using_TeX_hyphenation_patterns_in_OpenOffice.org
hyph_ga_IE.dic : ga.pat specials.txt substrings.pl
	perl substrings.pl ga.pat $@ ISO8859-1 2 2
	cat specials.txt | iconv -f utf8 -t iso-8859-1 >> $@
	sed -i "/^RIGHTH/s/.*/&\n1'.\nNEXTLEVEL/" $@
	chmod 644 $@

ga.pat : ga.dic ga.tra
	patgen ga.dic /dev/null ga.pat ga.tra  < inps
	mv pattmp.? ga.log

# strip out hyphens after 1st and before last TWICE:
# once before ispell so that "d'" etc. aren't added to "a|treoraigh"
# and once after since ispell generates such hyphens, e.g. "�|adh", etc.
#   Note that ispell -e3 only works with latin-1 input (hence latin-1 output) 
ga.dic : deanta.raw
	cat deanta.raw | sed 's/^\(.\)|/\1/' | sed 's/|\(.\)$$/\1/' | sed 's/|\(.\)\//\1\//' | iconv -f utf8 -t iso-8859-1 | ispell -dgaeilgehyph -e3 | iconv -f iso-8859-1 -t utf8 | tr " " "\n" | egrep -v '\/' | sed 's/^\(.\)|/\1/' | sed 's/|\(.\)$$/\1/' | tr "[:upper:]" "[:lower:]" | sort -u | tr "|" "!" | egrep -v -e '-' | egrep -v "'" | iconv -f utf8 -t iso-8859-1 > ga.dic

#  1/30/04, done with todo.raw -> deanta.raw; so no more make target!
#deanta.raw :
#	touch deanta.raw
#	cp deanta.raw deanta.raw.bak
#	(egrep -v '^[^/]*[aeiou�����AEIOU�����][^aeiou�����AEIOU�����/|#]+[aeiou�����AEIOU�����]' todo.raw; cat deanta.raw) > temp.raw
#	sed -i -n '/^[^/]*[aeiou�����AEIOU�����][^aeiou�����AEIOU�����/|#][^aeiou�����AEIOU�����/|#]*[aeiou�����AEIOU�����]/p' todo.raw
#	sort -u temp.raw | tr -d "#" > deanta.raw
#	rm -f temp.raw
#	diff deanta.raw.bak deanta.raw | more
#	rm -f deanta.raw.bak

check : FORCE
	@echo 'Illegal characters:'
	@if egrep '[^/a-zA-Z����������|]' deanta.raw; then echo "Problem."; fi;
	@echo 'Syllables with no vowels:'
	@if egrep '\|[^aeiou�����|]+\|' deanta.raw | egrep -v '\|nn\|a'; then echo "Problem."; fi;
	@echo 'Bad aitches:'
	@if egrep '[bcdfgmpstBCDFGMPST]\|h' deanta.raw; then echo "Problem."; fi;

# writes list of words with bad hyphens but which aren't explicitly ambig.
bugs.txt : ga.pat ambig.txt
	cat ambig.txt | sed 's/.*/\/^&$$\/d/' > words.sed
	egrep '\.' ga.log | tr -d '.!*' | sed -f words.sed > bugs.txt
	rm -f words.sed

ambig.txt : ga.dic
	cat ga.dic | tr -d '!' | LC_ALL=C sort | LC_ALL=C uniq -c | egrep -v '1' | sed 's/^ *[0-9]* //' > ambig.txt

clean :
	rm -f pattmp* todo.dic todo.tex endings.* flipped.raw longs.txt tobar *.aux *.log ambig.txt *.dvi todo.5 todofull.5 bugs.txt bugs-nlc.txt splits.txt twograms.txt tastail.pdf tastail.aux tastail.log

distclean :
	make clean
	rm -f ga.pat ga.dic todo.dic gahyph.tex hyph_ga_IE.* mile.dic mile.txt ga-nlc.dic ga-nlc.pat NLC mile.html ga.xml
#############################################################################                2-grams stuff for adding to tosaigh.pat          
#   1/31/04-- turns out this actually makes ga.pat BIGGER...
splits.txt : ga.dic
	cat ga.dic | sed 's/\(.\)!\(.\)!/\1!\2\2!/g' | egrep -o '.!.' | tr -d '!' | sort -u > splits.txt 

# twograms.txt : ga.dic
#	cat ga.dic | tr -d '!' | ngrams -s 2 | egrep -v '[<>]' | egrep '[0-9]{3}' | sed 's/^ *[0-9]* //' | sort > twograms.txt

# then do:
# cat twograms.txt | while read x; do if ! egrep "^${x}$" splits.txt > /dev/null; then echo "${x}" | sed 's/^\(.\)\(.\)/\16\2/'; fi; done


#############################################################################
#        web page stuff

# html files now installed by scripts in cadhan.com repo
installweb:
	cp -f tastail.css ${HOME}/public_html/fleiscin
	cp -f tastail.png ${HOME}/public_html/fleiscin
	cp -f tastail.pdf ${HOME}/public_html/fleiscin

#mile.html : mile.dic miletemp.html
#	cat mile.dic | head -n 1000 | sed 's/$$/<br>/; s/^/ /' | egrep -n '.' | sed 's/^1[^0-9]/<td width="25%">&/; s/^1000.*/&<\/td>/' | sed 's/^251/<\/td><td width="25%">251/; s/^501/<\/td><td width="25%">501/; s/^751/<\/td><td width="25%">751/' | iconv -f iso-8859-1 -t utf8 > mile.dic.temp
#	sed '/^Please/r mile.dic.temp' miletemp.html > mile.html
#	rm -f mile.dic.temp

#mile.dic : ga.pat ga.tra mile.txt
#	(echo "2"; echo "1"; echo "y") | patgen mile.txt ga.pat /dev/null ga.tra
#	cat pattmp.? | tr "." "-" > mile.dic
#	rm -f pattmp.?

# implicitly depends on entire corpus
#mile.txt :
#	brillcorp | togail ga keepok | tr "[:upper:]" "[:lower:]" | sort | uniq -c | sort -r -n | sed 's/^ *[0-9]* //' | egrep -v '^[Tt]he$$' | egrep -v "'" | egrep -v -e '-' | egrep '^([ai����]$$|..)' | head -n 2500 > mile.txt

tastail.pdf: tastail.tex
	pdflatex tastail


#############################################################################
#              stuff for stratified sampling
#done.txt : ga.dic
#	cat ga.dic | tr -d "!" | tr "[:upper:]" "[:lower:]" | sort -u > done.txt

NLC :
	togail ga dump | togail ga token | egrep -v '.{35}' | egrep -v '^[Tt]he$$' | egrep -v "'" | egrep -v -e '-' | egrep '^([ai����]$$|..)' | togail ga keepok | tr "[:upper:]" "[:lower:]" | sort -u > NLC

# used to use patgen to do this; build the "ga.pat" ruleset and then
# run "NLC" through it: 
# (echo "2"; echo "1"; echo "y") | patgen NLC ga.pat /dev/null ga.tra
# then change "." to "!" as usual
ga-nlc.dic : NLC ga.dic
	bash ./nlcdic > ga-nlc.dic

ga-nlc.pat : ga-nlc.dic ga.tra
	patgen ga-nlc.dic /dev/null ga-nlc.pat ga.tra  < inps
	mv pattmp.? ga-nlc.log

testnlc : ga-nlc.pat
	(echo "2"; echo "1"; echo "y") | patgen ga.dic ga-nlc.pat /dev/null ga.tra
	mv pattmp.? testnlc.log

bugs-nlc.txt : ga-nlc.pat
	egrep '[.!]' ga-nlc.log | tr -d '.!*' > bugs-nlc.txt

#############################################################################
#              stuff for bootstrapping (working on todo.raw)
#                         


# used to test current pattern set on "todo" with the following 
# (basically using patgen vs. TeX itself!)
todo.5 : todo.raw ga.tra ga.pat
	cat todo.raw | tr -d "#" | sed 's/\/.*//' | egrep -v '[A-Z�����]' | sed 's/^\(.\)|/\1/' | sed 's/|\(.\)$$/\1/' | sort -u | tr "|" "!" | egrep -v -e '-' | egrep -v "'" > todo.dic
	(echo "2"; echo "1"; echo "y") | patgen todo.dic ga.pat /dev/null ga.tra
	rm -f todo.dic
	cat pattmp.5 | egrep -v '!' | egrep -v '\.[^aeiou�����]+\.' | egrep -v '[aeiou�����][^aeiou�����.*]+[aeiou�����]' | sort -u > todo.5
	rm -f pattmp.?

# same as above, but use ispell to expand affix flags
#  Not useful for bootstrapping though
todofull.5 : todo.raw ga.tra ga.pat
	cat todo.raw | egrep -v '^[^/]*[A-Z]' | tr -d "#" | ispell -dgaeilgehyph -e3 | tr " " "\n" | egrep -v '\/' | sort -u | tr "|" "!" | egrep -v -e '-' | egrep -v "'" > todo.dic
	(echo "2"; echo "1"; echo "y") | patgen todo.dic ga.pat /dev/null ga.tra
	rm -f todo.dic
	mv -f pattmp.? todofull.5

# hyphenates todo list, using TeX not patgen
todo.tex : todo.raw todotemplate.tex
	(echo '\showhyphens{'; cat todo.raw | tr -d "#|" | sed 's/\/.*//'; echo '}') > todo.temp
	sed '/HERE/r todo.temp' todotemplate.tex > todo.tex
	rm -f todo.temp

# shows remaining long strings; work on em manually
longs.txt : todo.raw
	cat todo.raw | tr "|" "\n" | tr "#" "\n" | sed 's/\/.*//' | sort | uniq -c | egrep '[aeiou�����AEIOU�����][^aeiou�����AEIOU�����]+[aeiou�����AEIOU�����]' | sort -r -n > longs.txt

#############################################################################
#                     stuff for reversing todolist                          #
flip : flip.c
	gcc -o flip flip.c
	mv ./flip ${HOME}/clar/denartha

flipped.raw : todo.raw
	cat todo.raw | sed '/\//!{s/$$/\//}' | sed 's/\//\n\//' | flip | sed '/^\//!{N; s/\n//}' | sort | sed 's/\//\n\//' | flip | sed '/^\//!{N; s/\n//}' > flipped.raw

endings.4 : flipped.raw
	cat flipped.raw | tr -d "|" | sed 's/\/.*//' | sed 's/^.*\(....\)$$/\1/' | sort | uniq -c | sort -r -n > endings.4

endings.5 : flipped.raw
	cat flipped.raw | tr -d "|" | sed 's/\/.*//' | sed 's/^.*\(.....\)$$/\1/' | sort | uniq -c | sort -r -n > endings.5
##############################################################################
#                              DEFUNCT STUFF
#
# really only used to test "gaeilgehyph.aff"; everything matches
# as of 1/20/04, 9pm.
hyphtest :
	cat todo.raw deanta.raw | tr -d "#" | sed 's/^\(.\)|/\1/' | sed 's/|\(.\)$$/\1/' | sed 's/|\(.\)\//\1\//' | ispell -dgaeilgehyph -e3 | tr " " "\n" | egrep -v '\/' | tr -d "|" | sort -u | egrep -v -e '-' > hyphtest.1
	sort -u ${HOME}/gaeilge/ispell/ispell-gaeilge/aspell.txt | egrep -v -e '-' > hyphtest.2
	diff hyphtest.2 hyphtest.1
	rm -f hyphtest.1 hyphtest.2

#   never pursued the idea of extracting example from
#   Tobar na Gaedhilge...
tobar : FORCE
	cat /home/kps/gaeilge/diolaim/tobar/* | togail ga token | egrep '...*-' | sort -u > tobar
##############################################################################

FORCE :
