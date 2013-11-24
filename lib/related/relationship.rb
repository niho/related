module Related
  class Relationship < Entity

    validates_presence_of :label, :start_node_id, :end_node_id

    def initialize(*attributes)
      @_internal_id = attributes.first.is_a?(String) ? attributes.first : Related.generate_id
      @attributes = attributes.last
    end

    def start_node
      @start_node ||= Related::Node.find(start_node_id)
    end

    def end_node
      @end_node ||= Related::Node.find(end_node_id)
    end

    def rank(direction)
      Related.redis.zrevrank(r_key(direction), self.id)
    end

    def weight(direction)
      Related.redis.zscore(r_key(direction), self.id).to_f
    end

    def increment_weight!(direction, by = 1)
      Related.redis.zincrby(r_key(direction), by.to_f, self.id)
    end

    def decrement_weight!(direction, by = 1)
      Related.redis.zincrby(r_key(direction), -by.to_f, self.id)
    end

    def self.weight(&block)
      @weight = block
    end

    def self.create(label, node1, node2, attributes = {})
      self.new(attributes.merge(
        :label => label,
        :start_node_id => node1.is_a?(String) ? node1 : (node1 ? node1.id : nil),
        :end_node_id => node2.is_a?(String) ? node2 : (node2 ? node2.id : nil)
      )).save
    end

  private

    def r_key(direction)
      if direction.to_sym == :out
        "#{self.start_node_id}:r:#{self.label}:out"
      elsif direction.to_sym == :in
        "#{self.end_node_id}:r:#{self.label}:in"
      end
    end

    def n_key(direction)
      if direction.to_sym == :out
        "#{self.start_node_id}:n:#{self.label}:out"
      elsif direction.to_sym == :in
        "#{self.end_node_id}:n:#{self.label}:in"
      end
    end

    def dir_key
      "#{self.start_node_id}:#{self.label}:#{self.end_node_id}"
    end

    def self.weight_for(relationship, direction)
      if @weight
        relationship.instance_exec(direction, &@weight).to_i
      else
        Time.now.to_f
      end
    end

    def create
      #Related.redis.multi do
        super
        Related.redis.zadd(r_key(:out), self.class.weight_for(self, :out), self.id)
        Related.redis.zadd(r_key(:in), self.class.weight_for(self, :in), self.id)
        Related.redis.sadd(n_key(:out), self.end_node_id)
        Related.redis.sadd(n_key(:in), self.start_node_id)
        Related.redis.set(dir_key, self.id)
      #end
      Related.execute_data_flow(self.label, self)
      self
    end

    def update
      super
      Related.execute_data_flow(self.label, self)
      self
    end

    def delete
      #Related.redis.multi do
        Related.redis.zrem(r_key(:out), self.id)
        Related.redis.zrem(r_key(:in), self.id)
        Related.redis.srem(n_key(:out), self.end_node_id)
        Related.redis.srem(n_key(:in), self.start_node_id)
        Related.redis.del(dir_key)
        super
      #end
      Related.execute_data_flow(self.label, self)
      self
    end

  end
end