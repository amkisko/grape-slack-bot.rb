module SlackBot
  class Pager
    DEFAULT_PAGE = 1
    DEFAULT_LIMIT = 10

    attr_reader :source_cursor, :args, :limit, :page
    def initialize(source_cursor, args:, limit: nil, page: nil)
      @source_cursor = source_cursor
      @args = args
      @limit = limit || @args[:per_page]&.to_i || DEFAULT_LIMIT
      @page = page || @args[:page]&.to_i || DEFAULT_PAGE
    end

    def total_count
      source_cursor.count
    end

    def pages_count
      (source_cursor.count.to_f / limit).ceil
    end

    def offset
      (page - 1) * limit
    end

    def cursor
      source_cursor.limit(limit).offset(offset)
    end
  end
end
