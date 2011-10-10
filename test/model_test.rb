require File.expand_path('test/test_helper')

class ModelTest < ActiveModel::TestCase

  class Event < Related::Node
    property :attending_count, Integer
    property :popularity, Float
    property :start_date, DateTime
    property :end_date, DateTime
    property :location do |value|
      "http://maps.google.com/maps?q=#{value}"
    end
  end

  class Like < Related::Relationship
    weight do |dir|
      dir == :in ? in_score : out_score
    end
  end

  def setup
    Related.redis.flushall
  end

  def test_property_conversion
    event = Event.create(
      :attending_count => 42,
      :popularity => 0.9,
      :start_date => Time.parse('2011-01-01'),
      :location => 'Stockholm')
    event = Event.find(event.id)
    assert_equal 42, event.attending_count
    assert_equal 0.9, event.popularity
    assert_equal Time.parse('2011-01-01'), event.start_date
    assert_equal Time.parse('2011-01-01').iso8601, event.read_attribute(:start_date)
    assert_equal nil, event.end_date
    assert_equal "http://maps.google.com/maps?q=Stockholm", event.location
    assert event.as_json.has_key?('end_date')
  end

  def test_model_factory
    e1 = Event.create(:popularity => 0.0)
    e2 = Event.create(:popularity => 1.0)
    e1, e2 = Related::Node.find(e1.id, e2.id, :model =>
      lambda {|attributes| attributes['popularity'].to_f > 0.5 ? Event : Related::Node })
    assert_equal Related::Node, e1.class
    assert_equal Event, e2.class

    Related::Relationship.create(:test, e1, e2)
    nodes = e1.outgoing(:test).nodes.options(:model =>
      lambda {|attributes| attributes['popularity'].to_f > 0.5 ? Event : Related::Node }).to_a
    assert_equal Event, nodes.first.class
  end

  def test_custom_weight
    node1 = Related::Node.create
    node2 = Related::Node.create
    like = Like.create(:like, node1, node2, :in_score => 42, :out_score => 10)
    assert_equal 42, like.weight(:in)
    assert_equal 10, like.weight(:out)
    like.in_score = 50
    like.save
    assert_equal 50, like.weight(:in)
    assert_equal 10, like.weight(:out)
  end

  def test_weight_sorting
    node1 = Related::Node.create
    node2 = Related::Node.create
    node3 = Related::Node.create
    rel1 = Like.create(:like, node1, node2, :in_score => 1, :out_score => 1)
    rel2 = Like.create(:like, node1, node3, :in_score => 2, :out_score => 2)
    rel3 = Like.create(:like, node2, node1, :in_score => 1, :out_score => 1)
    rel4 = Like.create(:like, node3, node1, :in_score => 2, :out_score => 2)
    assert_equal [rel2,rel1], node1.outgoing(:like).relationships.options(:model => lambda { Like }).to_a
    assert_equal [rel4,rel3], node1.incoming(:like).relationships.options(:model => lambda { Like }).to_a
    assert_equal [rel1], node1.outgoing(:like).relationships.options(:model => lambda { Like }).per_page(2).page(rel2).to_a
    assert_equal [rel3], node1.incoming(:like).relationships.options(:model => lambda { Like }).per_page(2).page(rel4).to_a
  end

end
