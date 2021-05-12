#!/usr/bin/env bash

########################################################################
# flashindex.sh - Φτιάχνει μια στατική σελίδα HTML, που περιέχει μια
# λίστα με τα περιεχόμενα ενός καταλόγου, και αυτών από κάτω του σε προ-
# καθορισμένο βάθος.
# Όλα τα αρχεία που βρίσκει, τα γράφει στη λίστα ως συνδέσμους σε αυτά.
# Επίσης τσεκάρει τον κατάλογο μεταδεδομένων, τον οποίο δεν γράφει στη
# λίστα για πρακτικούς λόγους, για αρχεία που περιέχουν σημειώσεις οι
# οποίες μπαίνουν στην ιδιότητα title του HTML στοιχείου a.
# Τα μεταδεδομένα αντιστοιχίζονται είτε μέσω ονόματος αρχείου, είτε μέσω
# md5 κατ' επιλογήν, για την περίπτωση που συμπίπτουν τα ονόματα δύο ή
# περισσότερων αρχείων.
# Η σελίδα που παράγεται μπορεί να διαμορφωθεί CSS.
# Το έγραψα αυτό το σκριπτ για να μπορώ να τσεκάρω στα γρήγορα για
# αρχεία, ανεξάρτητα από πού τα βλέπω, με κάπως οργανωμένες σημειώσεις
# γιατί συχνά καταλήγω μετά από καιρό να μην έχω ιδέα τί και πού
# είναι το κάθε τί, από που το κατέβασα, γιατί κλπ. Σκέφτηκα πως αυτή
# είναι μια απλή και φορητή λύση. HTML διαβάζει και ένα καλό λαμπατέρ
# σήμερα, και ό,τι χρειάζομαι βρίσκεται σε μία σελίδα. Το σκριπτ είναι
# πιστεύω αρκετά φορητό, προσπάθησα να το κάνω ώστε να μην εξαρτάται από
# χαρακτηριστικά συγκεκριμένου κελύφους ή λειτουργικού συστήματος.
########################################################################

#Μεταβλητές σελίδας
SCRIPTNAME="flashindex.sh"
VERSION="0.8"
DEVICE="Verbatim USB drive"
PAGECOMMENT="© Copyright <a href=\"https://ionas.dev\">Ιωνάρας</a> 2020 $SCRIPTNAME $VERSION"
#Μεταβλητές καταλόγων
ROOT="$HOME" #αρχικός κατάλογος
OUTPUT="$ROOT/index.html" #σε ποιο αρχείο να γραφεί η σελίδα
META="" #κατάλογος σχολίων
#Μεταβλητές επιλογών κατά την εκτέλεση
CHECKMD5=false #χρήσιμο σε περιπτώσεις με ίδια ονόματα αρχείων. αργεί.
MAXDEPTH=5 #βάθος καταλόγων
CREATEDIRS=false #αν δεν υπάρχει κάποιος κατάλογος, να δημιουργηθεί
PRINTSIZE=false #γράφε και το μέγεθος του κάθε αρχείου στη σελίδα

while getopts "cd:fmn:o:r:s:t:" arg
do
  case $arg in
    c)
      CREATEDIRS=true
      ;;
    d)
      if [ "$OPTARG" -gt 0 ]
      then
        MAXDEPTH="$OPTARG"
      fi
      ;;
    f)
      PRINTSIZE=true
      ;;
    m)
      CHECKMD5=true
      ;;
    n)
      DEVICE="$OPTARG"
      ;;
    o)
      OUTPUT="$OPTARG"
      ;;
    r)
      ROOT="$OPTARG"
      OUTPUT="$ROOT/index.html"
      META="$ROOT/.meta"
      ;;
    s)
      STYLESHEET="$OPTARG"
      ;;
    t)
      META="$OPTARG"
      ;;
    *)
      printf "%s - generate a static HTML page of a directory's contents\n
