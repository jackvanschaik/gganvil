#' Parse uncompressed NBT data
#'
#' Most Minecraft data is stored in NBT format. This is a binary format similar to json
#' The format is documented [here](https://wiki.vg/NBT)
#' All NBT files contain all data in a base `TAG_Compund` tag,
#' so the default value of `N = 1` will typically read all tags.
#'
#' Be careful with `TAG_Long`. R doesn't support 64 bit integers. So instead,
#' the bytes are just read as a vector of 8 unsigned integers.
#'
#' @param connection file path of uncompressed NBT file
#' @param N number of tags to read
#'
#' @return a nested list of parsed results
#' @export
#'
#' @importFrom  stats setNames
parse_nbt <- function(connection, N=1) {
    parse_type_id <- function() readBin(file_obj, "int", size = 1, endian = "big")
    parse_int <- function(size) readBin(file_obj, "int", size = size, endian = "big")
    parse_long_int <- function() readBin(file_obj, "int", n = 8, size = 1, endian = "big", signed = FALSE)
    parse_float <- function() readBin(file_obj, "numeric", size = 4, endian = "big")
    parse_double <- function() readBin(file_obj, "double", size = 8, endian = "big")
    parse_bytes_array <- function(size) {
        array_size <- readBin(file_obj, "int", size = 4, endian = "big")
        if (array_size > 0) {
            return(readBin(file_obj, "int", n = array_size, size = size, endian = "big"))
        }
    }
    parse_long_bytes_array <- function() {
        array_size <- readBin(file_obj, "int", size = 4, endian = "big")
        if (array_size > 0) {
            raw_bytes <- readBin(file_obj, "raw", n = array_size * 8, size = 1, endian = "big")
            # Do this evil hack because R doesn't support 64 bit long ints :(
            M <- matrix(raw_bytes, nrow = 8)[8:1,]
            return(as.raw(M))
        }
    }
    parse_string <- function() {
        str_size <- readBin(file_obj, "int", size = 2, endian = "big", signed = FALSE)
        if (str_size > 0) {
            return(rawToChar(readBin(file_obj, "raw", n = str_size, endian = "big")))
        }
        else {
            return("")
        }
    }

    parse_list <- function() {
        type_id_all <- parse_type_id()

        list_size <- readBin(file_obj, "int", size = 4, endian = "big")
        if (list_size > 0) {
            L <- lapply(1:list_size, function(x) parse(type = type_id_all, named=FALSE))
            return(L)
        }
        else {
            return(list())
        }

    }

    # this will be slow :(
    parse_compound <- function(named = TRUE) {
        if (named == TRUE) {
            base_name <- parse_string()
        }

        comp <- list()

        while (TRUE) {
            c_type <- parse_type_id()
            if (c_type == 0) {
                if (named == TRUE) {
                    return(setNames(list(comp), base_name))
                }
                else {
                    return(list(comp))
                }
            }
            else {
                if (c_type == 10) {
                    res <- parse_compound()
                    comp <- c(comp, res)
                }
                else {
                    element_name <- parse_string()
                    res <- parse(c_type)
                    comp <- c(comp, setNames(list(res), element_name))
                }
            }
        }
    }

    parse <- function(type = NA, named=TRUE) {
        if (is.na(type)) {
            type <- parse_type_id()
        }

        if (type == 1) val <- parse_int(1)
        else if (type == 2) val <- parse_int(2)
        else if (type == 3) val <- parse_int(4)
        else if (type == 4) val <- parse_long_int()
        else if (type == 5) val <- parse_float()
        else if (type == 6) val <- parse_double()
        else if (type == 7) val <- parse_bytes_array(1)
        else if (type == 8) val <- parse_string()
        else if (type == 9) val <- parse_list()
        else if (type == 10) val <- parse_compound(named=named)
        else if (type == 11) val <- parse_bytes_array(4)
        else if (type == 12) val <- parse_long_bytes_array()
        else stop(sprintf("Something went wrong (type id %s not recognized)", type))
        return(val)
    }

    file_obj <- connection
    lapply(1:N, function(i) parse())
}

#' Parse a raw NBT file
#'
#' @param file_name file path
#' @param N number of tags to read
#'
#' @return a nested list of parsed results
#' @export
parse_nbt_file <- function(file_name, N=1) {
    connection <- file(file_name, "rb")
    results <- parse_nbt(connection)
    close(connection)
    return(results)
}
