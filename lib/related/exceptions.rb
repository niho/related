module Related
  class RelatedException < RuntimeError; end
  class NotFound < RelatedException; end
  class InvalidQuery < RelatedException; end
  class ValidationsFailed < RelatedException
    attr_reader :object
    def initialize(object)
      @object = object
      errors = @object.errors.full_messages.to_sentence
      super(errors)
    end
  end
end