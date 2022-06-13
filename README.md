# OutlierTree Ruby

:deciduous_tree: [OutlierTree](https://github.com/david-cortes/outliertree) - explainable outlier/anomaly detection - for Ruby

Produces human-readable explanations for why values are detected as outliers

```txt
Price (2.50) looks low given Department is Books and Sale is false
```

:evergreen_tree: Check out [IsoTree](https://github.com/ankane/isotree-ruby) for an alternative approach that uses Isolation Forest

[![Build Status](https://github.com/ankane/outliertree-ruby/workflows/build/badge.svg?branch=master)](https://github.com/ankane/outliertree-ruby/actions)

## Installation

Add this line to your application’s Gemfile:

```ruby
gem "outliertree"
```

## Getting Started

Prep your data

```ruby
data = [
  {department: "Books",  sale: false, price: 2.50},
  {department: "Books",  sale: true,  price: 3.00},
  {department: "Movies", sale: false, price: 5.00},
  # ...
]
```

Train a model

```ruby
model = OutlierTree.new
model.fit(data)
```

Get outliers

```ruby
model.outliers(data)
```

## Parameters

Pass parameters - default values below

```ruby
OutlierTree.new(
  max_depth: 4,
  min_gain: 0.01,
  z_norm: 2.67,
  z_outlier: 8.0,
  pct_outliers: 0.01,
  min_size_numeric: 25,
  min_size_categ: 50,
  categ_split: "binarize",
  categ_outliers: "tail",
  numeric_split: "raw",
  follow_all: false,
  gain_as_pct: true,
  nthreads: -1
)
```

See a [detailed explanation](https://outliertree.readthedocs.io/en/latest/#outliertree.OutlierTree)

## Data

Data can be an array of hashes

```ruby
[
  {department: "Books",  sale: false, price: 2.50},
  {department: "Books",  sale: true,  price: 3.00},
  {department: "Movies", sale: false, price: 5.00}
]
```

Or a Rover data frame

```ruby
Rover.read_csv("data.csv")
```

## Performance

OutlierTree uses OpenMP when possible for best performance. To enable OpenMP on Mac, run:

```sh
brew install libomp
```

Then reinstall the gem.

```sh
gem uninstall outliertree --force
bundle install
```

## Resources

- [Explainable outlier detection through decision tree conditioning](https://arxiv.org/pdf/2001.00636.pdf)

## History

View the [changelog](https://github.com/ankane/outliertree-ruby/blob/master/CHANGELOG.md)

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/ankane/outliertree-ruby/issues)
- Fix bugs and [submit pull requests](https://github.com/ankane/outliertree-ruby/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features

To get started with development:

```sh
git clone --recursive https://github.com/ankane/outliertree-ruby.git
cd outliertree-ruby
bundle install
bundle exec rake compile
bundle exec rake test
```
