EMACS ?= emacs

# Run all tests by default.
MATCH ?=

.PHONY: test bytecompile

test:
	cd test/ && $(EMACS) --batch -L . -L .. -l org-eval-test.el -eval '(ert-run-tests-batch-and-exit "$(MATCH)")'

clean:
	find . -name '*.elc' -delete

bytecompile:
	$(EMACS) --batch -L . -l org-eval.el -eval '(byte-compile-file "org-eval.el")'
