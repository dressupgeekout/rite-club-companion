require 'forwardable'

module RiteClub
  # An in-game triumvirate.
  class Triumvirate
    VALID_NAMES = [
      "Beyonders",
      "Chastity",
      "Fate",
      "Nightwings",
      "Pyrehearts",
      "True Nightwings",
    ]

    attr_accessor :name
    attr_accessor :image

    def initialize(name: nil)
      @name = name
      if !VALID_NAMES.include?(@name)
        raise ArgumentError 
      end
    end
  end

  # An in-game character who may participate in the Rites.
  class Character
    VALID_NAMES = [ # XXX incomplete
      "Hedwyn",
      "Jodariel",
      "Oralech",
      "Pamitha",
      "Rukey",
      "Sandra",
      "Tamitha",
      "Volfred",
      "Xae",
    ]

    attr_accessor :name
    attr_accessor :image

    def initialize(name: nil)
      @name = name
      if !VALID_NAMES.include?(@name)
        raise ArgumentError
      end
    end
  end

  # An in-game arena where Rites can take place.
  class Location

    VALID_NAMES = [
      "Fall of Soliam",
    ]

    attr_reader :name
    attr_reader :image

    def initialize(name: nil)
      @name = name
      if !VALID_NAMES.include?(@name)
        raise ArgumentError
      end
    end
  end

  # A human being in real life.
  class Player
    attr_accessor :name
    attr_accessor :location

    def initialize(name: "")
      @name = name
      @location = nil
    end

    def ==(other)
      attrs = %i[
        name
      ]
      return attrs.all? { |attr| self.send(attr) == other.send(attr) }
    end
  end

  # The choices a single player can make in a single Rite.
  #
  # XXX individual characteres can be augmented with masteries and
  # talismans...
  class RitePlayerChoices
    attr_accessor :triumvirate
    attr_accessor :character1
    attr_accessor :character2
    attr_accessor :character3
  end

  # A single Rite conducted by two Triumvirates.
  class Rite
    attr_accessor :player1
    attr_accessor :player2
    attr_accessor :player1_choices
    attr_accessor :player2_choices
    attr_accessor :location
    attr_accessor :music
    attr_reader :victor

    def initialize(players: [])
      @player1 = players[0]
      @player2 = players[1]
    end

    def declare_victor!(player)
      @victor = player
    end
  end

  # A series of Rites conducted as a single match.
  class Match
    include Enumerable

    attr_accessor :player1
    attr_accessor :player2
    attr_accessor :rites

    DEFAULT_MATCH_LENGTH = 7

    def initialize(players: [])
      @player1 = players[0]
      @player2 = players[1]
      if @player1 == @player2
        raise ArgumentError, "require 2 different players"
      end
      @rites = Array.new(DEFAULT_MATCH_LENGTH)
    end

    def each
      @rites.each { |rite| yield rite }
    end

    extend Forwardable
    def_delegator :@rites, :length
    def_delegator :@rites, :push
  end

  # A database of matches.
  class MatchCollection
    include Enumerable

    def initialize
      @matches = []
    end

    def each
      @matches.each { |match| yield match }
    end
  end
end
