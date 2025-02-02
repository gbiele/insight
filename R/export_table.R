#' Data frame and Tables Pretty Formatting
#'
#' @param x A data frame. May also be a list of data frames, to export multiple
#'   data frames into multiple tables.
#' @param sep Column separator.
#' @param header Header separator. Can be `NULL`.
#' @param empty_line Separator used for empty lines. If `NULL`, line remains
#'   empty (i.e. filled with whitespaces).
#' @param format Name of output-format, as string. If `NULL` (or `"text"`),
#'   returned output is used for basic printing. Can be one of `NULL` (the
#'   default) resp. `"text"` for plain text, `"markdown"` (or
#'   `"md"`) for markdown and `"html"` for HTML output.
#' @param title,caption,subtitle Table title (same as caption) and subtitle, as strings. If `NULL`,
#'   no title or subtitle is printed, unless it is stored as attributes (`table_title`,
#'   or its alias `table_caption`, and `table_subtitle`). If `x` is a list of
#'   data frames, `caption` may be a list of table captions, one for each table.
#' @param footer Table footer, as string. For markdown-formatted tables, table
#'   footers, due to the limitation in markdown rendering, are actually just a
#'   new text line under the table. If `x` is a list of data frames, `footer`
#'   may be a list of table captions, one for each table.
#' @param align Column alignment. For markdown-formatted tables, the default
#'   `align = NULL` will right-align numeric columns, while all other
#'   columns will be left-aligned. If `format = "html"`, the default is
#'   left-align first column and center all remaining. May be a string to
#'   indicate alignment rules for the complete table, like `"left"`,
#'   `"right"`, `"center"` or `"firstleft"` (to left-align first
#'   column, center remaining); or maybe a string with abbreviated alignment
#'   characters, where the length of the string must equal the number of columns,
#'   for instance, `align = "lccrl"` would left-align the first column, center
#'   the second and third, right-align column four and left-align the fifth
#'   column. For HTML-tables, may be one of `"center"`, `"left"` or
#'   `"right"`.
#' @param group_by Name of column in `x` that indicates grouping for tables.
#'   Only applies when `format = "html"`. `group_by` is passed down
#'   to `gt::gt(groupname_col = group_by)`.
#' @param width Refers to the width of columns (with numeric values). Can be
#'   either `NULL`, a number or a named numeric vector. If `NULL`, the width for
#'   each column is adjusted to the minimum required width. If a number, columns
#'   with numeric values will have the minimum width specified in `width`. If
#'   a named numeric vector, value names are matched against column names, and
#'   for each match, the specified width is used (see 'Examples'). Only applies
#'   to text-format (see `format`).
#' @param table_width Numeric, or `"auto"`, indicating the width of the complete
#'   table. If `table_width = "auto"` and the table is wider than the current
#'   width (i.e. line length) of the console (or any other source for textual
#'   output, like markdown files), the table is split into two parts. Else,
#'   if `table_width` is numeric and table rows are larger than `table_width`,
#'   the table is split into two parts.
#' @inheritParams format_value
#' @inheritParams get_data
#'
#' @note The values for `caption`, `subtitle` and `footer`
#'   can also be provided as attributes of `x`, e.g. if `caption = NULL`
#'   and `x` has attribute `table_caption`, the value for this
#'   attribute will be used as table caption. `table_subtitle` is the
#'   attribute for `subtitle`, and `table_footer` for `footer`.
#'
#' @inherit format_table seealso
#'
#' @return A data frame in character format.
#' @examples
#' export_table(head(iris))
#' export_table(head(iris), sep = " ", header = "*", digits = 1)
#'
#' # split longer tables
#' export_table(head(iris), table_width = 30)
#'
#' \dontrun{
#' # colored footers
#' data(iris)
#' x <- as.data.frame(iris[1:5, ])
#' attr(x, "table_footer") <- c("This is a yellow footer line.", "yellow")
#' export_table(x)
#'
#' attr(x, "table_footer") <- list(
#'   c("\nA yellow line", "yellow"),
#'   c("\nAnd a red line", "red"),
#'   c("\nAnd a blue line", "blue")
#' )
#' export_table(x)
#'
#' attr(x, "table_footer") <- list(
#'   c("Without the ", "yellow"),
#'   c("new-line character ", "red"),
#'   c("we can have multiple colors per line.", "blue")
#' )
#' export_table(x)
#' }
#'
#' # column-width
#' d <- data.frame(
#'   x = c(1, 2, 3),
#'   y = c(100, 200, 300),
#'   z = c(10000, 20000, 30000)
#' )
#' export_table(d)
#' export_table(d, width = 8)
#' export_table(d, width = c(x = 5, z = 10))
#' export_table(d, width = c(x = 5, y = 5, z = 10), align = "lcr")
#' @export
export_table <- function(x,
                         sep = " | ",
                         header = "-",
                         empty_line = NULL,
                         digits = 2,
                         protect_integers = TRUE,
                         missing = "",
                         width = NULL,
                         format = NULL,
                         title = NULL,
                         caption = title,
                         subtitle = NULL,
                         footer = NULL,
                         align = NULL,
                         group_by = NULL,
                         zap_small = FALSE,
                         table_width = NULL,
                         verbose = TRUE) {

  # check args
  if (is.null(format)) {
    format <- "text"
  }

  if (format == "md") {
    format <- "markdown"
  }

  # sanity check
  if (is.null(x) || (is.data.frame(x) && nrow(x) == 0) || .is_empty_object(x)) {
    if (isTRUE(verbose)) {
      message(paste0("Can't export table to ", format, ", data frame is empty."))
    }
    return(NULL)
  }

  # if we have a list of data frame and HTML format, create a single
  # data frame now...
  if (identical(format, "html") && !is.data.frame(x) && is.list(x)) {
    x <- do.call(rbind, lapply(x, function(i) {
      attr_name <- .check_caption_attr_name(i)
      i$Component <- attr(i, attr_name)[1]
      i
    }))
  }

  # check for indention
  indent_groups <- attributes(x)$indent_groups
  indent_rows <- attributes(x)$indent_rows

  # single data frame
  if (is.data.frame(x)) {

    # check default attributes for caption, sub-title and footer
    if (!is.null(title)) {
      caption <- title
    }
    if (is.null(caption)) {
      attr_name <- .check_caption_attr_name(x)
      caption <- attributes(x)[[attr_name]]
    }
    if (is.null(subtitle)) {
      subtitle <- attributes(x)$table_subtitle
    }
    if (is.null(footer)) {
      footer <- attributes(x)$table_footer
    }

    # convert data frame into specified output format
    out <- .export_table(
      x = x,
      sep = sep,
      header = header,
      digits = digits,
      protect_integers = protect_integers,
      missing = missing,
      width = width,
      format = format,
      caption = caption,
      subtitle = subtitle,
      footer = footer,
      align = align,
      group_by = group_by,
      zap_small = zap_small,
      empty_line = empty_line,
      indent_groups = indent_groups,
      indent_rows = indent_rows,
      table_width = table_width
    )
  } else if (is.list(x)) {

    # remove empty elements
    l <- .compact_list(x)

    # list of data frames
    tmp <- lapply(1:length(l), function(element) {
      i <- l[[element]]

      # use individual footer for each list element...
      t_footer <- attributes(i)$table_footer

      # ...unless we have a footer-argument.
      # Then use this as last (final) footer
      if (element == length(l) && is.null(attributes(i)$table_footer) && !is.null(footer) && !is.list(footer)) {
        t_footer <- footer
      }

      # if we still have no footer, check if user provided a list of titles
      if (is.null(t_footer) && !is.null(footer) && is.list(footer) && length(footer) == length(l)) {
        t_footer <- footer[[element]]
      }


      # for lists of data frame, each list element may have
      # an own attribute for the title, to have "subheadings"
      # for each table

      attr_name <- .check_caption_attr_name(i)

      # if only alias "title" is provided, copy it to caption-variable
      if (!is.null(title) && is.null(caption)) {
        caption <- title
      }

      # use individual title for each list element...
      t_title <- attributes(i)[[attr_name]]

      # ...unless we have a title-argument.
      # Then use this as first (main) header
      if (element == 1 && is.null(attributes(i)[[attr_name]]) && !is.null(caption) && !is.list(caption)) {
        t_title <- caption
      }

      # if we still have no title, check if user provided a list of titles
      if (is.null(t_title) && !is.null(caption) && is.list(caption) && length(caption) == length(l)) {
        t_title <- caption[[element]]
      }

      # convert data frame into specified output format
      .export_table(
        x = i,
        sep = sep,
        header = header,
        digits = digits,
        protect_integers = protect_integers,
        missing = missing,
        width = width,
        format = format,
        caption = t_title,
        subtitle = attributes(i)$table_subtitle,
        footer = t_footer,
        align = align,
        group_by = group_by,
        zap_small = zap_small,
        empty_line = empty_line,
        indent_groups = indent_groups,
        indent_rows = indent_rows,
        table_width = table_width
      )
    })

    # insert new lines between tables
    out <- c()
    if (format == "text") {
      for (i in 1:length(tmp)) {
        out <- paste0(out, tmp[[i]], "\n")
      }
      out <- substr(out, 1, nchar(out) - 1)
    } else if (format == "markdown") {
      for (i in 1:length(tmp)) {
        out <- c(out, tmp[[i]], "")
      }
      out <- out[1:(length(out) - 1)]
    }
  } else {
    return(NULL)
  }

  # add specific knitr-attribute for proper printing inside rmarkdown
  if (format == "markdown") {
    attr(out, "format") <- "pipe"
    class(out) <- c("knitr_kable", "character")
  } else if (format == "text") {
    class(out) <- c("insight_table", class(out))
  }
  out
}



