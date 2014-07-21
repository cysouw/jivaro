# author   : Johann-Mattis List
# email    : mattis.list@uni-marburg.de
# created  : 2014-07-21 10:50
# modified : 2014-07-21 10:50
"""
<++>
"""

__author__="Johann-Mattis List"
__date__="2014-07-21"

from lingpyd import *
from glob import glob

profs = glob('../orthography profiles/*.prf')
sca = rc('sca')
errors = open('errors.txt','w')
for prof in profs:
    #try:
    data = open(prof).read().split('\n')
    fline = data[0].split('\t')
    new_data = [[fline[0],fline[1],'SCA']+fline[2:]]
    for line in data[1:]:
        if not line.strip():
            new_data += [[line]]
        elif line.startswith('#'):
            new_data += [[line]]
        else:
            nline = line.split('\t')
            if len(nline) < 2:
                new_data += [[line]]
            else:
                char = nline[1]
                if char in sca:
                    cls = sca[char]
                    new_data += [[nline[0],nline[1],cls]+nline[2:]]
                elif char[0] in sca:
                    cls = sca[char[0]]
                    new_data += [[nline[0],nline[1],cls]+nline[2:]]
                else:
                    errors.write(nline[1]+'\n')
                    new_data += [[nline[0],nline[1],'?']+nline[2:]]

    with open(prof.replace('.prf','_with_classes.prf'), 'w') as f:
        for line in new_data:
            f.write('\t'.join(line)+'\n')
errors.close()
