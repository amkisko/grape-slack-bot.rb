# Unsupported Rails 6 security line

## Dependency

Active Support 6.1 in the rails6 appraisal and the library's former runtime compatibility floor.

## Symptom

The legacy appraisal could not meet the requirement that maintained hot-path framework dependencies remain on supported versions with available security fixes. It was not exercised by the current CI matrix and therefore advertised an unproved compatibility contract.

## Evidence

The rails6 appraisal and generated gemfile were removed. The runtime Active Support constraint now begins at 7.2.3.2 and remains below Rails 9. The maintained Rails 7.2 and 8.1 locks were regenerated at patched floors.

The complete root make test command passed, and bundle-audit reported no vulnerabilities in every remaining root and appraisal lock.

## Suggested fix

Support Rails 7.2.3.2 through Rails 8 only. Do not restore a Rails 6 matrix without an upstream-supported security line and a continuously executed CI job.

## Next

- Keep documentation and release notes explicit about the new minimum Rails version.
- Continue scanning each maintained appraisal graph in CI.

## Source

- grape-slack-bot.gemspec
- Appraisals
- .github/workflows/test.yml
