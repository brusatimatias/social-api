module Api
  module V1
    class LikesController < ApplicationController
      before_action :set_like, only: %i[show destroy]

      def index
        render json: Like.all
      end

      def show
        render json: @like
      end

      def create
        like = Like.new(like_params)

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
        @like = Like.find(params[:id])
      end

      def like_params
        params.require(:like).permit(:user_id, :post_id)
      end
    end
  end
end
