module OutlierTree
  class Result
    attr_reader :model_outputs, :df

    def initialize(model_outputs:, df:, numeric_columns:, categorical_columns:, categories:)
      @model_outputs = model_outputs
      @df = df
      @numeric_columns = numeric_columns
      @categorical_columns = categorical_columns
      @categories = categories
    end

    def process
      outliers = []
      model_outputs.outlier_scores_final.each_with_index do |score, row|
        if score < 1
          outl_col = model_outputs.outlier_columns_final[row]
          outl_clust = model_outputs.outlier_clusters_final[row]
          outl_tree = model_outputs.outlier_trees_final[row]

          # column and value
          if outl_col < @numeric_columns.size
            column = @numeric_columns[outl_col]
            value = df[column][row]
            _decimals = model_outputs.outlier_decimals_distr[row]
          else
            column = @categorical_columns[outl_col - @numeric_columns.size]
            value = df[column][row]
          end

          # group statistics
          group_statistics = {}
          if outl_col < @numeric_columns.size
            cluster = model_outputs.all_clusters(outl_col, outl_clust)
            if value >= cluster.upper_lim
              group_statistics[:upper_thr] = cluster.display_lim_high
              group_statistics[:pct_below] = cluster.perc_below
            else
              group_statistics[:lower_thr] = cluster.display_lim_low
              group_statistics[:pct_above] = cluster.perc_above
            end
            group_statistics[:mean] = cluster.display_mean
            group_statistics[:sd] = cluster.display_sd
            group_statistics[:n_obs] = cluster.cluster_size
          else
            # TODO categorical stats
          end

          # conditions
          conditions = []
          if cluster.column_type != :no_type
            conditions << add_condition(row, cluster.split_type, cluster)
          end

          # add conditions from tree branches
          curr_tree = outl_tree
          loop do
            break if curr_tree == 0

            tree = model_outputs.all_trees(outl_col, curr_tree)
            break if tree.parent_branch == :sub_trees

            parent_tree = tree.parent
            parent_cluster = model_outputs.all_trees(outl_col, parent_tree)

            if parent_cluster.all_branches.size > 0
              raise "Branch not supported yet. Please report an issue."
            else
              conditions << add_condition(row, tree.parent_branch, parent_cluster)
            end

            curr_tree = parent_tree
          end

          clean_conditions(conditions)

          outliers << {
            index: row,
            explanation: create_explanation(column, value, conditions, group_statistics),
            column: column,
            value: value,
            conditions: conditions,
            group_statistics: group_statistics
            # leave out for simplicity
            # score: score,
            # tree_depth: model_outputs.outlier_depth_final[row],
            # has_na_branch: model_outputs.all_clusters(outl_col, outl_clust).has_na_branch
          }
        end
      end
      outliers
    end

    private

    def add_condition(row, split_type, cluster)
      _coldecim = 0
      case cluster.column_type
      when :numeric
        cond_col = @numeric_columns[cluster.col_num]
        _coldecim = model_outputs.min_decimals_col[cluster.col_num]
      else
        cond_col = @categorical_columns[cluster.col_num]
      end
      colval = df[cond_col][row]

      case split_type
      when :greater, :less_or_equal
        colcond =  split_type == :greater ? ">" : "<="
        condval = cluster.split_point
      when :not_in_subset, :in_subset
        colcond = "in"
        condval = @categories[cond_col].keys.zip(cluster.split_subset)
        if split_type == :in_subset
          condval.select! { |k, v| v > 0 }
        else
          condval.select! { |k, v| v == 0 }
        end
        condval.map!(&:first)
      when :equal, :not_equal
        colcond = split_type == :equal ? "=" : "!="
        condval = @categories[cond_col].keys[cluster.split_lev]
      else
        raise "Split type not supported yet: #{split_type}. Please report an issue."
      end

      {
        column: cond_col,
        comparison: colcond,
        to: condval,
        value: colval
        # leave out for simplicity
        # decimals: coldecim
      }
    end

    # remove overlapping conditions
    # could be more efficient, but should be few conditions
    def clean_conditions(conditions)
      conditions.reject! do |condition|
        conditions.any? do |other|
          if condition[:column] == other[:column] && condition[:comparison] == other[:comparison]
            case condition[:comparison]
            when ">"
              # not <=
              condition[:to] < other[:to]
            when "<="
              condition[:to] > other[:to]
            end
          end
        end
      end
    end

    def create_explanation(column, value, conditions, group_statistics)
      explanation = String.new("#{column} (#{value}) ")

      looks =
        if group_statistics[:upper_thr]
          "high"
        elsif group_statistics[:lower_thr]
          "low"
        else
          "interesting"
        end
      explanation << "looks #{looks}"

      if conditions.any?
        explanation << " given"
        conditions.each_with_index do |condition, i|
          comparison = condition[:comparison] == "=" ? "is" : condition[:comparison]
          to = condition[:to]
          to = to.join(", ") if to.is_a?(Array)
          explanation << " #{condition[:column]} #{comparison} #{to}"

          # proper grammar
          if conditions.size > 1
            if i == conditions.size - 2
              explanation << " and"
            elsif i < conditions.size - 2
              explanation << ","
            end
          end
        end
      end

      explanation
    end
  end
end
