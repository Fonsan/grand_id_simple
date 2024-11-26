# frozen_string_literal: true

require 'cgi'
require 'webrick'
require 'grand_id_simple'
require 'sinatra/base'

class FakeGrandIdSimple < GrandIdSimple
  class FakePerson < Person
    def session_id
      @session_id ||= Digest::SHA256.hexdigest(rand.to_s)
    end

    def name
      "#{given_name} #{surname}"
    end
  end

  def self.add_query_parameter(url, name, value)
    uri = URI.parse(url)
    new_query_ar = URI.decode_www_form(uri.query || '') << [name, value]
    uri.query = URI.encode_www_form(new_query_ar)
    uri.to_s
  end

  def initialize(&block)
    super(nil, nil)
    @block = block
    @people = []
    @server = WEBrick::HTTPServer.new(Port: 0)
    @app = Sinatra.new do
      get '/' do
        return redirect params[:callback_url] if params[:session_id]

        settings.people.map do |person|
          %(<a href="#{FakeGrandIdSimple.add_query_parameter(params[:callback_url], 'grandidsession', person.session_id)}">#{person.name}</a><br/>)
        end.join
      end
    end
    @app.set :people, @people
    @server.mount('/', Rack::Handler::WEBrick, @app)
    @base_url = "http://localhost:#{@server.config[:Port]}"
  end

  def start!
    @server_thread = Thread.start { @server.start }
  end

  def federated_login(**options)
    @people.concat(@block.call) if @people.empty?
    redirect_url = FakeGrandIdSimple.add_query_parameter(@base_url, 'callback_url', options[:callbackUrl])
    Login.new(redirect_url: redirect_url)
  end

  def get_session(session_id)
    @people.find {|person| person.session_id == session_id }
  end

  def logout(_session_id)
    Logout.new(sessiondeleted: true)
  end
end
