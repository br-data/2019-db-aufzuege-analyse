# DB Aufzüge
Analyse zum Betriebsstatus der Aufzüge der DB

Die Deutsche Bahn geht mit den Statusinformationen der von ihr betriebenen Aufzüge transparent um und stellt sie über eine [Datenschnittstelle (API)](https://data.deutschebahn.com/dataset/fasta-station-facilities-status) in Echtzeit zur Verfügung.

BR Data hat zwischen August 2018 und November 2019 den Betriebszustand aller kundenrelevanten Aufzüge abgefragt. Die verwendeten Skripte und Daten befinden sich hier.

Link zum Projekt: [Bedingt barrierefrei](https://web.br.de/interaktiv/defekte-aufzuege/)

## Verwendung

1. Repository klonen `git clone https://...`
2. R-Skripte in `./scripts` der Reihe nach durchlaufen lassen:
	* `1-prepare.R`: gleicht Sekunden-Schwankungen der Messzeitpunkte aus.
	* `2-clean.R`: filtert größere Datenlücken und legt den Messzeitraum fest (Tage , Uhrzeiten)
	* `3-get-metadata.R`: erweitert die Metadaten, die von der API kamen um zusätzliche Aufzugs- und Stationsdaten der DB
	* (`4-export-json`): ist die Grundlage für die Animation und die Kalender-Grafik unserer [Webseite](https://web.br.de/interaktiv/defekte-aufzuege/). Für die weitere Analyse nicht notwendig

3. `analyse-aussagen.Rmd` in RStudio öffnen und laufen lassen.

4. Alternativ bietet `analyse-aussagen.html` die bereits fertige HTML-Version der Analyse an

## Daten

Input-Datein sind im Ordner `./input`:

- `raster-0-orig.csv.gz`: Rohdaten der DB in Form einer komprimierten csv-Datei. Ursprünglich flossen die Daten über die API der DB in eine Datenbank, die wir für die weitere Analyse exportiert haben
- `facilities-0-orig.csv`: Aufzüge-Metadaten, die wir auch über die API erhalten haben
- `./Open Data`: Der Ordner entählt weitere Metadaten zu [Aufzügen](https://data.deutschebahn.com/dataset/data-aufzug) und [Bahnhöfen](https://data.deutschebahn.com/dataset/data-stationsdaten) aus dem Open-Data-Portal der DB
- `elevator_duplicates_manual_match.csv`: Von uns angefertige Zuordnung von Equipentnummern, die sich während des Betrachtungszeitraums geändert haben
- `s-bahn-stations.csv`: Von uns angefertigte Zuordnung von Bahnhöfen zu den S-Bahnnetzen, in denen sie sich befinden

Die Daten zu den Betriebszuständen der Aufzüge kommen per API vom Open-Data-Portal der Deutschen Bahn:  
- [Station Facilities Status API](https://data.deutschebahn.com/dataset/fasta-station-facilities-status)    
Zusätzliche Informationen von der Deutschen Bahn:  
- [Aufzugsdaten](https://data.deutschebahn.com/dataset/data-aufzug)  
- [Stationsdaten](https://data.deutschebahn.com/dataset/data-stationsdaten)  
Die Daten zu den Betriebszuständen haben wir alle fünf Minuten mit einem Node.js-Skript via Jenkins abgefragt und in einer (PostgreSQL) abgelegt