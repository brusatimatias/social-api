module Api
  module V1
    class FeedController < ApplicationController
      def index
        result = Posts::FeedQuery.new(
          current_user,
          page: params.fetch(:page, 1),
          per_page: params.fetch(:per_page, Posts::FeedQuery::DEFAULT_PER_PAGE)
        ).call

        render json: Api::V1::Response.success(
          data: serialize_posts(result[:posts]),
          meta: result[:meta]
        )
      end

      private

      def serialize_posts(posts)
        posts.as_json(
          include: {
            comments: { include: :user },
            likes: { include: :user }
          }
        )
      end
    end
  end
end
