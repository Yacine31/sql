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
#       05/11/2026 : YOU - gestion des erreurs, base en erreur sans arrêt de la boucle
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# fonction d'erreur : affiche le message et envoie la notification, la boucle continue
#------------------------------------------------------------------------------
f_erreur() {
    echo "$1" >&2
    curl -H "t: Erreur FRA base ${ORACLE_SID} sur le serveur $(hostname)" -d "$1" -L ${NTFY_URL}
    EXIT_RC=1
} #f_erreur

#------------------------------------------------------------------------------
# inititalisation des variables d'environnement
#------------------------------------------------------------------------------
export SCRIPTS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

# Nom du fichier .env
ENV_FILE=${SCRIPTS_DIR}"/.env"

# Vérifier si le fichier .env existe
if [ ! -f "$ENV_FILE" ]; then
    echo "Erreur : Le fichier $ENV_FILE n'existe pas."
    echo "Erreur : Impossible de charger les variables d'environnement."
    exit 1
fi

# Charger les variables d'environnement depuis le fichier .env
source "$ENV_FILE"

# chemin par défaut si ACTION_SCRIPT du fichier .env ne pointe pas vers un fichier existant
[ -f "${ACTION_SCRIPT}" ] || ACTION_SCRIPT="${SCRIPTS_DIR}/backup_rman_AL.sh"

EXIT_RC=0

# ora_pmon_ : bases de données uniquement, sans les instances ASM (asm_pmon_) ni APX (apx_pmon_)
for sid in $(ps -eo args= | grep "^ora_pmon_" | sed 's/^ora_pmon_//' | sort)
do 
    #
    # positionner les variables d'environnement ORACLE
    #
    ORACLE_SID=$sid

    # vérifier si ORACLE_SID est pésente dans le fichier /etc/oratab
    if [ "$(grep -v '^$|^#' /etc/oratab | grep -c "^${ORACLE_SID}:")" -ne 1 ]; then
        echo "Base ${ORACLE_SID} absente du fichier /etc/oratab ... base ignorée" >&2
        EXIT_RC=2
        continue
    fi
    
    ORAENV_ASK=NO
    PATH=/usr/local/bin:$PATH
    . oraenv -s >/dev/null

    # 
    # calcul de la taille FRA 
    #
    if ! fra_usage=$(sqlplus -s -L '/ as sysdba' 2>&1 <<'SQL'
        whenever sqlerror exit failure
        whenever oserror exit failure
        set pages 0 feedback off;
        select round(sum(percent_space_used),0) from v$flash_recovery_area_usage;
        exit
SQL
); then
        # ORA-01507 : instance en NOMOUNT (restauration, duplication...), ce n'est pas une anomalie
        case "${fra_usage}" in
            *ORA-01507*) echo "${ORACLE_SID} : base non montée, FRA non lue" ;;
            *) f_erreur "Impossible de lire l'occupation de la FRA : ${fra_usage}" ;;
        esac
        continue
    fi

    pct_fra_used=$(echo ${fra_usage})

    # le résultat doit être un entier ; il est vide si la base n'a pas de FRA
    case "${pct_fra_used}" in
        "")
            echo "${ORACLE_SID} : pas de FRA configurée"
            continue
            ;;
        *[!0-9]*)
            f_erreur "Occupation de la FRA non numérique : ${pct_fra_used}"
            continue
            ;;
    esac

    # 
    # Si la FRA dépasse la limite on lance le script
    #
    if [ "${pct_fra_used}" -gt ${PCT_LIMIT} ]
    then
        echo ${pct_fra_used} : backup des archivelog necessaire par script ${ACTION_SCRIPT}
        sh ${ACTION_SCRIPT} ${ORACLE_SID}
        ACTION_RC=$?
        # 2 = sauvegarde déjà en cours ou base standby ; le script notifie lui-même ses autres erreurs
        if [ ${ACTION_RC} -ne 0 ] && [ ${ACTION_RC} -ne 2 ]; then
            echo "Échec de ${ACTION_SCRIPT} pour ${ORACLE_SID} (code retour ${ACTION_RC})" >&2
            EXIT_RC=1
        fi
    else
        echo ${pct_fra_used} : backup des archivelog non necessaire
    fi
done

exit ${EXIT_RC}
