_ = require 'lodash'
React = require 'react'

{DOM} = React

module.exports = React.createFactory React.createClass
  getInitialState: ->
    identityToLink: null

  selectIdentityToLink: (identity) ->
    @setState
      identityToLink: identity

  linkIdentity: (e) ->
    e.preventDefault()
    id1 = @props.identity._id
    id2 = @state.identityToLink._id
    url = "/admin/identity/link/#{id1}/#{id2}.json"
    @props.request.post url, {}, (err, data) =>
      return console.log err if err
      window.location.reload()

  render: ->
    ItemComponent = @props.getComponent @props.globals.public.streamItem
    Autocomplete = @props.getComponent 'kerplunk-identity-autocomplete:input'

    identityConfig = @props.globals.public.identity
    cardComponentPath = identityConfig.contactCardComponent ? identityConfig.defaultContactCard
    ContactCard = @props.getComponent cardComponentPath

    DOM.section
      className: 'content'
    ,
      DOM.div
        className: 'clearfix'
      ,
        ContactCard (_.extend {}, @props),
          _.map @props.identity.platform, (platform) =>
            return null unless @props.identity.data[platform]?.profileUrl
            url = @props.identity.data[platform].profileUrl
            DOM.div
              key: "profile-link-#{platform}"
            ,
              DOM.a
                href: url
                target: '_blank'
              ,
                "#{platform}: "
                url.replace /^https?:\/\/(www\.)?/i, ''

      DOM.div
        className: 'panel'
      ,
        DOM.h3 null, 'Link contact'
        Autocomplete _.extend {}, @props,
          onSelect: @selectIdentityToLink
          identity: @state.identityToLink
          omit: [@props.identity._id]
        if @state.identityToLink
          DOM.a
            href: '#'
            onClick: @linkIdentity
            className: 'btn btn-success'
          ,
            DOM.em className: 'glyphicon glyphicon-link'
            ' Link'

      _.map @props.items, (item) =>
        DOM.div
          key: "item-#{item._id}"
          className: 'panel'
        ,
          ItemComponent _.extend {}, @props,
            itemId: item._id
            item: item

          # grr @ manually sorting objects
          _ item.fullAttributes
          .map (attrs, name) ->
            attrs: attrs
            name: name
          .sortBy 'name'
          .map (obj) ->
            {attrs, name} = obj
            DOM.div
              key: "attr-#{name}"
            ,
              DOM.h3 null, "#{name}s"
              _.map attrs, (attr, index) ->
                DOM.p
                  key: "attr-#{name}-#{index}"
                ,
                  attr.text
                  ': '
                  Math.round attr.attributes?.score ? 0
          .value()
        #
        # DOM.pre null,
        #   JSON.stringify item, null, 2
