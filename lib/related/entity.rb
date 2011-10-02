module Related
  class Entity
    extend ActiveModel::Naming
    extend ActiveModel::Callbacks
    include ActiveModel::Conversion
    include ActiveModel::Validations
    include ActiveModel::Serializers::JSON
    include ActiveModel::Serializers::Xml
    include ActiveModel::Translation

    self.include_root_in_json = false

    define_model_callbacks :create, :update, :destroy, :save

    attr_reader :id
    attr_reader :attributes

    def initialize(*attributes)
      if attributes.first.is_a?(String)
        @id = attributes.first
        @attributes = attributes.last
      else
        @attributes = attributes.first
      end
      @attributes ||= {}
    end

    def to_s
      self.id
    end

    def attributes
      @attributes ||= {}
      @attributes.inject({}) { |memo,(k,v)|
        memo[k.to_s] = v
        memo
      }.merge('id' => self.id)
    end

    def read_attribute(name)
      @attributes ||= {}
      @attributes[name.to_s] || @attributes[name]
    end

    def write_attribute(name, value)
      @attributes ||= {}
      @attributes[name.to_s] = value
    end

    def has_attribute?(name)
      @attributes ||= {}
      @attributes.has_key?(name.to_s) || @attributes.has_key?(name)
    end

    def method_missing(sym, *args, &block)
      if sym.to_s =~ /=$/
        write_attribute(sym.to_s[0..-2], args.first)
      else
        read_attribute(sym)
      end
    end

    def ==(other)
      other.is_a?(Related::Entity) && self.to_key == other.to_key
    end

    def new?
      @id.nil? ? true : false
    end

    alias new_record? new?

    def persisted?
      !new?
    end

    def destroyed?
      @destroyed
    end

    def save
      create_or_update
    end

    def destroy
      delete
    end

    def self.create(attributes = {})
      self.new(attributes).save
    end

    def self.find(*args)
      options = args.size > 1 && args.last.is_a?(Hash) ? args.pop : {}
      args.size == 1 && args.first.is_a?(String) ?
        find_one(args.first, options) :
        find_many(args.flatten, options)
    end

  private

    def create_or_update
      run_callbacks :save do
        new? ? create : update
      end
    end

    def create
      run_callbacks :create do
        raise Related::ValidationsFailed, self unless valid?
        @id = Related.generate_id
        @attributes ||= {}
        @attributes.merge!('created_at' => Time.now.utc.iso8601)
        Related.redis.hmset(@id, *@attributes.to_a.flatten)
      end
      self
    end

    def update
      run_callbacks :update do
        raise Related::ValidationsFailed, self unless valid?
        @attributes ||= {}
        @attributes.merge!('updated_at' => Time.now.utc.iso8601)
        Related.redis.hmset(@id, *@attributes.to_a.flatten)
      end
      self
    end

    def delete
      run_callbacks :destroy do
        Related.redis.del(id)
        @destroyed = true
      end
      self
    end

    def self.find_fields(id, fields)
      res = Related.redis.hmget(id.to_s, *fields)
      if res
        attributes = {}
        res.each_with_index do |value, i|
          attributes[fields[i]] = value
        end
        attributes
      end
    end

    def self.find_one(id, options = {})
      attributes = options[:fields] ?
        find_fields(id, options[:fields]) :
        Related.redis.hgetall(id.to_s)
      if attributes.empty?
        if Related.redis.exists(id) == false
          raise Related::NotFound, id
        end
      end
      self.new(id, attributes)
    end

    def self.find_many(ids, options = {})
      res = Related.redis.pipelined do
        ids.each {|id|
          if options[:fields]
            Related.redis.hmget(id.to_s, *options[:fields])
          else
            Related.redis.hgetall(id.to_s)
          end
        }
      end
      objects = []
      ids.each_with_index do |id,i|
        if options[:fields]
          attributes = {}
          res[i].each_with_index do |value, i|
            attributes[options[:fields][i]] = value
          end
          objects << self.new(id, attributes)
        else
          objects << self.new(id, Hash[*res[i]])
        end
      end
      objects
    end

  end
end
