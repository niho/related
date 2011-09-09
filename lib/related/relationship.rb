module Related
  class Relationship < Entity

    def initialize(*attributes)
      if attributes.first.is_a?(String)
        @id = attributes.first
      end
      @attributes = attributes.last
    end

    def start_node
      @start_node ||= Related::Node.find(start_node_id)
    end

    def end_node
      @end_node ||= Related::Node.find(end_node_id)
    end

    def self.create(type, node1, node2, attributes = {})
      self.new(attributes.merge(
        :type => type,
        :start_node_id => node1.to_s,
        :end_node_id => node2.to_s
      )).save
    end

  private

    def create
      Related.redis.multi do
        super
        Related.redis.sadd("#{self.start_node_id}:rel:#{type}:out", self.id)
        Related.redis.sadd("#{self.end_node_id}:rel:#{type}:in", self.id)

        Related.redis.sadd("#{self.start_node_id}:nodes:#{type}:out", self.end_node_id)
        Related.redis.sadd("#{self.end_node_id}:nodes:#{type}:in", self.start_node_id)
      end
      self
    end

    def delete
      Related.redis.multi do
        Related.redis.srem("#{self.start_node_id}:rel:#{type}:out", self.id)
        Related.redis.srem("#{self.end_node_id}:rel:#{type}:in", self.id)

        Related.redis.srem("#{self.start_node_id}:nodes:#{type}:out", self.end_node_id)
        Related.redis.srem("#{self.end_node_id}:nodes:#{type}:in", self.start_node_id)
        super
      end
      self
    end

  end
end