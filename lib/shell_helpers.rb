require 'pathname'

module ShellHelpers
  def self.blacklist?(key)
    %w(PATH GEM_PATH GEM_HOME GIT_DIR).include?(key)
  end

  def self.initialize_env(path)
    env_dir = Pathname.new("#{path}")
    if env_dir.exist? && env_dir.directory?
      env_dir.each_child do |file|
        key   = file.basename.to_s
        value = file.read.strip
        ENV[key] = value
      end
    end
  end
end
