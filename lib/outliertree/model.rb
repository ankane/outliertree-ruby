module OutlierTree
  class Model
    def initialize(
      max_depth: 4, min_gain: 0.01, z_norm: 2.67, z_outlier: 8.0, pct_outliers: 0.01,
      min_size_numeric: 25, min_size_categ: 50, categ_split: "binarize", categ_outliers: "tail",
      numeric_split: "raw", follow_all: false, gain_as_pct: true, nthreads: -1
    )

      # TODO validate values
      @max_depth = max_depth
      @min_gain = min_gain
      @z_norm = z_norm
      @z_outlier = z_outlier
      @pct_outliers = pct_outliers
      @min_size_numeric = min_size_numeric
      @min_size_categ = min_size_categ
      @categ_split = categ_split
      @categ_outliers = categ_outliers
      @numeric_split = numeric_split
      @follow_all = follow_all
      @gain_as_pct = gain_as_pct

      # etc module returns virtual cores
      nthreads = Etc.nprocessors if nthreads < 0
      @nthreads = nthreads
    end

    def fit(df)
      df = Dataset.new(df)
      prep_fit(df)
      options = data_options(df).merge(fit_options)
      @model_outputs = Ext.fit_outliers_models(options)
    end

    def outliers(df)
      raise "Not fit" unless @model_outputs

      df = Dataset.new(df)
      prep_predict(df)
      options = data_options(df).merge(nthreads: @nthreads)
      model_outputs = Ext.find_new_outliers(@model_outputs, options)

      Result.new(
        model_outputs: model_outputs,
        df: df,
        numeric_columns: @numeric_columns,
        categorical_columns: @categorical_columns,
        categories: @categories
      ).process
    end

    private

    def prep_fit(df)
      @numeric_columns = df.numeric_columns
      @categorical_columns = df.categorical_columns
      @categories = {}
      @categorical_columns.each do |k|
        @categories[k] = df[k].uniq.to_a.compact.map.with_index.to_h
      end
    end

    def prep_predict(df)
      # TODO handle column type mismatches
      (@numeric_columns + @categorical_columns).each do |k|
        raise ArgumentError, "Missing column: #{k}" unless df[k]
      end
    end

    def data_options(df)
      options = {}

      # numeric
      numeric_data = String.new
      @numeric_columns.each do |k|
        # more efficient for Rover
        numeric_data << (df[k].respond_to?(:to_numo) ? df[k].to_numo.cast_to(Numo::DFloat).to_binary : df[k].pack("d*"))
      end
      options[:numeric_data] = numeric_data
      options[:ncols_numeric] = @numeric_columns.size

      # categorical
      categorical_data = String.new
      ncat = String.new
      @categorical_columns.each do |k|
        categories = @categories[k]
        # for unseen values, set to categories.size
        categories_size = categories.size
        values = df[k].map { |v| v.nil? ? -1 : (categories[v] || categories_size) }
        # TODO make more efficient
        if values.any? { |v| v == categories_size }
          warn "[outliertree] Unseen values in column: #{k}"
        end
        # more efficient for Rover
        categorical_data << (values.respond_to?(:to_numo) ? values.to_numo.cast_to(Numo::Int32).to_binary : values.pack("i*"))
        ncat << [categories.size].pack("i")
      end
      options[:categorical_data] = categorical_data
      options[:ncols_categ] = @categorical_columns.size
      options[:ncat] = ncat

      # not supported yet
      options[:ordinal_data] = nil
      options[:ncols_ord] = 0
      options[:ncat_ord] = nil

      options[:nrows] = df.size
      options
    end

    def fit_options
      keys = %i(
        max_depth min_gain z_norm z_outlier pct_outliers
        min_size_numeric min_size_categ follow_all gain_as_pct nthreads
      )
      options = {}
      keys.each do |k|
        options[k] = instance_variable_get("@#{k}")
      end
      options[:categ_as_bin] = @categ_split == "binarize"
      options[:ord_as_bin] = @categ_split == "binarize"
      options[:cat_bruteforce_subset] = @categ_split == "bruteforce"
      options[:categ_from_maj] = @categ_outliers == "majority"
      options[:take_mid] = @numeric_split == "mid"
      options
    end
  end
end