Usage: flashindex.sh [-r rootdir -o output.html]
\t-c: create metadata directory if needed
\t-d int: define maximum depth (default: 5)
\t-f: print size next to filename
\t-n name: cosmetic name of your choice, displayed at the page's top
\t-m: check files for script-related metadata using md5sum\
 instead of filename matching; useful for files with the same name in\
 different directories, but much slower
\t-o file: the HTML-formatted output file
\t-r directory: root directory to work with
\t-s stylesheet: CSS stylesheet file to link in <head>
\t-t directory: the metadata directory; to add a comment for a file,\
 create a plain text file with the same name (or the md5 hash as the\
 filename) in this directory\n" "${SCRIPTNAME}"
      exit 1
      ;;
  esac
done

filecheck () {
  # Αντιστοίχιση αρχείων - μεταδεδομένων/σχολίων
  if [ -n "$META" ]
  then
    unset comment
    if $CHECKMD5
    then
      local md5=($(md5sum "$1"))
      if [ -f "$META/$md5" ]
      then comment=$(cat "$META/$md5")
      else echo "Consider adding a comment for ${1}: $META/$md5"
      fi
    else
      local file=$(basename "$1")
      if [ -f "$META/$file" ]
      then
        comment=$(cat "$META/$file")
      fi
    fi
    if [ -n "$comment" ]
    then
      comment=" class=\"hascomment\" title=\"${comment}\""
    fi
  fi
}

printhtml () {
  if [ -n "$1" ]
  then
    printf "%s${1}\n" "$indent" >> "$OUTPUT"
  fi
}

getsize () {
  if $PRINTSIZE
  then
    local SIZE=($(du -sh "$1"))
    printf "<span class=\"size\"> (%s)</span>" "$SIZE"
  fi
}

if [ ! -d "$ROOT" ]
then
  echo "$ROOT not found"
  exit 1
fi
if $CREATEDIRS && [ ! -d "$META" ]
then mkdir -p "$META"
fi
#todo elegxos metavlhtwn
#     na antigrafei to stylesheet sto head me entolh
#     link sto sxolio me to open with...?
if [ ! -w "$OUTPUT" ]
then
  echo "output file not writable, exiting :("
  exit 1
fi
echo "Using root: $ROOT"
printf "<!DOCTYPE html>\n" > "$OUTPUT" #anti gia printhtml(), praktiko
printhtml "<html lang=\"en\">"
printhtml "<head>"
printhtml "<meta charset=\"utf-8\">"
printhtml '<meta name="viewport" content="width=device-width, initial-scale=1.0"> '
printhtml "<title>${DEVICE} index</title>"
printhtml "<meta title=\"generator\" content=\"$SCRIPTNAME $VERSION\">"
if [ -n "$STYLESHEET" ] && [ -r "$STYLESHEET" ]
then printhtml "<link rel=\"stylesheet\" type=\"text/css\" href=\"${STYLESHEET}\">"
fi
printhtml "</head>"
printhtml "<body>"
indent="  "
printhtml "<h2>$DEVICE file listing generated on $(date "+%x %X")</h2>"
printhtml "<ul>"
find "$ROOT" -maxdepth "$MAXDEPTH" -mindepth 1 -path "$META" -prune -o  -type d -print0 | sort -z | \
#για να μην πιάσει το $META, πρέπει να λάβεις υπόψην το παθ του -r σε σχέση με του -t
while IFS= read -r -d '' dir
do
  if [ -z "$(ls "$dir")" ]
  then continue
  fi
  indent="  "
  printhtml "<li class=\"dir\">$dir</li>"
  printhtml "<ul class=\"files\">"
  find "$dir" -maxdepth 1 -mindepth 1 -type f -print0 | sort -z | \
  while IFS= read -r -d '' file
  do
    indent="    "
    filecheck "$file"
    printhtml "<li><a href=\"$file\"${comment}>$(basename "$file")</a>$(getsize "$file")</li>"
  done
  printhtml "</ul>"
done
printhtml "</ul>"
printhtml "<p>$PAGECOMMENT</p>"
printhtml "</body>"
printhtml "</html>"
exit 0
