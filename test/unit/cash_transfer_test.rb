# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2015 Brice Texier, Thibaud Merigon
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
# 
# == Table: cash_transfers
#
#  accounted_at              :datetime         
#  comment                   :text             
#  company_id                :integer          not null
#  created_at                :datetime         not null
#  created_on                :date             
#  creator_id                :integer          
#  currency_id               :integer          
#  emitter_amount            :decimal(16, 2)   default(0.0), not null
#  emitter_cash_id           :integer          not null
#  emitter_currency_id       :integer          not null
#  emitter_currency_rate     :decimal(16, 6)   default(1.0), not null
#  emitter_journal_entry_id  :integer          
#  id                        :integer          not null, primary key
#  lock_version              :integer          default(0), not null
#  number                    :string(255)      not null
#  receiver_amount           :decimal(16, 2)   default(0.0), not null
#  receiver_cash_id          :integer          not null
#  receiver_currency_id      :integer          
#  receiver_currency_rate    :decimal(16, 6)   
#  receiver_journal_entry_id :integer          
#  updated_at                :datetime         not null
#  updater_id                :integer          
#


require 'test_helper'

class CashTransferTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
