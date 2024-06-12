require "tty-prompt"
require "bencode"
require "bytesize"

module Rutorrent
  class CLI
    def self.start
      puts Rutorrent::MESSAGES[:no_torrents_available] if Dir["#{Dir.home}/**/*.torrent"].empty? && exit

      selected_torrent_path = prompt.select(Rutorrent::MESSAGES[:select_torrent], Dir["#{Dir.home}/**/*.torrent"])
      decoded_torrent = BEncode.load_file(selected_torrent_path)
      torrent_files = prompt.multi_select(Rutorrent::MESSAGES[:instructions],
                                          format_torrent_files_with_size(decoded_torrent))

      torrent_files = format_torrent_files_with_size(decoded_torrent, show_byte_size: false)

      Rutorrent::Downloader.new(decoded_torrent, torrent_files).start
    end

    def self.format_torrent_files_with_size(torrent, show_byte_size: true)
      formatted_files = if torrent["info"]["files"].nil?
                          [torrent["info"]["name"]]
                        else
                          torrent["info"]["files"].map { |f| f["path"].join("/") }
                        end

      if show_byte_size
        formatted_files = formatted_files.map do |file|
          return "#{file} (#{ByteSize.new(torrent["info"]["length"])})" if torrent["info"]["files"].nil?

          index = torrent["info"]["files"].find_index { |f| f["path"].join("/") == file }
          "#{file} (#{ByteSize.new(torrent["info"]["files"][index]["length"])})"
        end
      else
        formatted_files
      end

      formatted_files
    end

    def self.prompt
      @prompt ||= TTY::Prompt.new
    end
  end
end
