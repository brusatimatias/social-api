module Api
  module V1
    class UsersController < ApplicationController
      before_action :set_user, only: %i[show update destroy]
      before_action :set_user_for_relationships, only: %i[followers following follow unfollow]
      before_action :authorize_user!, only: %i[update destroy]

      def index
        render json: User.all
      end

      def show
        render json: @user
      end

      def followers
        render json: @user.followers
      end

      def following
        render json: @user.following
      end

      def follow
        relationship = current_user.following_relationships.build(following: @user)

        if relationship.save
          render json: relationship, status: :created
        else
          render json: { errors: relationship.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def unfollow
        relationship = current_user.following_relationships.find_by!(following: @user)

        if relationship.destroy
          render json: relationship
        else
          render json: { errors: relationship.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @user.update(user_params)
          render json: @user
        else
          render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        if @user.destroy
          render json: @user
        else
          render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_user
        @user = User.find_by!(uuid: params[:id])
      end

      def set_user_for_relationships
        @user = User.find_by!(uuid: params[:id])
      end

      def authorize_user!
        return if @user == current_user

        render json: { error: "Forbidden" }, status: :forbidden
      end

      def user_params
        params.require(:user).permit(:name, :lastname, :email, :password, :password_confirmation)
      end
    end
  end
end
