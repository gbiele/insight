% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/datawizard.R
\name{data_relocate}
\alias{data_relocate}
\title{Relocate (reorder) columns of a data frame}
\usage{
data_relocate(data, cols, before = NULL, after = NULL, safe = TRUE, ...)
}
\arguments{
\item{data}{A data frame to pivot.}

\item{cols}{A character vector indicating the names of the columns to move.}

\item{before, after}{Destination of columns. Supplying neither will move
columns to the left-hand side; specifying both is an error.}

\item{safe}{If \code{TRUE}, will disregard non-existing columns.}

\item{...}{Additional arguments passed on to methods.}
}
\value{
A data frame with reordered columns.
}
\description{
Relocate (reorder) columns of a data frame
}
\examples{
# Reorder columns
head(data_relocate(iris, cols = "Species", before = "Sepal.Length"))
head(data_relocate(iris, cols = "Species", before = "Sepal.Width"))
head(data_relocate(iris, cols = "Sepal.Width", after = "Species"))
head(data_relocate(iris, cols = c("Species", "Petal.Length"), after = "Sepal.Width"))
}
