import sys
from osgeo import ogr

ogr.UseExceptions()

try:
  source = ogr.Open(sys.argv[1])
except Exception, e:
  print e
  sys.exit()

for index in range(source.GetLayerCount()):
  layer = source.GetLayerByIndex(index)
  print(layer.GetName())

del layer
