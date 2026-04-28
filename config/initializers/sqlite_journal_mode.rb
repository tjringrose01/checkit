Rails.application.config.after_initialize do
  begin
    ActiveRecord::Base.connection_pool.with_connection do |connection|
      next unless connection.adapter_name == "SQLite"

      # WSL2 bind mounts can behave poorly with WAL/SHM sidecar files.
      # Force the database back to the simpler DELETE journal mode for local stability.
      connection.execute("PRAGMA journal_mode=DELETE")
    end
  rescue ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid
    # Ignore boot-time database availability issues; db:prepare will create the database.
  end
end
