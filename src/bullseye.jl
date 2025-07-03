# SPDX-License-Identifier: MIT

using Census
using DataFrames, DataFramesMeta, Printf


"""
    dms_to_decimal(coords::AbstractString) -> String

Convert coordinates from degrees, minutes, seconds (DMS) format to decimal degrees (DD).

# Arguments
- `coords::AbstractString`: Coordinates in DMS format "DD° MM′ SS″ N/S, DD° MM′ SS″ E/W"

# Returns
- `String`: Coordinates in decimal degrees format "±DD.DDDD, ±DD.DDDD"

# Format
Input format must be:
- Degrees (°), minutes (′), and seconds (″) with their respective symbols
- Direction (N/S for latitude, E/W for longitude) after each coordinate
- Latitude and longitude separated by comma
- Spaces between components are optional

# Example
```julia
# Basic usage
coord = "42° 21′ 37″ N, 71° 03′ 28″ W"
result = dms_to_decimal(coord)  # Returns "42.36027777777778, -71.05777777777778"

# With decimal seconds
coord = "40° 26′ 46.302″ N, 79° 58′ 56.484″ W"
result = dms_to_decimal(coord)  # Returns "40.44619444444444, -79.98235555555555"
```

# Throws
- `ArgumentError`: If input format is invalid or coordinates are out of range
"""
function dms_to_decimal(coords::AbstractString)
    # Input validation
    if !occursin(",", coords)
        throw(ArgumentError("Invalid format: Latitude and longitude must be separated by comma"))
    end
    
    # Split the input string into latitude and longitude parts
    lat_dms, lon_dms = split(coords, ",")
    function to_decimal(dms::AbstractString)
        # Remove any extra whitespace and normalize unicode characters
        dms = strip(dms)
        dms = replace(dms, '′' => "'", '″' => "\"", '°' => "°")
        
        # Try to match the DMS pattern
        m = match(r"^(\d+)°\s*(\d+)['′]\s*(\d+(?:\.\d+)?)[\"″]\s*([NSEW])$", dms)
        if isnothing(m)
            throw(ArgumentError("Invalid DMS format: Expected 'DD° MM′ SS″ D' where D is N/S/E/W"))
        end
        
        # Extract and validate components
        deg, min, sec, dir = m.captures
        deg = parse(Float64, deg)
        min = parse(Float64, min)
        sec = parse(Float64, sec)
        
        # Validate ranges
        if deg < 0 || deg > 180
            throw(ArgumentError("Degrees must be between 0 and 180"))
        end
        if min < 0 || min >= 60
            throw(ArgumentError("Minutes must be between 0 and 59"))
        end
        if sec < 0 || sec >= 60
            throw(ArgumentError("Seconds must be between 0 and 59"))
        end
        
        # Calculate decimal degrees
        decimal = deg + (min / 60) + (sec / 3600)
        
        # Validate based on direction
        if (dir in ["N", "S"] && decimal > 90) || (dir in ["E", "W"] && decimal > 180)
            throw(ArgumentError("Invalid coordinate value for direction $dir"))
        end
        
        # Apply direction
        decimal *= (dir in ["S", "W"]) ? -1 : 1
        
        return decimal
    end
    
    try
        # Convert latitude and longitude to decimal degrees
        lat_decimal = to_decimal(lat_dms)
        lon_decimal = to_decimal(lon_dms)
        
        # Format with consistent precision
        return @sprintf("%.14f, %.14f", lat_decimal, lon_decimal)
    catch e
        if e isa ArgumentError
            rethrow(e)
        else
            throw(ArgumentError("Failed to parse coordinates: $(e.msg)"))
        end
    end
end

