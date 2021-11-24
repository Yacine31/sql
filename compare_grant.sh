# genérer 2 fichiers avec les ordres grant
# ensuite comparer les deux pour garder uniquement les ordres présents dans la source et pas dans la destination

# dans cet exemple :
# La commande pour extraire les GRANT qui sont dans la version 12 mais pas dans la 19 :
diff -w  <(cat /tmp/grant_12 | grep -v '^$' | sort -u) <(cat /tmp/grant_19 | grep -v '^$' | sort -u)  | grep '^<' | sed 's/< //g' | sort

