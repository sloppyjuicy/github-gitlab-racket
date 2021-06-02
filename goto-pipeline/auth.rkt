#lang racket

(require oauth2
         oauth2/storage/clients
         oauth2/client/flow
         oauth2/storage/config
         oauth2/private/logging
         )


(define rc (make-log-receiver oauth2-logger 'debug))

(void 
 (thread 
  (λ()(let loop () 
        (define v (sync rc))
        (printf "[~a] ~a\n" (vector-ref v 0) (vector-ref v 1)) 
        (loop)))))

(define gh-id "178c6fc778ccc68e1d6a")
(define gh-secret "34ddeff2b558a23d38fba8a6de74f086ede1cc0b")
(define github-client (make-client 
                       "GITHUB"
                       gh-id
                       gh-secret
                       "https://github.com/login/oauth/authorize"
                       "https://github.com/login/oauth/access_token"
                       #:revoke #f
                       #:introspect #f
                       ))

(set-preference! 'redirect-host-port 80)
(set-preference! 'redirect-path "/callback")

(define maybe-client (get-client "GITHUB"))

(initiate-code-flow github-client '())
