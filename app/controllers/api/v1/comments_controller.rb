module Api
  module V1
    class CommentsController < ApplicationController
      before_action :set_post
      before_action :authenticate_user!, only: %i[create update destroy]
      before_action :set_comment, only: %i[update destroy]
      before_action :authorize_comment!, only: %i[update destroy]

      def index
        render json: @post.comments.includes(:user)
      end

      def create
        comment = current_user.comments.build(comment_params.merge(post: @post))

        if comment.save
          render json: comment, status: :created
        else
          render json: { errors: comment.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @comment.update(comment_params)
          render json: @comment
        else
          render json: { errors: @comment.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @comment.destroy
        head :no_content
      end

      private

      def set_comment
        @comment = @post.comments.find(params[:id])
      end

      def set_post
        @post = Post.find(params[:post_id])
      end

      def authorize_comment!
        return if @comment.user == current_user

        render json: { error: "Forbidden" }, status: :forbidden
      end

      def comment_params
        params.require(:comment).permit(:content)
      end
    end
  end
end
