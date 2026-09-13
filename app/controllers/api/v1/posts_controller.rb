module Api
  module V1
    class PostsController < ApplicationController
      before_action :set_post, only: %i[show update destroy]

      def index
        render json: Api::V1::Response.success(
          data: current_user.posts.with_counts.for_status(params[:status])
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

      def set_post
        @post = current_user.posts.find(params[:id])
      end

      def post_params
        params.require(:post).permit(:content, :visibility, :status, media: [])
      end
    end
  end
end
