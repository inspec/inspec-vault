control "control-01" do
  describe input("test_input_01", value: "value_from_dsl_01") do
    it { should cmp "value_from_vault_01" }
  end
end
