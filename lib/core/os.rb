module OS
  def self.linux?
    !!(os =~ /^linux/)
  end

  def self.os
    RbConfig::CONFIG['host_os']
  end

  def self.osx?
    !!(os =~ /^darwin/)
  end
end
