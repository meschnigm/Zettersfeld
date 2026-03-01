# Optimierte Bilder

Dieses Verzeichnis enthält automatisch erzeugte WebP-Bilder für die Website.

## Erzeugung

Im Projektverzeichnis ausführen:

```bash
./scripts/optimize_images.sh
```

Das Skript erstellt je Eingabebild zwei Größen:

- `-800.webp` für Standarddarstellung
- `-1600.webp` für hochauflösende Displays (Retina)

## HTML-Einbindung (Beispiel)

```html
<img
  class="step-image"
  src="bilder/optimized/beispiel-800.webp"
  srcset="bilder/optimized/beispiel-800.webp 800w, bilder/optimized/beispiel-1600.webp 1600w"
  sizes="(max-width: 768px) 100vw, 820px"
  loading="lazy"
  decoding="async"
  alt="Beschreibung"
>
```
