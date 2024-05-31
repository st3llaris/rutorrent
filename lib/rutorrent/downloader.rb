module Rutorrent
  class Downloader
    def initialize(torrent, torrent_files)
      @torrent = torrent
      @torrent_files = torrent_files
    end

    def start
      tracker.connect
    end

    private

    def tracker
      @tracker ||= Rutorrent::Tracker.new(torrent, torrent_files)
    end

    attr_reader :torrent, :torrent_files
  end
end
