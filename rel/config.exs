use Mix.Releases.Config,
  default_release: :default,
  default_environment: :default

environment :default do
  set(dev_mode: false)
  set(include_erts: true)
  set(include_src: false)

  set(
    overlays: [
      {:template, "rel/templates/vm.args.eex", "releases/<%= release_version %>/vm.args"}
    ]
  )
end

release :ops do
  set(pre_start_hooks: "bin/hooks/")
  set(version: current_version(:ops))

  set(
    applications: [
      ops: :permanent,
      core: :permanent
    ]
  )

  set(config_providers: [ConfexConfigProvider])
end

release :ops_scheduler do
  set(version: current_version(:ops_scheduler))

  set(
    applications: [
      ops_scheduler: :permanent
    ]
  )

  set(config_providers: [ConfexConfigProvider])
end
