# Cheetoh

[![Build Status](https://travis-ci.org/datacite/cheetoh.svg?branch=master)](https://travis-ci.org/datacite/cheetoh) [![Maintainability](https://api.codeclimate.com/v1/badges/ddb2efcae1339a13bb51/maintainability)](https://codeclimate.com/github/datacite/cheetoh/maintainability) [![Test Coverage](https://api.codeclimate.com/v1/badges/ddb2efcae1339a13bb51/test_coverage)](https://codeclimate.com/github/datacite/cheetoh/test_coverage)

Rails web application for providing a compatibility API layer for the DataCite MDS API,
enabling [EZID API](https://ezid.cdlib.org/doc/apidoc.html) calls for DOI and
metadata registration. The application does not store any data internally.

For documentation, and for testing the API, please go to [DataCite Support](https://support.datacite.org/v1.1/reference#ezid-compatible-api).

## Installation

Using Docker.

```
docker run -p 8080:80 datacite/cheetoh
```

You can now point your browser to `http://localhost:8080` and use the application.

By default the application connects to the DataCite test infrastructure.
Set the `API_URL` environment variable to connect to the DataCite production
infrastructure:

```
API_URL=https://api.datacite.org
```

## Development

We use Rspec for unit and acceptance testing:

```
bundle exec rspec
```

Follow along via [Github Issues](https://github.com/datacite/cheetoh/issues).

### Note on Patches/Pull Requests

* Fork the project
* Write tests for your new feature or a test that reproduces a bug
* Implement your feature or make a bug fix
* Do not mess with Rakefile, version or history
* Commit, push and make a pull request. Bonus points for topical branches.

## License
**Cheetoh** is released under the [MIT License](https://github.com/datacite/cheetoh/blob/master/LICENSE).
