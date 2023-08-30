module SlackBot::Concerns
  module PagerKlass
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def pager_klass
        SlackBot::Pager
      end

      def pager(klass)
        define_singleton_method(:pager_klass) { klass }
      end
    end
  end
end
