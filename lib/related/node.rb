module Related
  class Node < Entity
    module QueryMethods
      def relationships
        query = self.query
        query.entity_type = :relationships
        query
      end

      def nodes
        query = self.query
        query.entity_type = :nodes
        query
      end

      def outgoing(type)
        query = self.query
        query.relationship_type = type
        query.direction = :out
        query
      end

      def incoming(type)
        query = self.query
        query.relationship_type = type
        query.direction = :in
        query
      end

      def limit(count)
        query = self.query
        query.limit = count
        query
      end

      def depth(depth)
        query = self.query
        query.depth = depth
        query
      end

      def include_start_node
        query = self.query
        query.include_start_node = true
        query
      end

      def path_to(node)
        query = self.query
        query.destination = node
        query.search_algorithm = :depth_first
        query
      end

      def shortest_path_to(node)
        query = self.query
        query.destination = node
        query.search_algorithm = :dijkstra
        query
      end
    end

    include QueryMethods

    class Query
      include QueryMethods

      attr_writer :entity_type
      attr_writer :relationship_type
      attr_writer :direction
      attr_writer :limit
      attr_writer :depth
      attr_writer :include_start_node
      attr_writer :destination
      attr_writer :search_algorithm

      def initialize(node)
        @node = node
        @entity_type = :nodes
        @depth = 4
      end

      def each(&block)
        self.to_a.each(&block)
      end

      def map(&block)
        self.to_a.map(&block)
      end

      def to_a
        res = []
        if @destination
          res = self.send(@search_algorithm, [@node.id])
          res.shift unless @include_start_node
          return Related::Node.find(res)
        else
          if @limit
            res = (1..@limit.to_i).map { Related.redis.srandmember(key) }
          else
            res = Related.redis.smembers(key)
          end
        end
        res = Relationship.find(res)
        if @entity_type == :nodes
          res = Related::Node.find(res.map {|rel| @direction == :in ? rel.start_node_id : rel.end_node_id })
          res.unshift(@node) if @include_start_node
        end
        res
      end

      def count
        @count = Related.redis.scard(key)
        @limit && @count > @limit ? @limit : @count
      end

      def size
        @count || count
      end

    protected

      def key
        "#{@node.id}:rel:#{@relationship_type}:#{@direction}"
      end

      def query
        self
      end

      def depth_first(nodes, depth = 0)
        return [] if depth > @depth
        nodes.each do |node|
          key = "#{node}:nodes:#{@relationship_type}:#{@direction}"
          if Related.redis.sismember(key, @destination.id)
            return [node, @destination.id]
          else
            res = depth_first(Related.redis.smembers(key), depth+1)
            return [node] + res unless res.empty?
          end
        end
        return []
      end

      def dijkstra(nodes, depth = 0)
        return [] if depth > @depth
        shortest_path = []
        nodes.each do |node|
          key = "#{node}:nodes:#{@relationship_type}:#{@direction}"
          if Related.redis.sismember(key, @destination.id)
            return [node, @destination.id]
          else
            res = dijkstra(Related.redis.smembers(key), depth+1)
            if res.size > 0
              res = [node] + res
              if res.size < shortest_path.size || shortest_path.size == 0
                shortest_path = res
              end
            end
          end
        end
        return shortest_path
      end

    end

  protected

    def query
      Query.new(self)
    end

  end
end