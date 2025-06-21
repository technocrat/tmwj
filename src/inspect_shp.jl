using ArchGDAL
"""
    inspect_shp(path::String)

Prints the structure and field names of a shapefile for inspection.
"""

function inspect_shp(path::String)
    dataset = ArchGDAL.read(path)
    layer = ArchGDAL.getlayer(dataset, 0)
    layerdefn = ArchGDAL.layerdefn(layer)
    
    println("Layer name: ", ArchGDAL.getname(layer))
    println("Feature count: ", ArchGDAL.nfeature(layer))
    println("Fields:")
    
    # Get field names by iterating through field definitions
    nfields = ArchGDAL.nfield(layerdefn)
    for i in 0:(nfields-1)
        fd = ArchGDAL.getfielddefn(layerdefn, i)
        field_name = ArchGDAL.getname(fd)
        println(" - ", field_name)
    end
    
    ArchGDAL.destroy(dataset)
end

export inspect_shp
