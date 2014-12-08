class Variable < ActiveRecord::Base
  
  def self.value_for(key)
    v = Rails.cache.fetch("variables-#{key.to_s}") do
      Variable.find_by( key: key.to_s ).value
    end
  end

  def self.get(key)
    self.value_for(key)
  end

end