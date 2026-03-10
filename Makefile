EMACS ?= emacs

# Run all tests by default.
MATCH ?=

.PHONY: test

test:
	cd test/ && $(EMACS) --batch -L . -L .. -l org-eval-test.el -eval '(ert-run-tests-batch-and-exit "$(MATCH)")'

clean:
	find . -name '*.elc' -delete

org-eval.elc: org-eval.el
	$(EMACS) --batch -L . -l org-eval.el -eval '(byte-compile-file "org-eval.el")'

bytecompile: org-eval.elc
