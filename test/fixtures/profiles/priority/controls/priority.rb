
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

# This group is intended to be run only with default priority
# A set of inputs that poke the threshold around the default priority of 60
control "priority_check_default" do
  describe input("priority_check_threshold_59", value: "value_from_dsl", priority: 59) do
    it { should cmp "value_from_vault" }   # Default vault = 60 - vault wins
  end
  describe input("priority_check_threshold_60", value: "value_from_dsl", priority: 60) do
    it { should cmp "value_from_vault" }   # DSL = 60, vault = 60 - tie - last wins
  end
  describe input("priority_check_threshold_61", value: "value_from_dsl", priority: 61) do
    it { should cmp "value_from_dsl" }   # DSL = 61, Vault = 60 - vault wins
  end
end
