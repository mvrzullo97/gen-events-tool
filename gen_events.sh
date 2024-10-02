#!/bin/bash
# usage menu
echo
echo "---------------------- Usage ----------------------"
echo -e "\n   bash $0\n\n    -tr < tratta > (ex. 'EUS')\n    -re < rete Entrata >\n    -pe < punto Entrata >\n    -ri < rete Itinere >\n    -pi < punto Itinere >\n    -ru < rete Uscita >\n    -pu < punto Uscita >\n    -de < datiEntrata > (yY or nN)\n    -rs < rete Svincolo >\n    -ps < punto Svincolo >\n    -ap < tipo apparato ('o' for OBU or 's' for SET) >\n    -sp < codice Service Provider >\n    -pl < targa veicolo >\n    -cc < cashback cantieri (yY or nN) >\n"
echo


#to do . aggiungere possibilità di generazione Evento di Sconto per cashback cantieri

counter_args=0

# parsing degli OPTARGS
while [[ "$#" -gt 0 ]] ; do
    case $1 in
        -tr) TRATTA="$2"
			((counter_args++))
			 	shift 2;;
		-re) RETE_E="$2"
			((counter_args++))
			 	shift 2;;
        -ru) RETE_U="$2"
			((counter_args++))
			 	shift 2;;
		-ri) RETE_I="$2"
			((counter_args++))
				shift 2;;
		-pi) PUNTO_I="$2"
			((counter_args++))
				shift 2;;
		-rs) RETE_S="$2"
			((counter_args++))
			 	shift 2;;
		-pe) PUNTO_E="$2"
			((counter_args++))
			 	shift 2;;
        -pu) PUNTO_U="$2"
			((counter_args++))
			 	shift 2;;
		-de) DATI_ENTRATA="$2"
			((counter_args++))
				shift 2;;
		-ps) PUNTO_S="$2"
			((counter_args++))
			 	shift 2;;
		-ap) APPARATO="$2"
			((counter_args++))
				shift 2;;
		-sp) SERVICE_PROVIDER="$2"
			((counter_args++))
				shift 2;;
		-pl) PLATE_NUMBER="$2"
			((counter_args++))
				shift 2;;
		-cc) CASHBACK_CANTIERI="$2"
			((counter_args++))
				shift 2;;
        *)  echo -e "Error: Invalid option $1\n"
			exit 0
    esac
done

rete_svincoli=('37')
punti_svincoli=('427' '428' '470')

# input validation
if [ $counter_args -lt 6 ] ; then
	echo "Argument error: please digit right command."
	echo
	exit 0
elif { [ $TRATTA == 'US' ] || [ $TRATTA == 'SU' ]; } && [[ "$DATI_ENTRATA" =~ ^([yY])$ ]] ; then 
	echo -e "Param error: for tratta '$TRATTA' datiEntrata param (-de) makes no sense, please delete it or digit 'n' or 'N' \n"
    exit 0 
