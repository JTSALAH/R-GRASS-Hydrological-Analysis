# R-GRASS-Hydrological-Analysis
Interface R &amp; GRASS GIS to automate a Hydrological Analysis from a DEM. Calculate streams, Strahler stream order, and Topographic Wetness Index for utilization as a SpatRaster in R.

# 1: Initialize GRASS GIS
To interface R & GRASS GIS, we need to initialize the R environment by specifying where GRASS is installed and ensure all modules of interest are present.
```r
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
```

# 2: Start Stream Order Analysis

```r
  # 0: Input DEM
  write_RAST(r, vname="elev", flags = c("o"))
```
```r
  # 1: Fill + Fill Direction
  execGRASS("r.fill.dir", 
            input = "elev", 
            output = "fill",
            direction = "flow_dir",
            areas = "sinks",
            flags = c("overwrite"))
```
```r
  # 2: Flow Accumulation
  execGRASS("r.watershed", 
            elevation = "elev", 
            accumulation = "flow_acc",
            flags = c("overwrite"))
```
```r
  # 3: Stream Extract
  execGRASS("r.stream.extract", 
            elevation = "elev", 
            accumulation = "flow_acc", 
            threshold = 100,              # Adjust threshold according to your data
            stream_raster = "streams",
            flags = c("overwrite"))
```
```r
  # 4: Stream Order
  execGRASS("r.stream.order", 
            stream_rast = "streams", 
            direction = "flow_dir", 
            elevation = "elev", 
            accumulation = "flow_acc",
            strahler = "stream_order",
            flags = c("overwrite", "z"))
```
```r
  # 5:Delineate watersheds
  execGRASS("r.watershed",
            elevation = "fill",
            stream = "streams",
            basin = "watersheds",
            flags = c("overwrite"))
```
```r
  # 6: Topographic Wetness Index
  execGRASS("r.topidx", input = "elev", output = "twi")
```

# 3: Import GRASS Layers into R

```r
  execGRASS("g.list", type = "raster")
  streams = read_RAST("streams")
  stream_order = read_RAST("stream_Order")
  watersheds = read_RAST("watersheds")
  twi = read_RAST("twi")
```
![Example TWI](https://github.com/JTSALAH/R-GRASS-Hydrological-Analysis/blob/main/Example_TWI.png)
