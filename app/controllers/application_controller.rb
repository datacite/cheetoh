class ApplicationController < ActionController::API
  include ActionController::HttpAuthentication::Basic::ControllerMethods

  include Helpable

  include Bolognese::DoiUtils
  include Bolognese::Utils
  include Cirneco::Utils
  include Cirneco::Api

  # check that username and password exist
  # store them in instance variables used for calling MDS API
  def authenticate_user_with_basic_auth!
    @username, @password = ActionController::HttpAuthentication::Basic::user_name_and_password(request)
    raise CanCan::AccessDenied unless @username.present? && @password.present?
  end

  def routing_error
    fail AbstractController::ActionNotFound
  end

  unless Rails.env.development?
    rescue_from *(RESCUABLE_EXCEPTIONS) do |exception|
      status = case exception.class.to_s
               when "CanCan::AccessDenied", "JWT::DecodeError" then 401
               when "AbstractController::ActionNotFound", "ActionController::RoutingError" then 404
               when "ActiveModel::ForbiddenAttributesError", "ActionController::UnpermittedParameters", "NoMethodError" then 422
               else 400
               end

      # EZID functionality not supported by this service
      status = 501 if exception.message.end_with?("not supported by this service")

      if status == 404
        message = "the resource you are looking for doesn't exist."
      elsif status == 401
        message = "unauthorized"
      else
        message = exception.message
      end

      render plain: "error: " + message, status: status
    end
  end
end
