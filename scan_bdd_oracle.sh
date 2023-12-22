#!/bin/sh
#------------------------------------------------------------------------------
# recherche des serveurs de base de données
# scan d'une plage d'adresse et une plage de port pour trouver
# un listener Oracle, une base mysql, postgres sql ou microsoft sql server
#------------------------------------------------------------------------------
# Historique :
# 26/07/2016 : YOU – Creation
# 29/07/2016 : YOU – Mise à jour
# 25/08/2021 : YOU - Adaptation pour les reseaux BM
# 14/09/2021 : YOU - Adresses reseau en notation CIDR xxx.xxx.xxx.xxx/xx
#------------------------------------------------------------------------------

#-------
# les réseaux à scanner
#-------
reseau="192.168.31.0/24"
# reseau="10.0.30.0 10.0.40.0 192.31.6.0 172.16.1.0"
mask_reseau=24

#-------
# les ports à scanner :
# 1500-3000             => la plage entre 1500 et 3000
# 1521,1621             => les deux ports 1521 et 1621
# 1521,1621-3000        => le port 1521 et la plage de 1621-3000
#-------
# les ports par base :
# Microsoft sql server  => 1433
# Oracle                => 1521-1699
# Sybase                => 2638
# Progress              => 3000-3003
# Mysql                 => 3306
# PostgreSQL            => 5432
#-------
# la ligne suivante est composée de plusieurs plages pour minimiser le temps du scan
# port_reseau="1430-1440,1500-1700,2600-2700,3000-3010,3300-3310,5400-5500"
#-------
port_reseau="1520-1530"

#-------
# les variables d'environnement
#-------
export repertoire_base=/root/scripts
export repertoire_logs=${repertoire_base}/logs
export fichier_log=${repertoire_logs}/scan_bdd_$(date +%Y.%m.%d-%Hh%M).log
mkdir -p ${repertoire_logs} > /dev/null
echo "" > ${fichier_log}

#-------
# paramètre du scan
#-------
echo "#--------------------- Paramètres du scan ----------------------------"       | tee -a ${fichier_log}
echo "# Date : $(date +%Y.%m.%d-%Hh%M)"                                             | tee -a ${fichier_log}
echo "# Répertoire de base du script : ${repertoire_base}"                          | tee -a ${fichier_log}
echo "# Répertoire des fichiers logs : ${repertoire_logs}"                          | tee -a ${fichier_log}
echo "# Nom du fichier log de cette session : ${fichier_log}"                       | tee -a ${fichier_log}
echo "# Les réseaux scannés : ${reseau}"                                            | tee -a ${fichier_log}
echo "#----------------------------------------------------------------------"      | tee -a ${fichier_log}

#-------
# on parcourt les réseau pour détecter les serveurs joignables par fping
# le résultat est scanné par nmap pour trouver les bases de données
#-------

for plage in $reseau
do
        plage_reseau=$(echo ${plage} | cut -d/ -f1)
        mask_reseau=$(echo ${plage} | cut -d/ -f2)
        if [ -z "${mask_reseau}" ]; then mask_reseau="24"; fi

        echo "#----------------------------------"      | tee -a ${fichier_log}
        echo "# Scan du reseau : ${plage} "             | tee -a ${fichier_log}
        echo "# Plage reseau   : ${plage_reseau} "      | tee -a ${fichier_log}
        echo "# Masque reseau  : ${mask_reseau} "       | tee -a ${fichier_log}
        echo "#----------------------------------"      | tee -a ${fichier_log}
        /usr/sbin/fping -q -a -d -g ${plage_reseau}/${mask_reseau} 2>/dev/null | while read ip
        do
                # nmap -sV : detection de la version du produit
                # namp -n : desactiver la resolution des nom pour acceler le scan
                # namp -sS : scan avec un packet TCP SYNC
                # ret=$(/usr/bin/nmap -n -sS -sV -p ${port_reseau} ${ip} | grep -i "open" | egrep -i "oracle|sql|Progress Database|sybase")
                ret=$(/usr/bin/nmap -n -sS -sV -p ${port_reseau} ${ip} | grep -i "open" | egrep -i "oracle")
                if [ "$ret" != "" ]; then
                        echo "${ret}" | sed "s/^/Serveur $ip \t:\t /g" | tee -a ${fichier_log}
                fi
        done
done


echo "#---------- SCAN TERMINE A $(date +%Y.%m.%d-%H:%M) -----------------"  | tee -a ${fichier_log}
echo "# Fichier log de cette session : ${fichier_log}"
echo "#-------------------------------------------------------------------"

#-------
# fin
#-------
