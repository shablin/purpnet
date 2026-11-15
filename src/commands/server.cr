require "./command"
require "../server"
require "log"

module CLI
    class ServerCommand < Command
        def run(host : String, port : Int32)
            Log.setup(:info)

            counter = 0

            handler : Network::Server::Handler = ->(req : Network::Protocol::Message) do
                case req.opcode
                when .get?
                    counter += 1
    
                    Network::Protocol::Response.new(
                        Network::Protocol::Opcode::GetReply,
                        Network::Protocol::Status::Ok,
                        "counter=#{counter}".to_slice
                    )
                when .send?
                    Log.info { "message: #{String.new(req.payload)}" }
    
                    Network::Protocol::Response.new(
                        Network::Protocol::Opcode::SendAck,
                        Network::Protocol::Status::Ok,
                        Bytes.empty
                    )
                else
                    nil
                end
            end

            server = Network::Server.new(host, port, &handler)
            server.run
        end
    end
end