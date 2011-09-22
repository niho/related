Related
=======

Related is a Redis-backed high performance graph database.

Raison d'être
-------------

Related is meant to be a simple graph database that is fun, free and easy to
use. The intention is not to compete with industrial grade graph databases
like Neo4j, but rather to be a replacement for a relational database when your
data is better described as a graph. For example when building social
software. Related is meant to be web scale, but ultimately relies on the
ability of Redis to scale (using Redis cluster for example).

Setup
-----

Assuming you already have Redis installed:

    $ gem install related

Or add the gem to your Gemfile.

    require 'related'
    Related.redis = 'redis://.../'

If you are using Rails, add the above to an initializer. If Redis is running
on localhost and on the default port the second line is not needed.

Example usage
-------------

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
    node1.path_to(node2).outgoing(:friends).depth(3)
    node1.shortest_path_to(node2).outgoing(:friends).depth(3)

To get the results from a query:

    node.outgoing(:friends).to_a
    node.outgoing(:friends).count (or .size, which is memoized)

You can also do set operations, like union, diff and intersect:

    node1.outgoing(:friends).union(node2.outgoing(:friends))
    node1.outgoing(:friends).diff(node2.outgoing(:friends))
    node1.outgoing(:friends).intersect(node2.outgoing(:friends))

Relationships are sorted based on when they were created, which means you can
paginate them:

    node.outgoing(:friends).relationship.per_page(100).page(1)
    node.outgoing(:friends).relationship.per_page(100).page(rel)

The second form paginates based on the id of the last relationship on the
previous page. Useful for cases where explicit page numbers are not
appropriate.

Pagination only works for relationships. If you want to access nodes directly
without going through the extra step of iterating through the relationship
objects you will only get random nodes. Thus you can use .limit (or .per_page)
like this to get a random selection of nodes:

    node.outgoing(:friends).nodes.limit(5)

Follower
--------

Related includes a helper module called Related::Follower that you can include
in your node sub-class to get basic Twitter-like follow functionality:

    class User < Related::Node
      include Related::Follower
    end

    user1 = User.create
    user2 = User.create

    user1.follow!(user2)
    user1.unfollow!(user2)
    user2.followers
    user1.following
    user1.friends
    user2.followed_by?(user1)
    user1.following?(user2)
    user2.followers_count
    user1.following_count

The two nodes does not need to be of the same type. You can for example have
a User following a Page or whatever makes sense in your app.

Development
-----------

If you want to make your own changes to Related, first clone the repo and
run the tests:

    git clone git://github.com/sutajio/related.git
    cd related
    rake test

Remember to install the Redis server on your local machine.

Contributing
------------

Once you've made your great commits:

1. Fork Related
2. Create a topic branch - git checkout -b my_branch
3. Push to your branch - git push origin my_branch
4. Create a Pull Request from your branch
5. That's it!

Author
------

Related was created by Niklas Holmgren (niklas@sutajio.se) and released under
the MIT license.
