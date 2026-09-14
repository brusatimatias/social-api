module Api
  module V1
    class PostsController < ApplicationController
      before_action :set_visible_post, only: :show
      before_action :set_own_post, only: %i[update destroy]
      before_action :validate_status_filter, only: :index

      rescue_from ArgumentError, with: :render_invalid_enum_value

      def index
        posts = current_user.posts.with_counts.for_status(params[:status]).includes(:user).with_attached_media

        render json: Api::V1::Response.success(
          data: posts,
          meta: { statuses: Post.statuses.keys }
        )
      end

      def show
        render json: Api::V1::Response.success(
          data: @post.as_json(include: { comments: { include: :user }, likes: { include: :user } })
        )
      end

      def create
        post = current_user.posts.build(post_params)

        if post.save
          render json: Api::V1::Response.success(data: post), status: :created
        else
          render json: Api::V1::Response.error(post.errors.full_messages), status: :unprocessable_entity
        end
      end

      def update
        if @post.update(post_params)
          render json: Api::V1::Response.success(data: @post)
        else
          render json: Api::V1::Response.error(@post.errors.full_messages), status: :unprocessable_entity
        end
      end

      def destroy
        if @post.destroy
          render json: Api::V1::Response.success(data: @post)
        else
          render json: Api::V1::Response.error(@post.errors.full_messages), status: :unprocessable_entity
        end
      end

      private

      def set_visible_post
        @post = Post.visible_to(current_user)
          .includes(:user, comments: :user, likes: :user)
          .with_attached_media
          .find(params[:id])
      end

      def set_own_post
        @post = current_user.posts
          .includes(:user, comments: :user, likes: :user)
          .with_attached_media
          .find(params[:id])
      end

      def post_params
        params.require(:post).permit(:content, :visibility, :status, media: [])
      end

      def validate_status_filter
        return if params[:status].blank? || Post.statuses.key?(params[:status])

        render json: Api::V1::Response.error(
          "Invalid status. Allowed values: #{Post.statuses.keys.join(", ")}"
        ), status: :bad_request
      end

      def render_invalid_enum_value(error)
        render json: Api::V1::Response.error(error.message), status: :bad_request
      end
    end
  end
end
