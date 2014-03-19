# hexdump.rb
# Copyright (C) 2010..2013 Carsten Bormann <cabo@tzi.org>

class String
  def hexdump(prefix = '', prepend_newline = true)
    a, i = [], 0
    a << '' if prepend_newline
    while i < length
      slice = self.byteslice(i, 16)
      a << '%s%-48s |%-16s|' %
        [prefix,
         slice.bytes.map { |b| '%02x' % b.ord }.join(' '),
         slice.gsub(/[^ -~]/mn, ".")]
      i += 16
    end
    a.join("\n")
  end
end
