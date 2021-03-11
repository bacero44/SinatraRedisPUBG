# frozen_string_literal: true

class Player
  attr_reader :name_tag
  attr_reader :user_id
  attr_reader :mastery
  attr_reader :stats
  attr_reader :date

  def initialize(name_tag)
    @name_tag = name_tag
    @user_id = nil
    @mastery = {}
    @stats = {}
    @date = nil
  end



  def fund?
    if !user_id.nil?
      true
    else
      false
    end
  end

  private

  Redis.
end
