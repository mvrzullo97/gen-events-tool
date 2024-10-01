gen_events.sh è uno script bash sviluppato per semplificare e velocizzare la creazione di eventi SET o OBU da dare in pasto a LEV.

i parametri disponibili sono:
    
    -tr) specifica la tipologia di Viaggio che si vuole creare (ex. 'EUS' acronimo di Entrata, Uscita e svincoloDopo)
    
    -re) rete di Entrata
    -pe) punto di Entrata
    -ri) rete di Itinere
    -pi) punto di Itinere
    -ru) rete di Uscita
    -pu) punto di Uscita
    -de) permette di inserire (yY) o meno (nN) i datiEntrata all'interno dell'evento di Uscita, se non viene inserito lo script prende di default 'nN'
    -rs) rete di Svincolo
    -ps) punto di Svincolo

    -ap) specifica la tipologia di apparato: SET (digitando 's') oppure OBU (digitando 'o')
    -sp) specifica il ServiceProvider di riferimento (attualmente è possibile usare solo i seguenti serviceProviders : '151' '2321' '3000' '7' '49')
    -pl) specifica la targa del veicolo (ex. AM000AM)


All'interno della stessa cartella è presente un file chiamato 'gen_events_conf.xml' che permette di modificare secondo le proprie necessità diversi parametri dello script:
    - timeout di certificazione SET (se è stato modificato nel file di configurazione lev.xml il timer di certificazione)
    - timeout di certificazione OBU (idem)
    - tempo di 'vecchiaia' degli eventi, ovvero la generazione di idTemporali in maniera tale da attendere pochi minuti per verificare che LEV certifichi correttamente il viaggio
    - lista dei codici dei service provider con relativa nazionalità


Immaginiamo di voler lanciare il seguente comando: bash gen_events.sh -tr EUS -re 1 -pe 411 -ru 1 -pu 414 -de y -rs 37 -ps 428 -pl AM001AM -sp 151 -ap s

Lo script crea, se non esiste già, una cartella 'OUT_DIR_EVENTS' al cui interno creerà, ad ogni run, un'ulteriore cartella contenente a sua volta i file da dare in pasto a LEV (tutte le cartelle saranno rinominate nel seguente modo: 'Viaggio<tipo_apparato>-<tratta>.xml'). Ogni file al suo interno sarà rinominato nel seguente modo: '<tipo_di_evento><tipo_apparato>-<stazione>.xml' in modo da essere facilmente riconoscibile.

Lo script è pensato per automatizzare il più possibile la preparazione degli eventi, quindi:
-   in caso di viaggio SET, genera un PAN in automatico seguendo questo pattern: '<YYYYMMDD>000<millisecondi(3 cifre)>0...0<numero_targa>F'
-   in caso di Viaggio OBU invece userà come escamotage 'sysdate' prendendo in considerazione solo la parte di secondi e millisecondi (ex. 5602)
-   sia in caso di SET che OBU, TUTTI gli idTemporali sono generati in maniera tale da attendere pochi minuti affinché LEV certifichi il viaggio risultante
-   dando in input la tratta, lo script riconosce se l'evento è di Sistema Aperto o Chiuso, se è uno svincoloPrima o Dopo e la relativa direzione (997 o 998)

una volta terminato il run, basterà eseguire il drag and drop dei file nelle code JMS dedicate.

Alcuni esempi di casistiche con relativo comando bash da lanciare:

-   Entrata + Uscita (con datiEntrata) SET ---> bash gen_events.sh -tr EU -re 1 -pe 557 -ru 1 -pu 558 -de y -ap s -sp 151 -pl AX000AA

-   Entrata + Uscita + svincoloDopo SET ---> bash gen_events.sh -tr EUS -re 1 -pe 411 -ru 1 -pu 414 -de y -rs 37 -ps 428 -ap s -sp 151 -pl AM001AM  
 
-   Uscita di sistema Aperto + svincoloDopo OBU ---> bash gen_events.sh -tr US -ru 34 -pu 469 -rs 37 -ps 428 -ap o -sp 49 -pl AC000BB
 
-   Entrata + Uscita (SENZA datiEntrata) OBU ---> bash gen_events.sh -tr EU -re 1 -pe 412 -ru 1 -pu 413 -de n -ap o -sp 151 -pl AC000BB

