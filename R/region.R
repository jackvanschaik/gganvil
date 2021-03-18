#' Parse a region file
#'
#' Based on documentation from [here](https://wiki.vg/Region_Files)
#'
#' @param fn File path of .dat file
#'
#' @return a list of header data and NBT data
#' @export
parse_dat <- function(fn) {
    raw <- readr::read_file_raw(fn)
    file_obj <- rawConnection(raw)

    offset <- numeric(1024)
    size <- numeric(1024)
    timestamp <- numeric(1024)

    w <- 256^c(2, 1, 0)

    for (j in 1:1024) {
        off <- readBin(file_obj, "int", n = 3, size = 1, endian = "big", signed = FALSE)
        offset[j] <- sum(w*off)
        size[j] <- readBin(file_obj, "int", size = 1, endian = "big")
    }

    for (k in 1:1024) {
        timestamp[k] <- readBin(file_obj, "int", size = 4, endian = "big")
    }

    close(file_obj)

    L <- lapply(1:1024, function(i) {
        left <- 4096 * offset[i] + 1
        right <- left + (4096*size[i])
        zlib_bytes <- raw[left:right][-c(1:5)]
        nbt_uncomp <- gzmem::mem_inflate(zlib_bytes, "zlib", 1000000)
        conn <- rawConnection(nbt_uncomp)
        val <- parse_nbt(conn)[[1]][[1]]
        close(conn)
        return(val)
    })

    df <- data.frame(
        offset = offset,
        size = size,
        timestamp = timestamp
    )

    list(
        header_info = df,
        nbt_data = L
    )
}

#' Top Blocks in a Region
#'
#' Get highest non-air block at each x-z coordinate in a region.
#' This results in a 512 x 512 character matrix useful for birds-eye plotting.
#'
#' @param dat_file File path of .dat file
#'
#' @return A 2d character matrix
#' @export
region_top_block <- function(dat_file) {
    region <- parse_dat(dat_file)
    top_blocks <- lapply(region$nbt_data, chunk_top_block)

    chunk_x <- rep(1:32, 32)
    chunk_z <- rep(1:32, each=32)

    M_reg <- matrix(data = "", nrow = 16*32, ncol = 16*32)
    for (j in 0:1023) {
        chunk_x <- 1 + (j %% 32)
        chunk_z <- 1 + floor(j/32)

        block_x <- 16*chunk_x
        block_z <- 16*chunk_z

        range_x <- (block_x - 15):block_x
        range_z <- (block_z - 15):block_z

        M_reg[range_x, range_z] <- top_blocks[[j + 1]]
    }

    M_reg
}

#' Get Region Data
#'
#' Get every block in a region with x,y, and coordinates as a data frame.
#' Useful for doing analysis of the world file.
#'
#' @param dat_file File path of .dat file
#'
#' @return A data.frame with block data. It will be over a million rows.
#' @export
region_data <- function(dat_file) {
    region <- parse_dat(dat_file)
    blocks <- lapply(region$nbt_data, chunk_top_block)

    blocks <- lapply(region$nbt_data, assemble_chunk)
    chunk_data <- do.call(rbind, lapply(0:1023, function(j) {
        df <- reshape2::melt(blocks[[j + 1]])
        names(df) <- c("x", "y", "z", "block")
        df$chunk_x <- 1 + (j %% 32)
        df$chunk_z <- 1 + floor(j/32)
        df
    }))

    chunk_data
}
