#!/bin/sh
# Prueft, ob der Webservice der Box wirklich traegt.
#
# Kein Klick, kein Login: nur der eingebackene Token gegen die REST-Schnittstelle.
# Genau das macht der Moodle-MCP auch. Wenn das hier durchlaeuft, laeuft die
# Vorfuehrung.
#
#   ./pruefe-webservice.sh [http://localhost:8080]
set -e

URL="${1:-http://localhost:8080}"
TOKEN="${MOODLE_MCP_TOKEN:-0ercamp2026werkbankdemotoken1234}"
REST="$URL/webservice/rest/server.php"

ruf() {
  # $1 = Funktionsname, $2.. = zusaetzliche Formfelder
  fn="$1"; shift
  set -- --data-urlencode "wstoken=$TOKEN" \
         --data-urlencode "wsfunction=$fn" \
         --data-urlencode "moodlewsrestformat=json" "$@"
  curl -s -G "$REST" "$@"
}

echo "== 1. Traegt der Token? (core_webservice_get_site_info)"
antwort=$(ruf core_webservice_get_site_info)
case "$antwort" in
  *exception*) echo "   FEHLGESCHLAGEN: $antwort"; exit 1 ;;
esac
echo "   ok: $(echo "$antwort" | tr ',' '\n' | grep -E '"(sitename|username|functions")' | head -2 | tr '\n' ' ')"

echo "== 2. Ist der Kurs da? (core_course_get_courses)"
kurse=$(ruf core_course_get_courses)
case "$kurse" in
  *exception*) echo "   FEHLGESCHLAGEN: $kurse"; exit 1 ;;
esac
kursid=$(echo "$kurse" | tr '{' '\n' | grep -v '"id":1,' | grep -oE '"id":[0-9]+' | head -1 | cut -d: -f2)
echo "   ok: Kurs-ID $kursid"

echo "== 3. Kann die KI einen Abschnitt anlegen? (local_wsmanagesections_create_sections)"
echo "   Das ist der eigentliche Beweis: eine Funktion aus einem eigenen Plugin,"
echo "   schreibend, ohne einen einzigen Klick in der Moodle-Oberflaeche."
neu=$(ruf local_wsmanagesections_create_sections \
      --data-urlencode "courseid=$kursid" \
      --data-urlencode "position=0" \
      --data-urlencode "number=1")
case "$neu" in
  *exception*) echo "   FEHLGESCHLAGEN: $neu"; exit 1 ;;
esac
echo "   ok: $neu"

echo
echo "Alle drei Proben bestanden. Endpunkt: $REST"
echo "Token: $TOKEN"
