module CookieNames
  ADMIN_PERMISSION_TOKEN          = ENV.fetch("COOKIES_ADMIN_PERMISSION_TOKEN")
  AUTH_TOKEN                      = ENV.fetch("COOKIES_AUTH_TOKEN")
  GLOBAL_INVITATION_TOKEN         = ENV.fetch("COOKIES_GLOBAL_INVITATION_TOKEN")
  LAST_PROFILE_USED               = ENV.fetch("COOKIES_LAST_PROFILE_USED")
  LAST_VISITED_SUBMISSION_SECTION = ENV.fetch("COOKIES_LAST_VISITED_SUBMISSION_SECTION")
  IP_GEOLOCATION                  = ENV.fetch("COOKIES_IP_GEOLOCATION")
  REDIRECTED_FROM                 = ENV.fetch("COOKIES_REDIRECTED_FROM")
  SIGNUP_TOKEN                    = ENV.fetch("COOKIES_SIGNUP_TOKEN")
  SESSION_TOKEN                   = ENV.fetch("COOKIES_SESSION_TOKEN")
end