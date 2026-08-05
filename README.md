# KI-Kurs in a Box

Ein kompletter Moodle-Kurs samt Automatisierungs-Werkstatt, auf dem eigenen
Rechner, in einem Befehl. Kein Server, keine Domain, keine Anmeldung irgendwo.
Zum Ausprobieren, zum Umbauen und ausdrücklich zum Kaputtmachen.

Der Kurs heißt **„KI & Automatisierung im Handel"** und stammt aus dem
Berufsschulunterricht. Er ist hier von der Original-Instanz gelöst und enthält
keine Nutzerdaten.

```bash
docker compose up -d
```

Der **Erststart dauert zwei bis drei Minuten**: Moodle installiert sich, spielt
den Kurs ein und richtet seine Schnittstelle ein. Danach:

| | |
|---|---|
| **Moodle** | <http://localhost:8080> · `admin` / `KiKurs-Demo-2026` |
| **n8n** | <http://localhost:5678> · Workflow „Postfach-Triage" liegt bereit |
| **Moodle-MCP** | <http://localhost:8000/mcp> · Schlüssel `ki-kurs-lokal` |

## Voraussetzung

**Docker Desktop** (Windows/macOS) oder Docker Engine (Linux), rund 3 GB
freier Arbeitsspeicher. Sonst nichts. Kein PHP, kein Node, keine Datenbank.

Die Images sind für **linux/amd64** gebaut. Auf Apple Silicon laufen sie über
Emulation, dann dauert der Erststart eher zehn bis fünfzehn Minuten.

## Was drin ist

| Container | Rolle | Zugang |
|-----------|-------|--------|
| `ki-kurs-moodle` + `ki-kurs-db` | der Kurs, installiert sich beim Erststart selbst | **admin / KiKurs-Demo-2026** |
| `ki-kurs-mcp` | Schnittstelle, über die eine KI im Kurs arbeiten kann | `x-api-key: ki-kurs-lokal` |
| `ki-kurs-n8n` | Automatisierungs-Sandbox mit fertigem Workflow | beim ersten Aufruf eigenes Konto anlegen |
| `ki-kurs-mail` | Demo-Postfach mit sechs Beispielmails (GreenMail) | **demo / demo123** |
| `ki-kurs-mailseed` | Einmal-Init, befüllt das Postfach und beendet sich | — |

## Die KI im Kurs arbeiten lassen

Die Box bringt eine **fertig eingerichtete Schnittstelle** mit: Webservices
sind aktiviert, ein Service mit 83 Funktionen ist angelegt, ein Token liegt
bereit. Es muss niemand vorher durch die Moodle-Administration klicken.

In **Claude Code** eintragen (`.mcp.json` im Projektordner):

```json
{
  "mcpServers": {
    "moodle-box": {
      "type": "http",
      "url": "http://localhost:8000/mcp",
      "headers": { "x-api-key": "ki-kurs-lokal" }
    }
  }
}
```

Danach genügt ein Satz: *„Leg im Kurs einen Abschnitt ‚Woche 5' an und häng
eine Seite mit diesem Text hinein."* Die KI erledigt es über die
Schnittstelle, ohne dass jemand klickt.

Selbst nachprüfen, ob die Schnittstelle trägt:

```bash
./pruefe-webservice.sh
```

Das Skript stellt drei Fragen an die laufende Box: Trägt der Token? Ist der
Kurs da? Und lässt sich ein Kursabschnitt anlegen, ohne die Oberfläche
anzufassen? Läuft es durch, funktioniert auch der MCP.

### Warum das ohne Zusatzarbeit geht

Ein Moodle von der Stange kann per Schnittstelle **keine** Kursabschnitte und
keine Aktivitäten anlegen, nur lesen. Deshalb stecken in diesem Image drei
zusätzliche Plugins: `sync_service` (Aktivitäten anlegen),
`wsmanagesections` (Abschnitte verwalten) und `h5p_api` (H5P-Inhalte). Ohne
sie wäre der interessante Teil nicht möglich.

## Sicherheit

> **Diese Box gehört nicht ins offene Netz.**
>
> Admin-Passwort und Schnittstellen-Token stehen hier im Klartext, weil es eine
> Lern- und Vorführbox ist, die weitergegeben wird. Auf `localhost` ist das
> genau richtig. Auf einem Server, den andere erreichen können, wäre es
> fahrlässig.

Wer sie doch irgendwo hinstellen will: mindestens `MOODLE_ADMIN_PASS`,
`MOODLE_MCP_TOKEN`, `MCP_API_KEY` und die Datenbank-Passwörter über eine
`.env` überschreiben (siehe `.env.example`) und die Ports nicht nach außen
geben.

## Eigenen KI-Schlüssel eintragen

Der n8n-Workflow kommt **ohne** KI-Zugang. Die Verbindung zum lokalen
Demo-Postfach ist vorkonfiguriert, deinen eigenen Schlüssel legst du einmalig
in n8n an (*Credentials → Header Auth*). Der Kurs führt dich hindurch.

## Wenn es klemmt

| Problem | Lösung |
|---|---|
| `localhost:8080` antwortet nicht | Erststart läuft noch. `docker compose logs -f moodle` zeigt den Fortschritt, fertig ist es bei `[ki-kurs-ws] Fertig.` |
| `port is already allocated` | Ein Port ist belegt. In der `docker-compose.yml` vorne eine andere Zahl eintragen, z. B. `8081:80`. |
| MCP findet keine Kurse | Moodle ist noch beim Erststart. Warten, dann erneut. |
| Claude Code sieht die Werkzeuge nicht | Schlüssel prüfen (`x-api-key: ki-kurs-lokal`) und ob die URL auf `/mcp` endet. |
| Es hakt irgendwo anders | Kompletter Neustart bei null: `docker compose down -v && docker compose up -d`. |

## Stoppen und zurücksetzen

```bash
docker compose down        # stoppen, Daten bleiben erhalten
docker compose down -v     # alles zurück auf Anfang, Kurs wird neu eingespielt
```

Willst du die Box ganz loswerden, danach noch die Images entfernen:

```bash
docker rmi dadalama/ki-kurs-moodle:1.1 dadalama/ki-kurs-moodle-mcp:1.0 \
           dadalama/ki-kurs-n8n:1.0 dadalama/ki-kurs-mailseed:1.0
```

## Herkunft und Lizenz

Entstanden für den Workshop **„KI als »echter« Mitarbeiter"** auf dem
[OERcamp Berlin 2026](https://dirk-schulenburg.net). Dort ist die Box das
schwere Gegenstück zur *Werkbank*, einer schlanken Entwicklungsumgebung für
interaktive Lernmodule:

- **Werkbank:** [`dadalama/oercamp-werkbank`](https://hub.docker.com/r/dadalama/oercamp-werkbank) · [Starter-Repo](https://github.com/dSchulenburg/oercamp-lernmodul-starter)

Die Idee dahinter: Ein Arbeitsblatt teilt ein Ergebnis. Ein Container teilt
eine ganze Arbeitsumgebung. OER hört bis heute beim Ergebnis auf.

| | |
|---|---|
| **Diese Dateien** (Compose, Skripte, README) | MIT |
| **Kursinhalte** im Moodle-Image | CC BY 4.0, Dirk Schulenburg |
| **Moodle** und die enthaltenen Plugins | GPL v3, jeweilige Urheber |

Dirk Schulenburg · [dirk-schulenburg.net](https://dirk-schulenburg.net)