# check whether "table_caption" or its alias "table_title" is used as attribute
.check_caption_attr_name <- function(x) {
  attr_name <- "table_caption"
  if (is.null(attr(x, attr_name, exact = TRUE)) && !is.null(attr(x, "table_title", exact = TRUE))) {
    attr_name <- "table_title"
  }
  attr_name
}



# create matrix of raw table layout --------------------


.export_table <- function(x,
                          sep = " | ",
                          header = "-",
                          digits = 2,
                          protect_integers = TRUE,
                          missing = "",
                          width = NULL,
                          format = NULL,
                          caption = NULL,
                          subtitle = NULL,
                          footer = NULL,
                          align = NULL,
                          group_by = NULL,
                          zap_small = FALSE,
                          empty_line = NULL,
                          indent_groups = NULL,
                          indent_rows = NULL,
                          table_width = NULL) {
  df <- as.data.frame(x)

  # check width argument, for format value. cannot have
  # named vector of length > 1 here
  if (is.null(width) || length(width) == 1) {
    col_width <- width
  } else {
    col_width <- NULL
  }

  # round all numerics
  col_names <- names(df)
  df <- as.data.frame(sapply(df, function(i) {
    if (is.numeric(i)) {
      format_value(i,
        digits = digits, protect_integers = protect_integers,
        missing = missing, width = col_width, zap_small = zap_small
      )
    } else {
      i
    }
  }, simplify = FALSE), stringsAsFactors = FALSE)


  # Convert to character
  df <- as.data.frame(sapply(df, as.character, simplify = FALSE), stringsAsFactors = FALSE)
  names(df) <- col_names
  df[is.na(df)] <- as.character(missing)


  if (identical(format, "html")) {
    # html formatting starts here, needs less preparation of table matrix
    out <- .format_html_table(
      df,
      caption = caption,
      subtitle = subtitle,
      footer = footer,
      align = align,
      group_by = group_by,
      indent_groups = indent_groups,
      indent_rows = indent_rows
    )

    # text and markdown go here...
  } else {
    # Add colnames as row
    df <- rbind(colnames(df), df)

    # Align
    aligned <- format(df, justify = "right")

    # default alignment
    col_align <- rep("right", ncol(df))

    # Center first row
    first_row <- as.character(aligned[1, ])
    for (i in 1:length(first_row)) {
      aligned[1, i] <- format(trimws(first_row[i]), width = nchar(first_row[i]), justify = "right")
    }

    final <- as.matrix(aligned)

    # left-align first column (if a character or a factor)
    if (!is.numeric(x[, 1])) {
      final[, 1] <- format(trimws(final[, 1]), justify = "left")
      col_align[1] <- "left"
    }

    if (format == "text") {

      # go for simple text output
      out <- .format_basic_table(
        final,
        header,
        sep,
        caption = caption,
        subtitle = subtitle,
        footer = footer,
        align = align,
        empty_line = empty_line,
        indent_groups = indent_groups,
        indent_rows = indent_rows,
        col_names = col_names,
        col_width = width,
        col_align = col_align,
        table_width = table_width
      )
    } else if (format == "markdown") {

      # markdown is a bit different...
      out <- .format_markdown_table(
        final,
        x,
        caption = caption,
        subtitle = subtitle,
        footer = footer,
        align = align,
        indent_groups = indent_groups,
        indent_rows = indent_rows
      )
    }
  }

  out
}






