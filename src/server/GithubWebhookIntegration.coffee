config           = require("./config.coffee").Configuration # deploy specific configuration
redisC           = require("./RedisClient.coffee").RedisClient(config.redis?.port, config.redis?.host)
crypto           = require('crypto')

# hackish, as anybody could really end up spoofing this information
# so, we don't let them do too much with this capability
module.exports.allowRepository = (room, repo_url, callback) ->
  redisC.hget "github:webhooks", repo_url, (err, reply) ->
    throw err if err

    if reply
      reply = JSON.parse(reply)
    else
      reply = []

    reply.push room

    redisC.hset "github:webhooks", repo_url, JSON.stringify(reply), (err, reply) ->
      throw err if err
      callback?(null)

module.exports.verifyAllowedRepository = (repo_url, callback) ->
  redisC.hget "github:webhooks", repo_url, (err, reply) ->
    throw err if err

    if reply
      reply = JSON.parse(reply)
      callback?(null, reply)
    else
      callback?("Ignoring request, no matches")

module.exports.prettyPrint = (githubResponse) ->
  r = githubResponse
  headCommit = r.head_commit.committer

  pluralize = (noun, n) ->
    if n > 1
      noun + "s"
    else
      noun

  "<img class='fl' src=#{module.exports.gravatarURL(r.pusher.email)}></img>
  #{r.pusher.name} just pushed #{r.commits.length} #{pluralize('commit', r.commits.length)} to
  <a href='#{r.repository.url}' target='_blank' title='#{r.repository.name} on GitHub'>#{r.repository.name}</a>"

module.exports.gravatarURLHash = (emailAddress) ->
  emailAddress = emailAddress.trim()
  emailAddress = emailAddress.toLowerCase()

  md5 = crypto.createHash 'md5'
  md5.update emailAddress
  md5.digest('hex')

module.exports.gravatarURL = (emailAddress) ->
  "http://www.gravatar.com/avatar/#{module.exports.gravatarURLHash(emailAddress)}.jpg?s=16&d=identicon"
