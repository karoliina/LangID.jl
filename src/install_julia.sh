#!/bin/bash

echo -e "\033[1;36mCreating installation directory...\033[0m\n"
mkdir julia-0.5.0
cd julia-0.5.0
echo -e "\033[1;36mDownloading Julia 0.5.0...\033[0m\n"
filename="julia-0.5.0-linux-x86_64.tar.gz"
wget "https://julialang.s3.amazonaws.com/bin/linux/x64/0.5/$filename"
echo -e "\033[1;36mUnpacking...\033[0m\n"
tar -xzf "$filename"
dir=`ls -d */`
working_dir=`pwd`
echo -e "\033[1;36mAdding to path...\033[0m\n"
PATH=$PATH:"$working_dir/julia-0.5.0/${dir}bin/"
echo -e "\033[1;36mInstalling required libraries, this will take a while...\033[0m\n"
julia ../Setup.jl
echo -e "\033[1;36mDone! Run the program with 'julia LangID.jl' from the src/ directory.\033[0m"
