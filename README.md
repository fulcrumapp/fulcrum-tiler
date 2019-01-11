## Fulcrum Tiler

Create styled MBTiles from vector data using the command line.

## Features

* Simple rendering of GIS data to styled .mbtiles
* Supports GeoJSON, Shapefile, and KML
* Automatic projection conversion so most input files should "just work"
* Automatic detection of the bounds of the data
* Polygon labeling using a custom attribute
* Interactivity using custom data attributes

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
