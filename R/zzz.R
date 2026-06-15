utils::globalVariables(c(
  # Column names
  "datetime", "period_start", "period_end", "common_name", "sel",
  "Variable", "Group", "Prop", "N", "distance", "speed",
  ".data", ".start", ".end", "event", "deltatime", "deployment",
  "first_record", "x", "y", "yA", "yB", "value", "Var1", "Var2",
  "ori_freq", "day_time", "radian", "geometry", "Polygon", "grid_area",
  ".", "Time", "Density", "Period", "n", "site", "species",
  "n_records", "total_duration",
  "QAIC", "best", "combn", "criteria", "id", "key", "model", "nadj2",
  "scientific_name", "min_date", "max_date",
  ### -----> spaceNtime
  "area", "occ", "cam", "dens_ij", "D", "SE", "int", "occ_int",
  "chk", "overlap", "d", "m", "nearest", "STE", "TTE", "censor",
  "wthn", "allgood", "timefromfirst",
  ### -----> REST / RAD-REST
  # Posterior-summary column names produced by MCMCvis
  "2.5%", "50%", "97.5%",
  # Symbols inside the von Mises mixture nimbleCode (activity model)
  "C", "stick_breaking", "v", "dvonMises", "act_data", "act_data_pred",
  "mu_mix", "kappa_mix", "group", "ndens", "dens.x"
))
