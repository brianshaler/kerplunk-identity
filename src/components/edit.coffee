_ = require 'lodash'
React = require 'react'

{DOM} = React

module.exports = React.createFactory React.createClass
  render: ->
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
          DOM.form
            action: '/admin/settings/identity'
            method: 'post'
          ,
            DOM.input
              name: 'firstName'
              placeholder: 'first name'
              defaultValue: @props.identity.firstName
            DOM.input
              name: 'lastName'
              placeholder: 'last name'
              defaultValue: @props.identity.lastName
            DOM.input
              name: 'fullName'
              placeholder: 'full name'
              defaultValue: @props.identity.fullName
            DOM.input
              name: 'nickName'
              placeholder: 'nick name'
              defaultValue: @props.identity.nickName
            DOM.input
              type: 'submit'
              value: 'save'
          _.map @props.identity.platform, (platform) =>
            return null unless @props.identity.data?[platform]?.profileUrl
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
