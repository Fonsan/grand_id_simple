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
  def initialize(&block)
    @block = block
    @people = []
    @server = WEBrick::HTTPServer.new(Port: 0)
    @app = Sinatra.new do
      get '/' do
        return redirect params[:callback_url] if params[:session_id]
        settings.people.map do |person|
          uri = URI.parse(params[:callback_url])
          new_query_ar = URI.decode_www_form(uri.query || '') << ["grandidsession", person.session_id]
          uri.query = URI.encode_www_form(new_query_ar)
          %(<a href="#{uri}">#{person.name}</a><br/>)
        end.join
      end
    end
    @app.set :people, @people
    @server.mount('/', Rack::Handler::WEBrick, @app)
    @server_thread = Thread.start { @server.start }
    @base_url = "http://localhost:#{@server.config[:Port]}"
  end

  def federated_login(callback_url, personal_number: nil)
    @people.concat(@block.call) if @people.empty?
    Login.new(
      redirect_url: "#{@base_url}?callback_url=#{callback_url}"
    )
  end

  def get_session(session_id)
    @people.find {|person| person.session_id == session_id}
  end

  def logout(session_id)
    Logout.new(sessiondeleted: true)
  end
end
