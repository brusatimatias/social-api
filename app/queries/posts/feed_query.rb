module Posts
  class FeedQuery
    DEFAULT_PER_PAGE = 20
    MAX_PER_PAGE = 50
    INVALID_PAGINATION_MESSAGE =
      "Pagination values must be positive integers and per_page cannot exceed #{MAX_PER_PAGE}"

    class InvalidPagination < StandardError; end

    def initialize(user, page: 1, per_page: DEFAULT_PER_PAGE)
      @user = user
      @page = parse_positive_integer(page)
      @per_page = parse_per_page(per_page)
    end

    def call
      {
        posts: paginated_posts,
        meta: {
          current_page: page,
          per_page: per_page,
          total_pages: total_pages,
          total_count: total_count
        }
      }
    end

    private

    attr_reader :user

    def posts
      Post
        .where(user_id: user.following.select(:id), status: Post.statuses[:published])
        .where(visibility: %w[public followers])
        .with_counts
        .includes(comments: :user, likes: :user)
        .with_attached_media
        .order(created_at: :desc, id: :desc)
    end

    def paginated_posts
      posts.offset((page - 1) * per_page).limit(per_page)
    end

    def total_count
      @total_count ||= posts.unscope(:select, :group, :order).distinct.count(:id)
    end

    def total_pages
      (total_count.to_f / per_page).ceil
    end

    def page
      @page
    end

    def per_page
      @per_page
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
