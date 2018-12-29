Bugsnag.configure do |config|
  config.api_key = ENV["BUGSNAG_KEY"]
  config.notify_release_stages = %w(stage production)
  config.app_version = Lupo::Application::VERSION
  config.auto_capture_sessions = true
end
