# config/initializers/cors.rb
# ref: https://github.com/cyu/rack-cors

# font cors issue with CDN
# Ref: https://stackoverflow.com/questions/56960709/rails-font-cors-policy
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*'
    resource '/packs/*', headers: :any, methods: [:get, :options]
    resource '/audio/*', headers: :any, methods: [:get, :options]
    # Make the public endpoints accessible to the frontend
    resource '/public/api/*', headers: :any, methods: :any

    if ActiveModel::Type::Boolean.new.cast(ENV.fetch('CW_API_ONLY_SERVER', false)) || Rails.env.development?
      resource '*', headers: :any, methods: :any, expose: %w[access-token client uid expiry]
    end
  end
end

################################################
######### Action Cable Related Config ##########
################################################

# Mount Action Cable outside main process or domain
Rails.application.config.action_cable.mount_path = nil

# Configure Action Cable URL from environment
action_cable_url = ENV['ACTION_CABLE_URL']
Rails.application.config.action_cable.url = action_cable_url if action_cable_url.present?

# Allowed origins for Action Cable
allowed_origins = ENV.fetch('ACTION_CABLE_ALLOWED_REQUEST_ORIGINS', '')
                    .split(',')
                    .map(&:strip)
                    .reject(&:empty?)
allowed_origins += [ENV['FRONTEND_URL'], ENV['BACKEND_URL']].compact
allowed_origins.uniq!
Rails.application.config.action_cable.allowed_request_origins = allowed_origins if allowed_origins.present?

# Enable connecting to the API channel public APIs
# Disables request forgery protection for Action Cable
Rails.application.config.action_cable.disable_request_forgery_protection = true
