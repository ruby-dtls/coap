module CoRE
  module CoAP
    class Resolver
      def self.address(host, force_ipv6 = false)
        a = if force_ipv6
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
