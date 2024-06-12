require "digest"

module Rutorrent
  class Tracker
    attr_reader :torrent, :torrent_files

    def initialize(torrent, torrent_files)
      @torrent = torrent
      @torrent_files = torrent_files
    end

    def connect
      if torrent["announce-list"][2][0].include?("udp")
        return UDPConnection.new(torrent, torrent_files, options).connect
      end

      if torrent["announce"].include?("http")
        HTTPConnection.new(torrent, torrent_files, options).connect

      elsif torrent["announce"].include?("udp")
        UDPConnection.new(torrent, torrent_files, options).connect
      end
    end

    def options
      {
        info_hash: Digest::SHA1.new.digest(torrent["info"].bencode),
        peer_id: "-RB0001-#{Array.new(12) { rand(0..9) }.join}",
        port: 6881,
        uploaded: 0,
        downloaded: 0,
        left: torrent["info"]["length"] || left,
        compact: 1,
        event: 2
      }
    end

    def left
      length = []
      torrent_files.map do |torrent_file|
        length << torrent["info"]["files"].find { |file| file["path"][0] == torrent_file }["length"]
      end

      length.sum
    end
  end
end
