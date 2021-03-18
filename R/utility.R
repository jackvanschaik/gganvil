#' Get Region Name
#'
#' Get the name of a region file (.mca file) based on the chunk x and z coordinates.
#' These coordinates can be determined by using the F3 menu in game.
#' The files are found under word/region/ for a given world.
#'
#' @param chunk_x The chunk X coordinate (east-west)
#' @param chunk_z The chunk z coordinate (north-south)
#'
#' @return A character of length one containing the filename
#' @export
get_region_name <- function(chunk_x, chunk_z) {
    x <- floor(chunk_x / 32)
    z <- floor(chunk_z / 32)
    sprintf("r.%s.%s.mca", x, z)
}