# plain text formatting ------------------------


.format_basic_table <- function(final,
                                header,
                                sep,
                                caption = NULL,
                                subtitle = NULL,
                                footer = NULL,
                                align = NULL,
                                empty_line = NULL,
                                indent_groups = NULL,
                                indent_rows = NULL,
                                col_names = NULL,
                                col_width = NULL,
                                col_align = NULL,
                                table_width = NULL) {

  # align table, if requested
  if (!is.null(align) && length(align) == 1) {
    for (i in 1:ncol(final)) {
      align_char <- ""
      if (align %in% c("left", "right", "center", "firstleft")) {
        align_char <- ""
      } else {
        align_char <- substr(align, i, i)
      }

      # left alignment, or at least first line only left?
      if (align == "left" || (align == "firstleft" && i == 1) || align_char == "l") {
        final[, i] <- format(trimws(final[, i]), justify = "left")
        col_align[i] <- "left"

        # right-alignment
      } else if (align == "right" || align_char == "r") {
        final[, i] <- format(trimws(final[, i]), justify = "right")
        col_align[i] <- "right"

        # else, center
      } else {
        final[, i] <- format(trimws(final[, i]), justify = "centre")
        col_align[i] <- "centre"
      }
    }
  }

  # indent groups?
  if (!is.null(indent_groups) && any(grepl(indent_groups, final[, 1], fixed = TRUE))) {
    final <- .indent_groups(final, indent_groups)
  } else if (!is.null(indent_rows) && any(grepl("# ", final[, 1], fixed = TRUE))) {
    final <- .indent_rows(final, indent_rows)
  }

  # check for fixed column widths
  if (!is.null(col_width) && length(col_width) > 1 && !is.null(names(col_width))) {
    matching_columns <- stats::na.omit(match(names(col_width), col_names))
    if (length(matching_columns)) {
      for (i in matching_columns) {
        w <- as.vector(col_width[col_names[i]])
        final[, i] <- format(trimws(final[, i]), width = w, justify = col_align[i])
      }
    }
  }

  # we can split very wide table into maximum three parts
  # this is currently hardcoded, not flexible, so we cannot allow
  # more than three parts of one wide table
  final2 <- NULL
  final3 <- NULL

  # save first column we may need this when table is wrapped into multiple
  # parts due to over-lengthy lines
  if (identical(table_width, "auto") || (!is.null(table_width) && is.numeric(table_width))) {
    # check current line width in console and width of table rows
    if (is.numeric(table_width)) {
      line_width <- table_width
    } else {
      line_width <- options()$width
    }
    # first split - table columns longer than "line_width" go
    # into a second string
    row_width <- nchar(paste0(final[1, ], collapse = sep))
    # if wider, save first column - we need to repeat this later
    if (row_width > line_width) {
      i <- 1
      while (nchar(paste0(final[1, 1:i], collapse = sep)) < line_width) {
        i <- i + 1
      }
      if (i > 2 && i < ncol(final)) {
        final2 <- final[, c(1, i:ncol(final))]
        final <- final[, 1:(i - 1)]
      }
    }
    # second split - table columns longer than "line_width" go
    # into a third string
    row_width <- nchar(paste0(final2[1, ], collapse = sep))
    # if wider, save first column - we need to repeat this later
    if (row_width > line_width) {
      i <- 1
      while (nchar(paste0(final2[1, 1:i], collapse = sep)) < line_width) {
        i <- i + 1
      }
      if (i > 2 && i < ncol(final2)) {
        final3 <- final2[, c(1, i:ncol(final2))]
        final2 <- final2[, 1:(i - 1)]
      }
    }
  }

  # Transform to character
  rows <- .table_parts(c(), final, header, sep, empty_line)

  # if we have over-lengthy tables that are split into two parts,
  # print second table here
  if (!is.null(final2)) {
    rows <- .table_parts(paste0(rows, "\n"), final2, header, sep, empty_line)
  }

  # if we have over-lengthy tables that are split into two parts,
  # print second table here
  if (!is.null(final3)) {
    rows <- .table_parts(paste0(rows, "\n"), final3, header, sep, empty_line)
  }

  # if caption is available, add a row with a headline
  if (!is.null(caption) && caption[1] != "") {
    if (length(caption) == 2 && .is_valid_colour(caption[2])) {
      caption <- .colour(caption[2], caption[1])
    }
    if (!is.null(subtitle)) {
      if (length(subtitle) == 2 && .is_valid_colour(subtitle[2])) {
        subtitle <- .colour(subtitle[2], subtitle[1])
      }
    } else {
      subtitle <- ""
    }

    # paste everything together and remove unnecessary double spaces
    title_line <- .trim(paste0(caption[1], " ", subtitle[1]))
    title_line <- gsub("  ", " ", title_line, fixed = TRUE)
    rows <- paste0(title_line, "\n\n", rows)
  }

  # if footer is available, add a row with a footer. footers may
  # also be provided as list of character vectors, so each footer
  # line can get its own color

  if (!is.null(footer)) {
    if (is.list(footer)) {
      for (i in footer) {
        rows <- .paste_footers(i, rows)
      }
    } else {
      rows <- .paste_footers(footer, rows)
    }
  }

  rows
}



