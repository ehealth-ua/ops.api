require 'pg'
require 'json'

template_file = File.read('output_nice.json')
template = JSON.parse(template_file)

conn = PG.connect(dbname: 'ops_dev')
blocks_conn = PG.connect(dbname: 'seed_dev')

DAYS = 7
PER_DAY = 100..200

puts "Preparing DBs..."

blocks_conn.exec("
  CREATE EXTENSION IF NOT EXISTS pgcrypto;
  DELETE FROM blocks;

  INSERT INTO blocks (hash, version, block_start, block_end, inserted_at) VALUES (digest(concat('Слава Україні!'), 'sha512')::text, 'v1', '1970-01-01 00:00:00', now(), now());
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
      ), '') AS value FROM declarations WHERE inserted_at > '%{from}' AND inserted_at <= '%{to}'
  )
  SELECT digest(concat(value), 'sha512')::text as hash, value FROM concat;
"

DAYS.times do |day|
  today = (Date.new(2014, 1, 1) + day + 1).to_s

  seed = blocks_conn.exec("SELECT hash FROM blocks ORDER BY inserted_at DESC LIMIT 1").map { |row| row["hash"] }[0]
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
        '#{today} 00:00:01',
        '#{today} 00:00:01',
        '3BA18EA0-09A7-4D5D-9330-029E02DD29AB',
        '#{seed}'
      )"
    )

    # TODO: add random time above
  end

  # inserted_at > '%{previous_block_ts}' AND a <= y '%{today}'

  before = Time.now.to_i
  calculated_seed = conn.exec(generate_new_hash % { from: "#{today} 00:00:00", to: "#{today} 23:59:59" })[0]
  after = Time.now.to_i

  new_hash = calculated_seed["hash"]
  new_value = calculated_seed["value"]

  # Note: Instead of inserting into seeds, we can insert into a temp table.
  #       Then compare values from the temp table with seed values from table in separate DB.
  #
  #       This will be analogue to "full check"
  #
  new_block = blocks_conn.exec("
    INSERT INTO blocks (hash, version, block_start, block_end, inserted_at)
      VALUES ('#{new_hash}', 'v1', '#{today}', '#{today} 23:59:59', now()) returning hash"
  )[0]

  puts "Day #{today}: generated #{samples} declarations. Hash: #{new_block["hash"]}. Block gen. took: #{after - before}s"
end

blocks_conn.exec("SELECT * FROM blocks ORDER BY inserted_at ASC OFFSET 1").each do |existing_block|
  from = existing_block["block_start"]
  to   = existing_block["block_end"]

  recalculated_block = conn.exec(generate_new_hash % { from: from, to: to })[0]

  new_hash      = recalculated_block["hash"]
  existing_hash = existing_block["hash"]

  if new_hash == existing_hash
    puts "Block #{from}..#{to} vas verified. It's correct!"
  else
    puts "Block #{from}..#{to} vas not verified. It's not correct!"
    puts "  - existing hash: #{existing_hash}"
    puts "  - recalculated hash: #{new_hash}"
    puts "    - #{recalculated_block["new_value"]}"
  end
end
