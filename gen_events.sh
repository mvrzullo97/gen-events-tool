#!/bin/bash
# usage menu
echo
echo "---------------------- Usage ----------------------"
echo -e "\n   bash $0\n\n    -tr < tratta > (ex. EUS)\n    -re < rete Entrata >\n    -pe < punto Entrata >\n    -ri < rete Itinere >\n    -pi < punto Itinere >\n    -ru < rete Uscita >\n    -pu < punto Uscita >\n    -de < datiEntrata > (yY or nN)\n    -rs < rete Svincolo >\n    -ps < punto Svincolo >\n    -ap < tipo apparato (o [OBU] - s [SET]) >\n    -sp < codice Service Provider >\n    -pl < targa veicolo >\n"
echo

# Parsing degli OPTARGS
while [[ "$#" -gt 0 ]] ; do
    case $1 in
        -tr) TRATTA="$2"
			 	shift 2;;
		-re) RETE_E="$2"
			 	shift 2;;
        -ru) RETE_U="$2"
			 	shift 2;;
		-ri) RETE_I="$2"
				shift 2;;
		-pi) PUNTO_I="$2"
				shift 2;;
		-rs) RETE_S="$2"
			 	shift 2;;
		-pe) PUNTO_E="$2"
			 	shift 2;;
        -pu) PUNTO_U="$2"
			 	shift 2;;
		-de) DATI_ENTRATA="$2"
				shift 2;;
		-ps) PUNTO_S="$2"
			 	shift 2;;
		-ap) APPARATO="$2"
				shift 2;;
		-sp) SERVICE_PROVIDER="$2"
				shift 2;;
		-pl) PLATE_NUMBER="$2"
				shift 2;;
        *)  echo -e "Error: Invalid option $1\n"
			exit 0
    esac
done

