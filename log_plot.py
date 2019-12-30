import numpy as np
import matplotlib.pyplot as plt
import sys
                     
f_name_in=sys.argv[1]


if len(sys.argv) <= 2:

	v_sample = []
	v_fastq = []
	v_unique = []
	v_total = []

	with open(f_name_in, 'r') as f_in:
		next(f_in)
		for line in f_in:     #for each line in input file
			linesp = line.split()          #separate line in two parts: seq and abd
			sample = linesp[0]
			fastq = int(linesp[1])
			unique = int(linesp[3])
			total = int(linesp[4])
			v_sample.append(sample)
			v_fastq.append(fastq)
			v_unique.append(unique)
			v_total.append(total)

	plt.style.use('ggplot')

	# data to plot
	n = len(v_sample)


	fig, ax = plt.subplots(figsize=(5*n, 10))


	index = np.arange(n)
	bar_width = 0.3
	opacity = 0.9
	ax.bar(index, v_fastq, bar_width, alpha=opacity, color='r', label='fastq')
	ax.bar(index+bar_width, v_unique, bar_width, alpha=opacity, color='b', label='unique')
	ax.bar(index+2*bar_width, v_total, bar_width, alpha=opacity, color='k', label='total')
	ax.set_xlabel('Sample', fontsize=18, color='black')
	ax.set_ylabel('Count reads', fontsize=18, color='black')
	ax.set_title('Some numbers', fontsize=20, color='black')
	ax.set_xticks(index + bar_width)
	ax.set_xticklabels(v_sample, fontsize=18, color='black')

	ax.tick_params(axis='both', color='black', labelsize=18, labelcolor='black')

	plt.tight_layout(pad=0.4, w_pad=0.5, h_pad=1.0)

	plt.legend(ncol=3, loc=2, prop={'size': 16})

	plt.savefig('plot.png')

	plt.show()

else:
	
	v_sample = []
	v_fastq = []
	v_unique = []
	v_total = []
	v_unique_aa = []
	v_total_aa = []

	with open(f_name_in, 'r') as f_in:
		next(f_in)
		for line in f_in:     #for each line in input file
			linesp = line.split()          #separate line in two parts: seq and abd
			sample = linesp[0]
			fastq = int(linesp[1])
			unique = int(linesp[3])
			total = int(linesp[4])
			v_sample.append(sample)
			v_fastq.append(fastq)
			v_unique.append(unique)
			v_total.append(total)

	plt.style.use('ggplot')

	# data to plot
	n = len(v_sample)


	fig, ax = plt.subplots(figsize=(2*n, 5))


	index = np.arange(n)
	bar_width = 0.1
	opacity = 0.9
	ax.bar(index, v_fastq, bar_width, alpha=opacity, color='r', label='fastq')
	ax.bar(index+bar_width, v_unique, bar_width, alpha=opacity, color='b', label='unique')
	ax.bar(index+2*bar_width, v_total, bar_width, alpha=opacity, color='k', label='total')
	ax.set_xlabel('Sample', fontsize=18, color='black')
	ax.set_ylabel('Count reads', fontsize=18, color='black')
	ax.set_title('Some numbers', fontsize=20, color='black')
	ax.set_xticks(index + bar_width)
	ax.set_xticklabels(v_sample, rotation = 90, fontsize=18, color='black')

	ax.tick_params(axis='both', color='black', labelsize=18, labelcolor='black')

	plt.tight_layout(pad=0.4, w_pad=0.5, h_pad=1.0)

	plt.legend(ncol=3, loc=2, prop={'size': 16})

	plt.savefig('plot.png')

	plt.show()
	
