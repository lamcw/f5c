#!/usr/bin/env bash

die() {
    local msg="${1}"
    echo "run.sh: ${msg}" >&2
    exit 1
}

exepath="./f5c"
testdir="test/ecoli_2kb_region/"
#cd "${tstdir}"

bamdir="${testdir}single_read/read1.sorted.bam"
fadir="${testdir}draft.fa"
fastqdir="${testdir}single_read/read1.fasta"
for file in "${bamdir}" "${fadir}" "${fastqdir}"; do
    [[ -f "${file}" ]] || die "${file}: File does not exist"
done

if [[ "${#}" -eq 0 ]]; then
    "${exepath}" call-methylation -b "${bamdir}" -g "${fadir}" -r "${fastqdir}" 
    #"${exepath}" call-methylation call-methylation -t 1 -r "$fastqdir" -b "${bamdir}" -g "${fadir}"

elif [[ "${#}" -eq 1 ]]; then
    if [[ "${1}" == "valgrind" ]]; then
        valgrind "${exepath}" call-methylation -b "${bamdir}" -g "${fadir}" -r "${fastqdir}"
    elif [[ "${1}" == "gdb" ]]; then
        gdb --args "${exepath}" call-methylation -b "${bamdir}" -g "${fadir}" -r "${fastqdir}"
    else
        echo "wrong option"
		exit 1
    fi
else
    echo "wrong option"
	exit 1
fi

exit 0
