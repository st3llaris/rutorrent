module Rutorrent
  class UDPConnection
    attr_reader :torrent, :options, :torrent_files

    def initialize(torrent, torrent_files, options = {})
      @torrent = torrent
      @options = options
      @torrent_files = torrent_files

      create_methods_by_options
    end

    def connect
      socket = UDPSocket.new
      socket.connect(format_udp_url[:host], format_udp_url[:port])
      transaction_id = rand(0..65_535)
      action = 0
      socket.send(connection_request(transaction_id, action), 0)
      connection_response, = socket.recvfrom(16)
      if connection_response.size < 16
        puts "Invalid response size"
        exit
      end

      recv_action, recv_transaction_id, connection_id_high, connection_id_low = connection_response.unpack("NNNN")
      if recv_action != action || recv_transaction_id != transaction_id
        puts "Invalid response action or transaction id"
        exit
      end

      action = 1
      connection_id = (connection_id_high << 32) | connection_id_low
      packet = announce_request(connection_id, transaction_id, action)
      socket.send(packet, 0)

      announce_response, = socket.recvfrom(1024)

      if announce_response.size < 20
        puts "Invalid response size"
        exit
      end

      recv_action, recv_transaction_id, interval, leechers, seeders = announce_response.unpack("NNNNN")
      if recv_action != action || recv_transaction_id != transaction_id
        puts "Invalid response action or transaction id"
        exit
      end

      puts "Interval: #{interval}"
      puts "Leechers: #{leechers}"
      puts "Seeders: #{seeders}"

      peers = announce_response[20..].scan(/.{6}/)
      unpacked_peers = unpack_peers(peers)
      peer_classes = []
      unpacked_peers.map do |ip, port|
        peer_classes << Peer.new(ip, port)
      end

      torrent_info = {
        info_hash: info_hash,
        peer_id: peer_id,
        torrent_files: torrent_files,
        torrent: torrent
      }

      PeerConnection.new(peer_classes, torrent_info, interval).start!

      socket.close
    end

    def connection_request(transaction_id, action)
      connection_id = 0x41727101980

      [connection_id >> 32, connection_id & 0xFFFFFFFF, action, transaction_id].pack("NNNN")
    end

    def announce_request(connection_id, transaction_id, action)
      ip = 0
      key = rand(0..65_535)
      num_want = -1
      [
        connection_id >> 32, connection_id & 0xFFFFFFFF, action, transaction_id,
        info_hash, peer_id, downloaded >> 32, downloaded & 0xFFFFFFFF,
        left >> 32, left & 0xFFFFFFFF, uploaded >> 32, uploaded & 0xFFFFFFFF,
        event, ip, key, num_want, port
      ].flatten.pack("NNNNa20a20NNNNNNNNNNn")
    end

    def create_methods_by_options
      options.each do |method_name, method_value|
        define_singleton_method(method_name) { method_value }
      end
    end

    def format_udp_url
      host, port = torrent["announce-list"][1][0].split("://").last.split(":")

      { host: host, port: port.to_i }
    end

    def unpack_peers(peers)
      peers.map { |peer| peer.unpack("a4n") }
    end
  end
end
