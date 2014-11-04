module CoRE
  module OS
    def self.linux?
      @@linux ||= !!(os =~ /^linux/)
    end

    def self.os
      RbConfig::CONFIG['host_os']
    end

    def self.osx?
      @@osx ||= !!(os =~ /^darwin/)
    end
  end
end