.table_parts <- function(rows, final, header, sep, empty_line) {
  for (row in 1:nrow(final)) {
    final_row <- paste0(final[row, ], collapse = sep)

    # check if we have an empty row
    if (!is.null(empty_line) && all(nchar(trimws(final[row, ])) == 0)) {
      rows <- paste0(rows, paste0(rep_len(empty_line, nchar(final_row)), collapse = ""), sep = "\n")
    } else {
      rows <- paste0(rows, final_row, sep = "\n")
    }

    # First row separation
    if (row == 1) {
      if (!is.null(header)) {
        rows <- paste0(rows, paste0(rep_len(header, nchar(final_row)), collapse = ""), sep = "\n")
      }
    }
  }

  rows
}




#' @export
print.insight_table <- function(x, ...) {
  cat(x)
  invisible(x)
}


# helper ----------------


.paste_footers <- function(footer, rows) {
  if (.is_empty_string(footer)) {
    return(rows)
  }
  if (length(footer) == 2 && .is_valid_colour(footer[2])) {
    footer <- .colour(footer[2], footer[1])
  }
  paste0(rows, footer[1])
}



.indent_groups <- function(final, indent_groups) {
  # check length of indent string
  whitespace <- sprintf("%*s", nchar(indent_groups), " ")

  # find start index of groups
  grps <- grep(indent_groups, final[, 1], fixed = TRUE)

  # create index for those rows that should be indented
  grp_rows <- seq(grps[1], nrow(final))
  grp_rows <- grp_rows[!grp_rows %in% grps]

  # indent
  final[grp_rows, 1] <- paste0(whitespace, final[grp_rows, 1])

  # remove indent token
  final[, 1] <- gsub(indent_groups, "", final[, 1], fixed = TRUE)

  # trim whitespace at end
  final[, 1] <- trimws(final[, 1], which = "right")

  # move group name (indent header) to left
  final[, 1] <- format(final[, 1], justify = "left", width = max(nchar(final[, 1])))
  final
}


