require "spec_helper"

describe "OmniAuth::Strategies::RTM" do
  def app
    Rack::Builder.new {
      use OmniAuth::Test::PhonySession
      use OmniAuth::Builder do
        provider :rtm, 'apikey', 'apisec'
      end
      run lambda { |env| [404, {'Content-Type' => 'text/plain'}, [env.key?('omniauth.auth').to_s]] }
    }.to_app
  end

  def session
    last_request.env['rack.session']
  end

  it 'should add a camelization for itself' do
    OmniAuth::Utils.camelize('rtm').should == 'RTM'
  end

  let(:rtm){ double 'rtm' }
  let(:rtm_auth){ double 'rtm_auth' }
  let(:auth_url){ double 'auth_url' }

  before do
    RTM::RTM.stub(:new).and_return(rtm)
    rtm.stub(:auth).and_return(rtm_auth)
    rtm_auth.stub(:url).and_return(auth_url)
  end

  describe '/auth/rtm' do
    context 'successful' do
      it 'should redirect to authorize_url' do
        rtm_auth.should_receive(:url).with(:delete, :web).and_return(auth_url)

        get '/auth/rtm'

        last_response.should be_redirect
        last_response.headers['Location'].should == auth_url
      end
    end

    context 'unsuccessful' do
      it 'should call fail! with :timeout' do
        rtm_auth.stub(:url).and_raise(::Timeout::Error)

        get '/auth/rtm'

        last_request.env['omniauth.error'].should be_kind_of(::Timeout::Error)
        last_request.env['omniauth.error.type'] = :timeout
      end

      it 'should call fail! with :service_unavailable' do
        rtm_auth.stub(:url).and_raise(::Net::HTTPFatalError.new(%Q{502 "Bad Gateway"}, nil))

        get '/auth/rtm'

        last_request.env['omniauth.error'].should be_kind_of(::Net::HTTPFatalError)
        last_request.env['omniauth.error.type'] = :service_unavailable
      end
    end
  end

  describe '/auth/rtm/callback' do
    before do
      rtm_auth.stub(:frob=)
      rtm_auth.stub(:get_token).and_return('rtmaccesstoken')
      rtm.stub(:token=)
      rtm.stub(:check_token).and_return({
        'auth' => {'user' => {
          'id' => 123456,
          'username' => 'nicck',
          'fullname' => 'Nickolay Abdrafikov',
        }}
      })
    end

    it 'should call through to the master app' do
      get '/auth/rtm/callback', {:frob => '123frob456'}, {'rack.session' => {'oauth' => {"rtm" => {}}}}
      last_response.body.should == 'true'
    end

    it 'should pass uid to env' do
      get '/auth/rtm/callback', {:frob => '123frob456'}, {'rack.session' => {'oauth' => {"rtm" => {}}}}
      last_request.env['omniauth.auth']['uid'].should == 123456
    end

    it 'should pass token to env' do
      get '/auth/rtm/callback', {:frob => '123frob456'}, {'rack.session' => {'oauth' => {"rtm" => {}}}}
      last_request.env['omniauth.auth']['provider'].should == 'rtm'
      last_request.env['omniauth.auth']['credentials']['token'].should == 'rtmaccesstoken'
    end

    it 'should pass info to env' do
      get '/auth/rtm/callback', {:frob => '123frob456'}, {'rack.session' => {'oauth' => {"rtm" => {}}}}
      last_request.env['omniauth.auth']['info']['name'].should == 'Nickolay Abdrafikov'
      last_request.env['omniauth.auth']['info']['nickname'].should == 'nicck'
    end

    describe 'rtm_api' do
      after do
        get '/auth/rtm/callback', {:frob => '123frob456'}, {'rack.session' => {'oauth' => {"rtm" => {}}}}
      end

      it 'should pass frob to rtm_auth' do
        rtm_auth.should_receive(:frob=).with('123frob456')
      end

      it 'should get token from rtm_auth' do
        rtm_auth.should_receive(:get_token)
      end

      it 'should pass token to rtm' do
        rtm.should_receive(:token=).with('rtmaccesstoken')
      end

      it 'should fetch user info from rtm' do
        rtm.should_receive(:check_token)
      end
    end

    context "bad gateway (or any 5xx) for access_token" do
      before do
        rtm_auth.stub(:get_token).
          and_raise(::Net::HTTPFatalError.new(%Q{502 "Bad Gateway"}, nil))

        get '/auth/rtm/callback', {:frob => '123frob456'}, {'rack.session' => {'oauth' => {"rtm" => {}}}}
      end

      it 'should call fail! with :service_unavailable' do
        last_request.env['omniauth.error'].should be_kind_of(::Net::HTTPFatalError)
        last_request.env['omniauth.error.type'] = :service_unavailable
      end
    end

    context "SSL failure" do
      before do
        rtm_auth.stub(:get_token).
          and_raise(::OpenSSL::SSL::SSLError.new("SSL_connect returned=1 errno=0 state=SSLv3 read server certificate B: certificate verify failed"))

        get '/auth/rtm/callback', {:frob => '123frob456'}, {'rack.session' => {'oauth' => {"rtm" => {'callback_confirmed' => true, 'request_token' => 'yourtoken', 'request_secret' => 'yoursecret'}}}}
      end

      it 'should call fail! with :service_unavailable' do
        last_request.env['omniauth.error'].should be_kind_of(::OpenSSL::SSL::SSLError)
        last_request.env['omniauth.error.type'] = :service_unavailable
      end
    end

    context "Timeout failure" do
      before do
        rtm_auth.stub(:get_token).
          and_raise(::Timeout::Error)

        get '/auth/rtm/callback', {:frob => '123frob456'}, {'rack.session' => {'oauth' => {"rtm" => {'callback_confirmed' => true, 'request_token' => 'yourtoken', 'request_secret' => 'yoursecret'}}}}
      end

      it 'should call fail! with :timeout' do
        last_request.env['omniauth.error'].should be_kind_of(::Timeout::Error)
        last_request.env['omniauth.error.type'] = :timeout
      end
    end

    context "Invalid frob failure" do
      before do
        rtm_auth.stub(:get_token).
          and_raise(::RTM::VerificationException)

        get '/auth/rtm/callback', {:frob => '123frob456'}, {'rack.session' => {'oauth' => {"rtm" => {'callback_confirmed' => true, 'request_token' => 'yourtoken', 'request_secret' => 'yoursecret'}}}}
      end

      it 'should call fail! with :invalid_credentials' do
        last_request.env['omniauth.error'].should be_kind_of(::RTM::VerificationException)
        last_request.env['omniauth.error.type'] = :invalid_credentials
      end
    end
  end

  describe '/auth/rtm/callback with expired session' do
    before do
      get '/auth/rtm/callback', {:from => '123frob456'}, {'rack.session' => {}}
    end

    it 'should call fail! with :session_expired' do
      last_request.env['omniauth.error'].should be_kind_of(::OmniAuth::NoSessionError)
      last_request.env['omniauth.error.type'] = :session_expired
    end
  end
end
