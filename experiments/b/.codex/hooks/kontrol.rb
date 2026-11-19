require 'digest'
require 'fileutils'
require 'json'
require 'open3'
require 'rbconfig'
require 'time'

ROOT = File.expand_path('../..', __dir__)
WATCHED = %w[lib/**/*.rb test/**/*.rb bin/kontrol].freeze

event = JSON.parse($stdin.read)
session_id = event.fetch('session_id')
abort 'Geçersiz oturum kimliği.' unless /\A[a-zA-Z0-9_-]+\z/.match?(session_id)

event_name = event.fetch('hook_event_name')
state_dir = File.join(ROOT, '.harness', session_id)
FileUtils.mkdir_p(state_dir)

File.open(File.join(state_dir, 'lock'), File::RDWR | File::CREAT) do |lock|
  lock.flock(File::LOCK_EX)
  state_path = File.join(state_dir, 'fingerprint')
  files = Dir.glob(WATCHED, base: ROOT).sort
  fingerprint = files.to_h do |path|
    [path, Digest::SHA256.file(File.join(ROOT, path)).hexdigest]
  end.to_json

  if event_name == 'SessionStart'
    File.write(state_path, fingerprint)
    next
  end

  previous = File.exist?(state_path) ? File.read(state_path) : '{}'
  next if fingerprint == previous

  before = JSON.parse(previous)
  after = JSON.parse(fingerprint)
  changed = (before.keys | after.keys).select { |path| before[path] != after[path] }
  output, status = Open3.capture2e(RbConfig.ruby, 'bin/kontrol', chdir: ROOT)
  output = output.encode('UTF-8', invalid: :replace, undef: :replace)
  File.open(File.join(state_dir, 'kontrol.jsonl'), 'a:UTF-8') do |log|
    log.puts JSON.generate(
      utc: Time.now.utc.iso8601(6),
      session_id: session_id,
      event: event_name,
      tool: event.fetch('tool_name'),
      paths: changed,
      exit_code: status.exitstatus,
      output: output
    )
  end
  File.write(state_path, fingerprint)

  result = status.success? ? 'başarılı' : 'başarısız'
  message = "Otomatik Ruby kontrolü #{result} (#{changed.join(', ')})."
  reply = {
    systemMessage: message,
    hookSpecificOutput: {
      hookEventName: 'PostToolUse',
      additionalContext: "#{message}\n#{output[0, 3000]}"
    }
  }
  unless status.success?
    reply[:decision] = 'block'
    reply[:reason] = "#{message}\n#{output[0, 3000]}"
  end
  puts JSON.generate(reply)
end
