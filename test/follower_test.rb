require File.expand_path('test/test_helper')
require 'related/follower'

class User < Related::Node
  include Related::Follower
end

class FollowerTest < MiniTest::Unit::TestCase

  def setup
    Related.redis.flushall
    @user1 = User.create
    @user2 = User.create
  end

  def test_can_follow
    @user1.follow!(@user2)
    assert @user1.following?(@user2)
    assert @user2.followed_by?(@user1)
  end

  def test_can_unfollow
    @user1.follow!(@user2)
    @user1.unfollow!(@user2)
    assert_equal false, @user1.following?(@user2)
  end

  def test_can_count_followers_and_following
    @user1.follow!(@user2)
    assert_equal 1, @user1.following_count
    assert_equal 0, @user1.followers_count
    assert_equal 0, @user2.following_count
    assert_equal 1, @user2.followers_count
  end

  def test_can_compute_friends
    @user1.follow!(@user2)
    @user2.follow!(@user1)
    assert_equal [@user2], @user1.friends.to_a
    assert_equal [@user1], @user2.friends.to_a
  end

end