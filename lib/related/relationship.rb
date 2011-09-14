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

    def rank
      Related.redis.zrank("#{self.start_node_id}:rel:#{self.label}:out", self.id)
    end

    def self.create(label, node1, node2, attributes = {})
      self.new(attributes.merge(
        :label => label,
        :start_node_id => node1.to_s,
        :end_node_id => node2.to_s
      )).save
    end

  private

    def create
      Related.redis.multi do
        super
        score = Time.now.to_i
        Related.redis.zadd("#{self.start_node_id}:rel:#{self.label}:out", score, self.id)
        Related.redis.zadd("#{self.end_node_id}:rel:#{self.label}:in", score, self.id)

        Related.redis.sadd("#{self.start_node_id}:nodes:#{self.label}:out", self.end_node_id)
        Related.redis.sadd("#{self.end_node_id}:nodes:#{self.label}:in", self.start_node_id)
      end
      self
    end

    def delete
      Related.redis.multi do
        Related.redis.zrem("#{self.start_node_id}:rel:#{self.label}:out", self.id)
        Related.redis.zrem("#{self.end_node_id}:rel:#{self.label}:in", self.id)

        Related.redis.srem("#{self.start_node_id}:nodes:#{self.label}:out", self.end_node_id)
        Related.redis.srem("#{self.end_node_id}:nodes:#{self.label}:in", self.start_node_id)
        super
      end
      self
    end

  end
end