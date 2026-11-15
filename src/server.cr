require "./protocol"
require "log"
require "./discovery_server"

module Network
    class Server
        alias Handler = Proc(Protocol::Message, Protocol::Response?)

        getter host : String
        getter port : Int32

        def initialize(@host : String, @port : Int32, &@handler : Handler)
            @listener = TCPServer.new(@host, @port)
            @discovery = DiscoveryServer.new(@port)

            Log.info { "Server listening on #{@host}:#{@port}..."}
        end

        def run : Nil
            spawn do
                @discovery.run
            end

            loop do
                client = @listener.accept?
                break unless client
                spawn serve(client)
                
                Log.info { "#{client.remote_address} connected" }
            end
        end

        def close : Nil
            @listener.close
            @discovery.close
        end

        private def serve(client : TCPSocket) : Nil
            loop do
                request = Protocol.read_message(client)
                break if request.nil?

                if request.opcode.value & 0x80_u8 != 0
                    raise Protocol::ProtoError.new("client sent response opcode")
                end

                response = begin
                    @handler.call(request)
                rescue ex
                    Log.error(exception: ex) { "handler failed" }
                    
                    Protocol::Response.new(
                        Protocol::Opcode::GetReply,
                        Protocol::Status::Internal,
                        Bytes.empty
                    )
                end

                next if response.nil?

                Protocol.write_frame(
                    client,
                    opcode: response.opcode,
                    request_id: request.request_id,
                    payload: response.payload,
                    status: response.status
                )
            end

        rescue Protocol::ProtoError
            # broken frame
        rescue IO::Error
            # connection lost
        ensure
            Log.info { "#{client.remote_address} closed connection" }
            client.close rescue nil
        end
    end
end