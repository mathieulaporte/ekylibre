# == Schema Information
# Schema version: 20090512102847
#
# Table name: journal_records
#
#  id            :integer       not null, primary key
#  resource_id   :integer       
#  resource_type :string(255)   
#  created_on    :date          not null
#  printed_on    :date          not null
#  number        :string(255)   not null
#  status        :string(1)     default("A"), not null
#  debit         :decimal(16, 2 default(0.0), not null
#  credit        :decimal(16, 2 default(0.0), not null
#  closed        :boolean       not null default "false"
#  position      :integer       not null
#  financialyear_id :interger   not null
#  journal_id    :integer       not null
#  company_id    :integer       not null
#  created_at    :datetime      not null
#  updated_at    :datetime      not null
#  created_by    :integer       
#  updated_by    :integer       
#  lock_version  :integer       default(0), not null
#

class JournalRecord < ActiveRecord::Base
  belongs_to :company
  belongs_to :journal
  belongs_to :financialyear, :class_name=>"Financialyear"
  belongs_to :resource 
  has_many :entries, :foreign_key=>:record_id, :dependent=>:destroy 
  acts_as_list :scope=>:financialyear

  validates_format_of :number, :with => /^[\dA-Z][\dA-Z]*$/
  validates_length_of :number, :is =>  4

  #
  def before_validation
    self.debit = self.entries.sum(:debit)
    self.credit = self.entries.sum(:credit)
    self.number = self.number.rjust(4, "0")
  end 
   
  #
  def validate
    errors.add :number, tc(:error_format_number) unless self.number=~/^[\dA-Z][\dA-Z]*$/
    #errors.add_to_base tc(:error_format_number) unless self.number=~/^[\dA-Z][\dA-Z]*$/
    errors.add :printed_on, tc(:error_printed_date) if self.printed_on > self.created_on
    #errors.add_to_base tc(:error_printed_date) if self.printed_on > self.created_on    
    errors.add :created_on, tc(:error_created_date_current_financialyear) if self.created_on < self.financialyear.started_on or self.created_on > self.financialyear.stopped_on
    #errors.add_to_base tc(:error_created_date_current_financialyear) if self.created_on < self.financialyear.started_on or self.created_on > self.financialyear.stopped_on
    if self.journal
     #raise Exception.new('oui')
      errors.add_to_base tc(:error_closed_journal,[self.journal.closed_on.to_formatted_s]) if self.created_on < self.journal.closed_on
     # errors.add :created_on, tc(:error_closed_journal,[self.journal.closed_on.to_formatted_s]) if self.created_on < self.journal.closed_on

    end
    
  end
  
  # this method computes the debit and the credit of the record.
  def refresh
    self.save
  end
  
  #determines if the record is balanced or not.
  def balanced
    self.debit == self.credit and self.debit != 0
  end

  #determines the difference between the debit and the credit from the record.
  def balance
    self.debit - self.credit 
  end

  # this method allows to lock the record.
  def close
    self.update_attribute(:closed, true)
    if self.entries.size > 0
      self.entries.each do |entrie|
        entrie.close
      end
    end
  end

end
