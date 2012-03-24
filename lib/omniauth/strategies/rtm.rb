require 'omniauth'
require 'moocow'

module OmniAuth
  module Strategies
    class RTM
      include OmniAuth::Strategy

      args [:consumer_key, :consumer_secret]

      option :consumer_key, nil
      option :consumer_secret, nil

      def request_phase
        auth_url = rtm_auth.url :delete, :web #, "http://localhost:3000/auth/rtm/callback"

        session['oauth'] ||= {}
        session['oauth']['rtm'] = {}

        redirect(auth_url)
      rescue ::Timeout::Error => e
        fail!(:timeout, e)
      rescue ::Net::HTTPFatalError => e
        fail!(:service_unavailable, e)
      end

      def callback_phase
        raise OmniAuth::NoSessionError.new("Session Expired") if session['oauth'].nil?

        rtm_auth.frob = request.params['frob']

        @token = rtm_auth.get_token
        rtm.token = @token

        resp = rtm.check_token

        @uid      = resp['auth']['user']['id']
        @nickname = resp['auth']['user']['username']
        @fullname = resp['auth']['user']['fullname']

        super
      rescue ::Timeout::Error => e
        fail!(:timeout, e)
      rescue ::Net::HTTPFatalError, ::OpenSSL::SSL::SSLError => e
        fail!(:service_unavailable, e)
      rescue ::RTM::VerificationException => e
        fail!(:invalid_credentials, e)
      rescue ::OmniAuth::NoSessionError => e
        fail!(:session_expired, e)
      end

      uid { @uid }

      info do
        {
          :name => @fullname,
          :nickname => @nickname
        }
      end

      credentials do
        {
          :token => @token
        }
      end

      private

      def rtm
        @rtm ||= ::RTM::RTM.new(::RTM::Endpoint.new(options.consumer_key, options.consumer_secret))
      end

      def rtm_auth
        @auth ||= rtm.auth
      end
    end
  end
end

OmniAuth.config.add_camelization 'rtm', 'RTM'
