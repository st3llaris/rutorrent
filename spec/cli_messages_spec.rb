RSpec.describe Rutorrent::MESSAGES do
  let(:messages) { Rutorrent::MESSAGES }

  it "should have messages" do
    expect(messages).not_to be nil
  end

  it "returns no torrents available" do
    expect(messages[:no_torrents_available]).to eq("No .torrent files found in your home directory. Please download at least one and try again.")
  end

  it "returns select torrent" do
    expect(messages[:select_torrent]).to eq("Please select a .torrent file to download")
  end

  it "returns instructions" do
    expect(messages[:instructions]).to eq("Use ↑/↓ arrow keys to choose a file, press Space to select and Enter to finish (by default, all files will be downloaded):")
  end

  it "should have 3 messages" do
    expect(messages.size).to eq(3)
  end
end