elif [ ${#TRATTA} -gt 3 ] ; then
	echo -e "Param error: '$TRATTA' is not valid \n"
	exit 0
elif ! [[ "$DATI_ENTRATA" =~ ^([yY])$ ]] && ! [[ "$DATI_ENTRATA" =~ ^([nN])$ ]] && ! [[ "$DATI_ENTRATA" == '' ]] ; then
    echo -e "Param error: please digit valid value for -de param (yY-nN) \n"
    exit 0
elif ! [[ ${rete_svincoli[@]} =~ $RETE_S ]] ; then
    echo -e "Param error: rete svincolo '$RETE_S' doesn't exist \n"
    exit 0 
elif ! [[ ${punti_svincoli[@]} =~ $PUNTO_S ]] ; then
    echo -e "Param error: punto svincolo '$PUNTO_S' doesn't exist \n"
    exit 0
elif [[ $APPARATO != 'o' ]] && [[ $APPARATO != 's' ]] ; then
	echo -e "Param error: please digit a valid apparato ('o' for OBU or 's' for SET) \n"
    exit 0
elif [ ${#PLATE_NUMBER} != 7 ] ; then 
    echo -e "Param error: length of targa veicolo must be 7 \n"
    exit 0
elif ! [[ "$CASHBACK_CANTIERI" =~ ^([yY])$ ]] && ! [[ "$CASHBACK_CANTIERI" =~ ^([nN])$ ]] && ! [[ "$CASHBACK_CANTIERI" == '' ]] ; then
    echo -e "Param error: please digit valid value for -cc param (yY-nN) \n"
    exit 0
elif [[ $APPARATO == 'o' && "$CASHBACK_CANTIERI" =~ ^([yY])$ ]] ; then
	echo -e "Param error: can not create a cashback file discount for OBU \n"
	exit 0
fi


# get conf_params from file, if exists
file_conf='gen_events_conf.xml'
dumb_nums='[0-9]+([.][0-9]+)?'

if [ -f $file_conf ] ; then
	echo -e "...recovered configuration params from file '$file_conf' \n"

	timeout_SET=$(grep -e "timeout_SET" $file_conf | grep -oE $dumb_nums)
	timeout_OBU=$(grep -e "timeout_OBU" $file_conf | grep -oE $dumb_nums)

	old_age_Entrata=$(grep -e "old_age_Entrata" $file_conf | grep -oE $dumb_nums)
	old_age_Itinere=$(grep -e "old_age_Itinere" $file_conf | grep -oE $dumb_nums)
	old_age_Uscita=$(grep -e "old_age_Uscita" $file_conf | grep -oE $dumb_nums)
	old_age_svincoloPrima=$(grep -e "old_age_svincoloPrima" $file_conf | grep -oE $dumb_nums)
	old_age_svincoloDopo=$(grep -e "old_age_svincoloDopo" $file_conf | grep -oE $dumb_nums)

	providers_code=()
	providers_code=$((grep -e "providers_code" $file_conf) | cut -d '=' -f2 )
	providers_code="${providers_code//','}"
	providers_code=($providers_code)
	
	naz_providers=()
	naz_providers=$((grep -e "naz_providers" $file_conf) | cut -d '=' -f2 )
	naz_providers="${naz_providers//','}"
	naz_providers=($naz_providers)

elif ! [ -f $file_conf ] ; then 
	echo -e "...file '$file_conf' not found, I'll use deafult params \n"
	timeout_SET=720
	timeout_OBU=4320
	old_age_Entrata=1
	old_age_Itinere=2
	old_age_Uscita=3
	old_age_svincoloPrima=1
	old_age_svincoloDopo=5
	providers_code=('151' '2321' '3000' '7' '49')
	naz_providers=('IT' 'IT' 'IT' 'DE' 'FR')
fi


if ! [[ ${providers_code[@]} =~ $S_PROVIDER ]] ; then
    echo -e "Param error: codice service provider '$SERVICE_PROVIDER' doesn't exist \n"
    exit 0
fi

if [ $APPARATO == 's' ] ; then
	declare -A hash_PVD_NAZ
	length=${#providers_code[@]}
	for ((i=0; i<$length; i++)) ; do
		hash_PVD_NAZ["${providers_code[i]}"]="${naz_providers[i]}"
	done
	NAZ_SERVICE_PROVIDER=${hash_PVD_NAZ[$SERVICE_PROVIDER]}
fi


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

# per ora 4n poi 3n
timestamp_PAN=$(date +"%Y%m%d000%4N")

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
	echo -e "...creating Viaggio 'SET' for tratta '$TRATTA'\n"
	APPARATO=$(generate_PAN $plate_number)
	time_old=$timeout_SET
	timeout="it.aitek.auto.pr.viaggi.close_cert_timeout_hours"
elif [ $APPARATO == 'o' ] ; then
	type_viaggio="OBU"
	echo -e "...creating Viaggio 'OBU' for tratta '$TRATTA'\n"
	# escamotage to gen OBU with "randomness"
	APPARATO=$(date "+%S%2N")
	if [ $TRATTA == 'EU' ] || [ $TRATTA == 'EIU' ]; then 
		time_old=$timeout_OBU
		timeout="it.aitek.auto.pr.viaggi.close_cert_timeout_hours"
	else
		time_old=$timeout_SET
		timeout="it.aitek.auto.pr.viaggi_timeout_minutes"
	fi
fi

id_temporale_ENTRATA=$(date -d "-$(expr $time_old - $old_age_Entrata) min" +"%Y-%m-%dT%H:%M:%S.%3N+02:00")
id_temporale_ITINERE=$(date -d "-$(expr $time_old - $old_age_Itinere) min" +"%Y-%m-%dT%H:%M:%S.%3N+02:00")
id_temporale_USCITA=$(date -d "-$(expr $time_old - $old_age_Uscita) min" +"%Y-%m-%dT%H:%M:%S.%3N+02:00")

if [ $TRATTA == 'EUS' ] || [ $TRATTA == 'US' ] ; then
	direction_svn='998'
	id_temporale_SVINCOLO=$(date -d "-$(expr $time_old - $old_age_svincoloDopo) min" +"%Y-%m-%dT%H:%M:%S.%3N+02:00")
	if [ $TRATTA == 'US' ] ; then 
		aperto_BOOL=true
	fi
elif [ $TRATTA == 'SEU' ] || [ $TRATTA == 'SU' ] ; then
	direction_svn='997'
	id_temporale_SVINCOLO=$(date -d "-$(expr $time_old - $old_age_svincoloPrima) min" +"%Y-%m-%dT%H:%M:%S.%3N+02:00")
	if [ $TRATTA == 'SU' ] ; then 
		aperto_BOOL=true
	fi
elif [ $TRATTA == 'U' ] ; then
	aperto_BOOL=true
fi

VIAGGIO_DIR="Viaggio-$type_viaggio-$TRATTA"
VIAGGIO_DIR_2="$VIAGGIO_DIR-conDatiEntrata"
path_VIAGGIO_dir=$path_OUT_dir/$VIAGGIO_DIR
path_VIAGGIO_dir_2=$path_OUT_dir/$VIAGGIO_DIR_2

if [ -d $path_VIAGGIO_dir ] ; then 
	rm -r $path_VIAGGIO_dir
fi

if [[ $dati_entrata_bool == true ]] && [ -d $path_VIAGGIO_dir_2 ] ; then 
	rm -r $path_VIAGGIO_dir_2
fi




# use only if you want generate multiple events
#--------------
#n_date=$(date +"%4N")
#VIAGGIO_DIR="Viaggio-$type_viaggio-$TRATTA$n_date"
#path_VIAGGIO_dir=$path_OUT_dir/$VIAGGIO_DIR

#mkdir $path_OUT_dir/$VIAGGIO_DIR
#path_VIAGGIO_dir=$path_OUT_dir/$VIAGGIO_DIR
#-----------------


#-- per il run normale devo decommentare le due righe sottostanti
mkdir $path_OUT_dir/$VIAGGIO_DIR
path_VIAGGIO_dir=$path_OUT_dir/$VIAGGIO_DIR
echo -e "...created folder '$VIAGGIO_DIR' at path: '$path_VIAGGIO_dir' \n"
chmod 0777 "$path_VIAGGIO_dir"

echo -e "...generating 'idTemporali' considering '$timeout' set to '$time_old' minutes\n"
echo -e ".......................................................................................................................................\n"

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
		<SET CodiceIssuer="${SERVICE_PROVIDER}" PAN="${APPARATO}" nazione="${NAZ_SERVICE_PROVIDER}" EFCContextMark="604006001D09"/>
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
		<SET CodiceIssuer="${SERVICE_PROVIDER}" PAN="${APPARATO}" nazione="${NAZ_SERVICE_PROVIDER}"/>
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
			echo -e "rete: $RETE_U\npunto: $PUNTO_U\nidTemporale: $id_temporale_USCITA\nserviceProvider: $SERVICE_PROVIDER \n$type_viaggio: $APPARATO \n"

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
		<SET CodiceIssuer="${SERVICE_PROVIDER}" PAN="${APPARATO}" nazione="${NAZ_SERVICE_PROVIDER}" EFCContextMark="604006001D09"/>
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
VIAGGIO_DIR="Viaggio-$type_viaggio-$TRATTA-conDatiEntrata"
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
		<SET CodiceIssuer="${SERVICE_PROVIDER}" PAN="${APPARATO}" nazione="${NAZ_SERVICE_PROVIDER}" EFCContextMark="604006001D09"/>
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

if ! [[ -z "${CASHBACK_CANTIERI}" ]] && [[ "$CASHBACK_CANTIERI" =~ ^([yY])$ ]] ; then
	
	cashback_filename="eventoDiSconto$type_viaggio-$TRATTA.xml"

	cat << EOF > "$path_VIAGGIO_dir/$cashback_filename"
<?xml version="1.0" encoding="UTF-8"?>
<ns0:evento xmlns:ns0="http://transit.pr.auto.aitek.it/messages">
	<tipoEvento cod="U"/>
	<idSpaziale rete="${RETE_U}" punto="${PUNTO_U}" periferica="1" progrMsg="10865" corsia="0" dirMarcia="1" tipoPeriferica="P"/>
	<idTemporale>${id_temporale_USCITA}</idTemporale>
	<infoVeicolo classe="10">
		<SET nazione="${NAZ_SERVICE_PROVIDER}" PAN="${APPARATO}" CodiceIssuer="${SERVICE_PROVIDER}" EFCContextMark="604006001D09"/>
	</infoVeicolo>
	<idViaggio tin=INSERT_TIN_HERE/>
	<datiEntrata idTemporale="${id_temporale_ENTRATA}">
		<stazione rete="${RETE_E}" punto="${PUNTO_E}"/>
	</datiEntrata>
	<reg dataOraMittente="${sysdate}"/>
	<sconti idMessaggioSconto="1">
		<sconto importo="15.2" codiceSconto="25"/>
	</sconti>
</ns0:evento>
EOF
echo -e "...creating file '$cashback_filename' for Cashback Cantieri discount \n"
mv $path_VIAGGIO_dir $path_VIAGGIO_dir"CashbackCantieri"
fi
echo -e "...all files are present at path: '$path_VIAGGIO_dir' \n"
