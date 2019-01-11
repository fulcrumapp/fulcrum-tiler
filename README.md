## Fulcrum Tiler

Create styled MBTiles from vector data using the command line.

## Requirements

* Python
* Docker

## Usage

Simple:

```sh
python mbtiles.py --input ~/Downloads/polygons.geojson --max-zoom 14 --text-name title
```

Complete:

```sh
python mbtiles.py \
  --input ~/Downloads/polygons.geojson \
  --min-zoom 4 \
  --max-zoom 13 \
  --text-name title \
  --polygon-fill "#0f0" \
  --polygon-opacity 0.3 \
  --line-width 2 \
  --line-color "#0f0" \
  --template-teaser "<strong>{{{title}}}</strong>" \
  --template-full "<strong>{{{title}}}</strong><br />{{{address}}}"
```
