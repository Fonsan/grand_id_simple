# frozen_string_literal: true

require_relative 'grand_id_simple/version'
require 'oj'
require 'typhoeus'

class GrandIdSimple
  DEFAULT_BASE_URL = 'client.grandid.com'

  class Error < StandardError
    attr_reader :code

    def initialize(code, message)
      @code = code
      super(message)
    end
  end

  Person = Struct.new(
    :personal_number,
    :name,
    :given_name,
    :surname,
    :ip_address,
    :not_before,
    :not_after,
    :signature,
    :ocsp_response,
    keyword_init: true,
  )

  Login = Struct.new(
    :session_id,
    :redirect_url,
    keyword_init: true,
  )

  Logout = Struct.new(
    :sessiondeleted,
    keyword_init: true,
  )

  def initialize(api_key, service_key, base_url: DEFAULT_BASE_URL)
    @api_key = api_key
    @service_key = service_key
    @base_url = base_url
  end

  def federated_login(callback_url, personal_number: nil)
    body = call_api(
      :FederatedLogin,
      method: :post,
      body: {
        thisDevice: false,
        askForSSN: !personal_number,
        personalNumber: personal_number,
        qr: true,
        callbackUrl: callback_url,
      },
    )
    Login.new(lower_keys(body))
  end

  def get_session(session_id)
    body = call_api(:GetSession, params: {sessionId: session_id})
    Person.new(lower_keys(body[:userAttributes]))
  end

  def logout(session_id)
    body = call_api(:Logout, params: {sessionId: session_id})
    Logout.new(lower_keys(body))
  end

  private

  def call_api(call, method: :get, params: {}, body: nil)
    request = Typhoeus::Request.new(
      url(call),
      method: method,
      params: default_params.merge(params),
      body: body,
    )
    response = request.run
    body = Oj.load(response.body, symbol_keys: true)
    raise StandardError, 'no body' unless body
    if error_object = body[:errorObject]
      raise Error.new(*lower_keys(error_object).values_at(:code, :message))
    end

    body
  end

  def default_params
    {
      apiKey: @api_key,
      authenticateServiceKey: @service_key,
    }
  end

  def lower_keys(hash)
    hash.transform_keys {|k| k.to_s.gsub(/([a-z])([A-Z]+)/, '\1_\2').downcase.to_sym }
  end

  def url(call)
    "#{@base_url}/json1.1/#{call}"
  end
end
