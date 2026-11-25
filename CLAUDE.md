# Spielwiese `ki-kurs-in-a-box`

Dieser Bereich ist **Spielwiese** (Ausprobieren, lokale Box, Prototypen ohne Auftrag). Nicht
zuständig für Schule, Selbstständigkeit, Kund:innen, Infrastruktur, Privates: das per Taskboard mit
Tag `bereich:<ziel>` übergeben, nur den Auftrag, keinen Kontext. Zugehörigkeit von Projekten im
docker-Repo steht in `C:\Users\mail\entwicklung\docker\docs\LANDKARTE.md`, Spalte Bereich, nie aus
Stichworten ableiten. Andere Bereiche nur über deren `SCHAUFENSTER.md` lesen. Aufgaben dieses
Bereichs tragen `bereich:spielwiese`. Hier ist nur `moodle-box` (lokale Box) angebunden, nie das
Produktions-Moodle; wird aus einem Versuch ein Auftrag, wandert er in dessen Bereich.

<!-- Am 18.10.2026 aus ~/.claude/CLAUDE.md hierher verschoben (Bereichstrennung, Task 3), Text 1:1. -->

Zwei fertige Container, die Dirk in beliebigen Ordnern benutzt — auch in leeren, in denen
sonst kein Projektkontext liegt. Wenn er sinngemäß danach fragt, ist das der gemeinte Weg.
Keine Installation auf dem Host vorschlagen; genau die will er vermeiden.

Der andere Container (Lernmodul-Werkbank) steht seit 18.10.2026 in `entwicklung\test\CLAUDE.md`.

### Kurs-in-a-Box — lokales Moodle

Vollständiges Moodle 5.0 mit Kurs, MariaDB, MCP-Server, n8n und Mailserver. Für „stell mir ein
Moodle hin", „ich brauche ein LMS zum Ausprobieren", „ein System, auf dem ich alles darf".

```powershell
docker compose -f ~/entwicklung/docker/ki-kurs-box/docker-compose.yml -f ~/entwicklung/docker/ki-kurs-box/docker-compose.code-welt.yml -f ~/entwicklung/docker/ki-kurs-box/docker-compose.tiles.yml up -d
```

**Immer alle drei Compose-Dateien.** Seit dem 03.09.2026 hängt das Overlay `docker-compose.code-welt.yml` zwei
Zusatz-Plugins (`filter_multilang2`, `mod_customcert`) als Bind-Mounts ein; ein `up -d` nur mit der
ersten Datei erzeugt den Moodle-Container ohne diese Mounts, dann zeigt der Kurs „Code-Welt" rohes
`{mlang}` und customcert fehlt. Vorbereitung einmalig: `bash ki-kurs-box/prepare-code-welt.sh`. Seit dem
15.09.2026 kommt `docker-compose.tiles.yml` dazu: Bind-Mount für `format_tiles` (Kursformat für „KI im
Handel v2"), Version 2025070364 aus Produktion. Fehlt diese dritte Datei, bleibt das Kursformat „Kacheln"
unverfügbar. Vorbereitung einmalig: `bash ki-kurs-box/prepare-ki-handel.sh`.

Moodle <http://localhost:8080>, Login `admin` / `KiKurs-Demo-2026`. Die Volumes sind
vorgewärmt: Der Start dauert dann rund zwanzig Sekunden statt zwei Minuten. Die Zugangsdaten
sind absichtlich öffentlich, es ist eine lokale Lernbox und gehört nicht ins offene Netz.

**In diese Box schreibt der MCP-Server `moodle-box`** (`http://localhost:8000/mcp`). Er ist
nutzerweit registriert und antwortet nur, solange die Box läuft.

> **Stand 18.10.2026:** `moodle-box` ist nicht mehr nutzerweit registriert, sondern nur noch
> in `.mcp.json` dieses Ordners und in `entwicklung\test\.mcp.json`. Das Produktions-Moodle
> (`moodle`) ist hier **nicht** erreichbar; Box und Produktion sind nie in derselben Sitzung.
