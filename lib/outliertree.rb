# ext
require "outliertree/ext"

# stdlib
require "etc"

# modules
require_relative "outliertree/dataset"
require_relative "outliertree/model"
require_relative "outliertree/result"
require_relative "outliertree/version"

module OutlierTree
  def self.new(**options)
    Model.new(**options)
  end
end
