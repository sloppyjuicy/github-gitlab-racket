#lang racket/base

(require
  json
  simple-http
  yaml
  racket/system

)

(provide
  github/pull-requests
  github/display-pull-request-info
  github/browse-pull-request)


(define describe-query #<<EOS
query associatedPRs($repo: String!, $owner: String!){
  repository(name: $repo, owner: $owner) { description }
}
EOS
)

(define pr-query #<<EOS
query associatedPRs($sha: String, $repo: String!, $owner: String!){
  repository(name: $repo, owner: $owner) {
    commit: object(expression: $sha) {
      ... on Commit {
        associatedPullRequests(first:5){
          edges{
            node{
              title
              number
              body
            }
          }
        }
      }
    }
  }
}
EOS
)

(define (describe-repo owner repo)
  (jsexpr->string
    (hash
      'query describe-query
      'variables (hash 
        'owner owner
        'repo repo
    ))))



;; from https://graphql.org/learn/serving-over-http/
(define (associated-pr-graphql-request owner repo ref)
  (jsexpr->string
    (hash
      'query pr-query
      'variables (hash 
        'sha ref
        'repo repo
        'owner owner)
    )
  )
)
(define oauth-token 
  (hash-ref
      (hash-ref
        (file->yaml 
          (expand-user-path "~/.config/gh/hosts.yml"))
        "github.com")
    "oauth_token"))

(define TOKEN (format "Authorization: bearer ~a" oauth-token))

;; https://developer.github.com/v4/guides/forming-calls/#the-graphql-endpoint
(define api-github-com
  (update-headers
   (update-ssl
    (update-host json-requester "api.github.com") #t)
   (list TOKEN)))

(define (graphql request)
  (post
    api-github-com
    "/graphql"
    #:data request))

(define (hash-deep-key hsh keys)
  (define current 
    (if
      (list? hsh)
      (map (lambda (h) (hash-ref h (car keys))) hsh)
      (hash-ref hsh (car keys))
    )
  )
  (define other-keys (cdr keys))
  (if
    (null? other-keys)
    current
    (hash-deep-key current other-keys)
  )
)

(define (github/pull-requests owner repo-name ref)
  (define response
    (graphql (associated-pr-graphql-request owner repo-name ref)))
  (when (eq? (get-status-code response) 200)
    (hash-deep-key (json-response-body response) '
      (data
        repository
        commit
        associatedPullRequests
        edges
        node
      ))))

(define (url-for-pr owner repository pr)
  (format "https://github.com/~a/~a/pull/~a"
    owner
    repository
    (hash-ref pr 'number)
  )
)

(define (github/display-pull-request-info owner repository pr)
  (displayln (format "~a (~a)" 
    (hash-ref pr 'title)
    (url-for-pr owner repository pr)
  ))
)

(define (github/browse-pull-request owner repository pr)
  (define url (url-for-pr owner repository pr))
  (displayln (format "Opening ~a..." url))
  (system (format "open ~a" url))
)

(define (describe owner repo)
  (graphql (describe-repo owner repo))
)

