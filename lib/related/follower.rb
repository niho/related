module Related
  module Follower
    def follow!(other)
      Related::Relationship.create(:follow, self, other)
    end

    def unfollow!(other)
      rel = self.following.relationships.find(other)
      rel.destroy if rel
    end

    def followers
      self.incoming(:follow)
    end

    def following
      self.outgoing(:follow)
    end

    def friends
      self.followers.intersect(self.following)
    end

    def followed_by?(other)
      self.followers.include?(other)
    end

    def following?(other)
      self.following.include?(other)
    end

    def followers_count
      self.followers.size
    end

    def following_count
      self.following.size
    end
  end
end
