# DB Aufzüge und Rolltreppen
Analyse zum Betriebsstatus der Aufzüge und Rolltreppen der DB

Die Deutsche Bahn geht mit den Statusinformationen der von ihr betriebenen Aufzüge transparent um und stellt sie über eine Datenschnittstelle in Echtzeit zur Verfügung.

BR Data hat zwischen August 2018 und November 2019 den Betriebszustand aller kundenrelevanten Aufzüge abgefragt. Die verwendeten Skripte und Daten befinden sich hier.

## Verwendung

1. Repository klonen `git clone https://...`
2. Datei `data/raster-0-orig.csv.gz` entpacken → `data/raster-0-orig.csv`
3. R-Skripte in `./src` der Reihe nach durchlaufen lassen:
	* (`0-import.R`): funktioniert nur mit Zugang zur Datenbank und dient an dieser Stelle nur der Nachvollziebarkeit. Die importierten Daten liegen im Ordner `./data`
	* `1-prepare.R`: gleicht Sekunden-Schwankungen der Messzeitpunkte aus.
	* `2-clean.R`: filtert größere Datenlücken und legt den Messzeitraum fest (Tage , Uhrzeiten)
	* `3-get-metadata.R`: erweitert die Metadaten, die von der API kamen um zusätzliche Aufzugs- und Stationsdaten der DB
	* (`4-export-json`): ist für die weitere Analyse nicht notwendig

4. `analyse-aussagen.Rmd` in RStudio öffnen und laufen lassen.

5. Alternativ bietet `analyse-aussagen.html` die bereits fertige HTML-Version der Analyse an

## Daten
Die Daten zu den Betriebszuständen der Aufzüge kommen per API vom Open-Data-Portal der Deutschen Bahn:  
- [Station Facilities Status API](https://data.deutschebahn.com/dataset/fasta-station-facilities-status)    
Zusätzliche Informationen von der Deutschen Bahn:  
- [Aufzugsdaten](https://data.deutschebahn.com/dataset/data-aufzug)  
- [Stationsdaten](https://data.deutschebahn.com/dataset/data-stationsdaten)  
Die Daten zu den Betriebszuständen haben wir alle fünf Minuten mit einem Node.js-Skript via Jenkins abgefragt und in einer (PostgreSQL) abgelegt