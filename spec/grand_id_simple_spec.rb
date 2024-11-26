# frozen_string_literal: true

RSpec.describe GrandIdSimple do
  subject { described_class.new(api_key, service_key, base_url: base_url) }

  let(:api_key) { '123' }
  let(:service_key) { '456' }
  let(:base_url) { 'https://test.grandid.com' }

  def response(body = {})
    Typhoeus::Response.new(code: 200, body: Oj.dump(body))
  end

  describe '#federated_login' do
    it 'requests with correct parameters' do
      Typhoeus.stub("#{base_url}/json1.1/FederatedLogin") do |request|
        expect(request.options[:params]).to eq(apiKey: '123', authenticateServiceKey: '456')
        response
      end
      subject.federated_login(callbackUrl: 'http://callback-host.com/abc')
    end

    it 'translates reponse' do
      Typhoeus.stub("#{base_url}/json1.1/FederatedLogin").and_return(
        response(
          sessionId: '999',
          redirectUrl: 'http://foo.com',
        ),
      )
      expect(
        subject.federated_login(callbackUrl: 'http://callback-host.com/abc'),
      ).to eq(
        GrandIdSimple::Login.new(
          session_id: '999',
          redirect_url: 'http://foo.com',
        ),
      )
    end
  end

  describe '#get_session' do
    it 'requests with correct parameters' do
      Typhoeus.stub("#{base_url}/json1.1/GetSession") do |request|
        expect(request.options[:params]).to eq(
          apiKey: '123',
          authenticateServiceKey: '456',
          sessionId: '999',
        )
        response(
          sessionId: '999',
          username: '88',
          userAttributes: {
            name: 'Robert',
          },
        )
      end
      subject.get_session('999')
    end

    it 'translates reponse' do
      Typhoeus.stub("#{base_url}/json1.1/GetSession").and_return(
        response(
          sessionId: '999',
          username: '88',
          userAttributes: {
            name: 'Robert',
          },
        ),
      )
      expect(
        subject.get_session('999'),
      ).to eq(
        GrandIdSimple::Person.new(name: 'Robert'),
      )
    end
  end

  describe '#logout' do
    it 'requests with correct parameters' do
      Typhoeus.stub("#{base_url}/json1.1/Logout") do |request|
        expect(request.options[:params]).to eq(
          apiKey: '123',
          authenticateServiceKey: '456',
          sessionId: '999',
        )
        response
      end
      subject.logout('999')
    end

    it 'translates reponse' do
      Typhoeus.stub("#{base_url}/json1.1/Logout").and_return(
        response(
          sessiondeleted: '1',
        ),
      )
      expect(
        subject.logout('999'),
      ).to eq(
        GrandIdSimple::Logout.new(sessiondeleted: '1'),
      )
    end
  end
end
