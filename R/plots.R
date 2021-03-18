#' Plot top blocks
#'
#' Plots a 2 dimensional character array of blocks. Designed for plotting
#' top blocks produced by `region_top_block`.
#'
#' Notice the in game x is mapped to the x coordinate in ggplot so the
#' north-south axis will be displayed left to right.
#'
#' @param top_blocks A character matrix (2d array) of block names
#'
#' @return A ggplot2 plot
#' @export
#'
#' @import ggplot2
#' @import rlang
plot_top_blocks <- function(top_blocks) {
    map_data <- reshape2::melt(t(top_blocks))
    names(map_data) <- c("x", "z", "block_name")
    map_data_2 <- dplyr::left_join(map_data, gganvil::color_map, by="block_name")
    map_data_2$rgb <- tidyr::replace_na(map_data_2$rgb, "#000000")

    ggplot(map_data_2, aes(x = .data$x, y = .data$z)) +
        theme(legend.position = "none") +
        geom_raster(fill = map_data_2$rgb) +
        theme_void()
}
