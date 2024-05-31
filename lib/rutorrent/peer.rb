module Rutorrent
  class Peer
    attr_reader :ip, :port, :bitfield

    def initialize(ip, port)
      @ip = IPAddr.new_ntoh(ip).to_s
      @port = port
      @bitfield = []
    end

    def update_bitfield
      @bitfield = bitfield
    end

    def has_piece?(piece_index)
      @bitfield[piece_index] == 1
    end
  end
end
