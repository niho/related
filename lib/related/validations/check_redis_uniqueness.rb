module Related
  class CheckRedisUniqueness < ActiveModel::Validator
    def validate(entity)
      if Related.redis.exists(entity.instance_variable_get(:@_internal_id))
        entity.errors[:id] << "\"#{entity.id}\" already exists."
      end
    end
  end
end