#include <Rcpp.h>
using namespace Rcpp;

// Helper function to get column types from all data frames
std::map<std::string, SEXPTYPE> get_column_types(List df_list, CharacterVector all_names) {
  std::map<std::string, SEXPTYPE> col_types;

  for (int i = 0; i < df_list.size(); ++i) {
    DataFrame df = as<DataFrame>(df_list[i]);
    CharacterVector names = df.names();

    for (int j = 0; j < names.size(); ++j) {
      std::string colname = as<std::string>(names[j]);
      // Only set type if not already determined
      if (col_types.find(colname) == col_types.end()) {
        col_types[colname] = TYPEOF(df[j]);
      }
    }
  }

  return col_types;
}

// [[Rcpp::export]]
List stack_list(List df_list) {
  // Check if input is a list
  if (!df_list.isNULL() && !Rf_isVectorList(df_list)) {
    stop("Input should be a plain list of dataframe items to be stacked");
  }

  // Get all unique column names from all data frames
  CharacterVector all_names;
  for (int i = 0; i < df_list.size(); ++i) {
    if (!Rf_isFrame(df_list[i])) {
      stop("All list elements must be data frames");
    }
    DataFrame df = as<DataFrame>(df_list[i]);
    CharacterVector names = df.names();
    all_names = union_(all_names, names);
  }

  // Get column types from their first appearance
  std::map<std::string, SEXPTYPE> col_types = get_column_types(df_list, all_names);

  // Prepare a list to hold all processed data frames
  List processed_dfs(df_list.size());

  for (int i = 0; i < df_list.size(); ++i) {
    DataFrame df = as<DataFrame>(df_list[i]);
    int nrows = df.nrows();

    // Create a new data frame with all columns
    List new_df(all_names.size());
    new_df.attr("names") = all_names;

    // Fill each column
    for (int j = 0; j < all_names.size(); ++j) {
      std::string colname = as<std::string>(all_names[j]);

      if (df.containsElementNamed(colname.c_str())) {
        // Column exists in original df - copy it
        new_df[j] = df[colname];
      } else {
        // Column doesn't exist - fill with NAs of correct type
        SEXPTYPE col_type = col_types[colname];

        if (nrows > 0) {
          switch(col_type) {
          case INTSXP: {
            IntegerVector na_col(nrows, NA_INTEGER);
            new_df[j] = na_col;
            break;
          }
          case REALSXP: {
            NumericVector na_col(nrows, NA_REAL);
            new_df[j] = na_col;
            break;
          }
          case STRSXP: {
            CharacterVector na_col(nrows, NA_STRING);
            new_df[j] = na_col;
            break;
          }
          case LGLSXP: {
            LogicalVector na_col(nrows, NA_LOGICAL);
            new_df[j] = na_col;
            break;
          }
          default: {
            NumericVector na_col(nrows, NA_REAL);
            new_df[j] = na_col;
          }
          }
        } else {
          // Empty data frame - create empty column of correct type
          switch(col_type) {
          case INTSXP: new_df[j] = IntegerVector(0); break;
          case REALSXP: new_df[j] = NumericVector(0); break;
          case STRSXP: new_df[j] = CharacterVector(0); break;
          case LGLSXP: new_df[j] = LogicalVector(0); break;
          default: new_df[j] = NumericVector(0);
          }
        }
      }
    }

    processed_dfs[i] = new_df;
  }

  return processed_dfs;
}
