require "./command"
require "../client"


module CLI
    class ConnectCommand < Command
        def run(host : String, port : Int32)
            client = Network::Client.new(host, port)
            client.send_message("hey there! i am connected!")
        end
    end
end