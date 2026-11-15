require "./protocol"

module Network
    class Client
        def initialize(host : String, port : Int32)
            @socket = TCPSocket.new(host, port)
        end
        
        def send_message(message : String)
            Network::Protocol.write_frame(
                @socket, Network::Protocol::Opcode::Send,
                1_u32, message.to_slice
            )
        end
    end
end


# TCPSocket.open("127.0.0.1", 25565) do |sock|
    
#     # ack = Network::Protocol.read_message(sock)
    
#     # puts <<-TEXT
#     # << SEND >> 
#     # id=#{ack.try(&.request_id)}
#     # status=#{ack.try(&.status)}
#     # ===============================
#     # TEXT

#     # Network::Protocol.write_frame(sock, Network::Protocol::Opcode::Get, 2_u32)
#     # reply = Network::Protocol.read_message(sock)

#     # puts <<-TEXT
#     # << SEND >>
#     # id=#{ack.try(&.request_id)}
#     # status=#{ack.try(&.status)}
#     # body=#{reply.try { |m| String.new(m.payload) }}
#     # ===============================
#     # TEXT
# end