module ContestsHelper
  
  def num_columns
    scaffold_columns.length + 1 
  end
  
  def scaffold_columns
    Contest.scaffold_columns
  end

  def contest_name(contest)
    contest.display_name || "Контест #{contest.id}"
  end
  
  def contest_kind(contest)
    "Тренировка"
  end
  
end
