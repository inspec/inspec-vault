
# This control file is intended to be run twice -
# once with the priority set to < 30, and once set to > 60.

# An input that vault manages and has no interference
control "priority_check_always_vault" do
  describe input("priority_check_always_vault") do
    it { should cmp "value_from_vault" }
  end
end

# An input that vault and DSL conflict, but DSL should win
control "priority_check_dsl_wins" do
  describe input("priority_check_dsl_wins", value: "value_from_dsl", priority: 90) do
    it { should cmp "value_from_dsl" }
  end
end

# An input that vault and DSL conflict upon
control "priority_check_variable_outcome" do
  describe input("priority_check_variable_outcome", value: "value_from_dsl", priority: 30) do
    it { should cmp "value_from_dsl" }   # Matches when run with vault on low priority
    it { should cmp "value_from_vault" } # Matches when run with vault on high priority
  end
end
