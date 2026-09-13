module Api
  module V1
    class LikesController < ApplicationController
      before_action :set_post, only: :create
      before_action :set_like, only: :destroy

      def create
        like = current_user.likes.build(post: @post)

        if like.save
          render json: Api::V1::Response.success(data: like), status: :created
        else
          render json: Api::V1::Response.error(like.errors.full_messages), status: :unprocessable_entity
        end
      end

      def destroy
        if @like.destroy
          render json: Api::V1::Response.success(data: @like)
        else
          render json: Api::V1::Response.error(@like.errors.full_messages), status: :unprocessable_entity
        end
      end

      private

      def set_like
        @like = current_user.likes.find_by!(id: params[:id], post_id: params[:post_id])
      end

      def set_post
        @post = Post.visible_to(current_user).find(params[:post_id])
      end
    end
  end
end
