rm(list=ls())
require(terra)
require(rgrass)

# Load DEM
dem = here::here('dem.tif') # Replace w/ YOUR DEM
r <- rast(dem)

# Initialize GRASS GIS
GRASS_INSTALLATION = "C:\\Program Files\\GRASS GIS 8.3" # Replace w/ YOUR GRASS Directory
initGRASS(gisBase=GRASS_INSTALLATION, 
          home=tempdir(), 
          gisDbase=getwd(),
          location="Stream_Analysis",
          mapset="PERMANENT",
          SG=r,
          override=TRUE)

# Install Stream Order GRASS Add-on
grass_modules = execGRASS("g.search.modules")
if(!"r.stream.order" %in% grass_modules) {
  execGRASS("g.extension",
            extension="r.stream.order",
            url="https://github.com/OSGeo/grass-addons/tree/grass8/src/raster/r.stream.order")
} else {
  print("r.stream.order is already installed.")
}

# Stream Order Analysis
# 0: Input DEM
write_RAST(r, vname="elev", flags = c("o"))
# 1: Fill + Fill Direction
execGRASS("r.fill.dir", 
          input = "elev", 
          output = "fill",
          direction = "flow_dir",
          areas = "sinks",
          flags = c("overwrite"))
# 2: Flow Accumulation
execGRASS("r.watershed", 
          elevation = "elev", 
          accumulation = "flow_acc",
          flags = c("overwrite"))
# 3: Stream Extract
execGRASS("r.stream.extract", 
          elevation = "elev", 
          accumulation = "flow_acc", 
          threshold = 100,              # Adjust threshold according to your data
          stream_raster = "streams",
          flags = c("overwrite"))
# 4: Stream Order
execGRASS("r.stream.order", 
          stream_rast = "streams", 
          direction = "flow_dir", 
          elevation = "elev", 
          accumulation = "flow_acc",
          strahler = "stream_order",
          flags = c("overwrite", "z"))

# Topographic Wetness Index
execGRASS("r.topidx", input = "elev", output = "twi")

# Import GRASS Layers into R
execGRASS("g.list", type = "raster")
streams = read_RAST("streams")
stream_order = read_RAST("stream_Order")
twi = read_RAST("twi")