#lang racket/base

(require 
  racket/function
  racket/system
  racket/sandbox
  simple-http
  emoji
  "git.rkt"
)

(provide
    gitlab/goto-pipeline
    gitlab/wait-for-pipeline
)

(define (pipe-url repo commit branch)
 (format "https://gitlab.ddbuild.io/octplane/~a/commit/~a/pipelines?ref=~a"
  repo commit branch
 ))

(define pipelines-url (format "/api/v4/projects/~a%2F~a/pipelines" owner repository))
(define pipeline-url (format "~a?sha=~a" pipelines-url commit))

(define TOKEN (format "PRIVATE-TOKEN: ~a" (getenv "GITLAB_TOKEN")))

(define gitlab-ddbuild-io
  (update-headers
   (update-ssl
    (update-host json-requester "gitlab.ddbuild.io") #t)
   (list TOKEN)))

(define (get-pipeline-from-gitlab)
   (with-handlers (
     [exn:fail:resource?  (thunk*
      (displayln "Timeout expired, VPN is not connected? ")
      (raise-user-error 'gitlab-not-reachable)

      )]
    )

    (call-with-deep-time-limit 5 (λ()
      (define pipeline (get gitlab-ddbuild-io pipeline-url))
      (define pipeline-body (json-response-body pipeline))
      (when (pair? pipeline-body)
        (car pipeline-body))
))))
  
(define (get-pipeline-url)
  (hash-ref (get-pipeline-from-gitlab) 'web_url))

(define (get-pipeline-details)
  (define pipe-id (hash-ref (get-pipeline-from-gitlab) 'id))
  (define pipeline (get gitlab-ddbuild-io
                        (format "~a/~a" pipelines-url pipe-id)))
  (define response (json-response-body pipeline))
  (when (pair? response)
    (car response))
)

(define (get-pipeline-status)
  (define pipeline (get gitlab-ddbuild-io pipeline-url))
  (define pipeline-body (json-response-body pipeline))
  (define pipe (get-pipeline-from-gitlab))
  (displayln pipe)
  (define web-url (hash-ref pipe 'web_url))
  (define status (hash-ref pipe 'status))
  (cond [(string=? status "success") (displayln (emojize "Pipeline has already suceeded :tada:"))]
        [(string=? status "failed") (displayln (emojize "Pipeline has failed :warning:"))]
        [else (displayln (format "Pipeline is ~a" status))]
        )
  status)

(define (gitlab/wait-for-pipeline-completion)
  (define status (get-pipeline-status))
  (when (string=? "running" status)
    (sleep 5)
    (gitlab/wait-for-pipeline-completion)))

(define (gitlab/goto-pipeline)
  (define url (get-pipeline-url))
  (displayln (format "Opening ~a ..." url))
  (system (format "open ~a" url))
)

(define (gitlab/wait-for-pipeline)
  (displayln (get-pipeline-url))
  (gitlab/wait-for-pipeline-completion)
  )
