export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib/

rm -f ../Analyses/GABranch/spool/$1*progress
rm -f ../Analyses/GABranch/spool/$1*out
#(echo $1; echo $2; echo $3; echo $4)

(echo $1; echo $2; echo $3; echo $4) | mpirun -np 33 /usr/local/bin/HYPHYMPI USEPATH=/dev/null ../Analyses/GABranch/GABranch.bf > Analyses/GABranch/hpout 2>&1 &