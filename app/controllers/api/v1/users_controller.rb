module Api
  module V1
    class UsersController < ApplicationController
      before_action :set_user, only: %i[follow unfollow]
      before_action :set_relationship_user, only: %i[followers following]

      def search
        result = Users::SearchQuery.new(
          current_user,
          query: params[:q],
          page: params.fetch(:page, 1),
          per_page: params.fetch(:per_page, Users::SearchQuery::DEFAULT_PER_PAGE)
        ).call

        render json: Api::V1::Response.success(data: result[:users], meta: result[:meta])
      end

      def followers
        render json: Api::V1::Response.success(data: @relationship_user.followers)
      end

      def following
        render json: Api::V1::Response.success(data: @relationship_user.following)
      end

      def follow
        relationship = current_user.following_relationships.build(following: @user)

        if relationship.save
          render json: Api::V1::Response.success(data: relationship), status: :created
        else
          render json: Api::V1::Response.error(
            relationship.errors.full_messages
          ), status: :unprocessable_entity
        end
      end

      def unfollow
        relationship = current_user.following_relationships.find_by!(following: @user)

        if relationship.destroy
          render json: Api::V1::Response.success(data: relationship)
        else
          render json: Api::V1::Response.error(
            relationship.errors.full_messages
          ), status: :unprocessable_entity
        end
      end

      private

      def set_user
        @user = User.find_by!(uuid: params[:id])
      end

      def set_relationship_user
        @relationship_user = params[:user_id].present? ? User.find_by!(uuid: params[:user_id]) : current_user
      end
    end
  end
end
