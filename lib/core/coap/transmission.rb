module CoRE
  module CoAP
    class Transmission
      # CoAP Message Layer FSM
      # https://tools.ietf.org/html/draft-ietf-lwig-coap-01#section-2.5.2
      class MessageFSM
        include Celluloid::FSM

        default_state :closed

        # Receive CON
        #   Send ACK (accept) -> :closed
        state :ack_pending, to: [:closed]

        # Sending and receiving
        #   Send NON (unreliable_send)
        #   Receive NON
        #   Receive ACK
        #   Receive CON -> :ack_pending
        #   Send CON (reliable_send) -> :reliable_tx
        state :closed, to: [:reliable_tx, :ack_pending]

        # Send CON
        #   Retransmit until
        #     Failure
        #       Timeout (fail) -> :closed
        #       Receive matching RST (fail) -> :closed
        #       Cancel (cancel) -> :closed
        #     Success
        #       Receive matching ACK, NON (rx) -> :closed
        #       Receive matching CON (rx) -> :ack_pending
        state :reliable_tx, to: [:closed, :ack_pending]
      end

      # CoAP Client Request/Response Layer FSM
      # https://tools.ietf.org/html/draft-ietf-lwig-coap-01#section-2.5.1
      class ClientFSM
        include Celluloid::FSM

        default_state :idle

        # Idle
        #   Outgoing request ((un)reliable_send) -> :waiting
        state :idle, to: [:waiting]

        # Waiting for response
        #   Response received (accept, rx) -> :idle
        #   Failure (fail) -> :idle
        #   Cancel (cancel) -> :idle
        state :waiting, to: [:idle]
      end

      # CoAP Server Request/Response Layer FSM
      # https://tools.ietf.org/html/draft-ietf-lwig-coap-01#section-2.5.1
      class ServerFSM
        include Celluloid::FSM

        default_state :idle

        # Idle
        #   On NON (rx) -> :separate
        #   On CON (rx) -> :serving
        state :idle, to: [:separate, :serving]

        # Separate
        #   Respond ((un)reliable_send) -> :idle
        state :separate, to: [:idle]

        # Serving
        #   Respond (accept) -> :idle
        #   Empty ACK (accept) -> :separate
        state :serving, to: [:idle, :separate]
      end

      attr_reader :fsm

      def initialize
        @fsm = MessageFSM.new
      end
    end
  end
end
