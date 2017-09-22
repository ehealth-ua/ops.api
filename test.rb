require 'pg'
require 'json'

template_file = File.read('output_nice.json')
template = JSON.parse(template_file)

conn = PG.connect(dbname: 'ops_dev')
conn_seeds = PG.connect(dbname: 'ops_seeds_dev')

DAYS = 7
PER_DAY = 300..400

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

  calculated_seed = conn.exec(generate_new_hash % { today: today })[0]

  new_hash = calculated_seed["new_seed"]
  new_value = calculated_seed["value"]

  # Note: Instead of inserting into seeds, we can insert into a temp table.
  #       Then compare values from the temp table with seed values from table in separate DB.
  #
  #       This will be analogue to "full check"
  #
  new_seed = conn_seeds.exec("INSERT INTO seeds (hash, debug, inserted_at) VALUES ('#{new_hash}', '#{new_value}', '#{today} 23:59:59') returning hash")[0]['hash']

  puts "Day #{today}: generated #{samples} declarations. Seed: #{new_seed}"
end

puts "
Verifying: every day distinctly...

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

puts "
Verifying: every day distinctly...

TODO: make this happen

"
