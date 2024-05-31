module Rutorrent
  module Constants
    PEER_MESSAGES_MAPPING = {
      0x0 => "choke",
      0x1 => "unchoke",
      0x2 => "interested",
      0x3 => "not interested",
      0x4 => "have",
      0x5 => "bitfield",
      0x6 => "request",
      0x7 => "piece",
      0x8 => "cancel"
    }.freeze
  end
end
