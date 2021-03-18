#' Block Color Map
#'
#' A data.frame for mapping minecraft block names to RGB colors. This is helpful
#' for creating map plots that line up with in game colors.
#'
#' The RGB values are pretty much improvised. There's json files in
#' assets/minecraft/models/block/ (in the minecraft.jar file) that seem to map
#' block names to the base textures in assets/minecraft/textures/block/, which
#' are all pngs. For blocks with available png files, the average RGB value is
#' used. Otherwise, the RGB value may be hand picked or missing.
#'
#' @format A data frame with 1395 rows and 3 variables:
#' \describe{
#'   \item{block_name}{Internal minecraft blockname. Links to chunk palette.}
#'   \item{base_text}{Base texture that the block maps to}
#'   \item{rgb}{Mapped or hand picked rgb value for block}
#' }
#' @source \url{http://www.diamondse.info/}
"color_map"
