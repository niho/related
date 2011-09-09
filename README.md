Related
=======

Related is a Redis-backed high performance graph database.

Example usage:

  node = Related::Node.create(:name => 'Example', :popularity => 2.3)
  node.new_record?
  node.popularity = 100
  node.save
  node = Related::Node.find(node.id)
  node.destroy

  node1 = Related::Node.create
  node2 = Related::Node.create
  rel = Related::Relationship.create(:friends, node1, node2, :have_met => true)

  n = Related::Node.find(node1.id)
  nn = Related::Node.find(node1.id, node2.id)

  n = Related::Node.find(node1.id, :fields => [:name])
  nn = Related::Node.find(node1.id, node2.id, :fields => [:name])

Nodes and relationships are both sub-classes of the same base class and both
behave similar to an ActiveRecord object and can store attributes etc.

To query the graph:

  node.outgoing(:friends)
  node.incoming(:friends)
  node.outgoing(:friends).relationships
  node.outgoing(:friends).nodes
  node.outgoing(:friends).limit(5)
  node1.shortest_path_to(node2).outgoing(:friends).depth(3)

To get the results from a query:

  node.outgoing(:friends).to_a
  node.outgoing(:friends).count (or .size, which is memoized)

You can also do set operations, like union, diff and intersect:

  node1.outgoing(:friends).union(node2.outgoing(:friends))
  node1.outgoing(:friends).diff(node2.outgoing(:friends))
  node1.outgoing(:friends).intersect(node2.outgoing(:friends))
