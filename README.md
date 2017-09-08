# OPS API

[![Build Status](https://travis-ci.org/edenlabllc/ops.api.svg?branch=master)](https://travis-ci.org/edenlabllc/ops.api) [![Coverage Status](https://coveralls.io/repos/github/edenlabllc/ops.api/badge.svg?branch=master)](https://coveralls.io/github/edenlabllc/ops.api?branch=master)

Operation database which stores Declarations for Ukrainian Health Services government institution.

## Specification

- [API docs](http://docs.ehealthapi1.apiary.io/#reference/internal.-ops-db)
- [Entity-relation diagram](https://edenlab.atlassian.net/wiki/display/EH/PRM)

## Installation

You can use official Docker container to deploy this service, it can be found on [edenlabllc/ops](https://hub.docker.com/r/edenlabllc/ops/) Docker Hub.

### Dependencies

- PostgreSQL 9.6 is used as storage back-end.
- Elixir 1.4
- Erlang/OTP 19.2

## Configuration

See [ENVIRONMENT.md](docs/ENVIRONMENT.md).

## License

See [LICENSE.md](LICENSE.md).
