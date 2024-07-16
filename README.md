gen_events.sh è uno script bash sviluppato per semplificare la creazione di Viaggi SET o OBU da dare in pasto a LEV.

i parametri da dare in pasto allo script sono:
    
    -tr) permette di specificare la tipologia di Viaggio che si vuole creare (ex. 'EUS' acronimo di Entrata, Uscita e Svincolo)
    
    -re) rete dell'evento di Entrata
    -pe) punto (o stazione) di Entrata
    -ri) rete dell'evento di Itinere
    -pi) punto di Itinere
    -ru) rete dell'evento di Uscita
    -pu) punto (o stazione) di Uscita
    -de) permette di inserire (yY) o meno (nN) i datiEntrata nell'evento di Uscita
    -rs) rete dell'evento di Svincolo
    -ps) punto (o stazione) di Svincolo

    -ap) permette di specificare che tipologia di apparato viene utilizzata: SET (digitando 's') oppure OBU (digitando 'o')
    -sp) permette di specificare il ServiceProvider di riferimento
    -pl) permette di specificare la targa del veicolo (ex. AM000AM)

Immaginiamo di voler lanciare il seguente comando : bash gen_events.sh -tr EUS -re 1 -pe 411 -ru 1 -pu 414 -de y -rs 37 -ps 428 -pl AM001AM -sp 151 -ap s

Lo script crea, se non esiste già, una cartella 'OUT_DIR_EVENTS' al cui interno creerà, ad ogni run, un'ulteriore cartella contenente a sua volta i file da dare in pasto a LEV (tutte le cartelle saranno rinominate nel seguente modo: 'Viaggio<tipo_apparato>-<tratta>.xml'). Ogni file al suo interno sarà rinominato nel seguente modo: '<tipo_di_evento><tipo_apparato>-<stazione>.xml' in modo da essere facilmente riconoscibili.

Lo script è pensato per automatizzare il più possibile la preparazione degli eventi, quindi:
-   in caso di viaggio SET, genera un PAN in automatico seguendo questo pattern: '<YYYYMMDD>000..00<numero_targa>F'
-   in caso di Viaggio OBU invece userà 'sysdate' prendendo in considerazione solo la parte di secondi e millisecondi (ex. 56002)
-   sia in caso di SET che OBU, TUTTI gli idTemporali sono generati in maniera tale da attendere pochi minuti affinché LEV certifichi il viaggio risultante
-   dando in input la tratta, lo script riconosce se l'evento è di Sistema Aperto o Chiuso, se è uno svincoloPrima o Dopo e la sua direzione (997 o 998)

una volta terminato il run, basterà eseguire il drag and drop dei file nelle code JMS dedicate.eh si