function generate_PAN 
{
    plate_number=$1
    pad_NUM="0"
    pad_F="F"
    pad_PRG_F=$plate_number$pad_F
    len_PAN=19
    str=$timestamp_PAN
    offset=$(expr $len_PAN - ${#pad_PRG_F})
    while [ ${#str} != $offset ] 
    do
        str=$str$pad_NUM
    done 
    str=$str$pad_NUM$pad_PRG_F
    echo ${str}
}

OUT_DIR="OUT_DIR_EVENTS"
# create OUT_DIR if not exist
if ! [ -d $OUT_DIR ] ; then
	mkdir $OUT_DIR
	path_OUT_dir=$(realpath $OUT_DIR)
    echo -e "...created '$OUT_DIR' at path: '$path_OUT_dir' \n"
    chmod 0777 "$path_OUT_dir"
else
	path_OUT_dir=$(realpath $OUT_DIR)
fi

# vars declaration
sysdate=$(date +"%Y-%m-%dT%H:%M:%S.%3N+02:00")
timestamp_PAN=$(date +"%Y%m%d")
aperto_BOOL=false
plate_f=${PLATE_NUMBER:0:2}
plate_number=${PLATE_NUMBER:2:3}
plate_l=${PLATE_NUMBER:5:2}
dati_entrata_bool=false

if [[ $DATI_ENTRATA =~ ^([yY])$ ]] ; then
	dati_entrata_bool=true
fi

if [ $APPARATO == 's' ] ; then
	type_viaggio="SET"
	echo -e "...creating Viaggio SET $TRATTA\n"
	APPARATO=$(generate_PAN $plate_number)
	time_old=720
elif [ $APPARATO == 'o' ] ; then
	type_viaggio="OBU"
	echo -e "...creating Viaggio OBU $TRATTA\n"
	# escamotage to gen OBU with "randomness"
	APPARATO=$(date "+%S%2N")
	if [ $TRATTA == 'EU' ] ; then 
		time_old=4320
	else
		time_old=720
	fi
fi

id_temporale_ENTRATA=$(date -d "-$(expr $time_old - 3) min" +"%Y-%m-%dT%H:%M:%S.%3N+02:00")
id_temporale_ITINERE=$(date -d "-$(expr $time_old - 4) min" +"%Y-%m-%dT%H:%M:%S.%3N+02:00")
id_temporale_USCITA=$(date -d "-$(expr $time_old - 5) min" +"%Y-%m-%dT%H:%M:%S.%3N+02:00")

if [ $TRATTA == 'EUS' ] || [ $TRATTA == 'US' ] ; then
	direction_svn='998'
	id_temporale_SVINCOLO=$(date -d "-$(expr $time_old - 10) min" +"%Y-%m-%dT%H:%M:%S.%3N+02:00")
	if [ $TRATTA == 'US' ] ; then 
		aperto_BOOL=true
	fi
elif [ $TRATTA == 'SEU' ] || [ $TRATTA == 'SU' ] ; then
	direction_svn='997'
	id_temporale_SVINCOLO=$(date -d "-$(expr $time_old - 3) min" +"%Y-%m-%dT%H:%M:%S.%3N+02:00")
	if [ $TRATTA == 'SU' ] ; then 
		aperto_BOOL=true
	fi
elif [ $TRATTA == 'U' ] ; then
	aperto_BOOL=true
fi

VIAGGIO_DIR="Viaggio$type_viaggio-$TRATTA"
path_VIAGGIO_dir=$path_OUT_dir/$VIAGGIO_DIR

if [ -d $path_VIAGGIO_dir ] ; then 
	rm -r $path_VIAGGIO_dir
fi

mkdir $path_OUT_dir/$VIAGGIO_DIR
path_VIAGGIO_dir=$path_OUT_dir/$VIAGGIO_DIR
echo -e "...created folder '$VIAGGIO_DIR' at path: '$path_VIAGGIO_dir' \n"
chmod 0777 "$path_VIAGGIO_dir"

# extract event type from TRATTA
length=${#TRATTA}
i=0
while [[ $i -lt $length ]] ; do 
	t=${TRATTA:i:1}
    case $t in
        E)	
			filename="entrata$type_viaggio-$PUNTO_E.xml"
			touch $path_VIAGGIO_dir/$filename
			echo -e "...creating file '$filename'\n"
			echo -e "rete: $RETE_E\npunto: $PUNTO_E\nidTemporale: $id_temporale_ENTRATA\nserviceProvider: $SERVICE_PROVIDER\n$type_viaggio: $APPARATO \n"
			# to do scrivi nel file .xml
cat << EOF > "$path_VIAGGIO_dir/$filename"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<ns0:evento xmlns:ns0="http://transit.pr.auto.aitek.it/messages">
    <tipoEvento cod="E" />
    <idSpaziale periferica="62" progrMsg="1" corsia="0" dirMarcia="1" tipoPeriferica="P" rete="${RETE_E}" punto="${PUNTO_E}" />
    <idTemporale>${id_temporale_ENTRATA}</idTemporale>
    <infoVeicolo classe="10">
        <targaAnt nomeFile="targaAnt.jpg" affid="9" nazione="IT">${PLATE_NUMBER}</targaAnt>
        <targaPost nomeFile="targaPost.jpg" affid="9" nazione="IT">${PLATE_NUMBER}</targaPost>
        <targaRif nazione="IT">${PLATE_NUMBER}</targaRif>
EOF
if [ $type_viaggio == 'SET' ] ; then
cat << EOF >> "$path_VIAGGIO_dir/$filename"	
		<SET CodiceIssuer="${SERVICE_PROVIDER}" PAN="${APPARATO}" nazione="IT" EFCContextMark="604006001D09"/>
EOF
else
cat << EOF >> "$path_VIAGGIO_dir/$filename"	
		<OBU>${APPARATO}</OBU>
EOF
fi
cat << EOF >> "$path_VIAGGIO_dir/$filename"
	</infoVeicolo>
    <reg dataOraMittente="${sysdate}" />
</ns0:evento>
EOF
			((i++));;

		I)
			filename="itinere$type_viaggio-$PUNTO_I.xml"
			touch $path_VIAGGIO_dir/$filename
			echo -e "...creating file '$filename'\n"
			echo -e "rete: $RETE_I\npunto: $PUNTO_I\nidTemporale: $id_temporale_ITINERE\n$type_viaggio: $APPARATO \n"

cat << EOF >> "$path_VIAGGIO_dir/$filename"
<ns2:evento xmlns:ns2="http://transit.pr.auto.aitek.it/messages">
	<tipoEvento cod="I"/>
	<idSpaziale corsia="1" dirMarcia="1" periferica="1" progrMsg="17229" punto="${PUNTO_I}" rete="${RETE_I}" tipoPeriferica="B"/>
	<idTemporale>${id_temporale_ITINERE}</idTemporale>
	<infoVeicolo>
EOF
if [ $type_viaggio == 'SET' ] ; then
cat << EOF >> "$path_VIAGGIO_dir/$filename"	
		<SET CodiceIssuer="${SERVICE_PROVIDER}" PAN="${APPARATO}" nazione="IT"/>
EOF
else
cat << EOF >> "$path_VIAGGIO_dir/$filename"	
		<OBU>${APPARATO}</OBU>
EOF
fi
cat << EOF >> "$path_VIAGGIO_dir/$filename"	
	</infoVeicolo>
	<reg dataOraMittente="${sysdate}"/>
</ns2:evento>
EOF
		((i++));;

		U)	
			if [ $aperto_BOOL == true ] && [ $TRATTA == 'US' ] ; then 
				direction_usc=997
				filename="uscitaAperto$type_viaggio-$PUNTO_U-dir$direction_usc.xml"
			elif [ $aperto_BOOL == true ] && [ $TRATTA == 'SU' ] ; then
				direction_usc=998
				filename="uscitaAperto$type_viaggio-$PUNTO_U-dir$direction_usc.xml"	
			elif [ $aperto_BOOL == true ] && [ $TRATTA == 'U' ] ; then
				direction_usc=997
				filename="uscitaAperto$type_viaggio-$PUNTO_U-dir$direction_usc.xml"
			else 
				filename="uscitaChiuso$type_viaggio-$PUNTO_U.xml"
			fi
			touch $path_VIAGGIO_dir/$filename
			echo -e "...creating file '$filename'\n"
			echo -e "rete: $RETE_U\npunto: $PUNTO_U\nidTemporale: $id_temporale_USCITA\nserviceProvider: $SERVICE_PROVIDER\n$type_viaggio: $APPARATO \n"

cat << EOF > "$path_VIAGGIO_dir/$filename"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<ns0:evento xmlns:ns0="http://transit.pr.auto.aitek.it/messages">
    <tipoEvento cod="U" />
    <idSpaziale periferica="62" progrMsg="4" corsia="0" dirMarcia="1" tipoPeriferica="P" rete="${RETE_U}" punto="${PUNTO_U}" />
    <idTemporale>${id_temporale_USCITA}</idTemporale>
    <infoVeicolo classe="10">
EOF
if ! [ $aperto_BOOL == true ] ; then
cat << EOF >> "$path_VIAGGIO_dir/$filename"	
        <targaAnt nomeFile="targaAnt.jpg" affid="9" nazione="IT">${PLATE_NUMBER}</targaAnt>
        <targaPost nomeFile="targaPost.jpg" affid="9" nazione="IT">${PLATE_NUMBER}</targaPost>  
        <targaRif nazione="IT">${PLATE_NUMBER}</targaRif>
EOF
fi

if [ $type_viaggio == 'SET' ] ; then
cat << EOF >> "$path_VIAGGIO_dir/$filename"	
		<SET CodiceIssuer="${SERVICE_PROVIDER}" PAN="${APPARATO}" nazione="IT" EFCContextMark="604006001D09"/>
EOF
else
cat << EOF >> "$path_VIAGGIO_dir/$filename"	
		<OBU>${APPARATO}</OBU>
EOF
fi

if ! [ $aperto_BOOL == true ] ; then
cat << EOF >> "$path_VIAGGIO_dir/$filename"
	</infoVeicolo>
    <idViaggio mezzoPagamento="TL" />
EOF
fi

if [ $dati_entrata_bool == true ] ; then
cat << EOF >> "$path_VIAGGIO_dir/$filename"
	<datiEntrata idTemporale="$id_temporale_ENTRATA" pista="12" classe="10">
	<stazione rete = "$RETE_E" punto = "$PUNTO_E"/>
	</datiEntrata>
EOF

mv "$path_VIAGGIO_dir/$filename" "$path_VIAGGIO_dir/"${filename%.*}conDatiEntrata.xml""
filename="${filename%.*}conDatiEntrata.xml"
mv "$path_OUT_dir/$VIAGGIO_DIR" $path_OUT_dir/"$VIAGGIO_DIR-conDatiEntrata"
VIAGGIO_DIR="Viaggio$type_viaggio-$TRATTA-conDatiEntrata"
path_VIAGGIO_dir=$path_OUT_dir/$VIAGGIO_DIR

elif [ $aperto_BOOL == true ] ; then 
cat << EOF >> "$path_VIAGGIO_dir/$filename"
	</infoVeicolo>
	<datiEntrata>
		<stazione rete="$RETE_U" punto="$direction_usc"/>
	</datiEntrata>
EOF
fi

cat << EOF >> "$path_VIAGGIO_dir/$filename"
    <reg dataOraMittente="${sysdate}" />
</ns0:evento>
EOF
			((i++));;

		S)
			if [ $direction_svn == '998' ] ; then
				nome_dir="Dopo$type_viaggio"
			else
				nome_dir="Prima$type_viaggio"
			fi
			filename="svincolo$nome_dir-$PUNTO_S.xml"
			touch $path_VIAGGIO_dir/$filename
			echo -e "...creating file '$filename'\n"
			echo -e "rete: $RETE_S\npunto: $PUNTO_S\nidTemporale: $id_temporale_SVINCOLO\nserviceProvider: $SERVICE_PROVIDER\n$type_viaggio: $APPARATO \n"

cat << EOF > "$path_VIAGGIO_dir/$filename"
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<ns2:evento xmlns:ns2="http://transit.pr.auto.aitek.it/messages">
    <tipoEvento cod="S"/>
    <idSpaziale corsia="1" dirMarcia="1" periferica="1" progrMsg="17621" punto="${PUNTO_S}" rete="${RETE_S}" tipoPeriferica="B"/>
    <idTemporale>${id_temporale_SVINCOLO}</idTemporale>
    <infoVeicolo>
EOF
if [ $type_viaggio == 'SET' ] ; then
cat << EOF >> "$path_VIAGGIO_dir/$filename"	
		<SET CodiceIssuer="${SERVICE_PROVIDER}" PAN="${APPARATO}" nazione="IT" EFCContextMark="604006001D09"/>
EOF
else
cat << EOF >> "$path_VIAGGIO_dir/$filename"	
		<OBU>${APPARATO}</OBU>
EOF
fi
cat << EOF >> "$path_VIAGGIO_dir/$filename"
    </infoVeicolo>
	<datiEntrata>
		<stazione rete="${RETE_S}" punto="${direction_svn}"/>
	</datiEntrata>
    <reg dataOraMittente="${sysdate}"/>
</ns2:evento>
EOF
			((i++));;
		
    esac
done

echo -e "...all files are present at path: '$path_VIAGGIO_dir' \n"

