# DB Aufzüge und Rolltreppen
Analyse zum Betriebsstatus der Aufzüge und Rolltreppen der DB

## Verwendung

1. Repository klonen `git clone https://...`
2. Daten entpacken
2. analyse-aussagen.Rmd in RStudio öffnen
3. analyse-aussagen.html enthält eine HTML-Version des R-Notebooks

## Daten
Die Daten zu den Betriebszuständen der Aufzüge kommen per API vom Open-Data-Portal der Deutschen Bahn:  
- [Station Facilities Status API](https://data.deutschebahn.com/dataset/fasta-station-facilities-status)    
Zusätzliche Informationen von der Deutschen Bahn:  
- [Aufzugsdaten](https://data.deutschebahn.com/dataset/data-aufzug)  
- [Stationsdaten](https://data.deutschebahn.com/dataset/data-stationsdaten)  
Die Daten zu den Betriebszuständen haben wir alle fünf Minuten mit einem Node.js-Skript via Jenkins abgefragt und in einer (PostgreSQL) abgelegt