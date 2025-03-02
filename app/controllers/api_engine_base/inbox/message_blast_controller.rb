# frozen_string_literal: true

module ApiEngineBase
  module Inbox
    class MessageBlastController < ::ApiEngineBase::ApplicationController
      include ApiEngineBase::SchemaHelper

      before_action :authenticate_user!
      before_action :authorize_user!

      # GET /inbox/blast
      def metadata
        result = ApiEngineBase::InboxService::Blast::Metadata.(id: params[:id].to_i)
        schema_succesful!(status: 200, schema: result.metadata)
      end

      # GET /inbox/blast/:id
      def blast
        result = ApiEngineBase::InboxService::Blast::Retrieve.(id: params[:id].to_i)
        if result.success?
          schema = result.message_blast
          status = 200
          schema_succesful!(status:, schema:)
        else
          invalid_arguments!(
            status: 400,
            message: result.msg,
            argument_object: result.invalid_argument_hash,
            schema: ApiEngineBase::Schema::PlainText::LoginRequest,
          )
        end
      end

      # POST /inbox/blast
      def create
        upsert
      end

      # PATCH /inbox/blast/:id
      def modify
        upsert(id: params[:id].to_i)
      end

      # DELETE /inbox/blast/:id
      def delete
        result = ApiEngineBase::InboxService::Blast::Delete.(id: params[:id].to_i)
        if result.success?
          schema = result.message
          status = 200
          render :json, { id: params[:id], msg: "Message Blast message deleted" }
        else
          invalid_arguments!(
            status: 400,
            message: result.msg,
            argument_object: result.invalid_argument_hash,
            schema: ApiEngineBase::Schema::PlainText::LoginRequest,
          )
        end
      end

      private

      def upsert(id: nil)
        upsert_params = {
          user: current_user,
          existing_users: safe_boolean(value: params[:existing_users]),
          new_users: safe_boolean(value: params[:new_users]),
          text: params[:text],
          title: params[:title],
          id:,
        }.compact
        result = ApiEngineBase::InboxService::Blast::Upsert.(**upsert_params)

        if result.success?
          schema = result.blast
          status = 200
          schema_succesful!(status:, schema:)
        else
          invalid_arguments!(
            status: 400,
            message: result.msg,
            argument_object: result.invalid_argument_hash,
            schema: ApiEngineBase::Schema::Inbox::BlastRequest
          )
        end
      end
    end
  end
end