.indent_rows <- function(final, indent_rows, whitespace = "  ") {
  # create index for those rows that should be indented
  grp_rows <- indent_rows + 1

  # indent
  final[grp_rows, 1] <- paste0(whitespace, final[grp_rows, 1])

  # find rows that should not be indented
  non_grp_rows <- 1:nrow(final)
  non_grp_rows <- non_grp_rows[!non_grp_rows %in% grp_rows]

  # paste whitespace at end, to ensure equal width for each string
  final[non_grp_rows, 1] <- paste0(final[non_grp_rows, 1], whitespace)

  # remove indent token
  grps <- grep("# ", final[, 1], fixed = TRUE)
  final[, 1] <- gsub("# ", "", final[, 1], fixed = TRUE)

  # move group name (indent header) to left
  final[grps, 1] <- format(final[grps, 1], justify = "left", width = max(nchar(final[, 1])))
  final
}



.indent_rows_html <- function(final, indent_rows, whitespace = "") {
  # create index for those rows that should be indented
  grp_rows <- indent_rows + 1

  # indent
  final[grp_rows, 1] <- paste0(whitespace, final[grp_rows, 1])

  # find rows that should not be indented
  non_grp_rows <- 1:nrow(final)
  non_grp_rows <- non_grp_rows[!non_grp_rows %in% grp_rows]

  # remove indent token
  final[, 1] <- gsub("# ", "", final[, 1])

  final
}


