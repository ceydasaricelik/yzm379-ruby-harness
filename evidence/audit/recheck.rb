require 'digest'
require 'json'
require 'prism'

ROOT = File.expand_path('../..', __dir__)
PROMPT = "Öğrenci devamsızlık kontrolü yap, devamsızlık sınırı %30'dur.".freeze

def path(relative)
  File.join(ROOT, relative)
end

def json(relative)
  JSON.parse(File.read(path(relative), encoding: 'bom|utf-8'))
end

def jsonl(relative)
  File.readlines(path(relative), encoding: 'bom|utf-8').map { |line| JSON.parse(line) }
end

def verify(condition, label)
  abort "FAIL #{label}" unless condition

  puts "PASS #{label}"
end

def items(events)
  events.filter_map { |event| event['item'] if event['type'] == 'item.completed' }
end

measurements = json('evidence/measurements.json')
threads = {}
%w[a b].each do |run|
  dir = "evidence/#{run}"
  events = jsonl("#{dir}/events.jsonl")
  records = jsonl("#{dir}/token-usage.jsonl").map { |record| record.fetch('payload') }
  thread = events.find { |event| event['type'] == 'thread.started' }.fetch('thread_id')
  threads[run] = thread
  prompt = jsonl("#{dir}/model-prompt.jsonl").fetch(0).fetch('payload')
  turns = events.select { |event| event['type'] == 'turn.completed' }
  metric = measurements.fetch(run)
  verify(prompt['role'] == 'user' && prompt['content'].map { |part| part['text'] } == [PROMPT] &&
    File.binread(path("#{dir}/prompt.txt")) == PROMPT.b, "#{run.upcase} exact prompt")
  verify(turns.size == 1 && metric['cli_turns'] == 1 &&
    records.map { |record| record['response_id'] }.uniq.size == records.size &&
    metric['model_responses_with_usage'] == records.size &&
    records.all? { |record| record['thread_id'] == thread } &&
    records.map { |record| record['turn_id'] }.uniq.size == 1 &&
    metric['thread_id'] == thread, "#{run.upcase} CLI turn, responses, and thread")

  usage = turns.fetch(0).fetch('usage')
  usage.each do |kind, count|
    verify(records.sum { |record| record.fetch('usage').fetch(kind) } == count &&
      records.last.fetch('turn_token_usage').fetch(kind) == count &&
      metric.fetch(kind) == count, "#{run.upcase} #{kind}=#{count}")
  end
  total = usage['input_tokens'] + usage['output_tokens']
  verify(metric['uncached_input_tokens'] == usage['input_tokens'] - usage['cached_input_tokens'] &&
    metric['total_tokens'] == total && records.last['turn_token_usage']['total_tokens'] == total &&
    records.sum { |record| record['usage']['total_tokens'] } == total &&
    metric.key?('cost') && metric['cost'].nil?, "#{run.upcase} total=#{total}, cost unavailable")
end

a_context = json('evidence/a/run-context.json')
b_context = json('evidence/b/run-context.json')
verify(a_context.reject { |key, _| key == 'cwd' } == b_context.reject { |key, _| key == 'cwd' } &&
  json('evidence/a/process.json')['executable'] == json('evidence/b/process.json')['executable'],
  'same A/B model, effort, permissions, and executable')

a_items = items(jsonl('evidence/a/events.jsonl'))
verify(json('evidence/a/snapshot.json')['file_count'] == 0 &&
  a_items.none? { |item| item['type'] == 'file_change' } &&
  a_items.find { |item| item['id'] == 'item_2' }.fetch('aggregated_output').strip.empty?,
  'A empty workspace observed, no file changes or resulting files')
a_final = a_items.find { |item| item['id'] == 'item_6' }.fetch('text')
verify(a_final.include?('Yoklama kayıtlarına ulaşamadım') && a_final.include?('toplam ders'),
  'A final message requests missing attendance data')

