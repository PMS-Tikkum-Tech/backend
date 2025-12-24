# frozen_string_literal: true

module Api
  module V1
    # Unified AuthController for authentication and user management
    # Handles login, me, logout, and CRUD operations for users
    class AuthController < ApplicationController
      include BaseController

      before_action :authenticate_user!, only: %i[me logout]
      before_action :set_user, only: %i[show update destroy]

      # POST /api/v1/auth/login
      def login
        input = AuthInput.login_params(login_params)
        return render_unauthorized('Login failed') if input.invalid?(:login)

        result = AuthService.new(params: input.to_login_params).login
        return render_unauthorized(result.message) unless result.success?

        render_success('Login successful',
                       AuthPresenter.login_response(result.data))
      rescue StandardError => e
        render_error('Login failed', [e.message], :unauthorized)
      end

      # GET /api/v1/auth/me
      def me
        result = AuthService.new(current_user: current_user).me
        render_success('Profile retrieved',
                       AuthPresenter.user_response(result.data, current_user))
      end

      # DELETE /api/v1/auth/logout
      def logout
        # Get the current JWT token from Authorization header
        token = request.headers['Authorization']&.sub(/^Bearer /, '')

        result = AuthService.new(current_user: current_user,
                                 params: { token: token, refresh_token: params[:refresh_token] })
          .logout(params[:refresh_token])

        unless result.success?
          return render_error('Logout failed', result.errors,
                              :unprocessable_entity)
        end

        render_success('Logout successful')
      end

      # GET /api/v1/users
      def index
        input = AuthInput.filter_params(filter_params)
        result = AuthService.new(current_user: current_user,
                                 filters: input.to_filter_params)
          .list_users
        unless result.success?
          return render_error('Failed to retrieve users', result.errors,
                              :unprocessable_entity)
        end

        render_success('Users retrieved',
                       AuthPresenter.users_collection(result.data, current_user))
      end

      # GET /api/v1/users/:id
      def show
        result = AuthService.new(current_user: current_user).show_user(params[:id])
        unless result.success?
          return render_error('Failed to retrieve user', result.errors,
                              :unprocessable_entity)
        end

        render_success('User retrieved',
                       AuthPresenter.user_response(result.data, current_user))
      end

      # POST /api/v1/users
      def create
        input = AuthInput.create_params(user_params)
        if input.invalid?(:create)
          return render_error('Validation failed',
                              input.errors.full_messages,
                              :unprocessable_entity)
        end

        result = AuthService.new(current_user: current_user,
                                 params: input.to_create_params)
          .create_user
        unless result.success?
          return render_error('Failed to create user', result.errors,
                              :unprocessable_entity)
        end

        render_success('User created',
                       AuthPresenter.user_response(result.data, current_user),
                       :created)
      end

      # PUT/PATCH /api/v1/users/:id
      def update
        input = AuthInput.update_params(user_params)
        if input.invalid?(:update)
          return render_error('Validation failed',
                              input.errors.full_messages,
                              :unprocessable_entity)
        end

        result = AuthService.new(current_user: current_user,
                                 params: input.to_update_params)
          .update_user(params[:id])
        unless result.success?
          return render_error('Failed to update user', result.errors,
                              :unprocessable_entity)
        end

        render_success('User updated',
                       AuthPresenter.user_response(result.data, current_user))
      end

      # DELETE /api/v1/users/:id
      def destroy
        result = AuthService.new(current_user: current_user).delete_user(params[:id])
        unless result.success?
          return render_error('Failed to delete user', result.errors,
                              :unprocessable_entity)
        end

        render_success('User deleted permanently')
      end

      private

      def set_user
        @user = User.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render_not_found('User not found')
      end

      def login_params
        params.permit(:email, :password)
      end

      def user_params
        params.fetch(:user, {}).permit(:email, :password, :first_name,
                                       :last_name, :phone, :role,
                                       :profile_photo, :remove_profile_photo)
      end

      def filter_params
        params.permit(:search, :page, :per_page, :role)
      end
    end
  end
end
