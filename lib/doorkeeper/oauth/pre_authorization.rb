module Doorkeeper
  module OAuth
    class PreAuthorization
      include Validations

      validate :response_type, error: :unsupported_response_type
      validate :client, error: :invalid_client
      validate :scopes, error: :invalid_scope
      validate :redirect_uri, error: :invalid_redirect_uri

      attr_accessor :config, :server, :client, :response_type, :redirect_uri, :state
      attr_writer   :scope

      def initialize(config, server, client, attrs = {})
        @config        = config
        @server        = server
        @client        = client
        @response_type = attrs[:response_type]
        @redirect_uri  = attrs[:redirect_uri]
        @scope         = attrs[:scope]
        @state         = attrs[:state]
      end

      def authorizable?
        valid?
      end

      def scopes
        Scopes.from_string scope
      end

      def scope
        @scope.presence || config.default_scopes.to_s
      end

      def error_response
        OAuth::ErrorResponse.from_request(self)
      end

      def validate
        super
        if extra_validation === false
          @error ||= :invalid_scope
        end
      end

      private

      def validate_response_type
        config.authorization_response_types.include? response_type
      end

      def validate_client
        client.present?
      end

      def validate_scopes
        return true unless scope.present?
        Helpers::ScopeChecker.valid? scope, config.scopes
      end

      # TODO: test uri should be matched against the client's one
      def validate_redirect_uri
        return false unless redirect_uri.present?
        Helpers::URIChecker.native_uri?(redirect_uri) ||
          Helpers::URIChecker.valid_for_authorization?(redirect_uri, client.redirect_uri)
      end

      def extra_validation
        Doorkeeper.configuration.validate_on_authorize.call self, @server.current_resource_owner, @client, scopes.all
      end
    end
  end
end
