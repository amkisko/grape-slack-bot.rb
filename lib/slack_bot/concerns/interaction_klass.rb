module SlackBot::Concerns
  module InteractionKlass
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def interaction_klass
        raise SlackBot::Errors::InteractionClassNotImplemented.new(name)
      end

      def interaction(klass)
        define_singleton_method(:interaction_klass) { klass }
      end
    end
  end
end