"""
    bullseye(capital::String, capital_coords::String)

Create an interactive HTML map with concentric circles (bullseye) centered on the specified capital.

# Arguments
- `capital::String`: The name of the capital city
- `capital_coords::String`: Coordinates in DMS format "DD° MM′ SS″ N/S, DD° MM′ SS″ E/W"

# Example
```julia
bullseye("Nashville", "36° 09′ 44″ N, 86° 46′ 28″ W")
```

# Output
Creates an HTML file named "{capital}.html" and opens it in the default browser.
"""
function bullseye(capital::String, capital_coords::String)
    pal = ("'Red', 'Green', 'Yellow', 'Blue', 'Purple'",
        "'#E74C3C', '#2ECC71', '#3498DB', '#F1C40F', '#9B59B6'",
        "'#FF4136', '#2ECC40', '#0074D9', '#FFDC00', '#B10DC9'",
        "'#D32F2F', '#388E3C', '#1976D2', '#FBC02D', '#7B1FA2'",
        "'#FF5733', '#C70039', '#900C3F', '#581845', '#FFC300'")
    centerpoint = dms_to_decimal(capital_coords)
    from = capital
    file_path = "$(capital).html"
    bands = "50, 100, 200, 400"
    band_colors = pal[4]
    bullseye_html = """
<!DOCTYPE html>
<html>
<head>
  <title>Leaflet Template</title>
  <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
  <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
  <style>
    body, html {
        margin: 0;
        padding: 0;
        width: 100%;
        height: 100%;
    }
    .flex-container {
        display: flex;
        align-items: flex-start;
        width: 100%;
        height: 100%;
    }
    #map {
        flex: 1;
        height: 100vh;
        margin: 0;
    }
    .tables-container {
        display: flex;
        flex-wrap: wrap;
        gap: 10px;
        padding: 20px;
    }
    table {
        border-collapse: collapse;
        width: 200px;
    }
    th, td {
        border: 1px solid black;
        padding: 8px;
        text-align: right;
    }
    .legend {
        padding: 6px 8px;
        background: white;
        background: rgba(255,255,255,0.9);
        box-shadow: 0 0 15px rgba(0,0,0,0.2);
        border-radius: 5px;
        line-height: 24px;
    }
</style>
</head>
<body>
<div class="flex-container">
  <div id="map">
  </div>
  <div class="tables-container">
  </div>
</div>
<script>
var mapOptions = {
   center: [$centerpoint],
   zoom: 7
};
var map = new L.map('map', mapOptions);

L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '© OpenStreetMap contributors',
    maxZoom: 19
}).addTo(map);

var marker = L.marker([$centerpoint]);
marker.addTo(map);
marker.bindPopup('$from').openPopup();

function milesToMeters(miles) {
   return miles * 1609.34;
}

var colors = [$band_colors];
var radii = [$bands].map(Number);

radii.forEach(function(radius, index) {
    var circle = L.circle([$centerpoint], {
        radius: milesToMeters(radius),
        color: colors[index],
        weight: 2,
        fill: true,
        fillColor: colors[index],
        fillOpacity: 0.05,
        interactive: false
    }).addTo(map);
    console.log('Added circle:', radius, 'miles');
});

var legend = L.control({position: 'bottomleft'});
legend.onAdd = function (map) {
    var div = L.DomUtil.create('div', 'legend');
    div.innerHTML = '<strong>Miles from center</strong><br>';
    radii.forEach(function(radius, i) {
        div.innerHTML +=
            '<i style="background:' + colors[i] + '; width: 18px; height: 18px; float: left; margin-right: 8px; opacity: 0.7;"></i> ' +
            radius + '<br>';
    });
    return div;
};
legend.addTo(map);

// Add resize handler to ensure map fills container after window resize
window.addEventListener('resize', function() {
    map.invalidateSize();
});
</script>
</body>
</html>
"""

    open(file_path, "w") do file
        write(file, bullseye_html)
    end
    run(`open $file_path`)
end

# Example usage with Nashville
bullseye("Nashville", "36° 09′ 44″ N, 86° 46′ 28″ W")
