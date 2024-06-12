require "concurrent-ruby"

module Rutorrent
  class PeerConnection
    attr_reader :peers, :info_hash, :peer_id, :torrent_files, :file_savers, :interval, :downloaded_pieces,
                :pool, :torrent_info, :piece_length, :total_pieces, :pieces_hashes, :download_complete, :left

    def initialize(peers, torrent_info, interval)
      @peers = peers
      @info_hash = torrent_info[:info_hash]
      @peer_id = torrent_info[:peer_id]
      @torrent_files = torrent_info[:torrent_files]
      format_pieces_from(torrent_info[:torrent])
      @file_savers = initialize_file_savers
      @interval = interval
      @downloaded_pieces = Set.new
      @pool = Concurrent::FixedThreadPool.new(100)
      @download_complete = Concurrent::AtomicBoolean.new(false)
    end

    def start!
      peers.each do |peer|
        pool.post { connect_to_peer(peer) }
      end
    ensure
      pool.shutdown
      pool.wait_for_termination
      file_savers.map(&:close)
      report_progress
    end

    private

    def start_connection(socket)
      perform_handshake(socket)
      message_code_class = MessageCodeHandler.new(socket, file_savers, downloaded_pieces, download_complete,
                                                  piece_length)
      loop do
        message = MessageReader.read_message(socket)
        message_code = Constants::PEER_MESSAGES_MAPPING[message[0]]
        message_code_class.send("handle_#{message_code}", message[1])
      end
    end

    def shutdown_pool
      puts "Shutting down thread pool..."
      pool.shutdown
      pool.wait_for_termination
      puts "All threads terminated."
    end

    def initialize_file_savers
      torrent_files.each_with_index.map do |torrent_file, _index|
        file_path = "#{Dir.home}/Downloads/#{torrent_file}"
        FileSaver.new(file_path, piece_length, total_pieces, pieces_hashes, left)
      end
    end

    def connect_to_peer(peer)
      puts "Connecting to peer #{peer.ip}:#{peer.port}"
      socket = TCPSocket.new(peer.ip, peer.port)
      start_connection(socket)
    rescue StandardError => e
      puts "Something went wrong: #{e}"
    ensure
      socket.close if socket && !socket.closed?
    end

    def perform_handshake(socket)
      socket.write(handshake)
      response = socket.read(68)

      raise "No response from peer" unless response

      received_info_hash = response[28, 20]
      received_peer_id = response[48, 20]

      raise "Info hash mismatch" if received_info_hash != info_hash

      puts "Connected to peer: #{received_peer_id.unpack1("H*")}"
    end

    def handshake
      @handshake ||= "\x13BitTorrent protocol\x00\x00\x00\x00\x00\x00\x00\x00#{info_hash}#{peer_id}"
    end

    def format_pieces_from(torrent)
      @piece_length = torrent["info"]["piece length"]
      @pieces_hashes = torrent["info"]["pieces"].scan(/.{20}/m)
      @total_pieces = @pieces_hashes.size
      @left = torrent["info"]["length"]
    end
  end
end
