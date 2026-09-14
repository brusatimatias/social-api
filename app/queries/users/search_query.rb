module Users
  class SearchQuery
    include Paginatable

    def initialize(current_user, query: nil, page: 1, per_page: Paginatable::DEFAULT_PER_PAGE)
      @current_user = current_user
      @query = query.to_s.strip
      paginate(page: page, per_page: per_page)
    end

    def call
      {
        users: paginated_users,
        meta: pagination_meta(total_count)
      }
    end

    private

    attr_reader :current_user, :query

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
      users.offset(pagination_offset).limit(per_page).with_attached_avatar
    end

    def total_count
      @total_count ||= users.unscope(:order).count
    end
  end
end
