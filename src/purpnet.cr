require "log"
require "option_parser"
require "./server"
require "./protocol"

require "./commands/server"
require "./commands/connect"
require "./commands/discover"

server = false
connect = false
lan_discover = false
wan_discover = false
host = "127.0.0.1"
port = 555

parser = OptionParser.new do |parser|
    parser.banner = "Usage: purpnet [subcommands] or [args]"

    parser.on("discover", "Discover Purpnet Servers in LAN or WAN") do
        parser.banner = "Usage: purpnet discover [args]"
        parser.on("-l", "--lan", "Discover Purpnet Servers in LAN") { lan_discover = true }
        
        #wan_discover = true
    end

    parser.on("connect", "Connect to a specific server") do
        connect = true
        parser.banner = "Usage: purpnet connect [args]"

        parser.on("-h HOST", "--host=HOST", "Server host") do |v|
            host = v
        end

        parser.on("-p PORT", "--port=PORT", "Server port") do |v|
            port = v.to_i
        end
    end

    parser.on("server", "Start Purpnet Server") do
        server = true
        parser.banner = "Usage: purpnet server [args]"
        
        parser.on("-H HOST", "--host=HOST", "Bind address") do |v|
            host = v
        end

        parser.on("-p PORT", "--port=PORT", "Set Purpnet port") do |v|
            port = v.to_i
        end
    end

    parser.on("-h", "--help", "Show help") do
      puts parser
      exit
    end
end

parser.parse

if server
    CLI::ServerCommand.run(host, port)
elsif connect
    CLI::ConnectCommand.run(host, port)
elsif lan_discover
    CLI::DiscoverCommand.run()
else
  puts parser
  exit
end


# server = Server.new("127.0.0.1", 5555, &handler)
# puts "listening..."
# server.run