module Related
  class RelatedException < RuntimeError; end
  class NotFound < RelatedException; end
  class InvalidQuery < RelatedException; end
  class ValidationsFailed < RelatedException; end
end