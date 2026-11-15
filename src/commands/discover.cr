require "./command"
require "../discovery_client"


module CLI
    class DiscoverCommand < Command
        def run
            p "trying to search..."
            client = Network::DiscoveryClient.new
            servers = client.scan

            servers.each do |server|
                puts "Found: #{server}"
            end
        end
    end
end