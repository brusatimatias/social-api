module Api
  module V1
    class PostsController < ApplicationController
      before_action :authenticate_user!, only: %i[create update destroy]
      before_action :set_post, only: %i[show update destroy]
      before_action :authorize_post!, only: %i[update destroy]

      def index
        posts = params[:status].present? ? Post.where(status: params[:status]) : Post.all
        render json: posts, include: { comments: { include: :user }, likes: { include: :user } }
      end

      def show
        render json: @post, include: { comments: { include: :user }, likes: { include: :user } }
      end

      def create
        post = current_user.posts.build(post_params)

        if post.save
          render json: post, status: :created
        else
          render json: { errors: post.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @post.update(post_params)
          render json: @post
        else
          render json: { errors: @post.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        if @post.destroy
          render json: @post
        else
          render json: { errors: @post.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_post
        @post = Post.find(params[:id])
      end

      def post_params
        params.require(:post).permit(:content, :visibility, :status, media: [])
      end

      def authorize_post!
        return if @post.user == current_user

        render json: { error: "Forbidden" }, status: :forbidden
      end
    end
  end
end
