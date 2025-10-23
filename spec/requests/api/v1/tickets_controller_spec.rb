# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::TicketsController, type: :request do
  let(:user) { create(:user) }
  let(:profile) { create(:profile, user: user) }
  let(:valid_ticket_params) do
    {
      ticket: {
        kind: 'bug',
        title: 'Test Bug Report',
        description: 'This is a test bug report with detailed description.',
        source: 'app'
      },
      app_version: '1.0.0',
      device_model: 'iPhone 14',
      os_version: '17.0',
      locale: 'en',
      timezone: 'America/New_York',
      network_state: 'online',
      current_route: 'help-support',
      user_id: user.id.to_s
    }
  end

  before do
    sign_in user
  end

  describe 'POST /api/v1/tickets' do
    context 'with valid parameters' do
      it 'creates a new ticket' do
        expect do
          post '/api/v1/tickets', params: valid_ticket_params
        end.to change(Ticket, :count).by(1)

        expect(response).to have_http_status(:created)

        ticket = Ticket.last
        aggregate_failures 'diagnostics metadata' do
          expect(ticket.kind).to eq('bug')
          expect(ticket.title).to eq('Test Bug Report')
          expect(ticket.description).to eq('This is a test bug report with detailed description.')
          expect(ticket.source).to eq('app')
          expect(ticket.profile.user).to eq(user)
          expect(ticket.metadata['app_version']).to eq('1.0.0')
          expect(ticket.metadata['device_model']).to eq('iPhone 14')
        end
      end
    end

    context 'with invalid parameters' do
      it 'returns unprocessable entity status' do
        invalid_params = valid_ticket_params.dup
        invalid_params[:ticket][:title] = ''

        post '/api/v1/tickets', params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['errors']).to include("Title can't be blank")
      end
    end

    context 'when user is not authenticated' do
      it 'returns unauthorized status' do
        sign_out user
        post '/api/v1/tickets', params: valid_ticket_params

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /api/v1/tickets/:id' do
    let(:ticket) { create(:ticket, profile: profile) }

    context 'when ticket exists' do
      it 'returns the ticket' do
        get "/api/v1/tickets/#{ticket.id}"

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['id']).to eq(ticket.id)
      end
    end

    context 'when ticket does not exist' do
      it 'returns not found status' do
        get '/api/v1/tickets/999999'

        expect(response).to have_http_status(:not_found)
        expect(response.parsed_body['error']).to eq('Ticket not found')
      end
    end

    context 'when user is not authenticated' do
      it 'returns unauthorized status' do
        sign_out user
        get "/api/v1/tickets/#{ticket.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
