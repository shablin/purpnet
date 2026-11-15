require "socket"
require "log"

module Network
    class DiscoveryServer
        DISCOVERY_PORT = 5556

        @socket : UDPSocket

        def initialize(@tcp_port : Int32)
            @socket = UDPSocket.new
            @socket.bind("0.0.0.0", DISCOVERY_PORT)
        end

        def run

            Log.info { "Discovery port on UDP: #{DISCOVERY_PORT}" }
            
            loop do
                message, address = @socket.receive

                Log.info { "Discovery req: #{address} #{message}" }
                
                next unless message == "PURPNET_DISCOVER_V1"
                response = "PURPNET_SERVER_V1|#{@tcp_port}"
                @socket.send(response, to: address)

                Log.debug { "Discovery response sent to #{address}" }
            end
        rescue IO::Error
            Log.info { "Discovery stopped" } if @socket.closed?
        end

        def close : Nil
            @socket.close unless @socket.closed?
        end
    end
end