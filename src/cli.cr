require "log"
require "./lib/crystal-base-template"
require "./lib/github-version-check"

module CLI
  def self.main
    Log.setup_from_env(default_level: :info)

    if ARGV.size != 2
      puts "Usage: crystal-base-template <num1> <num2>"
      exit 1
    end

    num1 = ARGV[0].to_i
    num2 = ARGV[1].to_i

    github_version_check

    Log.info { "attempting to crunch the numbers" }
    result = Crystal::Base::Template.add(num1, num2)

    puts result
  end
end

CLI.main
