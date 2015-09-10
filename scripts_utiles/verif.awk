BEGIN {
        IFS=" "
}
/^[(]/{
	print "*****Résultats pour la fusion manuelle*****"
}
/^[A-Z]/{
        if ($2 + $3 == $4) {
                print $1," OK"
        } else {
                print $1," ERREUR "($4-$3-$2)
        }
}