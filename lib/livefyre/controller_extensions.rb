module Livefyre
  # Public: Controller extensions for Rails. Adds methods to be called from your controller to integrate with Livefyre.
  module Controller
    extend ActiveSupport::Concern

    # Public: Creates the Livefyre session cookies. Should be called when the user logs in.
    def livefyre_login(id, display_name)
      cookie = (Livefyre.config[:cookie_options] || {}).clone || {:path => "/", :expires => Time.now + 1.year}
      expiry = cookie.delete(:expires) || (Time.now + 1.year)

      token = {
        :domain  => Livefyre.client.host,
        :user_id => id,
        :expires => expiry.to_i,
        :display_name => display_name
      }

      name = cookie.delete(:name) || "livefyre_utoken"
      cookies[name] = cookie.merge(:value => JWT.encode(token, Livefyre.client.key), :expires => expiry)
    end

    # Public: Destroys the Livefyre session cookies. Should be called when the user logs out
    def livefyre_logout
      name = (Livefyre.config[:cookie_options] || {})[:name] || "livefyre_utoken"
      cookies.delete(name)
    end

    # Public: Attempt to generate valid Livefyre profile dump from the passed user record by guessing at field names.
    #
    # user   - The user record to generate data from. Assumes it's ActiveModel-ish.
    # values - [Hash] of values to force values for, rather than guessing at.
    #
    # Returns [Hash] suitable for conversion to JSON
    def livefyre_profile(user, values = {})
      {
        :id            => user.id,
        :display_name  => user.try(:display_name) || user.try(:name) || user.try(:username),
        :email         => user.try(:email),
        :profile       => url_for(user),
        :settings_url  => url_for(:edit, user),
        :bio           => user.try(:bio) || user.try(:about),
        :name          => {
          :first_name  => user.try(:first_name),
          :last_name   => user.try(:last_name),
        }
      }.merge defaults
    end

    # Public: Check the validity of the JWT that Livefyre sends with pull requests.
    #
    # Raises [JWT::DecodeError] if the token is invalid or missing.
    def validate_livefyre_request!
      JWT::DecodeError if params[:lftoken].nil?
      token = JWT.decode params[:lftoken], Livefyre.client.key
      raise JWT::DecodeError unless token["domain"] == Livefyre.client.host
      return true
    end

    # Public: Used in your postback handler to parse the Livefyre postback body into an Activity stream for processing
    #
    # Returns [Array<Activity>] List of activities included in this postback.
    def parse_livefyre_postback
      JSON.parse(request.body).map {|item| Activity.new(client, item) }
    end

    module ClassMethods
      # Public: filter helper to validate postback signatures for Livefyre requests.
      #
      # options - valid before_filter options, plus :key
      #
      # Example:
      #
      #     validate_postback_signature :only => [:postback], :key => "your_site_key"
      def validate_postback_signature(options = {})
        key = options.delete :key
        before_filter Proc.new {|c|
          Livefyre::Site.validate_signature(c.params, key)
        }, options
      end
    end
  end
end
