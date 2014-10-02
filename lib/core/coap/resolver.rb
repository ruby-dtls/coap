module CoRE
  module CoAP
    class Resolver
      def self.address(host)
        a = if ENV['IPv4'].nil?
          IPv6FavorResolv.getaddress(host).to_s
        else
          Resolv.getaddress(host).to_s
        end

        raise Resolv::ResolvError if a.empty?

        a
      end
    end
  end
end
