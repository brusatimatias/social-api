module Api
  module V1
    class PostsController < ApplicationController
      before_action :set_post, only: %i[show update destroy]

      def index
        posts = current_user.posts
        posts = posts.where(status: params[:status]) if params[:status].present?
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
        @post = current_user.posts.find(params[:id])
      end

      def post_params
        params.require(:post).permit(:content, :visibility, :status, media: [])
      end
    end
  end
end
