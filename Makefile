.PHONY: release lint test audit clean

release:
	ruby usr/bin/release.rb

lint:
	bundle exec rubocop
	bundle exec rbs validate

test:
	bundle exec polyrun parallel-rspec --workers 5 --merge-failures

audit:
	bundle exec bundle audit check --update
	@for lock in gemfiles/*.gemfile.lock; do \
		gemfile="$${lock%.lock}"; \
		ruby -r ./usr/lib/release_appraisal_install -e 'ReleaseAppraisalInstall.audit_gemfile(ARGV.fetch(0)) or exit(1)' "$$gemfile" || exit 1; \
	done

clean:
	rm -rf coverage .pray/cache tmp
	rm -f spec/examples.txt *.gem
