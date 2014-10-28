class Socket
  def self.if_nametoindex(name)
    ifaddr_by_name(name).ifindex
  rescue NoMethodError
    0
  end

  def self.if_up?(name)
    ifaddr_by_name(name).flags & Socket::IFF_UP == 1
  rescue NoMethodError
    false
  end

  private

  def self.ifaddr_by_name(name)
    Socket.getifaddrs.select { |x| x.name == name }.first
  end
end
