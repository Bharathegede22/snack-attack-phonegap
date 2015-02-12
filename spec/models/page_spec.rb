require 'spec_helper'

describe Page do
  pending "add some examples to (or delete) #{__FILE__}"
end

# == Schema Information
#
# Table name: pages
#
#  id         :integer          not null, primary key
#  title      :string(255)
#  content    :text
#  active     :boolean          default(TRUE)
#  created_at :datetime
#  updated_at :datetime
#  city_id    :integer
#
# Indexes
#
#  index_pages_on_title  (title)
#
