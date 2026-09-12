module Api
  module V1
    class LikesController < ApplicationController
      before_action :set_post
      before_action :authenticate_user!, only: %i[create destroy]
      before_action :set_like, only: :destroy
      before_action :authorize_like!, only: :destroy

      def index
        render json: @post.likes.includes(:user)
      end

      def create
        like = current_user.likes.build(post: @post)

        if like.save
          render json: like, status: :created
        else
          render json: { errors: like.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @like.destroy
        head :no_content
      end

      private

      def set_like
        @like = @post.likes.find(params[:id])
      end

      def set_post
        @post = Post.find(params[:post_id])
      end

      def authorize_like!
        return if @like.user == current_user

        render json: { error: "Forbidden" }, status: :forbidden
      end
    end
  end
end
