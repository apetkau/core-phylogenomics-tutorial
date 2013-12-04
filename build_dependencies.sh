#!/bin/sh

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

software_dir=$ROOT_DIR/software
art_illumina_source=http://www.niehs.nih.gov/research/resources/assets/docs/art_illumina_src151targz.gz
art_illumina_destination=$software_dir/art_illumina_src151targz.gz
art_illumina_dir=$software_dir/art_illumina_dir
art_illumina_install=$software_dir/art_illumina
environment=$software_dir/environment.sh

mkdir $software_dir
mkdir $art_illumina_dir

wget -O $art_illumina_destination $art_illumina_source
tar -C $software_dir -xf $art_illumina_destination

cd $art_illumina_dir
./configure --prefix=$art_illumina_install
make && make install

cd $ROOT_DIR

echo "export PATH=$art_illumina_install/bin:\$PATH" > $environment

echo "ART Illumina Installed to $art_illumina_install"
echo -n "Testing install... "
source $environment
art_illumina 2>/dev/null 1>/dev/null
ret_value=$?
if [ "$ret_value" = "0" ]
then
	echo "good"
else
	echo "error occured, could not find art_illumina in PATH"
fi

echo
echo "**********************"
echo "ART Illumina Installed"
echo "Please run the below command to add to your PATH"
echo
echo "source $environment"
echo "**********************"
