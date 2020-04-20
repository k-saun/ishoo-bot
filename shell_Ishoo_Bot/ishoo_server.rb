require 'sinatra'
require 'octokit'
require 'dotenv/load' # Manages environment variables
require 'json'
require 'openssl'     # Verifies the webhook signature
require 'jwt'         # Authenticates a GitHub App
require 'time'        # Gets ISO 8601 representation of a Time object
require 'logger'      # Logs debug statements
require 'yaml'	      # For config.yaml parsing	

set :port, 3000
set :bind, '0.0.0.0'


# This is template code to create a GitHub App server.
# You can read more about GitHub Apps here: # https://developer.github.com/apps/
#
# On its own, this app does absolutely nothing, except that it can be installed.
# It's up to you to add functionality!
# You can check out one example in advanced_server.rb.
#
# This code is a Sinatra app, for two reasons:
#   1. Because the app will require a landing page for installation.
#   2. To easily handle webhook events.
#
# Of course, not all apps need to receive and process events!
# Feel free to rip out the event handling code if you don't need it.
#
# Have fun!
#

class GHAapp < Sinatra::Application

  # Expects that the private key in PEM format. Converts the newlines
  PRIVATE_KEY = OpenSSL::PKey::RSA.new(ENV['GITHUB_PRIVATE_KEY'].gsub('\n', "\n"))

  # Your registered app must have a secret set. The secret is used to verify
  # that webhooks are sent by GitHub.
  WEBHOOK_SECRET = ENV['GITHUB_WEBHOOK_SECRET']

  # The GitHub App's identifier (type integer) set when registering an app.
  APP_IDENTIFIER = ENV['GITHUB_APP_IDENTIFIER']

  # Turn on Sinatra's verbose logging during development
  configure :development do
    set :logging, Logger::DEBUG
  end


  # Before each request to the `/event_handler` route
  before '/event_handler' do
    get_payload_request(request)
    verify_webhook_signature
    authenticate_app
    # Authenticate the app installation in order to run API operations
    authenticate_installation(@payload)
  end


  post '/event_handler' do
    #http://octokit.github.io/octokit.rb/Octokit/Client/Issues.html#create_issue-instance_method
    #create issue, probably call this in a helper method 

    case request.env['HTTP_X_GITHUB_EVENT']
    when 'issues'
      if @payload['action'] === 'opened'
        handle_issue_opened_event(@payload)
      end
    end

  when 'push'
      handle_new_commit_event(@payload['commits'])
  end

  when 'issue_comment'
    puts "Handle issue comment commands here"
  end
 
    200 # success status
  end


  helpers do

    def handle_issue_opened_event(payload)
      #call generate Bug Report from IssueHandler2.jar
   
      CONFIG = Yaml.load_file("config.yml") unless defined? CONFIG #load config vals

#      repo = payload['repository']['full_name']
#      issue_number = payload['issue']['number']

      repo = "#{CONFIG['Github_UserInfo_repoOwner']}/#{CONFIG['Github_UserInfo_repoName']}"
      title = #{CONFIG['Github_IssueReport1_title']}
      body = #{CONFIG['Github_IssueReport1_body']}

      #test to see if issuereport is successfully generated from config.yaml
      ## SUPER AWESOME RESOURCE http://jerodsanto.net/2008/08/easy-configuration-with-ruby-and-yaml/

      @installation_client.create_issue(repo, title, body)

    end

    def handle_new_commit_event(commits)
      #invoke parser()
      commits.each  { |commit|
        commit['files'].each {|file|
          parse_commit(file['patch'])
        }
      }
      # if the code above doesnt have enough info, load each commit manuallt from push data. 
        # puts commit
        # commit_Data = commit(repo, sha, options = {})
        # parse_commit(commit_Data['patch'])
        #grab information needed to load commits using octokit
        # for each commit octokit provides parse the patch section.
        # parse_commit(commit)
      
      #create create issues in parser or return them and create them here.
    end

    def parse_commit(commit)
      str.each_line do |line|
        if line.include? "@ishoo"
          puts line
          if line.include? "[" and line.include? "]"
            puts "find description"
            descStart = line.index('[')     
            descEnd = line.index(']')
            Description = line[descStart, descEnd-descStart]   
          else
            puts "flag invalid, no description"
          end
        end
      end
    end



    # Saves the raw payload and converts the payload to JSON format
    def get_payload_request(request)
      # request.body is an IO or StringIO object
      # Rewind in case someone already read it
      request.body.rewind
      # The raw text of the body is required for webhook signature verification
      @payload_raw = request.body.read
      begin
        @payload = JSON.parse @payload_raw
      rescue => e
        fail  "Invalid JSON (#{e}): #{@payload_raw}"
      end
    end

    # Instantiate an Octokit client authenticated as a GitHub App.
    # GitHub App authentication requires that you construct a
    # JWT (https://jwt.io/introduction/) signed with the app's private key,
    # so GitHub can be sure that it came from the app and wasn't alterered by
    # a malicious third party.
    def authenticate_app
      payload = {
          # The time that this JWT was issued, _i.e._ now.
          iat: Time.now.to_i,

          # JWT expiration time (10 minute maximum)
          exp: Time.now.to_i + (10 * 60),

          # Your GitHub App's identifier number
          iss: APP_IDENTIFIER
      }

      # Cryptographically sign the JWT.
      jwt = JWT.encode(payload, PRIVATE_KEY, 'RS256')

      # Create the Octokit client, using the JWT as the auth token.
      @app_client ||= Octokit::Client.new(bearer_token: jwt)
    end

    # Instantiate an Octokit client, authenticated as an installation of a
    # GitHub App, to run API operations.
    def authenticate_installation(payload)
      @installation_id = payload['installation']['id']
      @installation_token = @app_client.create_app_installation_access_token(@installation_id)[:token]
      @installation_client = Octokit::Client.new(bearer_token: @installation_token)
    end

    # Check X-Hub-Signature to confirm that this webhook was generated by
    # GitHub, and not a malicious third party.
    #
    # GitHub uses the WEBHOOK_SECRET, registered to the GitHub App, to
    # create the hash signature sent in the `X-HUB-Signature` header of each
    # webhook. This code computes the expected hash signature and compares it to
    # the signature sent in the `X-HUB-Signature` header. If they don't match,
    # this request is an attack, and you should reject it. GitHub uses the HMAC
    # hexdigest to compute the signature. The `X-HUB-Signature` looks something
    # like this: "sha1=123456".
    # See https://developer.github.com/webhooks/securing/ for details.
    def verify_webhook_signature
      their_signature_header = request.env['HTTP_X_HUB_SIGNATURE'] || 'sha1='
      method, their_digest = their_signature_header.split('=')
      our_digest = OpenSSL::HMAC.hexdigest(method, WEBHOOK_SECRET, @payload_raw)
      halt 401 unless their_digest == our_digest

      # The X-GITHUB-EVENT header provides the name of the event.
      # The action value indicates the which action triggered the event.
      logger.debug "---- received event #{request.env['HTTP_X_GITHUB_EVENT']}"
      logger.debug "----    action #{@payload['action']}" unless @payload['action'].nil?
    end



    end
  end

  # Finally some logic to let us run this server directly from the command line,
  # or with Rack. Don't worry too much about this code. But, for the curious:
  # $0 is the executed file
  # __FILE__ is the current file
  # If they are the same—that is, we are running this file directly, call the
  # Sinatra run method
  run! if __FILE__ == $0
end
