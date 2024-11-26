# frozen_string_literal: true

require_relative 'grand_id_simple/version'
require 'oj'
require 'typhoeus'

class GrandIdSimple
  DEFAULT_BASE_URL = 'https://client.grandid.com'

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
    :uhi,
    :bank_id_issue_date,
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

  # callbackUrl string  Optional  Where to return end-user after completion.
  # customerURL string  Optional  Where to return end-user if they press the back button.
  # userVisibleData base64  Optional  Visible data for the end-user to sign.
  # userNonVisibleData  base64  Optional  Hidden data included in the signature.
  # userVisibleDataFormat string  Optional  Used to format the visible signature data.
  # authMessage base64  Optional  Visible data for the end-user to auth.
  # mobileBankId  bool  Optional  Set to true to force usage of a Mobile BankID.
  # desktopBankId bool  Optional  Set to true to force usage of a Desktop BankID.
  # thisDevice  bool  Optional  Set to true to allow usage of the end-users current device
  # qr  bool  Optional  Set to true to allow authentication/signing using a QR code
  # allowFingerprintAuth  string  Optional  Set whether usage of fingerprint biometrics is allowed with the authentication.
  # allowFingerprintSign  string  Optional  Set whether usage of fingerprint biometrics is allowed with the signature.
  # gui string  Optional  Set to false to opt out of GrandID’s user interface and build your custom implementation.
  # appRedirect string  Optional  Can be used to force a redirect to specific application from the BankID application.

  def federated_login(**options)
    body = call_api(
      :FederatedLogin,
      method: :post,
      body: {
        **options,
      },
    )
    Login.new(body)
  end

  def get_session(session_id)
    body = call_api(:GetSession, params: {sessionId: session_id})
    Person.new(body[:user_attributes])
  end

  def logout(session_id)
    body = call_api(:Logout, params: {sessionId: session_id})
    Logout.new(body)
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
    body = json_load(response.body)
    raise StandardError, 'no body' unless body
    if error_object = body[:error_object]
      raise Error.new(*error_object.values_at(:code, :message))
    end

    body
  end

  def default_params
    {
      apiKey: @api_key,
      authenticateServiceKey: @service_key,
    }
  end

  def json_load(body)
    deep_underscore_keys(Oj.load(body, symbol_keys: true))
  end

  def deep_underscore_keys(hash)
    deep_transform_keys(hash) {|key| key.to_s.gsub(/([a-z])([A-Z]+)/, '\1_\2').downcase.to_sym }
  end

  def deep_transform_keys(hash, &block)
    hash.each_with_object({}) do |(key, value), result|
      new_key = yield(key)
      new_value = if value.is_a?(Hash)
        deep_transform_keys(value, &block)
      elsif value.is_a?(Array)
        value.map {|item| item.is_a?(Hash) ? deep_transform_keys(item, &block) : item }
      else
        value
      end
      result[new_key] = new_value
    end
  end

  def url(call)
    "#{@base_url}/json1.1/#{call}"
  end
end
