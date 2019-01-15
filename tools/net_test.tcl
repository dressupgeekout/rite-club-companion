package require http

set server [lindex $argv 0]
if {$server == ""} { set server "http://noxalas.net" }

# HEAD /
set token [::http::geturl $server -validate true]
puts "HEAD / => [::http::ncode $token]"
::http::cleanup $token

# GET /
set token [::http::geturl $server -method GET]
puts "GET / => [::http::ncode $token]"
::http::cleanup $token

# GET /api/v1/usernames
set token [::http::geturl $server/api/v1/usernames -method GET]
puts "GET /api/v1/usernames => [::http::ncode $token]"
::http::cleanup $token

# POST /api/v1/rites
set token [::http::geturl $server/api/v1/rites -method POST]
puts "POST /api/v1/rites => [::http::ncode $token]"
::http::cleanup $token
