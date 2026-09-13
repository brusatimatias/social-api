module Users
  class SearchQuery
    DEFAULT_PER_PAGE = 20
    MAX_PER_PAGE = 50
    INVALID_PAGINATION_MESSAGE =
      "Pagination values must be positive integers and per_page cannot exceed #{MAX_PER_PAGE}"

    class InvalidPagination < StandardError; end

    def initialize(current_user, query: nil, page: 1, per_page: DEFAULT_PER_PAGE)
      @current_user = current_user
      @query = query.to_s.strip
      @page = parse_positive_integer(page)
      @per_page = parse_per_page(per_page)
    end

    def call
      {
        users: paginated_users,
        meta: {
          current_page: page,
          per_page: per_page,
          total_pages: total_pages,
          total_count: total_count
        }
      }
    end

    private

    attr_reader :current_user, :query, :page, :per_page

    def users
      scope = User.where.not(id: current_user.id)
      scope = filter_by_query(scope)
      scope.order(order_clause)
    end

    def filter_by_query(scope)
      return scope if query.blank?

      term = "%#{ActiveRecord::Base.sanitize_sql_like(query)}%"
      scope.where("name ILIKE :term OR lastname ILIKE :term OR email ILIKE :term", term: term)
    end

    def order_clause
      query.present? ? { name: :asc, lastname: :asc, id: :asc } : { created_at: :desc, id: :desc }
    end

    def paginated_users
      users.offset((page - 1) * per_page).limit(per_page)
    end

    def total_count
      @total_count ||= users.unscope(:order).count
    end

    def total_pages
      (total_count.to_f / per_page).ceil
    end

    def parse_positive_integer(value)
      return value.to_i if value.to_s.match?(/\A[1-9]\d*\z/)

      raise InvalidPagination, INVALID_PAGINATION_MESSAGE
    end

    def parse_per_page(value)
      parsed_value = parse_positive_integer(value)
      return parsed_value if parsed_value <= MAX_PER_PAGE

      raise InvalidPagination, INVALID_PAGINATION_MESSAGE
    end
  end
end
