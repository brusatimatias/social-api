module Api
  module V1
    class FollowersController < ApplicationController
      before_action :set_follower, only: :destroy

      def create
        follower = Follower.new(follower_params)

        if follower.save
          render json: follower, status: :created
        else
          render json: { errors: follower.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @follower.destroy
        head :no_content
      end

      private

      def set_follower
        @follower = Follower.find(params[:id])
      end

      def follower_params
        params.require(:follower).permit(:follower_id, :following_id)
      end
    end
  end
end
