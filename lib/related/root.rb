module Related
  class Root < Related::Node

    def initialize(attributes = {})
      @id = 'root'
      super(attributes)
    end

  end
end
