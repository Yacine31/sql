DATETIME=`date +%Y%m%d%H%M`
HNAME=$(hostname)

for r in $(ps -eaf | grep pmon | egrep -v 'grep|ASM1|APX1' | cut -d '_' -f3)
do
        export ORAENV_ASK=NO
        export ORACLE_SID=$r
        export HTML_FILE=Rapport_$HNAME_${ORACLE_SID}_${DATETIME}.html
        . oraenv -s > /dev/null
        echo "
        <!doctype html>
                <html lang=en>
                  <head>
                    <meta charset=utf-8>
                    <meta name=viewport content=width=device-width, initial-scale=1>
                    <title>Rapport</title>
                    <link href=https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/css/bootstrap.min.css rel=stylesheet integrity=sha384-GLhlTQ8iRABdZLl6O3oVMWSktQOp6b7In1Zl3/Jr59b6EGGoI1aFkw7cmDA6j6gD crossorigin=anonymous>
                  </head>
                  <body>
                   <div class=container>

        " > ${HTML_FILE}

        sqlplus -s "/ as sysdba" @rapport_html.sql >> ${HTML_FILE}
        sed -i 's/<table.*>$/<table class="table table-striped">/g' ${HTML_FILE}


        echo Rapport dans le fichier html : ${HTML_FILE}
done
