searchNodes=[{"ref":"OPS.Rpc.html","title":"OPS.Rpc","module":"OPS.Rpc","type":"module","doc":"This module contains functions that are called from other pods via RPC."},{"ref":"OPS.Rpc.html#declarations_by_employees/2","title":"OPS.Rpc.declarations_by_employees/2","module":"OPS.Rpc","type":"function","doc":"Get declarations by list of employee ids Examples iex&gt; OPS.Rpc.declarations_by_employees([&quot;4671ab27-57f8-4c55-a618-a042a68c7add&quot;], [:legal_entity_id]) [%{legal_entity_id: &quot;43ec9534-2250-42bb-94ec-e0a7ad33afd3&quot;}]"},{"ref":"OPS.Rpc.html#get_declaration/1","title":"OPS.Rpc.get_declaration/1","module":"OPS.Rpc","type":"function","doc":"Get declaration by params Examples iex&gt; OPS.Rpc.get_declaration(id: &quot;0042500e-6ac0-45fb-b82a-25f7857c49a8&quot;) %{ id: &quot;cdb4a85b-f12c-46c6-b840-590467e26acf&quot;, created_by: &quot;738c8cc1-ae9b-42a5-8660-4b7612b2b35c&quot;, declaration_number: &quot;0&quot;, declaration_request_id: &quot;382cc67b-7ade-4905-b8a9-0dfe2e9b9da0&quot;, division_id: &quot;bb15bdde-ffd2-4683-8ca9-03c86b1e6846&quot;, employee_id: &quot;f8cc0822-f214-4eea-a7d4-d03142901eb1&quot;, end_date: ~D[2019-01-21], inserted_at: #DateTime&lt;2019-01-30 12:24:36.455175Z&gt;, is_active: true, legal_entity_id: &quot;980d4d01-3427-4f7f-bbdd-bd7c1b25b1e2&quot;, person_id: &quot;071a2783-f752-42d9-bcfc-44ddc7eb923d&quot;, reason: nil, reason_description: nil, scope: &quot;&quot;, signed_at: #DateTime&lt;2019-01-20 12:24:36.442837Z&gt;, start_date: ~D[2019-01-20], status: &quot;active&quot;, updated_at: #DateTime&lt;2019-01-30 12:24:36.455185Z&gt;, updated_by: &quot;8dac0fc6-04fd-4e62-9711-a85c0a42992d&quot; }"},{"ref":"OPS.Rpc.html#last_medication_request_dates/1","title":"OPS.Rpc.last_medication_request_dates/1","module":"OPS.Rpc","type":"function","doc":"Searches medication request by given parameters (string key map) with maximum ended_at field. Available parameters (all of them are required): ParameterTypeExampleDescription person_idUUID72b38c55-4fc9-4ab3-b656-1091af4c557c medication_idbinary (lists are represented as binary with comma-separated values)64841249-7e59-4dfd-93ae-9a48b0f70595 or 7ac0d860-0430-4df5-9d56-0c267b64dfac,486bf854-9bae-496b-be13-1eeec5d57fed medical_program_idUUIDc4b3bf60-8352-4454-a762-fc67847e3797 statusbinary (lists are represented as binary with comma-separated values)ACTIVE or ACTIVE,COMPLETED Returns {:ok, %{&quot;started_at&quot; =&gt; Date.t(), &quot;ended_at&quot; =&gt; Date.t()} when medication request is found. {:ok, nil} when medication request is not found. {:error, Ecto.Changeset.t()} when search params are invalid. Examples iex&gt; OPS.Rpc.last_medication_request_dates(%{ &quot;person_id&quot; =&gt; &quot;4671ab27-57f8-4c55-a618-a042a68c7add&quot;, &quot;medication_id&quot; =&gt; &quot;43ec9534-2250-42bb-94ec-e0a7ad33afd3&quot;, &quot;medical_program_id&quot; =&gt; nil, &quot;status&quot; =&gt; &quot;ACTIVE&quot; }) {:ok, %{&quot;ended_at&quot; =&gt; ~D[2018-12-17], &quot;started_at&quot; =&gt; ~D[2018-12-17]}}"},{"ref":"OPS.Rpc.html#medication_request_by_id/1","title":"OPS.Rpc.medication_request_by_id/1","module":"OPS.Rpc","type":"function","doc":"Get medication request by id Examples iex&gt; OPS.Rpc.medication_request_by_id(&quot;0469f379-ff2e-4a69-81e8-2cbfadf88d6b&quot;) %{ category: &quot;community&quot;, context: %{ &quot;identifier&quot; =&gt; %{ &quot;type&quot; =&gt; %{ &quot;coding&quot; =&gt; [%{&quot;code&quot; =&gt; &quot;encounter&quot;, &quot;system&quot; =&gt; &quot;eHealth/resources&quot;}] }, &quot;value&quot; =&gt; &quot;e3e2a3cc-388a-4555-9e16-a51ccb109724&quot; } }, created_at: ~D[2019-02-05], dispense_valid_from: ~D[2019-02-05], dispense_valid_to: ~D[2019-02-08], division_id: &quot;406e4831-db4d-45a8-a26f-a246172705f5&quot;, dosage_instruction: [ %{ &quot;additional_instruction&quot; =&gt; [ %{ &quot;coding&quot; =&gt; [ %{ &quot;code&quot; =&gt; &quot;311504000&quot;, &quot;system&quot; =&gt; &quot;eHealth/SNOMED/additional_dosage_instructions&quot; } ] } ], &quot;as_needed_boolean&quot; =&gt; true, &quot;dose_and_rate&quot; =&gt; %{ &quot;dose_range&quot; =&gt; %{ &quot;high&quot; =&gt; %{ &quot;code&quot; =&gt; &quot;mg&quot;, &quot;system&quot; =&gt; &quot;eHealth/ucum/units&quot;, &quot;unit&quot; =&gt; &quot;mg&quot;, &quot;value&quot; =&gt; 13 }, &quot;low&quot; =&gt; %{ &quot;code&quot; =&gt; &quot;mg&quot;, &quot;system&quot; =&gt; &quot;eHealth/ucum/units&quot;, &quot;unit&quot; =&gt; &quot;mg&quot;, &quot;value&quot; =&gt; 13 } }, &quot;rate_ratio&quot; =&gt; %{ &quot;denominator&quot; =&gt; %{ &quot;code&quot; =&gt; &quot;mg&quot;, &quot;system&quot; =&gt; &quot;eHealth/ucum/units&quot;, &quot;unit&quot; =&gt; &quot;mg&quot;, &quot;value&quot; =&gt; 13 }, &quot;numerator&quot; =&gt; %{ &quot;code&quot; =&gt; &quot;mg&quot;, &quot;system&quot; =&gt; &quot;eHealth/ucum/units&quot;, &quot;unit&quot; =&gt; &quot;mg&quot;, &quot;value&quot; =&gt; 13 } }, &quot;type&quot; =&gt; %{ &quot;coding&quot; =&gt; [ %{&quot;code&quot; =&gt; &quot;ordered&quot;, &quot;system&quot; =&gt; &quot;eHealth/dose_and_rate&quot;} ] } }, &quot;max_dose_per_administration&quot; =&gt; %{ &quot;code&quot; =&gt; &quot;mg&quot;, &quot;system&quot; =&gt; &quot;eHealth/ucum/units&quot;, &quot;unit&quot; =&gt; &quot;mg&quot;, &quot;value&quot; =&gt; 13 }, &quot;max_dose_per_lifetime&quot; =&gt; %{ &quot;code&quot; =&gt; &quot;mg&quot;, &quot;system&quot; =&gt; &quot;eHealth/ucum/units&quot;, &quot;unit&quot; =&gt; &quot;mg&quot;, &quot;value&quot; =&gt; 13 }, &quot;max_dose_per_period&quot; =&gt; %{ &quot;denominator&quot; =&gt; %{ &quot;code&quot; =&gt; &quot;mg&quot;, &quot;system&quot; =&gt; &quot;eHealth/ucum/units&quot;, &quot;unit&quot; =&gt; &quot;mg&quot;, &quot;value&quot; =&gt; 13 }, &quot;numerator&quot; =&gt; %{ &quot;code&quot; =&gt; &quot;mg&quot;, &quot;system&quot; =&gt; &quot;eHealth/ucum/units&quot;, &quot;unit&quot; =&gt; &quot;mg&quot;, &quot;value&quot; =&gt; 13 } }, &quot;method&quot; =&gt; %{ &quot;coding&quot; =&gt; [ %{ &quot;code&quot; =&gt; &quot;419747000&quot;, &quot;system&quot; =&gt; &quot;eHealth/SNOMED/administration_methods&quot; } ] }, &quot;patient_instruction&quot; =&gt; &quot;0.25mg PO every 6-12 hours as needed for menses from Jan 15-20, 2015. Do not exceed more than 4mg per day&quot;, &quot;route&quot; =&gt; %{ &quot;coding&quot; =&gt; [ %{&quot;code&quot; =&gt; &quot;46713006&quot;, &quot;system&quot; =&gt; &quot;eHealth/SNOMED/route_codes&quot;} ] }, &quot;sequence&quot; =&gt; 1, &quot;site&quot; =&gt; %{ &quot;coding&quot; =&gt; [ %{ &quot;code&quot; =&gt; &quot;344001&quot;, &quot;system&quot; =&gt; &quot;eHealth/SNOMED/anatomical_structure_administration_site_codes&quot; } ] }, &quot;text&quot; =&gt; &quot;0.25mg PO every 6-12 hours as needed for menses from Jan 15-20, 2015. Do not exceed more than 4mg per day&quot;, &quot;timing&quot; =&gt; %{ &quot;code&quot; =&gt; %{ &quot;coding&quot; =&gt; [%{&quot;code&quot; =&gt; &quot;AM&quot;, &quot;system&quot; =&gt; &quot;TIMING_ABBREVIATION&quot;}] }, &quot;event&quot; =&gt; [&quot;2017-04-20T19:14:13Z&quot;], &quot;repeat&quot; =&gt; %{ &quot;bounds_duration&quot; =&gt; %{ &quot;code&quot; =&gt; &quot;d&quot;, &quot;system&quot; =&gt; &quot;eHealth/ucum/units&quot;, &quot;unit&quot; =&gt; &quot;days&quot;, &quot;value&quot; =&gt; 10 }, &quot;count&quot; =&gt; 2, &quot;count_max&quot; =&gt; 4, &quot;day_of_week&quot; =&gt; [&quot;mon&quot;], &quot;duration&quot; =&gt; 4, &quot;duration_max&quot; =&gt; 6, &quot;duration_unit&quot; =&gt; &quot;d&quot;, &quot;frequency&quot; =&gt; 1, &quot;frequency_max&quot; =&gt; 2, &quot;offset&quot; =&gt; 4, &quot;period&quot; =&gt; 4, &quot;period_max&quot; =&gt; 6, &quot;period_unit&quot; =&gt; &quot;d&quot;, &quot;time_of_day&quot; =&gt; [&quot;2017-04-20T19:14:13Z&quot;], &quot;when&quot; =&gt; [&quot;WAKE&quot;] } } } ], employee_id: &quot;43606f23-8a18-4902-93c4-0856cb2390ae&quot;, ended_at: ~D[2019-02-08], id: &quot;0469f379-ff2e-4a69-81e8-2cbfadf88d6b&quot;, inserted_at: ~N[2019-02-05 11:29:57.064635], inserted_by: &quot;34531e8a-ff95-4329-8de6-8c7bb9cb94a3&quot;, intent: &quot;order&quot;, is_active: true, legal_entity_id: &quot;be484454-c92e-4a1e-98ec-e1149b6c6bc3&quot;, medical_program_id: &quot;f088cc19-ac1d-49fb-a95c-e659914960d9&quot;, medication_id: &quot;7b8f8f3c-ce67-4b64-89b3-e0d31d0a1a2e&quot;, medication_qty: 10.0, medication_request_requests_id: &quot;3dcaf3ee-6469-483f-bacd-befbf74716b8&quot;, person_id: &quot;09564c9f-f4ef-4b8a-85c7-08ec48e5e562&quot;, reject_reason: &quot;Помилка призначення. Несумісні препарати.&quot;, rejected_at: ~D[2019-02-08], rejected_by: &quot;fb6c877f-1ed9-4589-b00a-023c69f8fca0&quot;, request_number: &quot;0000-X2HA-157X-0214&quot;, started_at: ~D[2019-02-05], status: &quot;EXPIRED&quot;, updated_at: ~N[2019-02-05 09:35:00.027131], updated_by: &quot;4261eacf-8008-4e62-899f-de1e2f7065f0&quot;, verification_code: &quot;7291&quot; }"},{"ref":"OPS.Rpc.html#medication_requests/1","title":"OPS.Rpc.medication_requests/1","module":"OPS.Rpc","type":"function","doc":"Search medication requests Examples iex&gt; OPS.Rpc.medication_requests(%{&quot;legal_entity_id&quot; =&gt; &quot;4d958f02-c2c3-4228-8ea3-ac4a7a7a286a&quot;}) %Scrivener.Page{ entries: [ %{ category: &quot;community&quot;, context: %{ &quot;identifier&quot; =&gt; %{ &quot;type&quot; =&gt; %{ &quot;coding&quot; =&gt; [ %{ &quot;code&quot; =&gt; &quot;encounter&quot;, &quot;system&quot; =&gt; &quot;eHealth/resources&quot; } ] }, &quot;value&quot; =&gt; &quot;b766941c-6cf0-42e2-888f-595a6658e1b4&quot; } }, created_at: ~D[2019-04-17], dispense_valid_from: ~D[2019-04-17], dispense_valid_to: ~D[2019-04-17], division_id: &quot;dc1fa9a2-46f1-4fcc-ae33-68c21f9c549a&quot;, dosage_instruction: [ %{ &quot;additional_instruction&quot; =&gt; [ %{ &quot;coding&quot; =&gt; [ %{ &quot;code&quot; =&gt; &quot;311504000&quot;, &quot;system&quot; =&gt; &quot;eHealth/SNOMED/additional_dosage_instructions&quot; } ] } ], &quot;as_needed_boolean&quot; =&gt; true, &quot;dose_and_rate&quot; =&gt; %{ &quot;dose_range&quot; =&gt; %{ &quot;high&quot; =&gt; %{ &quot;code&quot; =&gt; &quot;mg&quot;, &quot;comparator&quot; =&gt; &quot;&gt;&quot;, &quot;system&quot; =&gt; &quot;eHealth/units&quot;, &quot;unit&quot; =&gt; &quot;mg&quot;, &quot;value&quot; =&gt; 13 }, &quot;low&quot; =&gt; %{ &quot;code&quot; =&gt; &quot;mg&quot;, &quot;comparator&quot; =&gt; &quot;&gt;&quot;, &quot;system&quot; =&gt; &quot;eHealth/units&quot;, &quot;unit&quot; =&gt; &quot;mg&quot;, &quot;value&quot; =&gt; 13 } }, &quot;rate_ratio&quot; =&gt; %{ &quot;denominator&quot; =&gt; %{ &quot;code&quot; =&gt; &quot;mg&quot;, &quot;comparator&quot; =&gt; &quot;&gt;&quot;, &quot;system&quot; =&gt; &quot;eHealth/units&quot;, &quot;unit&quot; =&gt; &quot;mg&quot;, &quot;value&quot; =&gt; 13 }, &quot;numerator&quot; =&gt; %{ &quot;code&quot; =&gt; &quot;mg&quot;, &quot;comparator&quot; =&gt; &quot;&gt;&quot;, &quot;system&quot; =&gt; &quot;eHealth/units&quot;, &quot;unit&quot; =&gt; &quot;mg&quot;, &quot;value&quot; =&gt; 13 } }, &quot;type&quot; =&gt; %{ &quot;coding&quot; =&gt; [ %{ &quot;code&quot; =&gt; &quot;&#39;ordered&#39;&quot;, &quot;system&quot; =&gt; &quot;eHealth/dose_and_rate&quot; } ] } }, &quot;max_dose_per_administration&quot; =&gt; %{ &quot;code&quot; =&gt; &quot;mg&quot;, &quot;system&quot; =&gt; &quot;eHealth/units&quot;, &quot;unit&quot; =&gt; &quot;mg&quot;, &quot;value&quot; =&gt; 13 }, &quot;max_dose_per_lifetime&quot; =&gt; %{ &quot;code&quot; =&gt; &quot;mg&quot;, &quot;system&quot; =&gt; &quot;eHealth/units&quot;, &quot;unit&quot; =&gt; &quot;mg&quot;, &quot;value&quot; =&gt; 13 }, &quot;max_dose_per_period&quot; =&gt; %{ &quot;denominator&quot; =&gt; %{ &quot;code&quot; =&gt; &quot;mg&quot;, &quot;comparator&quot; =&gt; &quot;&gt;&quot;, &quot;system&quot; =&gt; &quot;eHealth/units&quot;, &quot;unit&quot; =&gt; &quot;mg&quot;, &quot;value&quot; =&gt; 13 }, &quot;numerator&quot; =&gt; %{ &quot;code&quot; =&gt; &quot;mg&quot;, &quot;comparator&quot; =&gt; &quot;&gt;&quot;, &quot;system&quot; =&gt; &quot;eHealth/units&quot;, &quot;unit&quot; =&gt; &quot;mg&quot;, &quot;value&quot; =&gt; 13 } }, &quot;method&quot; =&gt; %{ &quot;coding&quot; =&gt; [ %{ &quot;code&quot; =&gt; &quot;419747000&quot;, &quot;system&quot; =&gt; &quot;eHealth/SNOMED/administration_methods&quot; } ] }, &quot;patient_instruction&quot; =&gt; &quot;0.25mg PO every 6-12 hours as needed for menses from Jan 15-20, 2015. Do not exceed more than 4mg per day&quot;, &quot;route&quot; =&gt; %{ &quot;coding&quot; =&gt; [ %{ &quot;code&quot; =&gt; &quot;46713006&quot;, &quot;system&quot; =&gt; &quot;eHealth/SNOMED/route_codes&quot; } ] }, &quot;sequence&quot; =&gt; 1, &quot;site&quot; =&gt; %{ &quot;coding&quot; =&gt; [ %{ &quot;code&quot; =&gt; &quot;344001&quot;, &quot;system&quot; =&gt; &quot;eHealth/SNOMED/anatomical_structure_administration_site_codes&quot; } ] }, &quot;text&quot; =&gt; &quot;0.25mg PO every 6-12 hours as needed for menses from Jan 15-20, 2015. Do not exceed more than 4mg per day&quot;, &quot;timing&quot; =&gt; %{ &quot;code&quot; =&gt; %{ &quot;coding&quot; =&gt; [ %{ &quot;code&quot; =&gt; &quot;patient&quot;, &quot;system&quot; =&gt; &quot;eHealth/timing_abbreviation&quot; } ] }, &quot;event&quot; =&gt; [&quot;2017-04-20T19:14:13Z&quot;], &quot;repeat&quot; =&gt; %{ &quot;bounds_duration&quot; =&gt; %{ &quot;code&quot; =&gt; &quot;d&quot;, &quot;system&quot; =&gt; &quot;http://unitsofmeasure.org&quot;, &quot;unit&quot; =&gt; &quot;days&quot;, &quot;value&quot; =&gt; 10 }, &quot;count&quot; =&gt; 2, &quot;count_max&quot; =&gt; 4, &quot;day_of_week&quot; =&gt; [&quot;mon&quot;], &quot;duration&quot; =&gt; 4, &quot;duration_max&quot; =&gt; 6, &quot;duration_unit&quot; =&gt; &quot;d&quot;, &quot;frequency&quot; =&gt; 1, &quot;frequency_max&quot; =&gt; 2, &quot;offset&quot; =&gt; 4, &quot;period&quot; =&gt; 4, &quot;period_max&quot; =&gt; 6, &quot;period_unit&quot; =&gt; &quot;d&quot;, &quot;time_of_day&quot; =&gt; [&quot;2017-04-20T19:14:13Z&quot;], &quot;when&quot; =&gt; [&quot;WAKE&quot;] } } } ], employee_id: &quot;bed1bc93-ef2e-4ca0-9f07-e58f52b312c6&quot;, ended_at: ~D[2019-04-17], id: &quot;e9b4d92a-dc7c-483f-9ae9-f4b57bc89c4d&quot;, inserted_at: #DateTime&lt;2019-04-17 12:50:22Z&gt;, inserted_by: &quot;1630ef83-1b03-4d15-b03f-33f6b13a44b7&quot;, intent: &quot;order&quot;, is_active: true, legal_entity_id: &quot;4d958f02-c2c3-4228-8ea3-ac4a7a7a286a&quot;, medical_program_id: nil, medication_id: &quot;85e70454-6fd6-4a3d-8e5f-78fdf657d24b&quot;, medication_qty: 0.0, medication_request_requests_id: &quot;64878c2f-9960-4536-a92a-6f8571b0f4ed&quot;, person_id: &quot;13630bed-1a1c-4854-afaf-ff50cf5164d9&quot;, reject_reason: nil, rejected_at: nil, rejected_by: nil, request_number: &quot;0.7320575476812545&quot;, started_at: ~D[2019-04-17], status: &quot;ACTIVE&quot;, updated_at: #DateTime&lt;2019-04-17 12:50:22Z&gt;, updated_by: &quot;649ae8e4-eea3-46d5-b19f-747b9cdb2c39&quot;, verification_code: nil } ], page_number: 1, page_size: 50, total_entries: 1, total_pages: 1 }"},{"ref":"OPS.Rpc.html#search_declarations/3","title":"OPS.Rpc.search_declarations/3","module":"OPS.Rpc","type":"function","doc":"Get declarations by filter Check avaiable formats for filter here https://github.com/edenlabllc/ecto_filter Available parameters: ParameterTypeExampleDescription filterlist[{:reason, :equal, &quot;no_tax_id&quot;}]Required. Uses filtering format order_bylist[asc: :inserted_at] or [desc: :status] cursor{integer, integer} or nil{0, 10} Examples iex&gt; OPS.Rpc.search_declarations([{:person_id, :in, [&quot;0042500e-6ac0-45fb-b82a-25f7857c49a8&quot;]}], [start_date: :asc], {0, 10}) {:ok, [ %{ id: &quot;cdb4a85b-f12c-46c6-b840-590467e26acf&quot;, created_by: &quot;738c8cc1-ae9b-42a5-8660-4b7612b2b35c&quot;, declaration_number: &quot;0&quot;, declaration_request_id: &quot;382cc67b-7ade-4905-b8a9-0dfe2e9b9da0&quot;, division_id: &quot;bb15bdde-ffd2-4683-8ca9-03c86b1e6846&quot;, employee_id: &quot;f8cc0822-f214-4eea-a7d4-d03142901eb1&quot;, end_date: ~D[2019-01-21], inserted_at: #DateTime&lt;2019-01-30 12:24:36.455175Z&gt;, is_active: true, legal_entity_id: &quot;980d4d01-3427-4f7f-bbdd-bd7c1b25b1e2&quot;, person_id: &quot;071a2783-f752-42d9-bcfc-44ddc7eb923d&quot;, reason: nil, reason_description: nil, scope: &quot;&quot;, signed_at: #DateTime&lt;2019-01-20 12:24:36.442837Z&gt;, start_date: ~D[2019-01-20], status: &quot;active&quot;, updated_at: #DateTime&lt;2019-01-30 12:24:36.455185Z&gt;, updated_by: &quot;8dac0fc6-04fd-4e62-9711-a85c0a42992d&quot; } ]}"},{"ref":"OPS.Rpc.html#terminate_declaration/2","title":"OPS.Rpc.terminate_declaration/2","module":"OPS.Rpc","type":"function","doc":"Terminate declaration Available parameters: ParameterTypeExampleDescription updated_byUUID72b38c55-4fc9-4ab3-b656-1091af4c557cRequired statusbinaryactiveRequired reasonbinarymanual_personRequired reason_descriptionbinaryPerson died Examples iex&gt; OPS.Rpc.terminate_declaration(&quot;0042500e-6ac0-45fb-b82a-25f7857c49a8&quot;, %{&quot;updated_by&quot; =&gt; &quot;11225aae-7ac0-45fb-b82a-25f7857c49b0&quot;}) {:ok, %{ id: &quot;cdb4a85b-f12c-46c6-b840-590467e26acf&quot;, created_by: &quot;738c8cc1-ae9b-42a5-8660-4b7612b2b35c&quot;, declaration_number: &quot;0&quot;, declaration_request_id: &quot;382cc67b-7ade-4905-b8a9-0dfe2e9b9da0&quot;, division_id: &quot;bb15bdde-ffd2-4683-8ca9-03c86b1e6846&quot;, employee_id: &quot;f8cc0822-f214-4eea-a7d4-d03142901eb1&quot;, end_date: ~D[2019-01-21], inserted_at: #DateTime&lt;2019-01-30 12:24:36.455175Z&gt;, is_active: true, legal_entity_id: &quot;980d4d01-3427-4f7f-bbdd-bd7c1b25b1e2&quot;, person_id: &quot;071a2783-f752-42d9-bcfc-44ddc7eb923d&quot;, reason: nil, reason_description: nil, scope: &quot;&quot;, signed_at: #DateTime&lt;2019-01-20 12:24:36.442837Z&gt;, start_date: ~D[2019-01-20], status: &quot;active&quot;, updated_at: #DateTime&lt;2019-01-30 12:24:36.455185Z&gt;, updated_by: &quot;8dac0fc6-04fd-4e62-9711-a85c0a42992d&quot; } }"},{"ref":"OPS.Rpc.html#update_declaration/2","title":"OPS.Rpc.update_declaration/2","module":"OPS.Rpc","type":"function","doc":"Update declaration Available parameters: ParameterTypeExampleDescription updated_byUUID72b38c55-4fc9-4ab3-b656-1091af4c557cRequired employee_idUUIDdfe13714-92ed-448b-90d2-cccb8640948a person_idUUIDfba89efe-0cad-4c11-ad1f-d0cdce26b03a start_dateDate or binary~D[2015-10-10] or 2015-10-10 end_dateDate or binary~D[2030-10-10] or 2030-10-10 signed_atDateTime or binary2019-01-30 12:20:51 statusbinaryactive created_byUUID99a604f9-c319-4d93-a802-a5798d8efdf7 updated_byUUID99a604f9-c319-4d93-a802-a5798d8efdf7 is_activebooleantrue scopebinaryfamily_doctor division_idUUIDe217193a-e46b-49d9-9a66-79926abfefe8 legal_entity_idUUIDb5b30e2c-e347-49ba-a4e4-a52eaa057463 declaration_request_idUUIDcc3efcde-16b0-45a4-b0b8-f278d7b3c9ca Examples iex&gt; OPS.Rpc.update_declaration(&quot;0042500e-6ac0-45fb-b82a-25f7857c49a8&quot;, %{&quot;status&quot; =&gt; &quot;active&quot;}) {:ok, %{ id: &quot;cdb4a85b-f12c-46c6-b840-590467e26acf&quot;, created_by: &quot;738c8cc1-ae9b-42a5-8660-4b7612b2b35c&quot;, declaration_number: &quot;0&quot;, declaration_request_id: &quot;382cc67b-7ade-4905-b8a9-0dfe2e9b9da0&quot;, division_id: &quot;bb15bdde-ffd2-4683-8ca9-03c86b1e6846&quot;, employee_id: &quot;f8cc0822-f214-4eea-a7d4-d03142901eb1&quot;, end_date: ~D[2019-01-21], inserted_at: #DateTime&lt;2019-01-30 12:24:36.455175Z&gt;, is_active: true, legal_entity_id: &quot;980d4d01-3427-4f7f-bbdd-bd7c1b25b1e2&quot;, person_id: &quot;071a2783-f752-42d9-bcfc-44ddc7eb923d&quot;, reason: nil, reason_description: nil, scope: &quot;&quot;, signed_at: #DateTime&lt;2019-01-20 12:24:36.442837Z&gt;, start_date: ~D[2019-01-20], status: &quot;active&quot;, updated_at: #DateTime&lt;2019-01-30 12:24:36.455185Z&gt;, updated_by: &quot;8dac0fc6-04fd-4e62-9711-a85c0a42992d&quot; } }"},{"ref":"OPS.Rpc.html#t:declaration/0","title":"OPS.Rpc.declaration/0","module":"OPS.Rpc","type":"type","doc":""},{"ref":"OPS.Rpc.html#t:error/0","title":"OPS.Rpc.error/0","module":"OPS.Rpc","type":"type","doc":""},{"ref":"OPS.Rpc.html#t:errors/0","title":"OPS.Rpc.errors/0","module":"OPS.Rpc","type":"type","doc":""},{"ref":"OPS.Rpc.html#t:medication_request/0","title":"OPS.Rpc.medication_request/0","module":"OPS.Rpc","type":"type","doc":""},{"ref":"OPS.Rpc.html#t:page_medication_requests/0","title":"OPS.Rpc.page_medication_requests/0","module":"OPS.Rpc","type":"type","doc":""},{"ref":"OPS.Rpc.html#t:validation_changeset_error/0","title":"OPS.Rpc.validation_changeset_error/0","module":"OPS.Rpc","type":"type","doc":""}]