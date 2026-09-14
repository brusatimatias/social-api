module Posts
  class FeedQuery
    include Paginatable

    def initialize(user, page: 1, per_page: Paginatable::DEFAULT_PER_PAGE)
      @user = user
      paginate(page: page, per_page: per_page)
    end

    def call
      {
        posts: paginated_posts,
        meta: pagination_meta(total_count)
      }
    end

    private

    attr_reader :user

    def posts
      Post
        .where(user_id: user.following.select(:id), status: Post.statuses[:published])
        .where(visibility: %w[public followers])
        .with_counts
        .includes(
          :user,
          comments: { user: { avatar_attachment: :blob } },
          likes: { user: { avatar_attachment: :blob } }
        )
        .with_attached_media
        .order(created_at: :desc, id: :desc)
    end

    def paginated_posts
      posts.offset(pagination_offset).limit(per_page)
    end

    def total_count
      @total_count ||= posts.unscope(:select, :group, :order).distinct.count(:id)
    end
  end
end
