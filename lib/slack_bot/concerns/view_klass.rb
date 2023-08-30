module SlackBot::Concerns
  module ViewKlass
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def view_klass
        raise SlackBot::Errors::ViewClassNotImplemented.new(name)
      end

      def view(klass)
        define_singleton_method(:view_klass) { klass }
      end
    end
  end
end
