# author   : Johann-Mattis List
# email    : mattis.list@uni-marburg.de
# created  : 2014-07-20 09:41
# modified : 2014-07-20 09:41
"""
<++>
"""

__author__="Johann-Mattis List"
__date__="2014-07-20"

from lingpyd import *

wl = Wordlist('../data.tsv', row='language', col='translation')
wl.add_entries('tokens','alignment',lambda x:x.split(' '))
D = {}
dx = max([int(wl[k,'etymonid']) for k in wl]) + 1
for idx in wl:
    cid = int(wl[idx,'etymonid'])
    if cid == 0:
        D[idx] = dx
        dx += 1
    else:
        D[idx] = cid

wl.add_entries('cogid', D, lambda x: x)
wl.add_entries('concept', 'translation', lambda x:x)

wl.output('tsv', filename='.tmp')

alm = Alignments('.tmp.tsv')
#rc(verbose=True)
alm.align()
alm._msa2col()
alm.output('tsv', filename='datatmp', subset=True,         
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
        ignore = ['taxa', 'json', 'scorer', 'msa']
        )

