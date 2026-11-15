require "socket"
require "log"

module Network
    class DiscoveryClient
        DISCOVERY_PORT = 5556

        def scan(timeout : Time::Span = 3.seconds)
            socket = UDPSocket.new
            socket.broadcast = true

            broadcast = Socket::IPAddress.new(
                "255.255.255.255",
                DISCOVERY_PORT
            )

            socket.send("PURPNET_DISCOVERY_V1", to: broadcast)
            socket.read_timeout = timeout

            servers = [] of String

            loop do
                message, address = socket.receive
                Log.info { "Discovery client: #{message} #{address}" }
                next unless message.starts_with?("PURPNET_SERVER_V1|")

                tcp_port = message.split("|")[1]?
                next unless tcp_port

                result = "#{address.address}:#{tcp_port}"
                servers << result unless servers.includes?(result)
            rescue IO::TimeoutError
                break
            end

            servers
        ensure
            socket.try &.close
        end
    end
end