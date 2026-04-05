# Supabase Free-Tier Setup fuer die Huetten-Diashow

Dieses Setup ist auf die bestehende Huettenseite in `index.html` zugeschnitten.
Ziel:

- gemeinsame Diashow fuer alle Nutzer
- Upload neuer Bilder ueber die Website
- neue Bilder erst nach Freigabe sichtbar
- alles zunaechst im kostenlosen Supabase-Tarif

## Zielarchitektur

Die Loesung besteht aus 3 Bausteinen:

1. Storage-Bucket fuer die eigentlichen Bilddateien
2. Datenbanktabelle fuer Metadaten und Freigabestatus
3. statische Website, die freigegebene Bilder anzeigt und neue Bilder hochlaedt

Empfohlener Ablauf:

1. Gast waehlt Bild auf der Website aus
2. Website verkleinert das Bild im Browser
3. Bild wird in Supabase Storage hochgeladen
4. in der Tabelle wird ein Datensatz mit `approved = false` angelegt
5. du pruefst das Bild im Supabase-Dashboard
6. nach Freigabe erscheint das Bild fuer alle in der Diashow

## Supabase-Projekt anlegen

1. Neues Projekt in Supabase erstellen
2. Region moeglichst EU waehlen
3. Projektname z. B. `zettersfeld-huette`
4. Datenbank-Passwort sicher speichern

Danach benoetigst du spaeter:

- `Project URL`
- `anon public key`

Diese beiden Werte werden spaeter in die Website eingetragen.

## Storage-Bucket anlegen

Bucket-Name:

`slideshow`

Empfehlung:

- Bucket zunaechst nicht komplett oeffentlich fuer Uploads oeffnen
- Anzeigen der Bilder nur ueber freigegebene Eintraege steuern

Ordnerstruktur im Bucket:

- `pending/` fuer neu hochgeladene Bilder
- `approved/` fuer freigegebene Bilder

Einfacher Start:

- neue Uploads gehen nach `pending/`
- nach Freigabe verschiebst du sie manuell oder per spaeterer Admin-Hilfe nach `approved/`

Wenn du anfangs moeglichst wenig Aufwand willst, kannst du auch alles in einem Bucket lassen und nur ueber die Tabelle mit `approved` steuern.

## Datenbanktabelle anlegen

Im SQL Editor von Supabase ausfuehren:

```sql
create table if not exists public.slideshow_images (
    id uuid primary key default gen_random_uuid(),
    file_path text not null,
    public_url text,
    title text not null,
    uploaded_by text,
    created_at timestamptz not null default now(),
    approved boolean not null default false,
    source text not null default 'supabase',
    notes text
);

create index if not exists slideshow_images_created_at_idx
    on public.slideshow_images (created_at desc);

create index if not exists slideshow_images_approved_idx
    on public.slideshow_images (approved);
```

## Row Level Security aktivieren

```sql
alter table public.slideshow_images enable row level security;
```

## Policies fuer den Start

Diese Policies sind fuer eine einfache Free-Tier-Startloesung gedacht.

### Freigegebene Bilder fuer alle lesbar

```sql
create policy "read approved slideshow images"
on public.slideshow_images
for select
using (approved = true);
```

### Neue Upload-Metadaten anonym anlegen

Das ist bequem, aber bewusst offen. Wenn du spaeter haerter absichern willst, sollte das ueber Login oder Edge Function laufen.

```sql
create policy "insert slideshow image metadata"
on public.slideshow_images
for insert
with check (approved = false);
```

### Keine oeffentlichen Updates oder Deletes

Hier bewusst keine Policy anlegen. Dadurch kann nur ueber Service Role oder Dashboard freigegeben/geaendert werden.

## Storage Policies fuer den Start

Im SQL Editor fuer Storage ausfuehren:

```sql
create policy "public read slideshow files"
on storage.objects
for select
using (bucket_id = 'slideshow');

create policy "public upload slideshow files"
on storage.objects
for insert
with check (bucket_id = 'slideshow');
```

Wichtig:

- Das ist die einfache Startvariante.
- Sie erlaubt Uploads in den Bucket ohne Login.
- Deshalb sollten Dateigroesse und Dateitypen in der Website begrenzt werden.
- Fuer die erste Version ist das ok, spaeter sollte man das haerter absichern.

## Empfehlungen fuer die Website

Fuer den kostenlosen Tarif sollte die Website Bilder vor dem Upload verkleinern:

- maximale Kantenlaenge: `1600 px`
- Format: `jpeg` oder `webp`
- Qualitaet: ca. `0.8`
- Zielgroesse: meist `200 KB` bis `700 KB`

Damit reichen kostenloser Speicher und Traffic deutlich laenger.

## Empfohlene Eingabefelder pro Bild

Beim Upload auf der Website:

- Bilddatei
- Titel
- Name oder Vorname des Uploaders
- optional kurze Notiz

Minimal reicht aber auch:

- Bilddatei
- Titel

## Freigabe im Alltag

Startvariante ohne eigene Admin-Seite:

1. Im Supabase-Dashboard Tabelle `slideshow_images` oeffnen
2. Neue Eintraege mit `approved = false` pruefen
3. Gute Bilder auf `approved = true` setzen
4. Falls gewuenscht `file_path` auf einen freigegebenen Zielordner anpassen

Das reicht fuer den Anfang voellig aus.

## Was im kostenlosen Tarif realistisch ist

Bei vernuenftig verkleinerten Bildern ist das fuer eine Huettenseite gut nutzbar:

- einige hundert Bilder sind realistisch
- gelegentliche Uploads durch Gaeste sind unkritisch
- die Diashow kann fuer alle Nutzer zentral funktionieren

Problematisch wird es erst, wenn:

- Originalfotos in voller Handy-Aufloesung hochgeladen werden
- sehr viele Videos oder riesige Bilder dazukommen
- sehr viele automatische Aufrufe stattfinden

## Minimalintegration in die bestehende Seite

Wenn du die aktuelle Diashow in `index.html` auf Supabase umstellen willst, sind spaeter diese Schritte noetig:

1. Supabase JS Client einbinden
2. `Project URL` und `anon key` hinterlegen
3. freigegebene Bilder aus `slideshow_images` laden
4. Upload-Funktion statt lokalem `localStorage` auf Supabase umstellen
5. neue Uploads automatisch mit `approved = false` anlegen

## Werte, die du mir spaeter geben musst

Sobald du das Projekt angelegt hast, brauche ich nur noch:

1. `Project URL`
2. `anon public key`
3. Bucket-Name, falls du nicht `slideshow` nimmst
4. Entscheidung:
   - Bilder sofort sichtbar
   - oder erst nach Freigabe sichtbar

## Empfehlung fuer euren Start

Fuer Zettersfeld wuerde ich im Free-Tier genau so starten:

1. Bucket `slideshow`
2. Tabelle `slideshow_images`
3. Uploads offen, aber Bilder vor dem Upload verkleinern
4. Anzeige nur fuer `approved = true`
5. Freigabe zunaechst manuell im Dashboard

Das ist die kleinste sinnvolle, gemeinsam nutzbare Loesung ohne zusaetzlichen Server.