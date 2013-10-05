require File.expand_path('test/test_helper')

class CustomIdAttribute < ActiveModel::TestCase

  class FakeThing < Related::Node
    property :id, Integer
    property :name, String
  end

  def setup
    Related.redis.flushall
  end

  def test_manually_set_id
    FakeThing.create(id: 42, name: "Bond, James Bond")

    found = FakeThing.find(42)

    assert_equal 42, found.id
    assert_equal "Bond, James Bond", found.name
  end

  def test_unique_ids
    FakeThing.create(id: 42, name: "Bond, James Bond")

    assert_raise Related::ValidationsFailed do
      FakeThing.create(id: 42, name: "Black Bears")
    end

    found = FakeThing.find(42)

    assert_equal 42, found.id
    assert_equal "Bond, James Bond", found.name
  end
end