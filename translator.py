from __future__ import print_function
import sys

#genetic code
gencode = {
    'ATA':'I', 'ATC':'I', 'ATT':'I', 'ATG':'M', 'ACA':'T', 'ACC':'T', 'ACG':'T', 'ACT':'T',
    'AAC':'N', 'AAT':'N', 'AAA':'K', 'AAG':'K', 'AGC':'S', 'AGT':'S', 'AGA':'R', 'AGG':'R',
    'CTA':'L', 'CTC':'L', 'CTG':'L', 'CTT':'L', 'CCA':'P', 'CCC':'P', 'CCG':'P', 'CCT':'P',
    'CAC':'H', 'CAT':'H', 'CAA':'Q', 'CAG':'Q', 'CGA':'R', 'CGC':'R', 'CGG':'R', 'CGT':'R',
    'GTA':'V', 'GTC':'V', 'GTG':'V', 'GTT':'V', 'GCA':'A', 'GCC':'A', 'GCG':'A', 'GCT':'A',
    'GAC':'D', 'GAT':'D', 'GAA':'E', 'GAG':'E', 'GGA':'G', 'GGC':'G', 'GGG':'G', 'GGT':'G',
    'TCA':'S', 'TCC':'S', 'TCG':'S', 'TCT':'S', 'TTC':'F', 'TTT':'F', 'TTA':'L', 'TTG':'L',
    'TAC':'Y', 'TAT':'Y', 'TAA':'_', 'TAG':'_', 'TGC':'C', 'TGT':'C', 'TGA':'_', 'TGG':'W'}
 
# a function to translate a single codon
def translate_codon(codon):
    return gencode.get(codon.upper(), 'x')
 
# a function to split a sequence into codons
def split_into_codons(dna, frame):
    codons = []
    for i in range(frame - 1, len(dna)-2, 3):
        codon = dna[i:i+3]
        codons.append(codon)
    return codons
 
# a function to translate a dna sequence in a single frame
def translate_dna_single(dna, frame=1):
    codons = split_into_codons(dna, frame)
    amino_acids = ''
    for codon in codons:
        if translate_codon(codon) == "_":
        	#print "stop"
        	break
        else:
        	amino_acids = amino_acids + translate_codon(codon)
    return amino_acids   

#input file name
f_name_in= sys.argv[1]    

#output file name
f_name_out=  f_name_in.split(".")[0] + "_aa_dup.txt"
f_out=open(f_name_out, 'w') 

#number of lines on file = total number na unique seqs
size=0

#vector to store aa seqs and their abds
list=[]
 #total number molecules
tot = 0
#vector to store the header lines (first two lines)
head=[]
#unique aa seqs
unique=0


with open(f_name_in, 'r') as f_in:
	for line in f_in:     #for each line in input file
		if 'of' in line:     #header lines
			head.append(line)     
		if 'A' in line or 'G' in line or 'C' in line or 'T' in line:     #seq lines
			linesp = line.split()          #separate line in two parts: seq and abd
			seq_temp = str(translate_dna_single(linesp[0]))         #seq_temp = translated seq
			abd_temp = int(linesp[1])         #abd_temp = abundance of translated seq
			if len(seq_temp) == 0:
				list.append({'seq': "AAAAA-EMPTYSEQUENCE-AAAAA", 'abd': abd_temp})     #if translated sequences starts with stop codon
			else:
				list.append({'seq': seq_temp, 'abd': abd_temp})     #else
			tot += abd_temp
			size +=1
		
# count unique aa sequences in file (It will be printed in the terminal and hsould match the one in the counts file)
for i in range (0, len(list)):
	unique += 1
		
#Print header in the output file
print(str(head[0].split("=")[0]).ljust(30)+ "=" +str(unique).rjust(10), file=f_out)
print(str(head[1].split("=")[0]).ljust(30)+ "=" +str(tot).rjust(10), file=f_out)
print("", file=f_out)

#Print lines in file
for i in range (0, len(list)):
	print (str(list[i]['seq']).ljust(100) +  str(list[i]['abd']).rjust(20), file=f_out)

f_out.close()
