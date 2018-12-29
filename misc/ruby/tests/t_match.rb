require 'bacon'

require_relative 'match'

##########

describe RiteClub::Triumvirate do
  it "won't let you create a nonexistent triumvirate" do
    should.raise(ArgumentError) do
      RiteClub::Triumvirate.new(name: "XXX")
    end
  end
end

describe RiteClub::Match do
  it "won't allow a player to participate in a match with themself" do
    p1 = RiteClub::Player.new(name: "dressupgeekout")
    p2 = RiteClub::Player.new(name: "dressupgeekout")

    should.raise(ArgumentError) do
      # Same object:
      RiteClub::Match.new(players: [p1, p1])
    end

    should.raise(ArgumentError) do
      # Different object, but equal in value:
      RiteClub::Match.new(players: [p1, p2])
    end
  end

  it "enumerates rites" do
    p1 = RiteClub::Player.new(name: "A")
    p2 = RiteClub::Player.new(name: "B")
    match = RiteClub::Match.new(players: [p1, p2])
    match.should.respond_to(:length)
    match.should.respond_to(:each)
    match.length.should.equal(RiteClub::Match::DEFAULT_MATCH_LENGTH)
  end
end

describe RiteClub::MatchCollection do
  it "enumerates matches" do
    should.not.raise(NoMethodError) do
      RiteClub::MatchCollection.new.each { |match| p match }
    end
  end
end
