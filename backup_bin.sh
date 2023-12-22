#!/bin/sh
#------------------------------------------------------------------------------
# Historique :
#       25/09/2023 : YOU - premiere version pour sauvegarder les binaires
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
# fonction init : c'est ici qu'il faut modifier toutes les variables liées
# à l'environnement
#------------------------------------------------------------------------------

f_init() {

        # positionner les variables d'environnement
        export SCRIPTS_DIR=/home/oracle/scripts

        # répertoire source a sauvegarder
        export ORAAPP_LOCATION=/u01/app

        # répertoire destination de l'export
        export BKP_LOCATION=/u04/
} #f_init


#----------------------------------------
#------------ MAIN ----------------------
#----------------------------------------



#------------------------------------------------------------------------------
# inititalisation des variables d'environnement
#------------------------------------------------------------------------------
f_init

# creation du repertoire de sauvegarde. S'il existe la commande install ne fait rien
install -d ${BKP_LOCATION}

#------------------------------------------------------------------------------
# sauvegarde
#------------------------------------------------------------------------------

# compression du repertoire oracle app
cd ${BKP_LOCATION}
rm -fv backup_bin_oraapp_$(date +%Y%m%d).tgz
sudo tar cfz backup_bin_oraapp_$(date +%Y%m%d).tgz ${ORAAPP_LOCATION}

