#' Run App
#'
#' Launch ct GUI for image/video management
#'
#' @export
#'
#'
ct_app <- function() {

  source(paste0(system.file("app", package = "ct"), "/packages.R"))
  app_dir <- system.file("app", package = "ct")
  shiny::runApp(appDir = app_dir)
}




