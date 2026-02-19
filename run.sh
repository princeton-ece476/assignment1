# Adapted from ECE 475
# https://researchcomputing.princeton.edu/systems/adroit                                                        
# Intel Skylake on Adroit: Xeon Gold 6142 (2.6 GHz, 16 cores per socket)
# https://www.intel.com/content/www/us/en/products/sku/120487/intel-xeon-gold-6142-processor-22m-cache-2-60-ghz/specifications.html

#check number of arguments
if [ "$#" -ne 4 ]; then
    echo "Usage: ./run.sh <dir> <kernel> <cores> <kernel_opt>"
    echo "Example: ./run.sh prog1 mandelbrot 8 \"-t 2\""
    exit 1
fi

dir=$1
kernel=$2 #prog1_mandelbrot_threads, prog2_vecintrin, etc.
cores=$3 #1, 2, 4, 8, 16, 32
kernel_opt=$4

echo "Running $kernel"

# if cores less than 2
if [ $cores -lt 2 ]; then
    echo "Sequential execution, type $cores"
    cores=1
else
    echo "Using cores: $cores"
fi

binary="$kernel-C$cores"

sbatch_folder="sbatch"
out_folder="logs"
mkdir -p $sbatch_folder
mkdir -p $out_folder
out_file="$out_folder/$binary.log"

slurm_file="SLURM-$binary.log"
echo "#!/bin/bash"                       > batch.sh
echo "#SBATCH --nodes=1"                >> batch.sh
echo "#SBATCH --ntasks=1"               >> batch.sh          # total number of tasks across all nodes
echo "#SBATCH --time=00:09:00"          >> batch.sh
echo "#SBATCH --output=$sbatch_folder/$slurm_file" >> batch.sh
echo "#SBATCH --mem=16G" >> batch.sh
echo "#SBATCH --cpus-per-task=$cores"   >> batch.sh
echo "#SBATCH --job-name=$binary" >> batch.sh
echo "#SBATCH --distribution=block:block" >> batch.sh
if [ $cores -gt 32 ]; then
    echo "Job has more than 32 cores. It will have to run on Ice Lake CPUs."
    echo "#SBATCH --constraint=ice" >> batch.sh
else
    echo "#SBATCH --constraint=skylake" >> batch.sh			# using the skylake CPUs
    echo "#SBATCH -p class" >> batch.sh
fi

cmd="./$dir/$kernel $kernel_opt 2> $out_file"

echo $cmd >> batch.sh;
sbatch batch.sh;
name=`whoami`
squeue -u $name --format="%.18i %.9P %.50j %.8u %.2t %.10M %.6D %R"
