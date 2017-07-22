class ApplicationController < ActionController::API
  include Helpable

  RESCUABLE_EXCEPTIONS = [CanCan::AccessDenied,
                          JWT::DecodeError,
                          JWT::VerificationError,
                          AbstractController::ActionNotFound,
                          ActionController::RoutingError,
                          ActionController::ParameterMissing,
                          ActionController::UnpermittedParameters,
                          NoMethodError]

  def routing_error
    fail AbstractController::ActionNotFound
  end

  unless Rails.env.development?
    rescue_from *RESCUABLE_EXCEPTIONS do |exception|
      status = case exception.class.to_s
               when "CanCan::AccessDenied", "JWT::DecodeError" then 401
               when "AbstractController::ActionNotFound", "ActionController::RoutingError" then 404
               when "ActiveModel::ForbiddenAttributesError", "ActionController::UnpermittedParameters", "NoMethodError" then 422
               else 400
               end

      if status == 404
        message = "The page you are looking for doesn't exist."
      elsif status == 401
        message = "You are not authorized to access this page."
      else
        message = exception.message
      end

      respond_to do |format|
        format.all { render plain: message, status: status }
      end
    end
  end
end
