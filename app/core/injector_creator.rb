class InjectorCreator < Module
  attr_reader :container

  def initialize(container)
    @container = container
    super()
  end

  def included(base)
    define_use_deps(base, self.container)
  end

  def define_use_deps(base, container)
    base.class.define_method(:use_deps) do |*args|
      *methods, last  = args
      if last.is_a? Hash
        # named_methods = last
      else
        # named_methods = []
        methods << last
      end
      methods.each do |name|
        body = container[name.to_sym]
        if body.respond_to? :call
          self.define_method(name.to_sym, body)
        else
          self.define_method(name.to_sym) { body }
        end
      end
    end
  end
end
