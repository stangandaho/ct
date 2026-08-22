#' Plot overlap between two species' activity patterns
#'
#' This function visualizes the temporal overlap between two species' activity patterns based on time-of-day data.
#' It uses kernel density estimation to estimate activity densities and highlights areas of overlap between the two species.
#'
#' @param A A numeric vector of time-of-day observations (in radians, 0 to \eqn{2\pi}) for species A.
#' @param B A numeric vector of time-of-day observations (in radians, 0 to \eqn{2\pi}) for species B.
#' @param xscale A numeric value to scale the x-axis. Default is 24 for representing time in hours.
#' @param xcenter A string indicating the center of the x-axis. Options are `"noon"` (default) or `"midnight"`.
#' @param n_grid An integer specifying the number of grid points for density estimation. Default is 128.
#' @param kmax An integer indicating the maximum number of modes allowed in the activity pattern. Default is 3.
#' @param adjust A numeric value to adjust the bandwidth of the kernel density estimation. Default is 1.
#' @param overlap_color A string specifying the color of the overlap area. Default is `"gray40"`.
#' @param overlap_alpha A numeric value (0 to 1) for the transparency of the overlap area. Default is 0.8.
#' @param line_type A vector of integers specifying the line types for species A and B density lines. Default is `c(1, 2)`.
#' @param line_color A vector of strings specifying the colors of the density lines for species A and B. Default is `c("gray10", "gray0")`.
#' @param line_width A vector of numeric values specifying the line widths for species A and B density lines. Default is `c(1, 1)`.
#' @param species_names A character vector of length two giving the legend labels for species A and B.
#' @param legend_title A character string giving the density-line legend title.
#' @param overlap_only A logical value indicating whether to plot only the overlap region without individual density lines. Default is `FALSE`.
#' @param extend A string specifying the color of the extended area beyond the activity period. Default is `"lightgrey"`.
#' @param extend_alpha A numeric value (0 to 1) for the transparency of the extended area. Default is 0.8.
#'
#' @return A ggplot object representing the activity density curves and overlap between the two species.
#' If `overlap_only = TRUE`, only the overlap region is displayed.
#'
#'
#' @examples
#'   # Generate random data for two species
#'   set.seed(42)
#'   species_A <- runif(100, 0, 2 * pi)
#'   species_B <- runif(100, 0, 2 * pi)
#'
#'   # Plot overlap with default settings
#'   ct_plot_overlap(A = species_A, B = species_B)
#'
#'   # Customize plot with specific colors and line types
#'   ct_plot_overlap(A = species_A, B = species_B, overlap_color = "blue",
#'   line_color = c("red", "green"))
#'
#' @import ggplot2
#' @import overlap
#' @export
ct_plot_overlap <- function(A,
                            B,
                            xscale = 24,
                            xcenter = c("noon", "midnight"),
                            n_grid = 128,
                            kmax = 3,
                            adjust = 1,
                            overlap_color = "gray40",
                            overlap_alpha = 0.8,
                            line_type = c(1, 2),
                            line_color = c("gray10", "gray0"),
                            line_width = c(1, 1),
                            species_names = c("Species A", "Species B"),
                            legend_title = "Species",
                            overlap_only = FALSE,
                            extend = "lightgrey",
                            extend_alpha = 0.8
                        ) {

  suppressWarnings({

    # Input validation
    check_density_input(A)
    check_density_input(B)
    if (!is.character(species_names) || length(species_names) != 2) {
      cli::cli_abort("`species_names` must be a character vector of length 2.")
    }
    xcenter <- match.arg(xcenter)
    isMidnt <- xcenter == "midnight"

    # Bandwidth calculation
    bwA <- overlap::getBandWidth(A, kmax = kmax) / adjust
    bwB <- overlap::getBandWidth(B, kmax = kmax) / adjust
    if (is.na(bwA) || is.na(bwB)) cli::cli_abort("Bandwidth estimation failed.")

    # Create a sequence of values for density estimation
    xsc <- if (is.na(xscale)) 1 else xscale / (2 * pi)

    if (is.null(extend)) {
      xxRad  <- seq(0, 2 * pi, length.out = n_grid)
    } else {
      xxRad  <- seq(-pi/4, 9 * pi/4, length.out = n_grid)
    }

    if (isMidnt) xxRad  <- xxRad - pi

    xx <- xxRad * xsc

    # Density estimation
    densA <- overlap::densityFit(A, xxRad, bwA)/xsc
    densB <- overlap::densityFit(B, xxRad, bwB)/xsc
    densOL <- pmin(densA, densB)

    toPlot <- data.frame(x = xx , yA = densA, yB = densB)
    # Create polygon data for filled area (ensure it closes)
    poly_df <- rbind(
      data.frame(x = xx, y = densOL),
      data.frame(x = rev(xx), y = rep(0, length(densA)))
    )

    # Base ggplot object
    p <- ggplot2::ggplot(data = toPlot, ggplot2::aes(x = xx)) +
      ggplot2::geom_polygon(data = poly_df, mapping = ggplot2::aes(x = x, y = y),
                   color = NA, fill = overlap_color, alpha = overlap_alpha)+
      ggplot2::labs(x = "\nTime", y = "Density\n") +
      ggplot2::theme_minimal()+
      ggplot2::theme(
        axis.line = ggplot2::element_line(linewidth  = 0.5, color = "gray10"),
        axis.text = ggplot2::element_text(size = 12),
        axis.title = ggplot2::element_text(size = 14),
        axis.ticks = ggplot2::element_line(linewidth = 0.2, color = "gray10")
      )

    # Add density line
    if (length(line_width) == 1) {line_width <- c(line_width, line_width)}

    if (!overlap_only) {
      line_df <- rbind(
        data.frame(x = xx, y = densA, species = species_names[1]),
        data.frame(x = xx, y = densB, species = species_names[2])
      )
      line_df$species <- factor(line_df$species, levels = species_names)

      p <- p +
        ggplot2::geom_line(
          data = line_df,
          mapping = ggplot2::aes(x = x, y = y, color = species,
                                 linetype = species, linewidth = species)
        ) +
        ggplot2::scale_color_manual(
          name = legend_title,
          values = stats::setNames(line_color[1:2], species_names)
        ) +
        ggplot2::scale_linetype_manual(
          name = legend_title,
          values = stats::setNames(line_type[1:2], species_names)
        ) +
        ggplot2::scale_linewidth_manual(
          name = legend_title,
          values = stats::setNames(line_width[1:2], species_names)
        ) +
        ggplot2::guides(
          color = ggplot2::guide_legend(override.aes = list(linewidth = 1)),
          linewidth = "none"
        )
    }

    # Extend the plot if required
    if (!is.null(extend)) {
      if (isMidnt) {
        wrap <- c(-pi, pi) * xsc
      } else {
        wrap <- c(0, 2 * pi) * xsc
      }
      p <- p + ggplot2::annotate("rect", xmin = -Inf, xmax = wrap[1], ymin = -Inf, ymax = Inf,
                        fill = extend, alpha = extend_alpha) +
        ggplot2::annotate("rect", xmin = wrap[2], xmax = Inf, ymin = -Inf, ymax = Inf,
                 fill = extend, alpha = extend_alpha)+
        ggplot2::geom_polygon(data = poly_df, mapping = ggplot2::aes(x = x, y = y),
                              color = NA, fill = overlap_color, alpha = overlap_alpha)


      if (!overlap_only) {
        p <- p +
          ggplot2::geom_line(
            data = line_df,
            mapping = ggplot2::aes(x = x, y = y, color = species,
                                   linetype = species, linewidth = species),
            show.legend = FALSE
          )
      }

    }

    # Add axis customization
    # Customizing x-axis labels to show correct time, even for negative times
    p <- p +
      ggplot2::scale_x_continuous(
        breaks = if(xcenter == "noon"){seq(0, 24, 2)}else{seq(-12, 12, 2)},
        labels = function(x) {
          x <- ifelse(x < 0, 24 + x, x)
          hours <- floor(x)
          sprintf("%02d:00", hours %% 24)
        })


    return(p)

  })# suppress
}
