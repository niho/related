
dir = File.dirname(File.expand_path(__FILE__))
$LOAD_PATH.unshift dir + '/../lib'

require 'rubygems'
require 'bundler/setup'
require 'test/unit'
require 'related'
require 'redis/distributed'

#
# make sure we can run redis
#

if !system("which redis-server")
  puts '', "** can't find `redis-server` in your path"
  puts "** try running `sudo rake install`"
  abort ''
end


#
# start our own redis when the tests start,
# kill it when they end
#

at_exit do
  next if $!

  if defined?(MiniTest)
    exit_code = MiniTest::Unit.new.run(ARGV)
  else
    exit_code = Test::Unit::AutoRunner.run
  end

  puts "Killing test redis server..."
  loop do
    pid = `ps -A -o pid,command | grep [r]edis-test`.split(" ")[0]
    break if pid.nil?
    Process.kill("KILL", pid.to_i)
  end
  `rm -f #{dir}/*.rdb`
  exit exit_code
end

puts "Starting redis for testing..."

# `redis-server #{dir}/redis-test-1.conf`
# Related.redis = 'localhost:6379'

`redis-server #{dir}/redis-test-1.conf`
`redis-server #{dir}/redis-test-2.conf`
`redis-server #{dir}/redis-test-3.conf`
`redis-server #{dir}/redis-test-4.conf`

Related.redis = Redis::Distributed.new %w[
  redis://localhost:6379
  redis://localhost:6380
  redis://localhost:6381
  redis://localhost:6382],
  :tag => /^related:([^:]+)/
