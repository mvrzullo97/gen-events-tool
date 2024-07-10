#!/bin/bash

# usage menu
echo
echo "---------------------- Usage ----------------------"
echo -e "\n   bash $0\n\n    <  > \n"
echo

#   -t tratta (EUS)
#   -rE -rU -rS rete: entrata uscita svincolo
#   -pE -pU -pS punti: entrata uscita svincolo

while getopts re: flag
do
    case "${flag}" in
		re) n=${OPTARG};;
		\?) echo -e "\n Argument error! \n"; exit 0 ;;
	esac
done

echo "ciao $n"