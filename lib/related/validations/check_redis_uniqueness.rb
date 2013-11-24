module Related
  class CheckRedisUniqueness < ActiveModel::Validator
    def validate(entity)
      internal_id = entity.instance_variable_get(:@_internal_id)

      if Related.redis.exists(internal_id)
        entity.errors[:id] << "#{internal_id.inspect} already exists."
      end
    end
  end
end