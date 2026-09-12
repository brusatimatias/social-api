module Api
  module V1
    class CommentsController < ApplicationController
      before_action :set_post
      before_action :set_comment, only: %i[update destroy]

      def create
        comment = current_user.comments.build(comment_params.merge(post: @post))

        if comment.save
          render json: Api::V1::Response.success(data: comment), status: :created
        else
          render json: Api::V1::Response.error(comment.errors.full_messages), status: :unprocessable_entity
        end
      end

      def update
        if @comment.update(comment_params)
          render json: Api::V1::Response.success(data: @comment)
        else
          render json: Api::V1::Response.error(@comment.errors.full_messages), status: :unprocessable_entity
        end
      end

      def destroy
        if @comment.destroy
          render json: Api::V1::Response.success(data: @comment)
        else
          render json: Api::V1::Response.error(@comment.errors.full_messages), status: :unprocessable_entity
        end
      end

      private

      def set_comment
        @comment = @post.comments.find(params[:id])
      end

      def set_post
        @post = current_user.posts.find(params[:post_id])
      end

      def comment_params
        params.require(:comment).permit(:content)
      end
    end
  end
end
