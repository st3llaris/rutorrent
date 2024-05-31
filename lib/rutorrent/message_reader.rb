module Rutorrent
  module MessageReader
    def self.read_message(socket)
      length_prefix = socket.read(4)&.unpack1("N")

      return nil if length_prefix.nil? || length_prefix.zero?

      message_id = socket.read(1)&.unpack1("C")
      payload = socket.read(length_prefix - 1)
      [message_id, payload]
    end
  end
end
