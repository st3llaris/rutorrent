# frozen_string_literal: true

Dir["#{__dir__}/rutorrent/**/*.rb"].each { |f| require f }

module Rutorrent
  class Error < StandardError; end
end
