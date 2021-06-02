#lang racket/base

(require
  racket/list
  racket/string
  racket/system
  racket/port
  rash/prompt-helpers/git-info
)

(provide
    owner
    repository
    commit
    ref
)

(define (shell-stdout command)
  (string-trim (with-output-to-string (λ() (system command)))))

(define (remote-show)
  (shell-stdout "git remote show -n origin"))

(define (fetch-url-line remote-show-output)
  (first 
   (filter
    (lambda (s) (and (string-prefix? s "  Fetch URL:")))
    (string-split remote-show-output "\n"))))

(define (remote remote-show-output)
  (letrec (
    [remote-path (substring (fetch-url-line remote-show-output) (string-length "  Fetch URL: git@github.com:"))]
    [end-marker (if (string-suffix? remote-path ".git") (- (string-length remote-path) 4) (string-length remote-path))]
  )
    (string-split (substring remote-path 0 end-marker) "/")))

(define (owner-repository)
  (remote (remote-show)))

(define commit (shell-stdout "git rev-parse HEAD"))
(define ref (git-branch (current-directory)))

(define owner (first (owner-repository)))

(define repository (second (owner-repository)))

(module+ test
  (require rackunit)
  (define sample-remote-output "* remote origin\n  Fetch URL: git@github.com:octplane/cocotte.git\n  Push  URL: git@github.com:octplane/cocotte.git\n  HEAD branch: (not queried)\n  Remote branch: (status not queried)\n    master\n  Local branch configured for 'git pull':\n    master merges with remote master\n  Local ref configured for 'git push' (status not queried):\n    (matching) pushes to (matching)")
  (check-equal? (remote sample-remote-output) '("octplane" "cocotte") "Remote is not correctly computed")
  (check-equal? (owner-repository) '("DataDog" "experimental") "Remote is not correctly computed")
  (check-equal? repository "experimental" "Repository Name is not correctly computed")
  (check-equal? owner "DataDog" "Owner Name is not correctly computed")
)