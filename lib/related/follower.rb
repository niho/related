module Related
  module Follower
    def follow!(user)
      Related::Relationship.create(:follow, self, user)
    end

    def unfollow!(user)
      self.following.relationships.each do |rel|
        if rel.end_node_id == user.id
          rel.destroy
        end
      end
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

    def followed_by?(user)
      self.followers.include?(user)
    end

    def following?(user)
      self.following.include?(user)
    end

    def followers_count
      self.followers.size
    end

    def following_count
      self.following.size
    end
  end
end
