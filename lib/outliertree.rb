# ext
require "outliertree/ext"

# stdlib
require "etc"

# modules
require "outliertree/dataset"
require "outliertree/model"
require "outliertree/result"
require "outliertree/version"

module OutlierTree
  def self.new(**options)
    Model.new(**options)
  end
end
