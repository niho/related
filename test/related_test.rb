require File.expand_path('test/test_helper')

class RelatedTest < MiniTest::Unit::TestCase

  def setup
    Related.flushall
  end

  def test_can_set_a_namespace_through_a_url_like_string
    assert Related.redis
    assert_equal :related, Related.redis.namespace
    old_redis = Related.redis
    Related.redis = 'localhost:9736/namespace'
    assert_equal 'namespace', Related.redis.namespace
    Related.redis = old_redis
  end

  def test_can_create_node
    assert Related::Node.create
  end

  def test_can_create_node_with_attributes
    node = Related::Node.create(:name => 'Example', :popularity => 12.3)
    assert node
    assert_equal 'Example', node.name
    assert_equal 12.3, node.popularity
  end

  def test_can_create_node_and_then_find_it_again_using_its_id
    node1 = Related::Node.create(:name => 'Example', :popularity => 12.3)
    node2 = Related::Node.find(node1.id)
    assert node2
    assert_equal node1.id, node2.id
    assert_equal 'Example', node2.name
    assert_equal '12.3', node2.popularity
  end

  def test_can_find_many_nodes_at_the_same_time
    node1 = Related::Node.create(:name => 'One')
    node2 = Related::Node.create(:name => 'Two')
    one, two = Related::Node.find(node1.id, node2.id)
    assert one
    assert two
  end

  def test_will_raise_exception_when_a_node_is_not_found
    assert_raises Related::NotFound do
      Related::Node.find('foo')
    end
    assert_raises Related::NotFound do
      Related::Node.find(nil)
    end
  end

  def test_can_update_node_with_new_attributes
    node1 = Related::Node.create(:name => 'Example', :popularity => 12.3)
    node1.description = 'Example description.'
    node1.save
    node2 = Related::Node.find(node1.id)
    assert_equal node1.description, node2.description
  end

  def test_two_nodes_with_the_same_id_should_be_equal
    assert_equal Related::Node.new.send(:load_attributes, 'test', {}), Related::Node.new.send(:load_attributes, 'test', {})
  end

  def test_can_find_a_node_and_only_load_specific_attributes
    node1 = Related::Node.create(:name => 'Example', :popularity => 12.3)
    node2 = Related::Node.find(node1.id, :fields => [:does_not_exist, :name])
    assert_equal node1.name, node2.name
    assert_nil node2.does_not_exist
    assert_nil node2.popularity
  end

  def test_can_find_multiple_nodes_and_only_load_specific_attributes
    node1 = Related::Node.create(:name => 'Example 1', :popularity => 12.3)
    node2 = Related::Node.create(:name => 'Example 2', :popularity => 42.5)
    n = Related::Node.find(node1.id, node2.id, :fields => [:does_not_exist, :name])
    assert_equal 2, n.size
    assert_equal 'Example 1', n.first.name
    assert_nil n.first.does_not_exist
    assert_nil n.first.popularity
    assert_equal 'Example 2', n.last.name
    assert_nil n.last.does_not_exist
    assert_nil n.last.popularity
  end

  def test_can_destroy_node
    node = Related::Node.create
    node.destroy
    assert_raises Related::NotFound do
      Related::Node.find(node.id)
    end
  end

  def test_can_create_a_relationship_between_two_nodes
    node1 = Related::Node.create(:name => 'One')
    node2 = Related::Node.create(:name => 'Two')
    rel = Related::Relationship.create(:friends, node1, node2)
    assert_equal [rel], node1.outgoing(:friends).relationships.to_a
    assert_equal [node2], node1.outgoing(:friends).to_a
    assert_equal [], node1.incoming(:friends).to_a
    assert_equal [node1], node2.incoming(:friends).to_a
    assert_equal [], node2.outgoing(:friends).to_a
  end

  def test_can_create_a_relationship_with_attributes
    node1 = Related::Node.create(:name => 'One')
    node2 = Related::Node.create(:name => 'Two')
    rel = Related::Relationship.create(:friends, node1, node2, :score => 2.5)
    rel = Related::Relationship.find(rel.id)
    assert_equal '2.5', rel.score
  end

  def test_can_delete_a_relationship
    node1 = Related::Node.create(:name => 'One')
    node2 = Related::Node.create(:name => 'Two')
    rel = Related::Relationship.create(:friends, node1, node2)
    rel.destroy
    assert_equal [], node1.outgoing(:friends).to_a
    assert_equal [], node1.incoming(:friends).to_a
    assert_equal [], node2.incoming(:friends).to_a
    assert_equal [], node2.outgoing(:friends).to_a
    assert_raises Related::NotFound do
      Related::Relationship.find(rel.id)
    end
  end

  def test_can_limit_the_number_of_nodes_returned_from_a_query
    node1 = Related::Node.create
    node2 = Related::Node.create
    node3 = Related::Node.create
    node4 = Related::Node.create
    node5 = Related::Node.create
    Related::Relationship.create(:friends, node1, node2)
    Related::Relationship.create(:friends, node1, node3)
    Related::Relationship.create(:friends, node1, node4)
    Related::Relationship.create(:friends, node1, node5)
    assert_equal 3, node1.outgoing(:friends).nodes.limit(3).to_a.size
    assert_equal 3, node1.outgoing(:friends).relationships.limit(3).to_a.size
  end

  def test_can_paginate_the_results_from_a_query
    node1 = Related::Node.create
    node2 = Related::Node.create
    node3 = Related::Node.create
    node4 = Related::Node.create
    node5 = Related::Node.create
    node6 = Related::Node.create
    rel1 = Related::Relationship.create(:friends, node1, node2, :name => 'rel1')
    sleep(1)
    rel2 = Related::Relationship.create(:friends, node1, node3, :name => 'rel2')
    sleep(1)
    rel3 = Related::Relationship.create(:friends, node1, node4, :name => 'rel3')
    sleep(1)
    rel4 = Related::Relationship.create(:friends, node1, node5, :name => 'rel4')
    sleep(1)
    rel5 = Related::Relationship.create(:friends, node1, node6, :name => 'rel5')
    assert_equal [rel5,rel4,rel3], node1.outgoing(:friends).per_page(3).page(1).to_a
    assert_equal [rel2,rel1], node1.outgoing(:friends).per_page(3).page(2).to_a
    assert_equal [rel5,rel4,rel3], node1.outgoing(:friends).per_page(3).page(nil).to_a
    assert_equal [rel4,rel3,rel2], node1.outgoing(:friends).per_page(3).page(rel5).to_a
    assert_equal [rel2,rel1], node1.outgoing(:friends).per_page(3).page(rel3).to_a
  end

  def test_can_count_the_number_of_related_nodes
    node1 = Related::Node.create
    node2 = Related::Node.create
    node3 = Related::Node.create
    node4 = Related::Node.create
    node5 = Related::Node.create
    rel1 = Related::Relationship.create(:friends, node1, node2)
    rel1 = Related::Relationship.create(:friends, node1, node3)
    rel1 = Related::Relationship.create(:friends, node1, node4)
    rel1 = Related::Relationship.create(:friends, node1, node5)
    assert_equal 4, node1.outgoing(:friends).nodes.count
    assert_equal 4, node1.outgoing(:friends).nodes.size
    assert_equal 3, node1.outgoing(:friends).nodes.limit(3).count
    assert_equal 4, node1.outgoing(:friends).nodes.limit(5).count
    assert_equal 4, node1.outgoing(:friends).relationships.count
    assert_equal 4, node1.outgoing(:friends).relationships.size
    assert_equal 3, node1.outgoing(:friends).relationships.limit(3).count
    assert_equal 4, node1.outgoing(:friends).relationships.limit(5).count
  end

  def test_can_find_path_between_two_nodes
    node1 = Related::Node.create
    node2 = Related::Node.create
    node3 = Related::Node.create
    node4 = Related::Node.create
    node5 = Related::Node.create
    node6 = Related::Node.create
    node7 = Related::Node.create
    node8 = Related::Node.create
    rel1 = Related::Relationship.create(:friends, node1, node2)
    rel1 = Related::Relationship.create(:friends, node2, node3)
    rel1 = Related::Relationship.create(:friends, node3, node2)
    rel1 = Related::Relationship.create(:friends, node3, node4)
    rel1 = Related::Relationship.create(:friends, node4, node5)
    rel1 = Related::Relationship.create(:friends, node5, node3)
    rel1 = Related::Relationship.create(:friends, node5, node8)
    rel1 = Related::Relationship.create(:friends, node2, node5)
    rel1 = Related::Relationship.create(:friends, node2, node6)
    rel1 = Related::Relationship.create(:friends, node6, node7)
    rel1 = Related::Relationship.create(:friends, node7, node8)
    assert_equal node8, node1.path_to(node8).outgoing(:friends).depth(5).to_a.last
    assert_equal node1, node1.path_to(node8).outgoing(:friends).depth(5).include_start_node.to_a.first
    assert_equal node1, node8.path_to(node1).incoming(:friends).depth(5).to_a.last
    assert_equal node8, node8.path_to(node1).incoming(:friends).depth(5).include_start_node.to_a.first
  end

  def test_can_find_shortest_path_between_two_nodes
    node1 = Related::Node.create
    node2 = Related::Node.create
    node3 = Related::Node.create
    node4 = Related::Node.create
    node5 = Related::Node.create
    node6 = Related::Node.create
    node7 = Related::Node.create
    node8 = Related::Node.create
    rel1 = Related::Relationship.create(:friends, node1, node2)
    rel1 = Related::Relationship.create(:friends, node2, node3)
    rel1 = Related::Relationship.create(:friends, node3, node2)
    rel1 = Related::Relationship.create(:friends, node3, node4)
    rel1 = Related::Relationship.create(:friends, node4, node5)
    rel1 = Related::Relationship.create(:friends, node5, node3)
    rel1 = Related::Relationship.create(:friends, node5, node8)
    rel1 = Related::Relationship.create(:friends, node2, node5)
    rel1 = Related::Relationship.create(:friends, node2, node6)
    rel1 = Related::Relationship.create(:friends, node6, node7)
    rel1 = Related::Relationship.create(:friends, node7, node8)
    assert_equal [node2,node5,node8], node1.shortest_path_to(node8).outgoing(:friends).depth(5).to_a
    assert_equal [node1,node2,node5,node8], node1.shortest_path_to(node8).outgoing(:friends).depth(5).include_start_node.to_a
  end

  def test_can_union
    node1 = Related::Node.create
    node2 = Related::Node.create
    node3 = Related::Node.create
    node4 = Related::Node.create
    Related::Relationship.create(:friends, node1, node3)
    Related::Relationship.create(:friends, node2, node4)
    Related::Relationship.create(:friends, node2, node3)
    nodes = node1.outgoing(:friends).union(node2.outgoing(:friends)).to_a
    assert_equal 2, nodes.size
    assert nodes.include?(node3)
    assert nodes.include?(node4)
  end
  
  def test_can_diff
    node1 = Related::Node.create
    node2 = Related::Node.create
    node3 = Related::Node.create
    node4 = Related::Node.create
    Related::Relationship.create(:friends, node1, node3)
    Related::Relationship.create(:friends, node2, node4)
    Related::Relationship.create(:friends, node2, node3)
    nodes = node2.outgoing(:friends).diff(node1.outgoing(:friends)).to_a
    assert_equal 1, nodes.size
    assert nodes.include?(node4)
  end

  def test_can_intersect
    node1 = Related::Node.create
    node2 = Related::Node.create
    Related::Relationship.create(:friends, node1, node2)
    Related::Relationship.create(:friends, node2, node1)
    assert_equal [node2], node1.outgoing(:friends).intersect(node1.incoming(:friends)).to_a
    assert_equal [node1], node2.outgoing(:friends).intersect(node2.incoming(:friends)).to_a
    node3 = Related::Node.create
    Related::Relationship.create(:friends, node1, node3)
    assert_equal [node1], node2.incoming(:friends).intersect(node3.incoming(:friends)).to_a
  end

  def test_timestamps
    node = Related::Node.create.save
    node = Related::Node.find(node.id)
    assert_match /^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\dZ$/, node.created_at
    assert_match /^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\dZ$/, node.updated_at
  end

  def test_should_require_a_relationship_to_have_a_label_start_node_and_end_node
    assert_raises Related::ValidationsFailed do
      Related::Relationship.create(nil, 'x', 'y')
    end
    assert_raises Related::ValidationsFailed do
      Related::Relationship.create(:friend, nil, 'y')
    end
    assert_raises Related::ValidationsFailed do
      Related::Relationship.create(:friend, 'x', nil)
    end
  end

  def test_root
    assert_kind_of Related::Node, Related.root
    node = Related::Node.create
    rel = Related::Relationship.create(:friend, Related.root, node)
    assert_equal [node], Related.root.outgoing(:friend).to_a
    Related.root.name = 'Test'
    Related.root.save
  end

  def test_find
    node1 = Related::Node.create
    node2 = Related::Node.create
    rel = Related::Relationship.create(:friend, node1, node2)
    assert_equal node2, node1.outgoing(:friend).find(node2)
    assert_equal node1, node2.incoming(:friend).find(node1)
    assert_equal nil, node1.outgoing(:friend).find(node1)
    assert_equal nil, node2.incoming(:friend).find(node2)
    assert_equal rel, node1.outgoing(:friend).relationships.find(node2)
    assert_equal rel, node2.incoming(:friend).relationships.find(node1)
    assert_equal nil, node1.outgoing(:friend).relationships.find(node1)
    assert_equal nil, node2.incoming(:friend).relationships.find(node2)
  end

  def test_can_increment_and_decrement
    node = Related::Node.create(:test => 1)
    assert_equal 1, Related::Node.find(node.id).test.to_i
    node.increment!(:test, 5)
    assert_equal 6, Related::Node.find(node.id).test.to_i
    node.decrement!(:test, 4)
    assert_equal 2, Related::Node.find(node.id).test.to_i
  end

  def test_can_increment_and_decrement_relationship_weights
    node1 = Related::Node.create
    node2 = Related::Node.create
    rel = Related::Relationship.create(:friend, node1, node2)
    original_in_weight = Related::Relationship.find(rel.id).weight(:in)
    rel.increment_weight!(:in, 4.2)
    assert_equal original_in_weight + 4.2, Related::Relationship.find(rel.id).weight(:in)
    rel.decrement_weight!(:in, 2.2)
    assert_equal original_in_weight + 2.0, Related::Relationship.find(rel.id).weight(:in)
    original_out_weight = Related::Relationship.find(rel.id).weight(:out)
    rel.increment_weight!(:out, 5.2)
    assert_equal original_out_weight + 5.2, Related::Relationship.find(rel.id).weight(:out)
    rel.decrement_weight!(:out, 4.2)
    assert_equal original_out_weight + 1.0, Related::Relationship.find(rel.id).weight(:out)
  end

end
