module Related
  class Entity

      attr_reader :id
      attr_reader :attributes
      attr_reader :destroyed

      def initialize(*attributes)
        if attributes.first.is_a?(String)
          @id = attributes.first
          @attributes = attributes.last
        else
          @attributes = attributes.first
        end
      end

      def to_s
        self.id
      end

      def method_missing(sym, *args, &block)
        @attributes[sym] || @attributes[sym.to_s]
      end

      def ==(other)
        @id == other.id
      end

      def new_record?
        @id.nil? ? true : false
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

      def as_json(options = {})
        (attributes || {}).merge(:id => self.id)
      end

      def to_json(options = {})
        as_json.to_json(options)
      end

    private

      def create_or_update
        new_record? ? create : update
      end

      def create
        @id = Related.generate_id
        @attributes.merge!(:created_at => Time.now.utc)
        Related.redis.hmset(@id, *@attributes.to_a.flatten)
        self
      end

      def update
        @attributes.merge!(:updated_at => Time.now.utc)
        Related.redis.hmset(@id, *@attributes.to_a.flatten)
        self
      end

      def delete
        Related.redis.del(id)
        @destroyed = true
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