# markdown formatting -------------------


.format_markdown_table <- function(final,
                                   x,
                                   caption = NULL,
                                   subtitle = NULL,
                                   footer = NULL,
                                   align = NULL,
                                   indent_groups = NULL,
                                   indent_rows = NULL) {
  column_width <- nchar(final[1, ])
  n_columns <- ncol(final)
  first_row_leftalign <- (!is.null(align) && align == "firstleft")

  ## create header line for markdown table -----
  header <- "|"

  # indention? than adjust column width for first column
  if (!is.null(indent_rows) || !is.null(indent_groups)) {
    column_width[1] <- column_width[1] + 2
  }

  # go through all columns of the data frame
  for (i in 1:n_columns) {

    # create separator line for current column
    line <- paste0(rep_len("-", column_width[i]), collapse = "")

    # check if user-defined alignment is requested, and if so, extract
    # alignment direction and save to "align_char"
    align_char <- ""
    if (!is.null(align)) {
      if (align %in% c("left", "right", "center", "firstleft")) {
        align_char <- ""
      } else {
        align_char <- substr(align, i, i)
      }
    }

    # auto-alignment?
    if (is.null(align)) {

      # if so, check if string in column starts with
      # whitespace (indicating right-alignment) or not.
      if (grepl("^\\s", final[2, i])) {
        line <- paste0(line, ":")
        final[, i] <- format(final[, i], width = column_width[i] + 1, justify = "right")
      } else {
        line <- paste0(":", line)
        final[, i] <- format(final[, i], width = column_width[i] + 1, justify = "left")
      }

      # left alignment, or at least first line only left?
    } else if (align == "left" || (first_row_leftalign && i == 1) || align_char == "l") {
      line <- paste0(":", line)
      final[, i] <- format(final[, i], width = column_width[i] + 1, justify = "left")

      # right-alignment
    } else if (align == "right" || align_char == "r") {
      line <- paste0(line, ":")
      final[, i] <- format(final[, i], width = column_width[i] + 1, justify = "right")

      # else, center
    } else {
      line <- paste0(":", line, ":")
      final[, i] <- format(final[, i], width = column_width[i] + 2, justify = "centre")
    }

    # finally, we have our header-line that indicates column alignments
    header <- paste0(header, line, "|")
  }

  # indent groups?
  if (!is.null(indent_groups) && any(grepl(indent_groups, final[, 1], fixed = TRUE))) {
    final <- .indent_groups(final, indent_groups)
  } else if (!is.null(indent_rows) && any(grepl("# ", final[, 1], fixed = TRUE))) {
    final <- .indent_rows(final, indent_rows)
  }

  # Transform to character
  rows <- c()
  for (row in 1:nrow(final)) {
    final_row <- paste0("|", paste0(final[row, ], collapse = "|"), "|", collapse = "")
    rows <- c(rows, final_row)

    # First row separation
    if (row == 1) {
      rows <- c(rows, header)
    }
  }

  if (!is.null(caption)) {
    if (!is.null(subtitle)) {
      caption[1] <- paste0(caption[1], " ", subtitle[1])
    }
    rows <- c(paste0("Table: ", .trim(caption[1])), "", rows)
  }

  if (!is.null(footer)) {
    if (is.list(footer)) {
      for (i in footer) {
        if (!.is_empty_string(i)) {
          rows <- c(rows, i[1])
        }
      }
    } else if (!.is_empty_string(footer)) {
      rows <- c(rows, footer[1])
    }
  }

  rows
}



