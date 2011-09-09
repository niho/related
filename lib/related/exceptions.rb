module Related
  class RelatedException < RuntimeError; end
  class NotFound < RelatedException; end
end