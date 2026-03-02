EMACS ?= emacs

# Run all tests by default.
MATCH ?=

.PHONY: test

test:
	cd test/ && $(EMACS) --batch -L . -L .. -l org-eval-test.el -eval '(ert-run-tests-batch-and-exit "$(MATCH)")'
