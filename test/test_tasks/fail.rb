class Fail
  def self.fail
    raise ArgumentError.new("bad task")
  end
end
