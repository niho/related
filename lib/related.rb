require 'redis'
require 'redis/namespace'
require 'active_model'

require 'related/version'
require 'related/helpers'
require 'related/exceptions'
require 'related/validations/check_redis_uniqueness'
require 'related/entity'
require 'related/node'
require 'related/relationship'
require 'related/root'
require 'related/data_flow'

module Related
  include Helpers
  include DataFlow
  extend self

  # Accepts:
  #   1. A 'hostname:port' string
  #   2. A 'hostname:port:db' string (to select the Redis db)
  #   3. A 'hostname:port/namespace' string (to set the Redis namespace)
  #   4. A redis URL string 'redis://host:port'
  #   5. An instance of `Redis`, `Redis::Client`, `Redis::Distributed`,
  #      or `Redis::Namespace`.
  def redis=(server)
    if server.is_a? String
      if server =~ /redis\:\/\//
        redis = Redis.connect(:url => server)
      else
        server, namespace = server.split('/', 2)
        host, port, db = server.split(':')
        redis = Redis.new(:host => host, :port => port,
          :thread_safe => true, :db => db)
      end
      namespace ||= :related
      @redis = Redis::Namespace.new(namespace, :redis => redis)
    elsif server.respond_to? :namespace=
      @redis = server
    else
      @redis = Redis::Namespace.new(:related, :redis => server)
    end
  end

  # Returns the current Redis connection. If none has been created, will
  # create a new one.
  def redis
    return @redis if @redis
    self.redis = ENV['RELATED_REDIS_URL'] || ENV['REDIS_URL'] || 'localhost:6379'
    self.redis
  end

end