b_pre = json('evidence/b/pre-run.json')
verify(b_pre['lib_exists'] == false && b_pre['files'].all? do |file|
  file_path = path("experiments/b/#{file.fetch('path').tr('\\', '/')}")
  Digest::SHA256.file(file_path).hexdigest.casecmp?(file.fetch('sha256')) &&
    (!file['target'] || File.readlink(file_path) == file['target'])
end, 'B started without lib and archived harness is byte-identical')
verify(json('evidence/b/post-run.json').fetch('application_files').all? do |file|
  Digest::SHA256.file(path("experiments/b/#{file.fetch('path')}")).hexdigest.casecmp?(file.fetch('sha256'))
end, 'B original application matches recorded hashes')

b_items = items(jsonl('evidence/b/events.jsonl'))
verify(b_items.any? { |item| item.fetch('command', '').include?("LiteralPath 'AGENTS.md'") &&
  item['exit_code'] == 0 && item.fetch('aggregated_output', '').include?('define_method') },
  'B read the actual AGENTS.md contents')
test_cli = b_items.select { |item| item.fetch('command', '').match?(/ruby (?:-Ilib test\/ogrenci_test\.rb|bin\/kontrol)/) }
checks = jsonl('evidence/b/kontrol.jsonl')
summary = '8 runs, 61 assertions, 0 failures, 0 errors, 0 skips'
verify(test_cli.size == 2 && test_cli.all? { |item| item['exit_code'] == 0 && item['aggregated_output'].include?(summary) } &&
  checks.size == 1 && checks.first['exit_code'] == 0 && checks.first['output'].include?(summary),
  'B initial automatic and both explicit checks succeeded with 8 tests / 61 assertions')

other_threads = %w[a/initial a/desktop-elevated ratchet/hook ratchet/hook/untrusted audit/hook].map do |run|
  jsonl("evidence/#{run}/events.jsonl").find { |event| event['type'] == 'thread.started' }.fetch('thread_id')
end
verify((threads.values & other_threads).empty?, 'diagnostic A attempts and hook demo excluded from A/B totals')
a_total = measurements['a']['total_tokens']
delta = measurements['b']['total_tokens'] - a_total
puts "A/B difference: %+d tokens (%+.2f%%)" % [delta, 100.0 * delta / a_total]

%w[lib experiments/b/lib].each do |directory|
  definitions = []
  dangerous_calls = %i[method_missing respond_to_missing? class_eval module_eval instance_eval
    class_exec module_exec instance_exec define_singleton_method prepend alias_method
    include extend eval const_set remove_method undef_method refine using]
  Dir.glob(path("#{directory}/*.rb")).sort.each do |file|
    ast = Prism.parse_file(file)
    verify(ast.success?, "Prism parsed #{directory}/#{File.basename(file)}")
    pending = [ast.value]
    until pending.empty?
      node = pending.pop
      case node
      when Prism::ClassNode, Prism::ModuleNode
        definitions << node.constant_path.slice
      when Prism::DefNode, Prism::CallNode
        abort "FAIL forbidden AST node #{node.name} in #{file}" if dangerous_calls.include?(node.name)
      when Prism::SingletonClassNode, Prism::AliasMethodNode, Prism::UndefNode
        abort "FAIL runtime class alteration in #{file}"
      end
      pending.concat(node.compact_child_nodes)
    end
  end
  verify(definitions.sort == %w[DevamsizlikKontrol Ogrenci], "#{directory} only declares application types")
end

require path('lib/ogrenci.rb')
student = Ogrenci.new(ad: 'Denetim', durum: :aktif, devamsizlik: 3)
verify(student.method(:method_missing).owner == BasicObject &&
  Ogrenci::DURUMLAR.all? { |state| student.method("#{state}?").owner == Ogrenci },
  'runtime method lookup uses BasicObject fallback and Ogrenci predicates')
