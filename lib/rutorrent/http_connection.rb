require "net/http"

module Rutorrent
  class HTTPConnection
    attr_reader :torrent, :options, :torrent_files

    def initialize(torrent, torrent_files, options = {})
      @torrent = torrent
      @options = options
      @torrent_files = torrent_files

      create_methods_by_options
    end

    def connect
      uri = build_uri
      response = fetch_response(uri)
      handle_response(response)
    end

    private

    def request_params
      {
        info_hash: info_hash,
        peer_id: peer_id,
        port: port,
        uploaded: uploaded,
        downloaded: downloaded,
        left: left,
        compact: compact,
        event: event
      }
    end

    def build_uri
      URI("#{torrent["announce"]}?#{URI.encode_www_form(request_params)}")
    end

    def create_methods_by_options
      options.each do |method_name, method_value|
        define_singleton_method(method_name) { method_value }
      end
    end

    def fetch_response(uri)
      Net::HTTP.get_response(uri)
    rescue StandardError => e
      puts "Something went wrong: #{e}"
      exit
    end

    def handle_response(response)
      return if response.nil?

      response = BEncode.load(response.body)

      peers = response["peers"].scan(/.{6}/)
      puts "There are #{peers.size} peers available"

      unpacked_peers = unpack_peers(peers)
      peer_classes = []

      unpacked_peers.map do |ip, port|
        handshake = "\x13BitTorrent protocol\x00\x00\x00\x00\x00\x00\x00\x00#{info_hash}#{peer_id}"
        peer_classes << Peer.new(ip, port, handshake, info_hash)
      end
    end

    def unpack_peers(peers)
      peers.map { |peer| peer.unpack("a4n") }
    end
  end
end
