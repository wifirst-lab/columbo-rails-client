module Columbo
  module Resource
    def columbo
      ::Columbo::Resource::Publisher.new(self)
    end
  end
end
