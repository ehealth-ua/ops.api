require 'pg'
require 'json'

template_file = File.read('output_nice.json')
template = JSON.parse(template_file)

conn = PG.connect(dbname: 'ops_dev')
conn_seeds = PG.connect(dbname: 'ops_seeds_dev')

DAYS = 7
PER_DAY = 1..1

puts "Preparing DBs..."

conn_seeds.exec("
  CREATE EXTENSION IF NOT EXISTS pgcrypto;
  DELETE FROM seeds;

  INSERT INTO seeds (hash, debug, inserted_at) VALUES (digest('Слава Україні!', 'sha512'), 'Слава Україні!', '2014-01-01 23:59:59');
")

conn.exec("
  CREATE EXTENSION IF NOT EXISTS pgcrypto;
  DELETE FROM declarations;
")

puts "Generating data, for #{DAYS} days, #{PER_DAY} declarations every day..."

generate_new_hash = "
  WITH concat AS (
    SELECT
      ARRAY_TO_STRING(ARRAY_AGG(
        CONCAT(
          id,
          employee_id,
          start_date,
          end_date,
          signed_at,
          created_by,
          is_active,
          scope,
          division_id,
          legal_entity_id,
          inserted_at,
          declaration_request_id,
          seed
        ) ORDER BY id ASC
      ), '') AS value FROM declarations WHERE DATE(inserted_at) = '%{today}'
  )
  SELECT digest(value, 'sha512') as new_seed, value FROM concat;
"

DAYS.times do |day|
  yesterday = (Date.new(2014, 1, 1) + day).to_s
  today = (Date.new(2014, 1, 1) + day + 1).to_s

  seed = conn_seeds.exec("SELECT hash FROM seeds ORDER BY inserted_at DESC LIMIT 1").map { |row| row["hash"] }[0]
  samples = PER_DAY.to_a.sample

  samples.times do |_declaration|
    conn.exec("
      INSERT INTO declarations (
        id,
        employee_id,
        person_id,
        start_date,
        end_date,
        status,
        signed_at,
        created_by,
        updated_by,
        is_active,
        scope,
        division_id,
        legal_entity_id,
        inserted_at,
        updated_at,
        declaration_request_id,
        seed
      ) VALUES (
        uuid_generate_v4(),
        '#{template["employee"]["id"]}',
        '#{template["person"]["id"]}',
        '#{template["start_date"]}',
        '#{template["end_date"]}',
        '#{template["status"]}',
        now(),
        'CCC6C85B-C4DC-43FC-8E75-BA9B855EA597',
        'FB7FF889-4D20-4F00-BAF5-B9E2D3618341',
        'true',
        '#{template["scope"]}',
        '#{template["division"]["id"]}',
        '#{template["legal_entity"]["id"]}',
        '#{today}',
        '#{today}',
        '3BA18EA0-09A7-4D5D-9330-029E02DD29AB',
        '#{seed}'
      )"
    )
  end

  new_seed = conn.exec(generate_new_hash % { today: today })[0]

  new_hash = new_seed["new_seed"]
  new_value = new_seed["value"]

  new_seed = conn_seeds.exec("INSERT INTO seeds (hash, debug, inserted_at) VALUES ('#{new_hash}', '#{new_value}', '#{today} 23:59:59') returning hash")[0]['hash']

  puts "Day #{today}: generated #{samples} declarations: "
  puts "  seed: #{new_seed}"
  puts "  value: #{new_value}"
end

puts "
Verifying...

"

conn.exec("SELECT DISTINCT date(inserted_at) AS today FROM declarations ORDER BY today;").each do |row|
  today = row['today']
  new_seed = conn.exec(generate_new_hash % { today: today })[0]

  new_hash = new_seed["new_seed"]
  new_value = new_seed["value"]

  existing_hash = conn_seeds.exec("SELECT hash FROM seeds WHERE date(inserted_at) = '#{today}'").map { |row| row["hash"] }[0]

  if new_hash == existing_hash
    puts "Day #{today} vas verified. It's correct!"
  else
    puts "Day #{today} vas verified. It's not correct!"
    puts "  - recalculated hash: #{new_hash}"
    puts "  - existing hash: #{existing_hash}"
    puts "    - #{new_value}"
  end
end

# 9d62e831-e727-4b58-87db-01273e110d4213d3af77-82e6-4fcb-a2b3-4451d9e685e32017-07-142017-07-152017-09-21 15:03:01.675414ccc6c85b-c4dc-43fc-8e75-ba9b855ea597tfamily_doctora7007627-cb29-4159-b813-68cd51bb3d989c81824b-bc13-4d07-bc76-b069e2a2876b2014-01-08 00:00:003ba18ea0-09a7-4d5d-9330-029e02dd29ab\x5fbed87f9a67607b37e6297e47ed29e74a0a38a516e3bb2b549dd0d92dbd3910b3e5909c15fbd8aea05ac26fbda7da1efaef0da5be1700176980aaefa84dabc9
# 9d62e831-e727-4b58-87db-01273e110d4213d3af77-82e6-4fcb-a2b3-4451d9e685e32017-07-142017-07-152017-09-21 15:03:01.675414ccc6c85b-c4dc-43fc-8e75-ba9b855ea597tfamily_doctora7007627-cb29-4159-b813-68cd51bb3d989c81824b-bc13-4d07-bc76-b069e2a2876b2014-01-08 00:00:003ba18ea0-09a7-4d5d-9330-029e02dd29ab\x5fbed87f9a67607b37e6297e47ed29e74a0a38a516e3bb2b549dd0d92dbd3910b3e5909c15fbd8aea05ac26fbda7da1efaef0da5be1700176980aaefa84dabc9
