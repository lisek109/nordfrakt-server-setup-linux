#!/bin/bash
# Sjekker om brukere fra CSV-filen eksisterer i systemet.

getent passwd | awk -F: '$3 >= 1000 && $1 != "nobody" && $1 != "nogroup" {print "Bruker: "$1", UID: "$3", GECOS (Dane): "$5}'