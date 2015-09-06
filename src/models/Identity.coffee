###
# Identity schema
###
_ = require 'lodash'
Promise = require 'when'

module.exports = (mongoose) ->
  Schema = mongoose.Schema
  ObjectId = Schema.ObjectId

  IdentitySchema = new Schema
    firstName:
      type: String
      index: true
    lastName:
      type: String
      index: true
    fullName:
      type: String
      index: true
    nickName:
      type: String
      index: true
    guid: [
      type: String
      index: true
    ]
    platform: [String]
    data: {}
    photo: [{}]
    attributes:
      type: Object
      default: -> {}
    locationText:
      type: String
    homeLocation:
      type: [Number]
      index: '2d'
    lastOutboundInteraction:
      type: Date
    lastInboundInteraction:
      type: Date
    lastInteraction:
      type: Date
    updatedAt:
      type: Date
      default: Date.now
    createdAt:
      type: Date
      default: Date.now

  IdentitySchema.methods.setData = (key, hash) ->
    # in case data is already contained within the same key
    keys = Object.keys hash
    if keys.length == 1 and keys[0] == key
      hash = hash[key]

    if !@data
      @data = {}
    if !@data[key]
      @data[key] = {}

    for k, v of hash
      @data[key][k] = v

  IdentitySchema.statics.getMe = (next) ->
    Identity = mongoose.model 'Identity'
    props =
      guid: ['me']
      platform: ['kerplunk']
    Identity.getOrCreate props, next

  IdentitySchema.statics.getOrCreate = (props, next) ->
    Identity = mongoose.model 'Identity'
    q = {}

    if props.guid?[0]
      q.guid = props.guid[0]
    # else if props.platform?[0] and props.data?[props.platform[0]].id
    #   q.platform = props.platform[0]
    #   q["data.#{props.platform[0]}.id"] = props.data?[props.platform[0]].id
    else
      console.error props
      err = new Error 'invalid identity search'
      return next err

    Identity
    .where q
    .findOne (err, identity) ->
      return next err if err

      return next null, identity if identity

      identity = new Identity props
      # unless identity.guid?
      #   identity.guid = ["#{props.platform}-#{props.platformId}"]
      identity.save (err) ->
        return next err if err
        next null, identity

  IdentitySchema.methods.link = (target, next) ->
    ActivityItem = mongoose.model 'ActivityItem'
    Identity = mongoose.model 'Identity'

    @data = {} unless @data

    for k, v of target.data
      @data[k] = v
    @markModified 'data'

    @attributes = _.merge {}, target.attributes, @attributes
    @markModified 'attributes'

    @guid = _.uniq @guid.concat target.guid
    @markModified 'guid'
    @platform = _.uniq @platform.concat target.platform
    @markModified 'platform'

    lowers = ['createdAt']
    for prop in lowers
      @[prop] = if @[prop] < target[prop]
        @[prop]
      else
        target[prop]
      @markModified prop

    highers = [
      'lastInteraction'
      'lastOutboundInteraction'
      'lastInboundInteraction'
    ]
    for prop in highers
      @[prop] = if @[prop] > target[prop]
        @[prop]
      else
        target[prop]
      @markModified prop

    @photo = @photo.concat target.photo
    @markModified 'photo'

    @save (err) =>
      return next err if err
      where =
        identity: target._id
      delta =
        identity: @_id
      options =
        multi: true
      ActivityItem
      .update where, delta, options, (err, updateResult) ->
        console.log 'link result', err, updateResult
        return next err if err
        Identity
        .where
          _id: target._id
        .remove (err, result) ->
          console.log 'removal result', target._id, err, result
          return next err if err
          next null, @


  IdentitySchema.methods.unlink = (target, next) ->
    return next new Error "Haven't rewritten unlink yet sry"

  mongoose.model 'Identity', IdentitySchema
