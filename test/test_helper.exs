Application.load(:agnus)

for app <- Application.spec(:agnus, :applications) do
  Application.ensure_all_started(app)
end

File.rm("/tmp/agnus.json")

# ExUnit.start(capture_log: true)
ExUnit.start()
