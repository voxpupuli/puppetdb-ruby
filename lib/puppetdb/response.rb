module PuppetDB
  class Response
    attr_reader :data, :total_records

    def initialize(data, total_records = nil)
      @data = data
      @total_records = total_records
    end
  end
end
