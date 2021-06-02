#!/usr/bin/env racket
#lang racket/base

(require
  racket/cmdline
  racket/function
  "github.rkt"
  "gitlab.rkt"
  "git.rkt"
)

(define (goto-pr)
  (define pull-requests (github/pull-requests owner repository ref))
  (map (curry github/display-pull-request-info owner repository) pull-requests)
  (cond [(eq? 1 (length pull-requests))
    (github/browse-pull-request owner repository (car pull-requests))]
    [(eq? 0 (length pull-requests)) (displayln "No pull request, go create one!")]
  )
)

(define goto-pipeline (make-parameter #t))
(define wait-pipeline (make-parameter #f))
(define open-pr (make-parameter #f))

(command-line
 #:program "goto"
 #:once-any
 [("-p" "--pipeline") "Open corresponding pipeline" (goto-pipeline #t)]
 [("-w" "--wait-for-pipeline") "Wait for current pipeline" (wait-pipeline #t)]
 [("-r" "--pull-request")   "Open corresponding pull-request" (open-pr #t)]
 )

(if goto-pipeline (gitlab/goto-pipeline)
  (if wait-pipeline (gitlab/wait-for-pipeline)
    (when open-pr (goto-pr))))
