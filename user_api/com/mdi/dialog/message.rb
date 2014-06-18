#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################


module UserApis
  module Mdi
    module Dialog
      # A message is a generic purpose data structure used for two-way communication with the device. The object you will received in your callbacks is an instance of this class.
      # @note The only attribute you should really care about is the `content`.
      # @api public
      class MessageClass < Struct.new(:id, :parent_id, :thread_id, :asset, :sender, :recipient, :type, :recorded_at, :received_at, :channel, :account, :meta, :content, :cookies)

        # @!attribute [rw] id
        #   @api public
        #   @return [Integer] a unique message ID set by the server.
        #   Don't touch this

        # @!attribute [rw] parent_id
        #   @api public
        #   A message can be an answer to another. In this case, this attribute will be set to the previous message ID.
        #   @return [String] the ID of the message this message is an answer to. Automaticallly set by the DeviceGate if 

        # @!attribute [rw] thread_id
        #   @api public
        #   A thread is a sequence of messages between the device and the server, each message being a response to the previous one.
        #   Such messages in a sequence will have the same thread id.
        #   @return [String] a thread ID

        # @!attribute [rw] asset
        #   @api public
        #   @return [String] the IMEI or a similar unique identifier of the asset who sent this message (if the essage if coming from a device).

        # @!attribute [rw] sender
        #   @api public
        #   @return [String] an identifier for the sender.

        # @!attribute [rw] recipient
        #   @api public
        #   @return [String] an identifier for the recipient (for instance, `@@server@@`). If your agent receive the message, then he is the intended recipient (you do not need to check this field)

        # @!attribute [rw] type
        #   @api public
        #   @return [String] type of the message ("message", "ack" or "error"). Your agent will actually only receive (and send) "messages"
        #                    so you can ignore this attribute

        # @!attribute [rw] recorded_at
        #   @api public
        #   @return [Bignum] a timestamp indicating when the message was recorded on the device

        # @!attribute [rw] received_at
        #   @api public
        #   @return [Bignum] a timestamp indicating when the message was received on the server.

        # @!attribute [rw] channel
        #   @api public
        #   @return [String] the name of the communication channel. Your agent will only received messages for a channel he is listening to.
        #                    When sending a message, the channek will be set to the first channel the agent is listening to.

        # @!attribute [rw] account
        #   @api public
        #   @return [String] name of the account for this message ("unstable", "municio", ...)

        # @!attribute [rw] meta
        #   @api public
        #   @return [Hash] some metadata for the message, can be nil.

        # @!attribute [rw] content
        #   @api public
        #   @return [String] the payload of the message. That is the part your agent will deal with.

        # @!attribute [rw] cookies
        #   @api public
        #   @return [Array] Protogen cookies. See the Protogen guide for a reference.

        # @api private
        def initialize(apis, struct = nil)

          @user_apis = apis

          account = apis.initial_event_content == nil ? nil : apis.initial_event_content.account

          if struct.blank?
            self.meta = {
              'class'=> 'message',
              'account' => account
            }
            self.type = 'message'
            self.account = account
          else

            self.meta = struct['meta']
            payload = struct['payload']

            self.content = payload['payload']
            self.id = payload['id']
            self.parent_id = payload['parent_id']
            self.thread_id = payload['thread_id']
            self.asset = payload['asset']
            self.sender = payload['sender']
            self.recipient = payload['recipient']
            self.type = payload['type']
            self.recorded_at = payload['recorded_at'].to_i
            self.received_at = payload['received_at'].to_i
            self.channel = payload['channel']

            if meta.is_a? Hash
              self.account = meta['account']
              self.cookies = meta['protogen_cookies']
            end

            if self.type != 'message' && self.type != 'ack'
              raise "Message: wrong type of message : '#{type}'"
            end

            # TODO futur: raise if self.meta.class != 'message'

            if self.id.blank?
              self.id = CC.indigen_next_id(self.asset)
            end

          end

        end

        # @api private
        def user_api
          @user_apis
        end

        # Hash representation of a message.
        #
        #   ``` ruby
        #   {'meta' => self.meta,
        #   'payload' => {
        #     'payload' => self.content,
        #     'channel' => self.channel,
        #     'parent_id' => self.parent_id,
        #     'thread_id' => self.thread_id,
        #     'id' => self.id,
        #     'asset' => self.asset,
        #     'sender' => self.sender,
        #     'recipient' => self.recipient,
        #     'type' => self.type,
        #     'recorded_at' =>  self.recorded_at,
        #     'received_at' =>  self.received_at,
        #     'channel' =>  self.channel
        #   }
        #   ```
        #
        # @return [Hash] a hash representing this message.
        # @api private
        def to_hash
          r_hash = {}
          r_hash['meta'] = self.meta
          r_hash['meta'] = {} if r_hash['meta'] == nil
          r_hash['meta']['class'] = 'message'
          r_hash['meta']['account'] = self.account
          r_hash['payload'] = {
            'payload' => self.content,
            'channel' => self.channel,
            'parent_id' => self.parent_id,
            'thread_id' => self.thread_id,
            'id' => self.id,
            'asset' => self.asset,
            'sender' => self.sender,
            'recipient' => self.recipient,
            'type' => self.type,
            'recorded_at' =>  self.recorded_at.to_i,
            'received_at' =>  self.received_at.to_i,
            'channel' =>  self.channel
          }
          r_hash['meta'].delete_if { |k, v| v.nil? }
          r_hash['payload'].delete_if { |k, v| v.nil? }
          r_hash
        end

        # Pushes the message to the device without any preliminary setup.
        # Useful if you want to do all the setup yourself.
        # @api private
        def fast_push
          CC.push(self.to_hash)
        end

        # Sends this message to the device, using the current message configuration.
        #
        # It will not do any Protogen-related stuff before sending the message.
        #
        # This method will set the `received_at` field to `Time.now.to_i`. Will also set the sender to `@@server@@` if not exists.
        #
        # If the method parameters are not defined the current values stored in the message will be used.
        #
        # @param [String] asset the IMEI of the device or other similar unique identifier.
        # @param [Account] account the account name to use.
        # @api private
        def push(asset = nil, account = nil)
          if !(self.content.is_a? String)
            raise "message content must be of type String (got #{self.content.class.name})"
          end

          # set asset unless nil
          self.asset = asset unless asset.nil?
          self.recipient = asset unless asset.nil?

          # set acount unless nil
          self.account = account unless account.nil?

          # set sender if not defined (ie a direct push)
          self.sender ||= '@@server@@'

          # set received_at
          self.received_at = Time.now.to_i

          self.fast_push
        end


      end #Message
    end #Dialog
  end #Mdi
end #UserApis
