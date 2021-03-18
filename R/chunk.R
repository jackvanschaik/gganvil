#' Chunk Section to R Array
#'
#' Convert chunk section data to a 3d array. Each element in the array
#' corresponds to a block from that section's palette. This format is
#' documented at [gamepedia](https://minecraft.gamepedia.com/Chunk_format)
#'
#' @param section A specific chunk section
#'
#' @return a 3d array
#' @export
section_to_array <- function(section) {
    block_states <- section[[1]]$BlockStates
    palette <- section[[1]]$Palette

    # get names of palette items
    pal_names <- unlist(lapply(palette, function(x) x[[1]]$Name), use.names = FALSE)

    # get number number of bits for each index
    n_bits <- max(c(4, ceiling(log2(length(pal_names)))))
    usable_bits <- floor(64/n_bits)*n_bits

    block_bits <- rawToBits(block_states)
    M <- matrix(block_bits, nrow = 64)[1:usable_bits,]
    M_2 <- matrix(as.numeric(M), nrow = n_bits)

    # use bit array to get palette indices
    w <- 2^(0:(n_bits - 1))
    indices <- apply(M_2, 2, function(x) sum(x * w) + 1)

    # Load into an array, permute dimensions to (X, Y, Z)
    all_blocks <- pal_names[indices]
    block_array <- aperm(array(all_blocks, c(16, 16, 16)), perm = c(1, 3, 2))

    block_array
}

#' Assemble a Chunk
#'
#' Combine multiple sections of a chunk to get a complete representation of it's blocks
#'
#' @param chunk a chunk in output from `parse_dat`
#'
#' @return a multidimensional array
#' @export
assemble_chunk <- function(chunk) {
    I <- unlist(lapply(chunk$Level$Sections, function(x) {
        nm <- names(x[[1]])
        x[[1]]$Y >= 0 & "BlockStates" %in% nm & "Palette" %in% nm
    }))
    L <- lapply(chunk$Level$Sections[I], section_to_array)
    ac <- c(L, list(along = 2))
    do.call(abind::abind, ac)
}

#' Top Block in a Chunk
#'
#' Get the highest opaque block in a chunk, after assembling it.
#'
#' This is the block we want to see when plotting.
#'
#' @param chunk a chunk in output from `parse_dat`
#'
#' @return a 16 x 16 matrix
#' @export
chunk_top_block <- function(chunk) {
    result <- matrix("", nrow = 16, ncol = 16)
    M <- assemble_chunk(chunk)
    for (i in 1:16) {
        for (j in 1:16) {
            slice <- as.character(M[i,,j])
            result[i,j] <- slice[max(which(slice != "minecraft:air"))]
        }
    }
    result
}
