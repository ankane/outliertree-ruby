#include <complex>
#include <vector>

// outliertree
#include <outlier_tree.hpp>

// rice
#include <rice/rice.hpp>
#include <rice/stl.hpp>

using Rice::Array;
using Rice::Hash;
using Rice::Object;
using Rice::String;
using Rice::Symbol;

namespace Rice::detail {
  template<typename T>
  class To_Ruby<std::vector<T>> {
  public:
    To_Ruby() = default;

    explicit To_Ruby(Arg* arg) : arg_(arg) { }

    VALUE convert(std::vector<T> const & x) {
      auto a = rb_ary_new2(x.size());
      for (const auto& v : x) {
        rb_ary_push(a, To_Ruby<T>().convert(v));
      }
      return a;
    }

  private:
    Arg* arg_ = nullptr;
  };

  template<>
  class To_Ruby<std::vector<signed char>> {
  public:
    To_Ruby() = default;

    explicit To_Ruby(Arg* arg) : arg_(arg) { }

    VALUE convert(std::vector<signed char> const & x) {
      auto a = rb_ary_new2(x.size());
      for (const auto& v : x) {
        rb_ary_push(a, To_Ruby<signed char>().convert(v));
      }
      return a;
    }

  private:
    Arg* arg_ = nullptr;
  };

  template<>
  struct Type<std::vector<signed char>> {
    static bool verify() {
      return true;
    }
  };

  template<>
  struct Type<ColType> {
    static bool verify() {
      return true;
    }
  };

  template<>
  class To_Ruby<ColType> {
  public:
    To_Ruby() = default;

    explicit To_Ruby(Arg* arg) : arg_(arg) { }

    VALUE convert(ColType const & x) {
      switch (x) {
        case Numeric: return Symbol("numeric");
        case Categorical: return Symbol("categorical");
        case Ordinal: return Symbol("ordinal");
        case NoType: return Symbol("no_type");
      }
      throw std::runtime_error("Unknown column type");
    }

  private:
    Arg* arg_ = nullptr;
  };

  template<>
  struct Type<SplitType> {
    static bool verify() {
      return true;
    }
  };

  template<>
  class To_Ruby<SplitType> {
  public:
    To_Ruby() = default;

    explicit To_Ruby(Arg* arg) : arg_(arg) { }

    VALUE convert(SplitType const & x) {
      switch (x) {
        case LessOrEqual: return Symbol("less_or_equal");
        case Greater: return Symbol("greater");
        case Equal: return Symbol("equal");
        case NotEqual: return Symbol("not_equal");
        case InSubset: return Symbol("in_subset");
        case NotInSubset: return Symbol("not_in_subset");
        case SingleCateg: return Symbol("single_categ");
        case SubTrees: return Symbol("sub_trees");
        case IsNa: return Symbol("is_na");
        case Root: return Symbol("root");
      }
      throw std::runtime_error("Unknown split type");
    }

  private:
    Arg* arg_ = nullptr;
  };
} // namespace Rice::detail

