%{
  configs: [
    %{
      name: "default",
      color: true,
      files: %{
        included: ["lib/"],
        excluded: ["lib/ops/tasks.ex"]
      },
      checks: [
        {Credo.Check.Design.TagTODO, exit_status: 0},
        {Credo.Check.Readability.MaxLineLength, priority: :low, max_length: 120},
        {Credo.Check.Readability.Specs, false}
      ]
    }
  ]
}
