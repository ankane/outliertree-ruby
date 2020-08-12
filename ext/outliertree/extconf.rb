require "mkmf-rice"

$CXXFLAGS += " -std=c++11"

apple_clang = RbConfig::CONFIG["CC_VERSION_MESSAGE"] =~ /apple clang/i

# check omp first
if have_library("omp") || have_library("gomp")
  $CXXFLAGS += " -Xclang" if apple_clang
  $CXXFLAGS += " -fopenmp"
end

ext = File.expand_path(".", __dir__)
outliertree = File.expand_path("../../vendor/outliertree/src", __dir__)

exclude = %w(Rwrapper.cpp RcppExports.cpp)
$srcs = Dir["{#{ext},#{outliertree}}/*.{cc,cpp}"].reject { |f| exclude.include?(File.basename(f)) }
$INCFLAGS += " -I#{outliertree}"
$VPATH << outliertree

create_makefile("outliertree/ext")
