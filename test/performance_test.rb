require File.expand_path('test/test_helper')
require 'benchmark'

class PerformanceTest < Test::Unit::TestCase

  def setup
    Related.redis.flushall
  end

  def test_simple
    puts "Simple:"
    node = Related::Node.create
    time = Benchmark.measure do
      1000.times do
        n = Related::Node.create
        rel = Related::Relationship.create(:friends, node, n)
      end
    end
    puts time
    time = Benchmark.measure do
      node.outgoing(:friends).to_a
    end
    puts time
  end

  def test_with_attributes
    puts "With attributes:"
    node = Related::Node.create
    time = Benchmark.measure do
      1000.times do
        n = Related::Node.create(
          :title => 'Example title',
          :description => 'Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
          :status => 'archived',
          :length => 42.3,
          :enabled => true)
        rel = Related::Relationship.create(:friends, node, n, :weight => 2.5, :list => 'Co-workers')
      end
    end
    puts time
    time = Benchmark.measure do
      node.outgoing(:friends).to_a
    end
    puts time
  end

  def test_search
    puts "Search:"
    node = Related::Node.create
    time = Benchmark.measure do
      10.times do
        n = Related::Node.create
        rel = Related::Relationship.create(:friends, node, n)
        10.times do
          n2 = Related::Node.create
          rel2 = Related::Relationship.create(:friends, n, n2)
          10.times do
            n3 = Related::Node.create
            rel3 = Related::Relationship.create(:friends, n2, n3)
            10.times do
              n4 = Related::Node.create
              rel4 = Related::Relationship.create(:friends, n3, n4)
            end
          end
        end
      end
    end
    puts time
    time = Benchmark.measure do
      node.outgoing(:friends).path_to(Related::Node.create)
    end
    puts time
  end

end