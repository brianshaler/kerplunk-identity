_ = require 'lodash'
React = require 'react'

# ugh @ amdifying when
# Promise = require 'when'

{DOM} = React

module.exports = React.createFactory React.createClass
  getInitialState: ->
    groups: @props.groups ? []

  merge: (group) ->
    (e) =>
      e.preventDefault()
      [first, others...] = group
      console.log 'merge', first._id, 'with', _.pluck others, '_id'
      Promise.all _.map others, (other) =>
        deferred = Promise.defer()
        url = "/admin/identity/link/#{first._id}/#{other._id}.json"
        console.log 'link', url
        @props.request.get url, {}, (err, data) ->
          return deferred.reject err if err
          deferred.resolve data
        deferred.promise
      .then (results) =>
        return unless @isMounted()
        console.log 'results', results
        @setState
          groups: _.filter @state.groups, (g) ->
            g[0]._id != group[0]._id
      .catch (err) =>
        console.log 'crap', err, group

  render: ->
    identityConfig = @props.globals.public.identity
    cardComponentPath = identityConfig.contactCardComponent ? identityConfig.defaultContactCard
    ContactCard = @props.getComponent cardComponentPath

    DOM.section
      className: 'content'
    ,
      DOM.h3 null, 'Merge duplicate contacts'
      _.map @state.groups, (group, index) =>
        DOM.div
          key: "group-#{index}"
          className: 'panel'
          style:
            marginBottom: '2em'
        ,
          DOM.div
            className: 'clearfix'
          ,
            _.map group, (identity) =>
              ContactCard _.extend {}, @props,
                identity: identity
                key: "card-#{identity._id}"
          DOM.div null,
            DOM.a
              onClick: @merge group
              href: '#'
              className: 'btn btn-success'
            , 'merge'
