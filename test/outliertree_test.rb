require_relative "test_helper"

class OutlierTreeTest < Minitest::Test
  def setup
    @train_data = nil
    @test_data = nil
  end

  def test_works
    model = OutlierTree.new
    model.fit(train_data)
    outliers = model.outliers(test_data)

    assert_equal 1, outliers.size

    outlier = outliers.first
    assert_equal 0, outlier[:index]
    assert_equal "numeric_col2 (-1000000.0) looks low", outlier[:explanation]
    assert_equal :numeric_col2, outlier[:column]
    assert_equal(-1000000, outlier[:value])
    assert_equal [], outlier[:conditions]
  end

  def test_rover
    require "rover"

    train_df = Rover::DataFrame.new(train_data)
    test_df = Rover::DataFrame.new(test_data)

    model = OutlierTree.new
    model.fit(train_df)
    outliers = model.outliers(test_df)

    assert_equal 1, outliers.size

    outlier = outliers.first
    assert_equal 0, outlier[:index]
    assert_equal "numeric_col2 (-1000000.0) looks low", outlier[:explanation]
    assert_equal "numeric_col2", outlier[:column]
    assert_equal(-1000000, outlier[:value])
    assert_equal [], outlier[:conditions]
  end

  def test_missing_values
    model = OutlierTree.new
    train_data[1][:numeric_col1] = nil
    train_data[3][:categ_col] = nil
    model.fit(train_data)
    outliers = model.outliers(test_data)
    assert_equal 1, outliers.size
  end

  def test_not_fit
    model = OutlierTree.new
    error = assert_raises do
      model.outliers(test_data)
    end
    assert_equal "Not fit", error.message
  end

  def test_predict_missing_column
    model = OutlierTree.new
    model.fit(train_data)
    test_data.each { |v| v.delete(:numeric_col2) }
    error = assert_raises(ArgumentError) do
      model.outliers(test_data)
    end
    assert_equal "Missing column: numeric_col2", error.message
  end

  def test_predict_unseen_value
    model = OutlierTree.new
    model.fit(train_data)
    test_data.last[:categ_col] = "categD"
    expected = "[outliertree] Unseen values in column: categ_col\n"
    assert_output(nil, expected) do
      model.outliers(test_data)
    end
  end

  def train_data
    @train_data ||= dataset("train")
  end

  def test_data
    @test_data ||= dataset("test")
  end

  def dataset(name)
    CSV.table("test/support/#{name}.csv").map(&:to_h)
  end
end
