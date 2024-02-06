#!/bin/bash

# Vérifier si le nombre d'arguments est correct
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <DBNAME>"
    exit 1
fi

# Récupérer le paramètre DBNAME depuis la ligne de commande
DBNAME="$1"

# Exécuter la commande et stocker la sortie dans une variable
output=$(/usr/dbvisit/standbymp/oracle/dbvctl -d "$DBNAME" -i)

# Extraire les valeurs de "Transfer Log Gap" et "Apply Log Gap"
transfer_log_gap=$(echo "$output" | awk '/Transfer Log Gap/{print $4}')
apply_log_gap=$(echo "$output" | awk '/Apply Log Gap/{print $4}')

# Test pour Transfer Log Gap
if [ "$transfer_log_gap" -gt 10 ]; then
    # Afficher le message d'alerte avec la valeur actuelle
    echo "Alerte : La valeur de Transfer Log Gap ($transfer_log_gap) pour $ORCL est supérieure à 10."
else
    # Afficher un message indiquant que tout est OK
    echo "La valeur de Transfer Log Gap pour $ORCL est inférieure ou égale à 10."
fi

# Test pour Apply Log Gap
if [ "$apply_log_gap" -gt 10 ]; then
    # Afficher le message d'alerte avec la valeur actuelle
    echo "Alerte : La valeur de Apply Log Gap ($apply_log_gap) pour $ORCL est supérieure à 10."
else
    # Afficher un message indiquant que tout est OK
    echo "La valeur de Apply Log Gap pour $ORCL est inférieure ou égale à 10."
fi