extern "C"
void Init_ext() {
  Rice::Module rb_mOutlierTree = Rice::define_module("OutlierTree");
  Rice::Module rb_mExt = Rice::define_module_under(rb_mOutlierTree, "Ext");

  Rice::define_class_under<Cluster>(rb_mExt, "Cluster")
    .define_method("upper_lim", [](Cluster& self) { return self.upper_lim; })
    .define_method("display_lim_high", [](Cluster& self) { return self.display_lim_high; })
    .define_method("perc_below", [](Cluster& self) { return self.perc_below; })
    .define_method("display_lim_low", [](Cluster& self) { return self.display_lim_low; })
    .define_method("perc_above", [](Cluster& self) { return self.perc_above; })
    .define_method("display_mean", [](Cluster& self) { return self.display_mean; })
    .define_method("display_sd", [](Cluster& self) { return self.display_sd; })
    .define_method("cluster_size", [](Cluster& self) { return self.cluster_size; })
    .define_method("split_point", [](Cluster& self) { return self.split_point; })
    .define_method("split_subset", [](Cluster& self) { return self.split_subset; })
    .define_method("split_lev", [](Cluster& self) { return self.split_lev; })
    .define_method("split_type", [](Cluster& self) { return self.split_type; })
    .define_method("column_type", [](Cluster& self) { return self.column_type; })
    .define_method("has_na_branch", [](Cluster& self) { return self.has_NA_branch; })
    .define_method("col_num", [](Cluster& self) { return self.col_num; });

  Rice::define_class_under<ClusterTree>(rb_mExt, "ClusterTree")
    .define_method("parent_branch", [](ClusterTree& self) { return self.parent_branch; })
    .define_method("parent", [](ClusterTree& self) { return self.parent; })
    .define_method("all_branches", [](ClusterTree& self) { return self.all_branches; })
    .define_method("column_type", [](ClusterTree& self) { return self.column_type; })
    .define_method("col_num", [](ClusterTree& self) { return self.col_num; })
    .define_method("split_point", [](ClusterTree& self) { return self.split_point; })
    .define_method("split_subset", [](ClusterTree& self) { return self.split_subset; })
    .define_method("split_lev", [](ClusterTree& self) { return self.split_lev; });

  Rice::define_class_under<ModelOutputs>(rb_mExt, "ModelOutputs")
    .define_method("outlier_scores_final", [](ModelOutputs& self) { return self.outlier_scores_final; })
    .define_method("outlier_columns_final", [](ModelOutputs& self) { return self.outlier_columns_final; })
    .define_method("outlier_clusters_final", [](ModelOutputs& self) { return self.outlier_clusters_final; })
    .define_method("outlier_trees_final", [](ModelOutputs& self) { return self.outlier_trees_final; })
    .define_method("outlier_depth_final", [](ModelOutputs& self) { return self.outlier_depth_final; })
    .define_method("outlier_decimals_distr", [](ModelOutputs& self) { return self.outlier_decimals_distr; })
    .define_method("min_decimals_col", [](ModelOutputs& self) { return self.min_decimals_col; })
    .define_method(
      "all_clusters",
      [](ModelOutputs& self, size_t i, size_t j) {
        return self.all_clusters[i][j];
      })
    .define_method(
      "all_trees",
      [](ModelOutputs& self, size_t i, size_t j) {
        return self.all_trees[i][j];
      });

  rb_mExt
    .define_singleton_function(
      "fit_outliers_models",
      [](Hash options) {
        ModelOutputs model_outputs;

        // data
        size_t nrows = options.get<size_t, Symbol>("nrows");
        size_t ncols_numeric = options.get<size_t, Symbol>("ncols_numeric");
        size_t ncols_categ = options.get<size_t, Symbol>("ncols_categ");
        size_t ncols_ord = options.get<size_t, Symbol>("ncols_ord");

        double *restrict numeric_data = NULL;
        if (ncols_numeric > 0) {
          numeric_data = (double*) options.get<String, Symbol>("numeric_data").c_str();
        }

        int *restrict categorical_data = NULL;
        int *restrict ncat = NULL;
        if (ncols_categ > 0) {
          categorical_data = (int*) options.get<String, Symbol>("categorical_data").c_str();
          ncat = (int*) options.get<String, Symbol>("ncat").c_str();
        }

        int *restrict ordinal_data = NULL;
        int *restrict ncat_ord = NULL;
        if (ncols_ord > 0) {
          ordinal_data = (int*) options.get<String, Symbol>("ordinal_data").c_str();
          ncat_ord = (int*) options.get<String, Symbol>("ncat_ord").c_str();
        }

        // options
        char *restrict cols_ignore = NULL;
        int nthreads = options.get<int, Symbol>("nthreads");
        bool categ_as_bin = options.get<bool, Symbol>("categ_as_bin");
        bool ord_as_bin = options.get<bool, Symbol>("ord_as_bin");
        bool cat_bruteforce_subset = options.get<bool, Symbol>("cat_bruteforce_subset");
        bool categ_from_maj = options.get<bool, Symbol>("categ_from_maj");
        bool take_mid = options.get<bool, Symbol>("take_mid");
        size_t max_depth = options.get<size_t, Symbol>("max_depth");
        double max_perc_outliers = options.get<double, Symbol>("pct_outliers");
        size_t min_size_numeric = options.get<size_t, Symbol>("min_size_numeric");
        size_t min_size_categ = options.get<size_t, Symbol>("min_size_categ");
        double min_gain = options.get<double, Symbol>("min_gain");
        bool gain_as_pct = options.get<bool, Symbol>("gain_as_pct");
        bool follow_all = options.get<bool, Symbol>("follow_all");
        double z_norm = options.get<double, Symbol>("z_norm");
        double z_outlier = options.get<double, Symbol>("z_outlier");

        fit_outliers_models(
          model_outputs,
          numeric_data,
          ncols_numeric,
          categorical_data,
          ncols_categ,
          ncat,
          ordinal_data,
          ncols_ord,
          ncat_ord,
          nrows,
          cols_ignore,
          nthreads,
          categ_as_bin,
          ord_as_bin,
          cat_bruteforce_subset,
          categ_from_maj,
          take_mid,
          max_depth,
          max_perc_outliers,
          min_size_numeric,
          min_size_categ,
          min_gain,
          gain_as_pct,
          follow_all,
          z_norm,
          z_outlier
        );
        return model_outputs;
      })
    .define_singleton_function(
      "find_new_outliers",
      [](ModelOutputs& model_outputs, Hash options) {
        // data
        size_t nrows = options.get<size_t, Symbol>("nrows");
        size_t ncols_numeric = options.get<size_t, Symbol>("ncols_numeric");
        size_t ncols_categ = options.get<size_t, Symbol>("ncols_categ");
        size_t ncols_ord = options.get<size_t, Symbol>("ncols_ord");

        double *restrict numeric_data = NULL;
        if (ncols_numeric > 0) {
          numeric_data = (double*) options.get<String, Symbol>("numeric_data").c_str();
        }

        int *restrict categorical_data = NULL;
        if (ncols_categ > 0) {
          categorical_data = (int*) options.get<String, Symbol>("categorical_data").c_str();
        }

        int *restrict ordinal_data = NULL;
        if (ncols_ord > 0) {
          ordinal_data = (int*) options.get<String, Symbol>("ordinal_data").c_str();
        }

        // options
        int nthreads = options.get<int, Symbol>("nthreads");

        find_new_outliers(
          numeric_data,
          categorical_data,
          ordinal_data,
          nrows,
          nthreads,
          model_outputs
        );

        return model_outputs;
      });
}
