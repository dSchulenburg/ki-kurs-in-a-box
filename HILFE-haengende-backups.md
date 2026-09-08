# Wenn ein Backup in der Kurs-in-a-Box nicht fertig wird

**Symptom:** Du startest in Moodle eine Sicherung, und sie bleibt stehen. Kein Fehler,
kein Fortschritt — der Vorgang steht einfach da, auch nach Stunden. Manchmal trifft es
auch das Wiederherstellen.

**Kurzfassung:** Die Box hat keinen Hintergrunddienst, der Aufgaben abarbeitet. Solange
Moodle Sicherungen "asynchron" anlegt, landen sie in einer Warteschlange, die niemand
leert. Ab Image-Version `2` ist das ab Werk erledigt. Wer eine ältere Box laufen hat,
findet unten den Sofort-Weg.

---

## Der schnelle Weg (läuft sofort, ohne neues Image)

Zwei Befehle im Terminal, während die Box läuft:

```bash
docker exec ki-kurs-moodle php /var/www/html/admin/cli/upgrade.php --non-interactive
docker exec ki-kurs-moodle php /var/www/html/admin/cli/cron.php --keep-alive=0
```

Der erste bringt die Datenbank auf den Stand des Moodle-Codes, der zweite arbeitet die
liegengebliebenen Aufgaben ab — **auch deine hängenden Sicherungen**. Danach stehen sie
in Moodle als fertig da und sind herunterladbar.

Damit es nicht wieder passiert, zusätzlich einmal:

```bash
docker exec ki-kurs-moodle php /var/www/html/admin/cli/cfg.php --name=enableasyncbackup --set=0
```

Ab dann laufen Sicherungen direkt im Browser durch, statt in einer Warteschlange zu warten.

## Der saubere Weg (neues Image)

In deiner `docker-compose.yml` beim Moodle-Dienst den Bildnamen auf Version `2` setzen:

```yaml
image: dadalama/ki-kurs-moodle:2
```

Dann im Ordner mit der `docker-compose.yml`:

```bash
docker compose pull moodle
docker compose up -d moodle
```

Beim Start erledigt die Box jetzt alles von selbst. Im Protokoll (`docker logs ki-kurs-moodle`)
siehst du dann diese Zeilen:

```
[ki-kurs] Datenbank ist aelter als der Code - fuehre Upgrade aus...
[ki-kurs] Upgrade fertig.
[ki-kurs] Arbeite liegengebliebene Aufgaben ab...
```

**Deine Kurse und Daten bleiben erhalten.** Das Volume wird nicht angefasst, nur die
Datenbank auf den passenden Stand gebracht — genau das, was Moodle bei einem Update
ohnehin verlangt.

---

## Warum das passiert ist

Drei Dinge greifen unglücklich ineinander:

1. Das Box-Image lädt beim Bauen **immer das neueste Moodle 5.0**. Ziehst du später ein
   neueres Image, ist der Programmcode neuer als die Datenbank in deinem Volume.
2. In dieser Lage **stellt Moodle den Hintergrunddienst (Cron) komplett ein**. Im
   Protokoll steht dann: `Moodle upgrade pending, cron execution suspended`.
3. Moodle legt Sicherungen ab Werk **asynchron** an — sie werden also nicht sofort
   ausgeführt, sondern als Aufgabe eingereiht. Die Warteschlange bearbeitet aber genau
   der Dienst, der unter Punkt 2 stillsteht.

Ergebnis: Die Sicherung hängt nicht, sie wartet. Nur sieht das von außen gleich aus.

Ab Image `2` prüft die Box das bei jedem Start selbst, führt ein fälliges Upgrade aus,
leert die Warteschlange und schaltet die asynchrone Verarbeitung ab.

## Nachsehen, ob es an dir liegt

```bash
docker exec ki-kurs-moodle php /var/www/html/admin/cli/cron.php --keep-alive=0
```

Kommt `Moodle upgrade pending, cron execution suspended`, ist es genau dieser Fall.
Kommt `Cron run completed correctly`, liegt es an etwas anderem — dann melde dich mit
dem, was in Moodle unter *Website-Administration → Berichte → Protokolle* steht.
