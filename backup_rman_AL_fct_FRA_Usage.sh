#!/bin/sh
#
# 
#------------------------------------------------------------------------------
# ORACLE DATABASE : BACKUP RMAN des AL
# le script récupère le pourcentage d'occupation de la FRA
# Si ce pourcentage est supérieur à un seuil prédéfinit, il lance un script 
# pour sauvegarder les archivelog et purger la FRA
#------------------------------------------------------------------------------
# Historique :
#       21/12/2023 : YOU - Creation 
#------------------------------------------------------------------------------


for sid in $(ps -ef | grep pmon | grep -v grep | cut -d_ -f3 | sort)
do 
    #
    # positionner les variables d'environnement ORACLE
    #
    ORACLE_SID=$sid

    # vérifier si ORACLE_SID est pésente dans le fichier /etc/oratab
    if [ "$(grep -v '^$|^#' /etc/oratab | grep -c "^${ORACLE_SID}:")" -ne 1 ]; then
        echo "Base ${ORACLE_SID} absente du fichier /etc/oratab ... fin du script"
        exit 2
    fi
    
    ORAENV_ASK=NO
    PATH=/usr/local/bin:$PATH
    . oraenv -s >/dev/null

    # Variables d'initialisation 
    script_dir=/home/oracle/scripts
    pct_limit=85
    action_script="${script_dir}/backup_rman_AL.sh ${ORACLE_SID}"

    # 
    # calcul de la taille FRA 
    #
    fra_usage=$(sqlplus -s '/ as sysdba' << EOF
        set pages 0 feedback off;
        select round(sum(percent_space_used),0) from v\$flash_recovery_area_usage;
EOF
) 

    pct_fra_used=$(echo ${fra_usage} | egrep -o "[0-9]*")

    # 
    # Si la FRA dépasse la limite on lance le script
    #
    if [ "${pct_fra_used}" -gt ${pct_limit} ]
    then
        echo ${pct_fra_used} : backup des archivelog necessaire par script ${action_script}
        sh ${action_script}
    else
        echo ${pct_fra_used} : backup des archivelog non necessaire
    fi
done
