# frozen_string_literal: true

# Loads environment variables from .env into ENV for local/dev usage.
# Does not override already-set variables.

def load_env!(path = File.join(__dir__, '.env'))
  return unless File.exist?(path)

  File.read(path).each_line do |line|
    line = line.strip
    next if line.empty? || line.start_with?('#')

    key, value = line.split('=', 2)
    next if key.nil? || key.empty?

    value = value ? value.strip : ''
    if (value.start_with?('"') && value.end_with?('"')) || (value.start_with?("'") && value.end_with?("'"))
      value = value[1..-2]
    end

    ENV[key] ||= value
  end
end

load_env!
