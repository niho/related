module Related
  class RelatedException < RuntimeError; end
  class NotFound < RelatedException; end
  class InvalidQuery < RelatedException; end
end