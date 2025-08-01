% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ct_plot_camtrap_activity.R
\name{ct_plot_camtrap_activity}
\alias{ct_plot_camtrap_activity}
\title{Plot camera trap activity over time}
\usage{
ct_plot_camtrap_activity(
  data,
  deployment_column,
  datetime_column,
  threshold = 5,
  time_unit = "days",
  format = NULL,
  activity_style = list(width = 0.8, color = "steelblue", alpha = 0.7, linetype = 1),
  break_style = list(width = 0.8, color = "#c90026", alpha = 0.9, linetype = 1),
  show_gaps = TRUE,
  ylabel_format = "\%Y-\%m-\%d",
  ybreak = paste(1, time_unit)
)
}
\arguments{
\item{data}{A data frame containing the datetime column.}

\item{deployment_column}{Column name (unquoted) that identifies the deployment or camera ID.}

\item{datetime_column}{The datetime column.}

\item{threshold}{A numeric value indicating the minimum gap to be considered a break (default is 10).}

\item{time_unit}{The unit for the threshold. Supported values include "secs", "mins", "hours", "days", and "weeks".}

\item{format}{Optional. A character string specifying the datetime format, passed to \code{as.POSIXlt}.}

\item{activity_style}{A list controlling the appearance of active periods. Can include:
\itemize{
\item \code{linewidth}: Line width (default 0.8)
\item \code{color}: Color of activity bars (default \code{"steelblue"})
\item \code{alpha}: Transparency (default 0.7)
\item \code{linetype}: Line type (default 1)
}}

\item{break_style}{A list controlling the appearance of gaps/inactive periods. Can include:
\itemize{
\item \code{linewidth}: Line width (default 0.8)
\item \code{color}: Color of gap bars (default \code{"#c90026"})
\item \code{alpha}: Transparency (default 0.9)
\item \code{linetype}: Line type (default 1)
}}

\item{show_gaps}{Logical. If \code{TRUE} (default), shows vertical bars for detected gaps in deployment activity.}

\item{ylabel_format}{Character. Format for y-axis date-time labels. Default is \code{"\%Y-\%m-\%d"}.}

\item{ybreak}{Character. Spacing for y-axis breaks, e.g., \code{"1 days"} or \code{"12 hours"}. Default is based on \code{time_unit}.}
}
\value{
A \code{ggplot2} object showing periods of activity (and optionally gaps) for each deployment.
}
\description{
Visualizes the activity history of camera trap deployments to show periods of data capture.
It also optionally highlights periods of inactivity (break/gap).
}
\examples{
# Load example data and filter for one project
camtrap_data <- read.csv(ct:::table_files()[1]) \%>\%
  dplyr::filter(project == "Last")

# Plot with default styles
ct_plot_camtrap_activity(
  data = camtrap_data,
  deployment_column = camera,
  datetime_column = datetimes,
  threshold = 7,
  time_unit = "days"
)

#' # Customize plot appearance
ct_plot_camtrap_activity(
  data = camtrap_data,
  deployment_column = camera,
  datetime_column = "datetimes",
  threshold = 15,
  time_unit = "days",
  ybreak = "3 days",
  activity_style = list(width = 1.1, color = "gray10")
)+
  ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))
#'
}
