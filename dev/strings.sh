#!/bin/bash

cities=' Paris,    London, Barcelona, Vilanova '
cities_no_blanks="$(echo -e "${cities}" | tr -d '[:space:]')"
IFS=', ' read -r -a array <<< "$cities_no_blanks"

for element in "${array[@]}"
do
	echo "$element"
done

echo "------------------------------------------------------------"
cities=' Paris,    London, Barcelona, Vilanova '
echo -e "cities: '$cities'"
cities_no_blanks="$(echo -e "${cities}" | tr -d '[:space:]')"
echo -e "cities_no_blanks: '$cities_no_blanks'"
set -f                      # avoid globbing (expansion of *).
cities=(${cities_no_blanks//,/ })
for city in "${!cities[@]}"
do
    echo "$city=>${cities[city]}"
done