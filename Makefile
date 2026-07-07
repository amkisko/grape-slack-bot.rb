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
	@for lock in Gemfile.lock gemfiles/*.gemfile.lock; do \
		gemfile="$${lock%.lock}"; \
		echo "==> $${gemfile}"; \
		if ! BUNDLE_GEMFILE="$${gemfile}" bundle install --quiet 2>/dev/null; then \
			echo "    skip (incompatible ruby for this gemfile)"; \
			continue; \
		fi; \
		BUNDLE_GEMFILE="$${gemfile}" bundle exec bundle audit check || exit 1; \
	done

clean:
	rm -rf coverage .pray/cache tmp
	rm -f spec/examples.txt *.gem
