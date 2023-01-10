# Set up workspace --------------------------------------------------------

# Check if packages are installed and install them if necessary
# Set the CRAN mirror to use
CRAN <- "https://cran.csiro.au"

# Define the packages to check
packages <- c('tidyverse', 'rgdal',  'mapdeck', 'sf')

# Check if packages are installed and install them if necessary
lapply(packages, function(x) {
  ifelse(x %in% installed.packages(), library(x, character.only = TRUE), 
         install.packages(x, dependencies = TRUE, repos = CRAN))
})

act_house <- read.csv(file.path("data", "raw", "ACT_address.csv"))

# Convert act_house to an sf object
point <- st_as_sf(act_house, coords = c("LONGITUDE", "LATITUDE"))

# Read in shapefiles
sa3 <- sf::st_read(file.path('data','raw','SA3_2016_AUST.shp'))
mb <- sf::st_read(file.path('data','raw','MB_2016_ACT.shp'))

# set CRS for the points to be the same as shapefile
st_crs(point) <- st_crs(mb)

# For POINTS that fall within CA_counties, adds ATTRIBUTES, retains ALL pts if left=TRUE, otherwise uses inner_join
isd_ca_co_pts <- st_join(point, mb)

set_token(Sys.getenv("MAPBOX_TK"))

# Set the style for the map
ms = mapdeck_style("light")

# Create the map
mapdeck(style = ms, pitch = 45, location = c(134, -28), zoom = 4) %>%
  #Add the sa3 polygon layer
  add_polygon(
    data = sa3 #sf::st_cast(nc, "POLYGON")
    , layer = "polygon_layer"
    , fill_colour = "STATE_CODE"
    , fill_opacity = 0.1
    , stroke_colour = "SA3_CODE"
    , stroke_width = 8
    , stroke_opacity = .5
    # Add the point layer, filtering to only include points with MB_CAT16 equal to 'Residential'
  ) %>% add_scatterplot(
    data = filter(isd_ca_co_pts, MB_CAT16 == 'Residential')
    , lat = "LATITUDE"
    , lon = "LONGITUDE"
    , radius = 10
    , fill_colour = "blue"
    , layer_id = "LOCALITY_NAME"
    , tooltip = "LOCALITY_NAME"
  )


isd_ca_co_pts %>% n_distinct()
