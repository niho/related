require File.expand_path('test/test_helper')
require 'pp'

class CustomNodeTest < ActiveModel::TestCase

  class CustomNode
    include Related::Node::QueryMethods
    attr_accessor :id
    def self.flush
      @database = {}
    end
    def self.create
      n = self.new
      n.id = Related.generate_id
      @database ||= {}
      @database[n.id] = n
      n
    end
    def self.find(*ids)
      ids.pop if ids.size > 1 && ids.last.is_a?(Hash)
      ids.flatten.map do |id|
        @database[id]
      end
    end
    def to_s
      @id
    end
    protected
      def query
        Related::Node::Query.new(self)
      end
  end

  def setup
    Related.flushall
    CustomNode.flush
  end

  def test_property_conversion
    node1 = CustomNode.create
    node2 = CustomNode.create
    Related::Relationship.create(:friend, node1, node2)
    assert_equal [node2], node1.shortest_path_to(node2).outgoing(:friend).nodes.to_a
  end

end
