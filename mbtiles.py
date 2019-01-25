from argparse import ArgumentParser
from shutil import copyfile
import os
import sys
import platform

parser = ArgumentParser()
parser.add_argument("--input", dest="input", required=True,
                    help="input file")
parser.add_argument("--layer-name", dest="layer_name",
                    help="input layer name (default: the first layer)")
parser.add_argument("--geometry-type", dest="geometry_type",
                    help="input geometry type (default: autodetect) one of: polygon, linestring, point")
parser.add_argument("--min-zoom", dest="min_zoom", default=2,
                    help="min zoom")
parser.add_argument("--max-zoom", dest="max_zoom", default=12,
                    help="max zoom")
parser.add_argument("--marker-fill", dest="marker_fill", default="#c10505",
                    help="marker fill color")
parser.add_argument("--marker-width", dest="marker_width", default=8,
                    help="marker width")
parser.add_argument("--line-width", dest="line_width", default=0.5,
                    help="line width")
parser.add_argument("--line-color", dest="line_color", default="#594",
                    help="line color")
parser.add_argument("--polygon-fill", dest="polygon_fill", default="#ae8",
                    help="polygon fill")
parser.add_argument("--polygon-opacity", dest="polygon_opacity", default=0.8,
                    help="polygon opacity")
parser.add_argument("--text-name", dest="text_name",
                    help="label attribute")
parser.add_argument("--template-teaser", dest="template_teaser",
                    help="template for the interactivity teaser (defaults to the text name)")
parser.add_argument("--template-full", dest="template_full",
                    help="template for the full interactivity text (defaults to the teaser)")
parser.add_argument("--output", dest="output", default="output",
                    help="output filename")

args = parser.parse_args()

app_path = os.path.join(os.getcwd(), "app")
input_path = os.path.join(os.getcwd(), "input")
output_path = os.path.join(os.getcwd(), "output")

try:
    os.makedirs(app_path)
except:
    pass

try:
    os.makedirs(input_path)
except:
    pass

try:
    os.makedirs(output_path)
except:
    pass

base = os.path.basename(args.input)

mounted_input = os.path.join(input_path, base)

copyfile(args.input, mounted_input)

if base.endswith(".shp"):
    try:
        copyfile(args.input.replace('.shp', '.shx'), mounted_input.replace('.shp', '.shx'))
    except:
        pass

    try:
        copyfile(args.input.replace('.shp', '.dbf'), mounted_input.replace('.shp', '.dbf'))
    except:
        pass

    try:
        copyfile(args.input.replace('.shp', '.prj'), mounted_input.replace('.shp', '.prj'))
    except:
        pass

    try:
        copyfile(args.input.replace('.shp', '.cpg'), mounted_input.replace('.shp', '.cpg'))
    except:
        pass

args = []

for arg in sys.argv[1:]:
    if arg.startswith("--"):
        args.append(arg)
    else:
        args.append("'" + arg + "'")

run_command = 'bash -c "cd /tileoven/scripts && ruby mbtiles.rb export --file %s %s"' % (base, ' '.join(args))

command = 'docker pull fulcrumapp/tiler && docker run --name fulcrum-tiler --memory 4gb --rm -v %s:/input -v %s:/output -v %s:/root/Documents/MapBox -it --entrypoint="" fulcrumapp/tiler:latest %s' % (input_path, output_path, app_path, run_command)

print(command)

os.system(command)
