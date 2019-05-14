# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](Https://conventionalcommits.org) for commit guidelines.

<!-- changelog -->

## [2.6.1](https://github.com/edenlabllc/ops.api/compare/2.6.0...2.6.1) (2019-5-14)




### Bug Fixes:

* audit log actor_id param fetching fixed (#234)

## [2.6.0](https://github.com/edenlabllc/ops.api/compare/2.6.0...2.6.0) (2019-5-9)




### Features:

* chunk tail-recursive termination (#231)

* medication request idempotency insert (#230)

* if declaration exists, ignore insert actions (#229)

* reimbursement rpc (#223)

* process medication dispense in transaction (#224)

* medication request search param 'started_at_to' added (#222)

* medication_requests rpc (#219)

* last_medication_request_dates rpc func modified - search medication_id by list (#216)

* no event_manger repo, use kafka (#207)

* cache list declarations (#208)

* use ecto 3 (#198)

* phoenix instruments (#194)

* kaffe library is now used instead of kafka_ex (#190)

* ehealth logger (#192)

* consumer now terminates declarations in chunks (#188)

* medication request by id rpc call (#184)

### Bug Fixes:

* medication dispense process (#228)

* add kaffe to ops api (#210)

* allow out of range pages (#199)

* core: return rest of datetime fields with timezones

* refactor(core): return timestamps with timezones (#196)

* kafka topics migration (#187)

* rpc usage (#185)

* bump alpine (#183)
