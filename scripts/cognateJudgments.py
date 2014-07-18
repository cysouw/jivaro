# author   : Johann-Mattis List
# email    : mattis.list@uni-marburg.de
# created  : 2014-07-18 11:37
# modified : 2014-07-18 11:37
"""
Find initial cognates in data.tsv.
"""

__author__="Johann-Mattis List"
__date__="2014-07-18"

from lingpyd import *

# add tokens as entries to the wordlist
wl = Wordlist('../data.tsv', col='translation', row='language')
header = list(wl.header)
wl.add_entries('concept','translation',lambda x:x)
wl.add_entries('tokens','alignment',lambda x:x)

print("Carried out the basic configuration.")

wl.output('tsv', filename='.tmp')

# carry out cognate judgments
lex = LexStat('.tmp.tsv')
lex.cluster(method='sca', threshold=0.4, mode='overlap',
        cluster_method = 'upgma')

# select all entries which are in fact cognates
D = {}
idx = 1
etd = lex.get_etymdict(ref='scaid')
for k,line in etd.items():
    if line.count(0) < 3:
        for cogid in line:
            if cogid != 0:
                D[cogid[0]] = idx
        idx += 1
    else:
        for cogid in line:
            if cogid != 0:
                D[cogid[0]] = 0

for k in wl:
    if k not in D:
        D[k] = 0
        
lex.pickle()

lex.add_entries('etymonid', D, lambda x: x)
lex.output(
        'tsv',
        filename='datanew',
        subset=True,
        cols = [
                "language",
                "source",
                "page",
                "word",
                "etymonid",
                "alignment",
                "translation",
                ],
        formatter = "ID",
        ignore = ['taxa', 'json', 'scorer', 'msa'],
        )



