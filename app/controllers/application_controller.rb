class ApplicationController < ActionController::API
  include ActionController::HttpAuthentication::Basic::ControllerMethods

  include Bolognese::DoiUtils
  include Bolognese::Utils

  attr_accessor :username, :password

  before_action :set_raven_context
  after_action :set_consumer_header

  # check that username and password exist
  # store them in instance variables used for calling MDS API
  def authenticate_user_with_basic_auth!
    @username, @password = ActionController::HttpAuthentication::Basic::user_name_and_password(request)

    request_http_basic_authentication(realm = ENV['REALM']) unless @username.present? && @password.present?
  end

  def set_consumer_header
    if username
      response.headers['X-Credential-Username'] = username
    else
      response.headers['X-Anonymous-Consumer'] = true
    end
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
               when "NotImplementedError" then 501
               else 400
               end

      # EZID functionality not supported by this service
      status = 501 if exception.message.end_with?("not supported by this service")

      if status == 404
        message = "bad request - no such identifier"
        status = 400
      elsif status == 401
        message = "unauthorized"
      elsif status == 501 || exception.class.to_s == "IdentifierError"
        # don't raise Sentry error
        
        message = exception.message
      else
        Raven.capture_exception(exception)

        message = exception.message
      end

      Rails.logger.error "[#{status}]: " + message

      render plain: "error: " + message, status: status
    end
  end

  def append_info_to_payload(payload)
    super
    payload[:uid] = username.downcase if username.present?
    payload[:data] = request.raw_post.from_anvl if request.raw_post.present?
  end

  def set_raven_context
    if username.present?
      Raven.user_context(
        id: username.downcase,
        ip_address: request.ip
      )
    else
      Raven.user_context(
        ip_address: request.ip
      ) 
    end
  end
end
