#!/bin/sh

set -e

clean_cache=false
testdir=test/chr22_meth_example
bamfile=$testdir/reads.sorted.bam
ref=$testdir/humangenome.fa
reads=$testdir/reads.fastq
batchsize=512
bases=100M
disable_cuda=yes
thread_loop=true
if command -v nproc > /dev/null
then
	threads=$(nproc --all)
else
	threads=8
fi
f5c_output=/dev/null
nano_output=/dev/null

# terminate script
die() {
	echo "test.sh: $1" >&2
	echo
	help_msg
	exit 1
}

clear_fscache() {
	sync; echo 3 | tee /proc/sys/vm/drop_caches
}

run() {
	echo $1
	eval $1
	[ $clean_cache = true ] && clear_fscache
	return 0
}

help_msg() {
	echo "Benchmark script for f5c."
	echo "Usage: f5c_dir/script/benchmark.sh [-c] [-b bam file] [-g reference genome] [-r fastq/fasta read] [f5c path] [nanopolish path]"
	echo
	echo "-c                   Clean file system cache between every f5c and nanopolish call."
	echo "-b [bam file]        Same as f5c -b."
	echo "-r [read file]       Same as f5c -r."
	echo "-g [ref genome]      Same as f5c -g."
	echo "-K [n]               Same as f5c -K."
	echo "-B [n]K/M/G          Same as f5c -B."
	echo "-C                   Same as f5c --disable-cuda=no."
	echo "-f [file]            File to save f5c output. (/dev/null)"
	echo "-F [file]            File to save nanopolish output. (/dev/null)"
	echo "-t [n]               Maximum number of threads. Minimum is 8."
	echo "-T                   Disable benchmarking over an increasing number of threads."
	echo "-h                   Show this help message."
}

while getopts b:g:r:t:K:f:F:B:cChT opt
do
	case $opt in
		b) bamfile="$OPTARG";;
		g) ref="$OPTARG";;
		r) reads="$OPTARG";;
		t) if [ "$OPTARG" -lt 8 ]
		   then
			die "Thread size must be >= 8"
		   fi
		   threads="$OPTARG";;
		T) thread_loop=false;;
		K) batchsize="$OPTARG";;
		B) bases="$OPTARG";;
		c) clean_cache=true;;
		C) disable_cuda=no
		   bases=2M;;
		f) f5c_output="$OPTARG";;
		F) nano_output="$OPTARG";;
		h) help_msg
		   exit 0;;
		?) printf "Usage: %s [-c] [-h] [f5c path] [nanopolish path]\n" $0
		   exit 2;;
	esac
done

shift $(($OPTIND - 1))
[ -z $1 ] && die "Specify f5c path."
[ -z $2 ] && die "Specify nanopolish path."
f5c_path=$1
nanopolish_path=$2

for file in ${bamfile} ${ref} ${reads}
do
	[ -f ${file} ] || die "${file} not found."
done

rm -f *_benchmark.log

[ $clean_cache = true ] && clear_fscache

t=8

if [ $thread_loop = false ]
then
	t=$threads
fi
# run benchmark
while [ $t -le $threads ]
do
	run "/usr/bin/time -v ${f5c_path} call-methylation -b ${bamfile} -g ${ref} -r ${reads} -t $t --secondary=yes --min-mapq=0 -K $batchsize --disable-cuda=$disable_cuda -B $bases > $f5c_output 2>> f5c_benchmark.log"
	run "/usr/bin/time -v ${nanopolish_path} call-methylation -b ${bamfile} -g ${ref} -r ${reads} -t $t -K $batchsize > $nano_output 2>> nano_benchmark.log"
	t=$(( t + 8 ))
done

echo "f5c time"
grep "Elapsed (wall clock) time (h:mm:ss or m:ss):" f5c_benchmark.log | cut -d ' ' -f 8 |tr ':' \\t |  awk '{if(NF==1) print; else{ if(NF==2) print(($1*60)+$2); else print(($1*3600)+($2*60)+$3)}}' | tr '\n' '\t'
echo
echo "nanopolish time"
grep "Elapsed (wall clock) time (h:mm:ss or m:ss):" nano_benchmark.log | cut -d ' ' -f 8 |tr ':' \\t |  awk '{if(NF==1) print; else{ if(NF==2) print(($1*60)+$2); else print(($1*3600)+($2*60)+$3)}}' | tr '\n' '\t'
echo