# html formatting ---------------------------

.format_html_table <- function(final,
                               caption = NULL,
                               subtitle = NULL,
                               footer = NULL,
                               align = "center",
                               group_by = NULL,
                               indent_groups = NULL,
                               indent_rows = NULL) {
  # installed?
  check_if_installed("gt")

  if (is.null(align)) {
    align <- "firstleft"
  }

  group_by_columns <- c(intersect(c("Group", "Response", "Effects", "Component"), names(final)), group_by)
  if (!length(group_by_columns)) {
    group_by_columns <- NULL
  } else {

    # remove columns with only 1 unique value - this *should* be safe to
    # remove, but we may check if all printed sub titles look like intended

    for (i in group_by_columns) {
      if (.n_unique(final[[i]]) <= 1) {
        final[[i]] <- NULL
      }
    }
  }

  # indent groups?
  if (!is.null(indent_rows) && any(grepl("# ", final[, 1], fixed = TRUE))) {
    final <- .indent_rows_html(final, indent_rows)
  }

  tab <- gt::gt(final, groupname_col = group_by_columns)
  header <- gt::tab_header(tab, title = caption, subtitle = subtitle)
  footer <- gt::tab_source_note(header, source_note = footer)
  out <- gt::cols_align(footer, align = "center")

  # align columns
  if (!is.null(out[["_boxhead"]]) && !is.null(out[["_boxhead"]]$column_align)) {
    if (align == "firstleft") {
      out[["_boxhead"]]$column_align[1] <- "left"
    } else {
      col_align <- c()
      for (i in 1:nchar(align)) {
        col_align <- c(col_align, switch(substr(align, i, i),
          "l" = "left",
          "r" = "right",
          "center"
        ))
      }
      out[["_boxhead"]]$column_align <- col_align
    }
  }

  out
}
