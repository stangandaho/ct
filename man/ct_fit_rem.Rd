% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/rem_density.R
\name{ct_fit_rem}
\alias{ct_fit_rem}
\title{Fit Random Encounter Model (REM)}
\usage{
ct_fit_rem(
  data,
  traprate_data,
  radius_model = NULL,
  angle_model = NULL,
  speed_model = NULL,
  activity_model = NULL,
  strata = NULL,
  time_of_day,
  n_bootstrap = 1000
)
}
\arguments{
\item{data}{A data frame of observations, including distance, angle, speed, and time-of-day (in radians).}

\item{traprate_data}{A data frame created by \code{\link[=ct_traprate_data]{ct_traprate_data()}}.}

\item{radius_model}{Optional. A detection function model for radius (distance) fitted using \code{\link[=ct_fit_detmodel]{ct_fit_detmodel()}}.}

\item{angle_model}{Optional. A detection function model for angle fitted using \code{\link[=ct_fit_detmodel]{ct_fit_detmodel()}}.}

\item{speed_model}{Optional. A model for movement speed fitted using \code{\link[=ct_fit_speedmodel]{ct_fit_speedmodel()}}.}

\item{activity_model}{Optional. An activity model fitted with \code{\link[activity:fitact]{activity::fitact()}}.}

\item{strata}{Optional. A data frame of stratification information with columns \code{stratumID} and \code{area}.}

\item{time_of_day}{The column name (unquoted or as a string) representing time-of-day in radians.}

\item{n_bootstrap}{Number of bootstrap replicates for uncertainty estimation. Default is 1000.}
}
\value{
A data frame with columns:
\itemize{
\item \code{parameters}: Model parameter name
\item \code{estimate}: Estimated value
\item \code{se}: Standard error
\item \code{cv}: Coefficient of variation
\item \code{lower_ci}: Lower bound of 95\% confidence interval
\item \code{upper_ci}: Upper bound of 95\% confidence interval
}
}
\description{
Fits a random encounter model using observed data and trap rate information.
Automatically estimates detection radius, detection angle, animal speed, and
activity pattern models if not provided.
}
\examples{
data("ctdp")
deployments <- ctdp$data$deployments
observations <- ctdp$data$observations \%>\%
  dplyr::filter(scientificName == "Vulpes vulpes") \%>\%
  # Add time of day
  dplyr::mutate(time_of_day = ct_to_radian(times = timestamp))

# Prepare trap rate data
trap_rate <- ct_traprate_data(observation_data = observations,
                              deployment_data = deployments,
                              deployment_column = deploymentID,
                              datetime_column = timestamp,
                              start = start, end = 'end'
)


# Fit REM
ct_fit_rem(data = observations,
           traprate_data = trap_rate,
           time_of_day = time_of_day)

}
\seealso{
\code{\link[=ct_fit_speedmodel]{ct_fit_speedmodel()}}, \code{\link[=ct_fit_detmodel]{ct_fit_detmodel()}}, \code{\link[=ct_fit_activity]{ct_fit_activity()}}
}
