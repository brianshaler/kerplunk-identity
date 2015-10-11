_ = require 'lodash'
IdentitySchema = require './models/Identity'
Promise = require 'when'

module.exports = (System) ->
  Identity = System.registerModel 'Identity', IdentitySchema
  ActivityItem = null

  me = null

  linkMe = (identity, next) ->
    me.link identity, next

  updateMe = (data, next) ->
    for k, v of data
      me[k] = v
    me.save next

  findIdentity = (where) ->
    mpromise = Identity
    .where where
    .findOne()
    Promise mpromise

  getFriendCount = (where = {}) ->
    where['attributes.isFriend'] = true
    mpromise = Identity
    .where where
    .count()
    Promise mpromise

  list = (req, res, next) ->
    dir = if req.query.dir == 'desc' then -1 else 1
    sort = req.query.sort ? 'firstName'
    if sort == 'lastInteraction' and !req.query.dir
      dir = -1
    sortBy = {}
    sortBy[sort] = dir

    perPage = parseInt req.query.perPage
    perPage = 40 unless perPage > 0
    page = parseInt req.query.page
    page = if page > 1
      page - 1
    else
      0

    where =
      'attributes.isFriend': true

    where[sort] =
      '$exists': true
      '$ne': ''

    mpromise = Identity
    .where where
    .sort sortBy
    .limit perPage
    .skip page * perPage
    .find()

    Promise.all [
      Promise mpromise
      getFriendCount where
    ]
    .done (results) ->
      [identities, count] = results
      res.render 'list',
        identities: identities
        total: count
        perPage: perPage
        currentPage: page + 1
        sort: sort
        dir: if dir == -1 then 'desc' else 'asc'
    , (err) ->
      next err

  linkByIds = (req, res, next) ->
    {id1, id2} = req.params

    Promise.all [
      findIdentity {_id: id1}
      findIdentity {_id: id2}
    ]
    .then (identities) ->
      return next() unless identities?[0]?._id and identities?[1]?._id
      identities[0].link identities[1], (err, newIdentity) ->
        res.send
          err: err
          identity: newIdentity

  unlinkById = (req, res, next) ->
    {id} = req.params
    return next new Error "no unlink yet"

  viewIdentity = (req, res, next) ->
    key = req.params.id
    return next() unless key
    where = {}
    if -1 < key.indexOf '-'
      #[where.platform, where.platformid] = key.split '-'
      where.guid = key
    else
      where._id = key
    Identity
    .where where
    .findOne (err, identity) ->
      return next err if err
      return next() unless identity

      #console.log "req.params.streamType", req.params.streamType
      #res.send identity
      ActivityItem
      .where
        identity: identity._id
      .sort
        postedAt: -1
      .limit 50
      .populate 'identity'
      .find (err, items) ->
        return next err if err
        Promise.all _.map items, (item) ->
          System.do 'activityItem.populate', item
        .then (populated) ->
          res.render 'show',
            identity: identity
            items: populated
        .catch (err) ->
          next err

  editMe = (req, res, next) ->
    done = ->
      res.render 'edit',
        identity: me
        items: []
    if req.body?.firstName
      updateMe req.body, (err) ->
        return next err if err
        done()
    else
      done()

  removeIdentity = (req, res, next) ->
    return next new Error "requires unlink, which isn't ready"

    key = req.params.id
    return next() unless key
    where = {}
    if -1 < key.indexOf '-'
      #[where.platform, where.platformid] = key.split '-'
      where.guid = key
    else
      where._id = key
    Identity.find where
    .findOne (err, identity) ->
      return next err if err
      return next() unless identity?._id

      ActivityItem.remove {identity: identity._id}, (err) ->
        return next err if err
        #return res.send 'removed items'
        Identity.unlinkById identity._id, (err, results) ->
          return next err if err
          Identity.remove {_id: identity._id}, (err) ->
            return next err if err
            res.send 'removed identity'

  merge = (req, res, next) ->
    Identity
    .where
      'attributes.isFriend': true
    .find (err, whoaAllFriends) ->
      return next err if err

      groups = _ whoaAllFriends
        .map (id) ->
          id.names = _ [
            id.nickName?.toLowerCase?()?.replace /\s/g, ''
            id.fullName?.toLowerCase?()?.replace /\s/g, ''
          ]
            .compact()
            .unique()
            .value()
          _.map id.names, (name) ->
            identity: id
            name: name
        .flatten()
        .groupBy 'name'
        .filter (group) ->
          group.length > 1
        .map (group) ->
          _.pluck group, 'identity'
        .reduce (memo, group) ->
          ids = _.pluck group, '_id'
          for id in ids
            if memo.ids.indexOf(id) != -1
              return memo
          for id in ids
            memo.ids.push id
          memo.groups.push group
          memo
        , {groups: [], ids: []}
        .groups
      res.render 'merge',
        groups: groups

  routes:
    admin:
      '/admin/identity/view/:id/:streamType?': 'viewIdentity'
      '/admin/identity/remove/:id': 'removeIdentity'
      '/admin/identity/link/:id1/:id2': 'linkByIds'
      '/admin/identity/unlink/:id': 'unlinkById'
      '/admin/contacts': 'list'
      '/admin/contacts/merge': 'merge'
      '/admin/settings/identity': 'editMe'

  handlers:
    viewIdentity: viewIdentity
    removeIdentity: removeIdentity
    linkByIds: linkByIds
    unlinkById: unlinkById
    list: list
    merge: merge
    editMe: editMe

  globals:
    public:
      identity:
        avatarComponent: 'kerplunk-stream:avatar'
        defaultContactCard: 'kerplunk-identity:defaultContactCard'
      nav:
        Admin:
          Settings:
            Identity: '/admin/settings/identity'
        Contacts:
          All: '/admin/contacts'
          Merge: '/admin/contacts/merge'

  events:
    init:
      post: ->
        ActivityItem = System.getModel 'ActivityItem'
        return
    identity:
      save:
        do: (identity) ->
          Promise identity.save()

  getMe: -> me

  methods:
    linkMe: linkMe
    updateMe: updateMe

  init: (next) ->
    ActivityItem = System.getModel 'ActivityItem'
    defaultMe =
      guid: ['me']
      platform: ['kerplunk']

    Identity.getOrCreate defaultMe, (err, identity) ->
      return next err if err
      me = identity
      next()
