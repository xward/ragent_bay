module ProtocolGenerator

  module Models

    class Shot

      attr_accessor :message_type, :name, :id, :retry_policy
      attr_reader :next_shots

      def initialize(params = {})
        self.way = params[:way]
        @name = params[:name]
        @message_type = params[:message_type] # Models::Message
        @callbacks = {}
        AVAILABLE_CALLBACKS.each do |cb|
          add_callback(cb, params[cb]) if params[cb] # string
        end
        @next_shots = params[:next_shots] || []
        @id = params[:id]

        @timeouts = {}
        if (params[:send_timeout] || params[:receive_timeout]) && self.way == :toDevice
          raise Error::ProtogenError.new("Protogen does not handle server-side timeouts.")
        end
        @timeouts[:send] = 60
        @timeouts[:send] = params[:send_timeout] if params[:send_timeout]
        @timeouts[:receive] = 60
        @timeouts[:receive] = params[:receive_timeout] if params[:receive_timeout]
        self.multiple = if params[:multiple] then params[:multiple] else false end
      end

      # @return `true` if it this shot does not have any "next shots" defined
      def last?
        @next_shots.size == 0
      end

      def multiple=(multiple)
        if multiple
          if way != :to_device
            raise ArgumentError.new("A shot can be marked as multiple only if it way is set to :to_device")
          end
        end
        @multiple = multiple
      end

      # @return `true` if this shot can be send several times in succession, triggering the device callback each time
      def multiple?
        @multiple
      end

      def way=(new_way)
        if new_way != :to_server && new_way != :to_device
          raise ArgumentError.new("A shot way can only be :to_server or :to_device, got #{way}")
        end
        unless @message_type.nil?
          if @message_type.way != new_way
            raise ArgumentError.new("Shot way set to #{new_way} while its message type has 'way' set to #{@message_type.way}")
          end
        end
        if self.multiple?
          if new_way == :to_server
            raise ArgumentError.new("A shot marked as multiple can not be sent to the server.")
          end
        end
        @way = new_way
      end

      def way
        @way
      end

      def next_shots=(next_shots)
        unless next_shots.is_a? Array # to prevent next_shots from being nil
          raise ArgumentError.new("Next shots can't be nil (but can be an empty array)")
        end
        @next_shots = next_shots
      end

      # @param [Symbol] cb a specific callback (like :received_callback)
      def has_callback?(cb)
        @callbacks.has_key?(cb)
      end

      # @param [Symbol] cb callback type (like :received_callback)
      # @params [String] cb_name name of the callback
      def add_callback(cb, cb_name)
        if AVAILABLE_CALLBACKS.include?(cb)
          if(validate_callback_name(cb))
            @callbacks[cb] = cb_name
          else
            raise Error::SequenceError.new("Invalid callback name: #{cb_name}")
          end
        else
          raise Error::ProtogenError.new("Invalid callback: #{cb}, expected one of #{AVAILABLE_CALLBACKS.inspect}")
        end
      end

      # @param [Symbol] cb a callback
      # @return [String] the callback name (nil if no callback name was defined for this callback
      # @raise [Error::ProtogenError] if the @a cb parameter is not a callback that Protogen accepts.
      def callback(cb)
        if AVAILABLE_CALLBACKS.include?(cb)
          return @callbacks[cb]
        else
          raise Error::ProtogenError.new("Invalid callback: #{cb}, expected one of #{AVAILABLE_CALLBACKS.inspect}")
        end
      end

      # @return [Array<Symbol>] the list of the callbacks the user explicitely defined for this shot
      def defined_callbacks
        @callbacks.keys
      end

      def callbacks
        @callbacks.values
      end

      # @return [Integer] in seconds, duration for the given timeout. Note that these timeouts are always defined if they are relevant (with default value if necessary).
      # @param [Symbol] event :send or :receive (if applicable)
      # @return [Fixnum] the timeout for the given event (the default value is used if it was not explicitely defined before)
      # @raise [Error::ProtogenError] when trying to access an invalid event or when asking for the :receive event when no server reply is expected
      def timeout(event)
        unless [:receive, :send].include?(event)
          raise Error::ProtogenError.new("Invalid timeout event: #{event} #{if self.name then '(shot ' + self.name + ')' end }")
        end
        if event == :receive && self.last?
          raise Error::ProtogenError.new("No response timeout is available for shots that do not expect a reply #{if self.name then '(shot ' + self.name + ')' end }")
        end
        if @timeouts.has_key?(event)
          return @timeouts[event]
        else
          return DEFAULT_TIMEOUT[event] #defined in schema.rb
        end
      end

      # Runs the following list of checks:
      # * :received_callbacks should be defined
      # * if it is a multiple shot, the "all_received_callback" should be defined
      # * if the way is set to :toDevice, no other callback should be defined.
      # @return [Boolean] if all checks passed
      def validate_callbacks
        ok = @callbacks.has_key?(:received_callback)
        if multiple?
          ok &&= @callbacks.has_key?(:all_received_callback)
          if @way == :to_device
            ok &&= (@callbacks.size == 2)
          end
        else
          if @way == :to_device
            ok &&= (@callbacks.size == 1)
          end
        end
        ok
      end

      def has_retry_policy?
        !@retry_policy.nil?
      end

      private

      def validate_callback_name(name)
        name.match(/^[a-z]/)
      end

    end

  end

end