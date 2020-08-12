module OutlierTree
  class Dataset
    attr_reader :numeric_columns, :categorical_columns

    def initialize(data)
      @data = data

      if defined?(Rover::DataFrame) && data.is_a?(Rover::DataFrame)
        @vectors = data.vectors
        @numeric_columns, @categorical_columns = data.keys.partition { |k, v| ![:object, :bool].include?(data[k].type) }
      else
        @vectors = {}
        raise ArgumentError, "Array elements must be hashes" unless data.all? { |d| d.is_a?(Hash) }
        keys = data.flat_map(&:keys).uniq
        keys.each do |k|
          @vectors[k] = []
        end
        data.each do |d|
          keys.each do |k|
            @vectors[k] << d[k]
          end
        end
        @numeric_columns, @categorical_columns = keys.partition { |k| @vectors[k].all? { |v| v.nil? || v.is_a?(Numeric) } }
      end
    end

    def [](k)
      @vectors[k]
    end

    def size
      @vectors.any? ? @vectors.values.first.size : 0
    end
  end
end
