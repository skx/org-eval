# org-eval

`org-eval` is a utility package which makes it possible to automatically execute the contents of named blocks when `org-mode` files are loaded, or saved.

It can be used to automatically update all tables in a document, via the use of `(org-table-iterate-buffer-tables)` for example.



## Installation / Configuration

The legacy way to install would be to clone this repository and ensure the directory is available upon your load-path, or copy your local lisp tree.

The package should be available upon MELPA soon.

Suggested usage if you're using the traditional approach:

```
(require 'org-eval)

;; Set the safe-directory prefix.
(setq org-eval-prefix-list (list (expand-file-name "~/Private/")))

;; Set the names of the blocks we should execute on load/save.
(setq org-eval-loadblock-name "my-startblock"
      org-eval-saveblock-name "my-saveblock")

;; Enable for all org-mode files.
(org-eval-global-mode 1)
```

If you prefer `use-package` then this works:

```
(use-package org-eval
  :after org
  :config
    (setq org-eval-prefix-list    (list (expand-file-name "~/Private/"))
          org-eval-loadblock-name "my-startblock"
          org-eval-saveblock-name "my-saveblock")
    (org-eval-global-mode 1))
```

If you **don't** enable `org-eval-global-mode` you can instead add a hook on certain files.



## Safety

Because evaluating arbitrary lisp-code can have serious side-effects, and compromise security, the package will only execute code from files located within directories contained upon the list `org-eval-prefix-list`.



## Example Usage

Consider the following `org-mode` file, assuming it is located within a directory listed on the safe prefix list, as noted above, when you load it a message should appear:

```
* Intro
  This is a random `org-mode' file which is used for example purposes.

* Lisp Stuff
  Here we have a block of code which is automatically evaluated when this file is loaded:

  #+NAME: skx-startblock
  #+BEGIN_SRC emacs-lisp :results output silent
    (message "I am alive!")
  #+END_SRC

  You could define a second block, with the name =my-saveblock= which would be executed
  when your file is saved too - which you might use to update all tables, or perform
  similar automation.
```



## Testing

You can run `make test` via the supplied [Makefile](Makefile) to run the tests in a batch-mode, otherwise load the file [test/org-eval-test.el](test/org-eval-test.el) and run `M-x eval buffer`, you should see the test results in a new buffer.

If any tests fail that's a bug.
